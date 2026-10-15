import 'package:flutter/material.dart';
import '../../models/ngo_admin_model.dart';
import '../../services/ngo_admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

/// NGO administration and monitoring (CFSASA-97). Every figure on these
/// pages is read live from the backend (`/ngo/admin/*`).
class NgoAdministrationScreen extends StatelessWidget {
  final String token;
  final int initialTab;

  const NgoAdministrationScreen({
    super.key,
    required this.token,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey(initialTab),
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: AppTheme.fieldFill,
        body: Column(
          children: [
            NgoHeader(
              title: 'Manage',
              subtitle: 'Donors, recipients and delivery alerts',
              bottom: const HeaderTabBar(
                tabs: [
                  Tab(text: 'Donors'),
                  Tab(text: 'Recipients'),
                  Tab(text: 'Alerts'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DonorsPage(token: token),
                  _RecipientsPage(token: token),
                  _AlertsPage(token: token),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads data once, shows loading/error states and supports pull-to-refresh.
class _LoadablePage<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
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
        final matchesQuery =
            q.isEmpty ||
            d.displayName.toLowerCase().contains(q) ||
            d.email.toLowerCase().contains(q) ||
            d.customUserId.toLowerCase().contains(q);
        return matchesStatus && matchesQuery;
      }).toList();
      return Column(
        children: [
          SearchField(
            hint: 'Search by name, email or ID',
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
    margin: const EdgeInsets.fromLTRB(16, 9, 16, 9),
    padding: const EdgeInsets.all(18),
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
                    donor.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(donor.status),
          ],
        ),
        const SizedBox(height: 12),
        InfoRow(Icons.email_outlined, donor.email, maxLines: 1),
        const SizedBox(height: 5),
        InfoRow(Icons.badge_outlined, 'ID: ${donor.customUserId}', maxLines: 1),
        const SizedBox(height: 5),
        InfoRow(
          Icons.calendar_today_outlined,
          'Joined ${formatDate(donor.joinedAt)}',
          maxLines: 1,
        ),
        if (donor.donorType == 'ORGANIZATION' &&
            donor.name.isNotEmpty &&
            donor.name != donor.displayName) ...[
          const SizedBox(height: 5),
          InfoRow(Icons.person_outline, donor.name, maxLines: 1),
        ],
        const Divider(height: 30, color: AppTheme.border),
        MetricGrid(
          children: [
            _AdminStatBox(
              value: '${donor.totalDonations}',
              label: 'Total donations',
            ),
            _AdminStatBox(
              value: '${donor.approvedDonations}',
              label: 'Approved',
              color: AppTheme.primaryGreenDark,
            ),
            _AdminStatBox(
              value: '${donor.pendingDonations}',
              label: 'Pending review',
              color: Colors.orange.shade700,
            ),
            _AdminStatBox(
              value: '${donor.rejectedDonations}',
              label: 'Rejected',
              color: Colors.red.shade600,
            ),
          ],
        ),
        if (donor.lastDonationAt != null) ...[
          const SizedBox(height: 12),
          InfoRow(
            Icons.history,
            'Last donation ${formatDate(donor.lastDonationAt)}',
          ),
        ],
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
        final matchesQuery =
            q.isEmpty ||
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
    margin: const EdgeInsets.fromLTRB(16, 9, 16, 9),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8EEFC),
              child: Text(
                recipient.name.isEmpty ? '?' : recipient.name[0].toUpperCase(),
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
        const SizedBox(height: 14),
        InfoRow(Icons.location_on_outlined, recipient.location),
        const SizedBox(height: 5),
        InfoRow(Icons.email_outlined, recipient.email, maxLines: 1),
        const SizedBox(height: 5),
        InfoRow(Icons.phone_outlined, recipient.phoneNumber, maxLines: 1),
        const Divider(height: 30, color: AppTheme.border),
        MetricGrid(
          children: [
            _AdminStatBox(
              value: '${recipient.totalRequests}',
              label: 'Total requests',
            ),
            _AdminStatBox(
              value: '${recipient.approvedRequests}',
              label: 'Approved',
              color: AppTheme.primaryGreenDark,
            ),
            _AdminStatBox(
              value: '${recipient.pendingRequests}',
              label: 'Pending review',
              color: Colors.orange.shade700,
            ),
            _AdminStatBox(
              value: '${recipient.rejectedRequests}',
              label: 'Rejected',
              color: Colors.red.shade600,
            ),
          ],
        ),
      ],
    ),
  );
}

class _AdminStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _AdminStatBox({
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.fieldFill,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: StatTile(value, label, color: color),
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
                        hint:
                            'Problems reported by volunteers during deliveries appear here.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => _AlertCard(
                      alert: visible[i],
                      onUpdate: (status) => _update(visible[i], status, reload),
                    ),
                  ),
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
