import 'package:flutter/material.dart';
import '../../models/ngo_admin_model.dart';
import '../../services/ngo_admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';
import 'ngo_impact_dashboard_screen.dart';

/// NGO administration and monitoring (CFSASA-97). Every figure on these
/// pages is read live from the backend (`/ngo/admin/*`).
class NgoAdministrationScreen extends StatefulWidget {
  final String token;
  const NgoAdministrationScreen({super.key, required this.token});

  @override
  State<NgoAdministrationScreen> createState() =>
      _NgoAdministrationScreenState();
}

class _NgoAdministrationScreenState extends State<NgoAdministrationScreen> {
  int _selectedIndex = 0;

  static const _titles = [
    'Administration',
    'Donors',
    'Recipients',
    'Alerts',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OverviewPage(token: widget.token),
      _DonorsPage(token: widget.token),
      _RecipientsPage(token: widget.token),
      _AlertsPage(token: widget.token),
    ];
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: AppTheme.lightGreen,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreenDark),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(
              Icons.volunteer_activism,
              color: AppTheme.primaryGreenDark,
            ),
            label: 'Donors',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: AppTheme.primaryGreenDark),
            label: 'Recipients',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(
              Icons.notifications,
              color: AppTheme.primaryGreenDark,
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

/// Loads data once, shows loading/error states and supports pull-to-refresh.
class _LoadablePage<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload)
      builder;

  const _LoadablePage({required this.load, required this.builder});

  @override
  State<_LoadablePage<T>> createState() => _LoadablePageState<T>();
}

class _LoadablePageState<T> extends State<_LoadablePage<T>>
    with AutomaticKeepAliveClientMixin {
  T? _data;
  String? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }
    if (_data == null) {
      return ErrorState(
        error: _error ?? 'Unknown error',
        onRetry: () {
          setState(() => _loading = true);
          _reload();
        },
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _reload,
      child: widget.builder(context, _data as T, _reload),
    );
  }
}

// ---------------------------------------------------------------- Overview

class _OverviewPage extends StatelessWidget {
  final String token;
  const _OverviewPage({required this.token});

  @override
  Widget build(BuildContext context) => _LoadablePage<AdminOverview>(
        load: () => NgoAdminService.getOverview(token: token),
        builder: (context, overview, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HeroSummary(
                label: 'Needs your attention',
                value:
                    '${overview.pendingDonations + overview.pendingRequests + overview.openProblems}',
                caption: overview.pendingDonations +
                            overview.pendingRequests +
                            overview.openProblems ==
                        0
                    ? 'You are all caught up'
                    : 'items waiting for your review',
                stats: [
                  ('${overview.pendingDonations}', 'Donations'),
                  ('${overview.pendingRequests}', 'Requests'),
                  ('${overview.openProblems}', 'Alerts'),
                ],
              ),
            ),
            const _SectionHeading('Platform at a glance'),
            MetricGrid(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                MetricCard(
                  icon: Icons.volunteer_activism_outlined,
                  value: '${overview.donors}',
                  label: 'Donors',
                ),
                MetricCard(
                  icon: Icons.groups_outlined,
                  value: '${overview.recipients}',
                  label: 'Recipients',
                  color: const Color(0xFF3F6EDC),
                ),
                MetricCard(
                  icon: Icons.directions_bike_outlined,
                  value: '${overview.volunteers}',
                  label: 'Volunteers',
                  color: const Color(0xFF008C82),
                ),
                MetricCard(
                  icon: Icons.inventory_2_outlined,
                  value: '${overview.donationsThisMonth}',
                  label: 'Donations this month',
                  color: const Color(0xFF9B6DCE),
                ),
              ],
            ),
            if (overview.priorityTasks.isNotEmpty) ...[
              const _SectionHeading('Next up'),
              ...overview.priorityTasks.map((task) => _TaskCard(task: task)),
            ],
            if (overview.pendingDeliveries > 0)
              NgoCard(
                child: Row(
                  children: [
                    IconBadge(
                      Icons.local_shipping_outlined,
                      color: Colors.orange.shade700,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${overview.pendingDeliveries} deliveries are waiting for a volunteer',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const _SectionHeading('Reports'),
            NgoCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImpactDashboardScreen(token: token),
                ),
              ),
              child: const Row(
                children: [
                  IconBadge(
                    Icons.insights_outlined,
                    color: AppTheme.primaryGreenDark,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform impact & reports',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'View charts and export PDF or CSV reports',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.greyText),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
      );
}

class _TaskCard extends StatelessWidget {
  final AdminTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final high = task.priority == 'HIGH';
    final color = high ? Colors.red.shade600 : Colors.orange.shade700;
    return NgoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.detail} • ${timeAgo(task.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(high ? 'High' : 'Medium', color: color),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Donors

class _DonorsPage extends StatefulWidget {
  final String token;
  const _DonorsPage({required this.token});

  @override
  State<_DonorsPage> createState() => _DonorsPageState();
}

class _DonorsPageState extends State<_DonorsPage> {
  String _query = '';
  String _status = 'ALL';

  @override
  Widget build(BuildContext context) => _LoadablePage<List<AdminDonor>>(
        load: () => NgoAdminService.getDonors(token: widget.token),
        builder: (context, donors, _) {
          final visible = donors.where((d) {
            final matchesStatus = _status == 'ALL' || d.status == _status;
            final q = _query.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                d.email.toLowerCase().contains(q) ||
                d.customUserId.toLowerCase().contains(q);
            return matchesStatus && matchesQuery;
          }).toList();
          return Column(
            children: [
              SearchField(
                hint: 'Search by email or ID',
                onChanged: (v) => setState(() => _query = v),
              ),
              FilterChips(
                options: const ['ALL', 'ACTIVE', 'INACTIVE', 'NEW'],
                selected: _status,
                onSelected: (v) => setState(() => _status = v),
              ),
              Expanded(
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          EmptyState('No donors found'),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _DonorCard(donor: visible[i]),
                      ),
              ),
              const _HonestyNote(
                'Active = donated in the last 90 days. Donor names are not stored, so email is shown.',
              ),
            ],
          );
        },
      );
}

class _DonorCard extends StatelessWidget {
  final AdminDonor donor;
  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) => NgoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.lightGreen,
                  child: Icon(
                    Icons.volunteer_activism,
                    color: AppTheme.primaryGreenDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${donor.customUserId} • Joined ${formatDate(donor.joinedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(donor.status),
              ],
            ),
            const Divider(height: 24, color: AppTheme.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatTile('${donor.totalDonations}', 'Donations'),
                StatTile(
                  '${donor.approvedDonations}',
                  'Approved',
                  color: AppTheme.primaryGreenDark,
                ),
                StatTile(
                  '${donor.pendingDonations}',
                  'Pending',
                  color: Colors.orange.shade700,
                ),
                StatTile(
                  '${donor.rejectedDonations}',
                  'Rejected',
                  color: Colors.red.shade600,
                ),
              ],
            ),
            if (donor.lastDonationAt != null)
              InfoRow(
                Icons.history,
                'Last donation ${formatDate(donor.lastDonationAt)}',
              ),
          ],
        ),
      );
}

// -------------------------------------------------------------- Recipients

class _RecipientsPage extends StatefulWidget {
  final String token;
  const _RecipientsPage({required this.token});

  @override
  State<_RecipientsPage> createState() => _RecipientsPageState();
}

class _RecipientsPageState extends State<_RecipientsPage> {
  String _query = '';
  String _status = 'ALL';

  @override
  Widget build(BuildContext context) => _LoadablePage<List<AdminRecipient>>(
        load: () => NgoAdminService.getRecipients(token: widget.token),
        builder: (context, recipients, _) {
          final visible = recipients.where((r) {
            final matchesStatus = _status == 'ALL' || r.status == _status;
            final q = _query.trim().toLowerCase();
            final matchesQuery = q.isEmpty ||
                r.name.toLowerCase().contains(q) ||
                r.email.toLowerCase().contains(q) ||
                r.location.toLowerCase().contains(q);
            return matchesStatus && matchesQuery;
          }).toList();
          return Column(
            children: [
              SearchField(
                hint: 'Search by name, email or location',
                onChanged: (v) => setState(() => _query = v),
              ),
              FilterChips(
                options: const ['ALL', 'ACTIVE', 'INACTIVE', 'NEW'],
                selected: _status,
                onSelected: (v) => setState(() => _status = v),
              ),
              Expanded(
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          EmptyState('No recipients found'),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: visible.length,
                        itemBuilder: (_, i) =>
                            _RecipientCard(recipient: visible[i]),
                      ),
              ),
              const _HonestyNote(
                'Active = requested food in the last 90 days.',
              ),
            ],
          );
        },
      );
}

class _RecipientCard extends StatelessWidget {
  final AdminRecipient recipient;
  const _RecipientCard({required this.recipient});

  @override
  Widget build(BuildContext context) => NgoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8EEFC),
                  child: Text(
                    recipient.name.isEmpty
                        ? '?'
                        : recipient.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF3F6EDC),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recipient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(recipient.status),
              ],
            ),
            InfoRow(Icons.location_on_outlined, recipient.location),
            InfoRow(Icons.email_outlined, recipient.email, maxLines: 1),
            InfoRow(Icons.phone_outlined, recipient.phoneNumber, maxLines: 1),
            const Divider(height: 24, color: AppTheme.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatTile('${recipient.totalRequests}', 'Requests'),
                StatTile(
                  '${recipient.approvedRequests}',
                  'Approved',
                  color: AppTheme.primaryGreenDark,
                ),
                StatTile(
                  '${recipient.pendingRequests}',
                  'Pending',
                  color: Colors.orange.shade700,
                ),
                StatTile(
                  '${recipient.rejectedRequests}',
                  'Rejected',
                  color: Colors.red.shade600,
                ),
              ],
            ),
          ],
        ),
      );
}

// ------------------------------------------------------------------ Alerts

class _AlertsPage extends StatefulWidget {
  final String token;
  const _AlertsPage({required this.token});

  @override
  State<_AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<_AlertsPage> {
  String _filter = 'OPEN';

  Future<void> _update(
    AdminAlert alert,
    String status,
    Future<void> Function() reload,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NgoAdminService.updateAlertStatus(
        token: widget.token,
        id: alert.id,
        status: status,
      );
      await reload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'RESOLVED'
                ? 'Alert marked as resolved.'
                : 'Alert acknowledged.',
          ),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _LoadablePage<List<AdminAlert>>(
        load: () => NgoAdminService.getAlerts(token: widget.token),
        builder: (context, alerts, reload) {
          final visible = alerts.where((a) {
            switch (_filter) {
              case 'OPEN':
                return !a.isResolved;
              case 'RESOLVED':
                return a.isResolved;
              default:
                return true;
            }
          }).toList();
          return Column(
            children: [
              FilterChips(
                options: const ['OPEN', 'RESOLVED', 'ALL'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          EmptyState(
                            'No alerts here',
                            icon: Icons.notifications_off_outlined,
                            hint: 'Problems reported by volunteers during deliveries appear here.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _AlertCard(
                          alert: visible[i],
                          onUpdate: (status) =>
                              _update(visible[i], status, reload),
                        ),
                      ),
              ),
              const _HonestyNote(
                'Alerts are delivery problems reported by volunteers.',
              ),
            ],
          );
        },
      );
}

class _AlertCard extends StatelessWidget {
  final AdminAlert alert;
  final ValueChanged<String> onUpdate;
  const _AlertCard({required this.alert, required this.onUpdate});

  @override
  Widget build(BuildContext context) => NgoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  Icons.report_problem_outlined,
                  color: statusColor(alert.status),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.problemType,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        timeAgo(alert.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(alert.status),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(Icons.notes_outlined, alert.description, maxLines: 3),
            InfoRow(Icons.restaurant_outlined, 'Delivery: ${alert.foodItem}'),
            if ((alert.dropoffAddress ?? '').isNotEmpty)
              InfoRow(Icons.place_outlined, 'To: ${alert.dropoffAddress}'),
            InfoRow(
              Icons.person_outline,
              'Reported by volunteer ${alert.volunteerId}',
              maxLines: 1,
            ),
            if (!alert.isResolved) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (alert.status == 'REPORTED')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onUpdate('ACKNOWLEDGED'),
                        child: const Text('Acknowledge'),
                      ),
                    ),
                  if (alert.status == 'REPORTED') const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onUpdate('RESOLVED'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                      child: const Text('Mark resolved'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _HonestyNote extends StatelessWidget {
  final String text;
  const _HonestyNote(this.text);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.greyText),
        ),
      );
}
