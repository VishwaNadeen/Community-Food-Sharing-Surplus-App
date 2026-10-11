import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ngo_admin_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ngo_admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

/// First page the NGO coordinator sees after login: what needs attention
/// now, quick shortcuts and the key numbers of the network.
class NgoOverviewScreen extends StatefulWidget {
  final String token;
  final ValueChanged<int> onNavigate;
  final int refreshTick;

  const NgoOverviewScreen({
    super.key,
    required this.token,
    required this.onNavigate,
    this.refreshTick = 0,
  });

  @override
  State<NgoOverviewScreen> createState() => _NgoOverviewScreenState();
}

class _NgoOverviewScreenState extends State<NgoOverviewScreen> {
  late Future<AdminOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = NgoAdminService.getOverview(token: widget.token);
  }

  @override
  void didUpdateWidget(NgoOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _future = NgoAdminService.getOverview(token: widget.token);
    }
  }

  Future<void> _refresh() async {
    final next = NgoAdminService.getOverview(token: widget.token);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<AdminOverview>(
            future: _future,
            builder: (context, snapshot) {
              final overview = snapshot.data;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Header(
                    greeting: _greeting,
                    email: user?.email ?? '',
                    userId: user?.customUserId ?? '',
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState != ConnectionState.done &&
                      overview == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    ErrorState(
                      error: snapshot.error.toString(),
                      onRetry: _refresh,
                    )
                  else if (overview != null) ..._content(overview),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(AdminOverview o) {
    final waiting =
        o.pendingDonations + o.pendingRequests + o.pendingDeliveries + o.openProblems;

    return [
      NgoCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  waiting == 0
                      ? Icons.check_circle_outline
                      : Icons.notifications_active_outlined,
                  color: waiting == 0 ? AppTheme.primaryGreen : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waiting == 0 ? 'All caught up' : 'Needs your attention',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        waiting == 0
                            ? 'Nothing is waiting for review.'
                            : '$waiting item${waiting == 1 ? '' : 's'} waiting',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AttentionRow(
              icon: Icons.volunteer_activism_outlined,
              label: 'Donations to approve',
              count: o.pendingDonations,
              onTap: () => widget.onNavigate(1),
            ),
            _AttentionRow(
              icon: Icons.restaurant_outlined,
              label: 'Food requests to review',
              count: o.pendingRequests,
              onTap: () => widget.onNavigate(1),
            ),
            _AttentionRow(
              icon: Icons.local_shipping_outlined,
              label: 'Pending deliveries',
              count: o.pendingDeliveries,
              onTap: () => widget.onNavigate(3),
            ),
            _AttentionRow(
              icon: Icons.report_problem_outlined,
              label: 'Open alerts',
              count: o.openProblems,
              onTap: () => widget.onNavigate(3),
            ),
          ],
        ),
      ),
      const SectionTitle('Quick actions', horizontal: 0),
      Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.fact_check_outlined,
              label: 'Review',
              onTap: () => widget.onNavigate(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.insights_outlined,
              label: 'Impact',
              onTap: () => widget.onNavigate(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Reports',
              onTap: () => widget.onNavigate(2),
            ),
          ),
        ],
      ),
      const SectionTitle('Network at a glance', horizontal: 0),
      MetricGrid(
        children: [
          MetricCard(
            icon: Icons.storefront_outlined,
            value: '${o.donors}',
            label: 'Donors',
          ),
          MetricCard(
            icon: Icons.groups_outlined,
            value: '${o.recipients}',
            label: 'Recipients',
            color: Colors.blue,
          ),
          MetricCard(
            icon: Icons.directions_bike_outlined,
            value: '${o.volunteers}',
            label: 'Volunteers',
            color: Colors.purple,
          ),
          MetricCard(
            icon: Icons.inventory_2_outlined,
            value: '${o.donationsThisMonth}',
            label: 'Donations this month',
            color: Colors.orange,
          ),
        ],
      ),
      if (o.priorityTasks.isNotEmpty) ...[
        const SectionTitle('Priority tasks', horizontal: 0),
        for (final task in o.priorityTasks.take(3))
          NgoCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => widget.onNavigate(3),
            child: Row(
              children: [
                IconBadge(
                  Icons.flag_outlined,
                  color: task.priority.toUpperCase() == 'HIGH'
                      ? Colors.red
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        task.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(titleCase(task.priority)),
              ],
            ),
          ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String email;
  final String userId;

  const _Header({
    required this.greeting,
    required this.email,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'NGO Coordinator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userId.isEmpty ? email : '$email  •  $userId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _AttentionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.greyText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.darkText, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: active ? Colors.orange.shade50 : AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.orange.shade800
                      : AppTheme.primaryGreenDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.greyText),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryGreenDark, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
