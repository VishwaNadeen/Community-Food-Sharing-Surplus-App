import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ngo_admin_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ngo_admin_service.dart';
import '../../services/ngo_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

/// First page the NGO coordinator sees after login: what needs attention
/// now, shortcuts to the main areas and the key numbers of the network.
/// All figures come from `/ngo/admin/overview`.
class NgoOverviewScreen extends StatefulWidget {
  final String token;
  final void Function(int destination, [int section]) onNavigate;
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
    _loadCoordinatorName();
  }

  Future<void> _loadCoordinatorName() async {
    try {
      final profile = await NgoProfileService.getProfile(widget.token);
      if (!mounted) return;
      Provider.of<AuthProvider>(context, listen: false).setNgoCoordinatorName(
        profile['firstName'] as String?,
        profile['lastName'] as String?,
      );
    } catch (_) {
      // Keep the dashboard usable when the optional profile is not set yet.
    }
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
    final coordinatorName =
        Provider.of<AuthProvider>(context).ngoCoordinatorName;
    final firstName = coordinatorName?.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      body: FutureBuilder<AdminOverview>(
        future: _future,
        builder: (context, snapshot) {
          final o = snapshot.data;
          final alerts = o?.openProblems ?? 0;
          return Column(
            children: [
              NgoHeader(
                title: firstName == null
                    ? '$_greeting,'
                    : '$_greeting, $firstName',
                subtitle: 'NGO Coordinator',
                actions: [
                  HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Delivery alerts',
                    badge: alerts,
                    onPressed: () => widget.onNavigate(3, 2),
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _refresh,
                  child: _body(snapshot, o),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(AsyncSnapshot<AdminOverview> snapshot, AdminOverview? o) {
    if (o == null) {
      final child = snapshot.hasError
          ? ErrorState(error: snapshot.error.toString(), onRetry: _refresh)
          : const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 320, child: child)],
      );
    }

    final attentionCount =
        o.pendingRequests + o.pendingDonations + o.openProblems;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CommunitySnapshot(overview: o),
        SectionTitle(
          'Priority queue',
          trailing: attentionCount == 0
              ? 'All clear'
              : '$attentionCount need attention',
          horizontal: 0,
        ),
        _queue(o),
        const SectionTitle(
          'Your workspace',
          trailing: 'Quick access',
          horizontal: 0,
        ),
        _OperationCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Administration',
          subtitle: 'Manage donor and recipient records',
          onTap: () => widget.onNavigate(3, 0),
        ),
        const SizedBox(height: 10),
        _OperationCard(
          icon: Icons.insights_outlined,
          title: 'Platform impact',
          subtitle: 'Results, trends and downloadable reports',
          onTap: () => widget.onNavigate(2),
        ),
      ],
    );
  }

  Widget _queue(AdminOverview o) {
    final rows = <Widget>[
      if (o.pendingRequests > 0)
        _QueueRow(
          icon: Icons.restaurant_outlined,
          label: 'Food requests',
          detail: '${o.pendingRequests} waiting for approval',
          onTap: () => widget.onNavigate(1, 0),
        ),
      if (o.pendingDonations > 0)
        _QueueRow(
          icon: Icons.volunteer_activism_outlined,
          label: 'Food donations',
          detail: '${o.pendingDonations} waiting for approval',
          onTap: () => widget.onNavigate(1, 1),
        ),
      if (o.openProblems > 0)
        _QueueRow(
          icon: Icons.report_problem_outlined,
          label: 'Delivery alerts',
          detail: '${o.openProblems} reported by volunteers',
          onTap: () => widget.onNavigate(3, 2),
        ),
    ];

    if (rows.isEmpty) {
      return const NgoCard(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            IconBadge(Icons.check_circle_outline, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'All caught up. Nothing needs your attention.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return NgoCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _CommunitySnapshot extends StatelessWidget {
  final AdminOverview overview;
  const _CommunitySnapshot({required this.overview});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF117C4C), Color(0xFF2EAD67)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24117C4C),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'COMMUNITY SNAPSHOT',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .65,
                  fontSize: 10.5,
                ),
              ),
            ),
            const Icon(Icons.insights_outlined, color: Colors.white70, size: 19),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          '${overview.donationsThisMonth}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'donations submitted this month',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: .25),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SnapshotMetric(value: overview.donors, label: 'Donors'),
            _SnapshotMetric(value: overview.recipients, label: 'Recipients'),
            _SnapshotMetric(value: overview.volunteers, label: 'Volunteers'),
          ],
        ),
      ],
    ),
  );
}

class _SnapshotMetric extends StatelessWidget {
  final int value;
  final String label;
  const _SnapshotMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _OperationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OperationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => NgoCard(
    margin: EdgeInsets.zero,
    onTap: onTap,
    child: Row(
      children: [
        IconBadge(icon, color: AppTheme.primaryGreenDark, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.greyText,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppTheme.greyText),
      ],
    ),
  );
}

class _QueueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  const _QueueRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          IconBadge(icon, color: AppTheme.primaryGreenDark, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.greyText),
        ],
      ),
    ),
  );
}
