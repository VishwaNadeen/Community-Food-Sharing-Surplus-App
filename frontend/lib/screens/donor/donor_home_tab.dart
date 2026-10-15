
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import 'donor_ui.dart';

class DonorHomeTab extends StatefulWidget {
  /// Opens the Donations tab on a section: ALL, PENDING, APPROVED or
  /// REJECTED.
  final ValueChanged<String>? onViewDonations;

  const DonorHomeTab({
    super.key,
    this.onViewDonations,
  });

  @override
  State<DonorHomeTab> createState() => _DonorHomeTabState();
}

class _DonorHomeTabState extends State<DonorHomeTab> {
  List<DonationModel> _donations = [];
  String? _firstName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _donations.isEmpty;
      _error = null;
    });

    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    // The name is only used in the greeting, so a failure here is ignored.
    _loadFirstName(token);

    try {
      final donations =
          await DonationService.getMyDonations(token: token);

      if (!mounted) return;

      // Show the newest donations first.
      final activeDonations = donations
          .where(
            (donation) =>
                donation.status.toUpperCase() != 'CANCELLED',
          )
          .toList()
        ..sort(
          (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
        );

      setState(() {
        _donations = activeDonations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFirstName(String token) async {
    try {
      final response = await AuthService.getDonorProfile(token);
      final profile = response['profile'] ?? response['donor'] ?? response;
      final name = profile is Map ? profile['firstName']?.toString() : null;

      if (!mounted || name == null || name.trim().isEmpty) return;
      setState(() => _firstName = name.trim());
    } catch (_) {
      // Keep the generic greeting.
    }
  }

  int _countByStatus(String status) {
    return _donations
        .where(
          (donation) =>
              donation.status.toUpperCase() == status,
        )
        .length;
  }

  // ---------- Greeting ----------

  /// Greeting and icon for the current time of day.
  static ({String text, IconData icon}) _greeting(DateTime now) {
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return (text: 'Good morning', icon: Icons.wb_sunny_outlined);
    }
    if (hour >= 12 && hour < 17) {
      return (text: 'Good afternoon', icon: Icons.light_mode_outlined);
    }
    return (text: 'Good evening', icon: Icons.nights_stay_outlined);
  }

  Widget _welcomeCard() {
    final now = DateTime.now();
    final greeting = _greeting(now);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // The darker green keeps white text readable.
        color: AppTheme.primaryGreenDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(greeting.icon, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(
                formatFriendlyDate(now),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: DonorTextSize.small,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${greeting.text}, ${_firstName ?? 'Donor'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your food donations can make a difference '
            'in your community.',
            style: TextStyle(
              color: Colors.white,
              fontSize: DonorTextSize.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Donation overview ----------

  /// Proportional bar showing how donations are split by status.
  Widget _statusBar(List<({int count, Color color})> parts, int total) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: total == 0
            ? const ColoredBox(color: AppTheme.border)
            : Row(
                children: [
                  for (final part in parts)
                    if (part.count > 0)
                      Expanded(
                        flex: part.count,
                        child: Container(
                          // Thin white gap between segments.
                          margin: const EdgeInsets.only(right: 2),
                          color: part.color,
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  Widget _statusCount(String label, String status, int count) {
    final style = DonationStatusStyle.of(status);

    return Expanded(
      child: Semantics(
        button: true,
        label: '$count $label. Show $label donations.',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => widget.onViewDonations?.call(status),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.foreground, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: DonorTextSize.small,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One line telling the donor what needs their attention.
  ({String text, IconData icon, Color color}) _overviewHint(
    int total,
    int pending,
    int rejected,
  ) {
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

    if (total == 0) {
      return (
        text: 'Your donation progress will show here after you share food.',
        icon: Icons.info_outline,
        color: AppTheme.mutedText,
      );
    }
    if (pending > 0) {
      return (
        text: '${plural(pending, 'donation')} '
            '${pending == 1 ? 'is' : 'are'} waiting for review.',
        icon: Icons.hourglass_top_rounded,
        color: AppTheme.warning,
      );
    }
    if (rejected > 0) {
      return (
        text: '${plural(rejected, 'donation')} '
            '${rejected == 1 ? 'was' : 'were'} not accepted. '
            'Tap to see them.',
        icon: Icons.info_outline,
        color: AppTheme.danger,
      );
    }
    return (
      text: 'All caught up. Thank you for sharing!',
      icon: Icons.favorite_outline,
      color: AppTheme.primaryGreenDark,
    );
  }

  Widget _overviewCard() {
    final total = _donations.length;
    final pending = _countByStatus('PENDING');
    final approved =
        _countByStatus('APPROVED') + _countByStatus('AVAILABLE');
    final rejected = _countByStatus('REJECTED');
    final other = total - pending - approved - rejected;

    final hint = _overviewHint(total, pending, rejected);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  total == 1 ? 'active donation' : 'active donations',
                  style: const TextStyle(
                    fontSize: DonorTextSize.body,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Split by status
          _statusBar([
            (
              count: approved,
              color: DonationStatusStyle.of('APPROVED').foreground,
            ),
            (
              count: pending,
              color: const Color(0xFFE0A100),
            ),
            (
              count: rejected,
              color: DonationStatusStyle.of('REJECTED').foreground,
            ),
            (count: other, color: AppTheme.greyText),
          ], total),
          const SizedBox(height: 6),

          // Counts (tap to open My Donations)
          Row(
            children: [
              _statusCount('Pending', 'PENDING', pending),
              _statusCount('Approved', 'APPROVED', approved),
              _statusCount('Rejected', 'REJECTED', rejected),
            ],
          ),

          const Divider(height: 20, color: AppTheme.border),

          // What needs attention
          InkWell(
            // Opens the section the hint is about.
            onTap: total == 0
                ? null
                : () => widget.onViewDonations?.call(
                      pending > 0
                          ? 'PENDING'
                          : rejected > 0
                              ? 'REJECTED'
                              : 'ALL',
                    ),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(hint.icon, color: hint.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint.text,
                      style: TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: hint.color,
                      ),
                    ),
                  ),
                  if (total > 0)
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.greyText,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recent donations ----------

  Widget _recentDonationCard(DonationModel donation) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => widget.onViewDonations?.call('ALL'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DonationImage(
                url: donation.imageUrl,
                width: 72,
                height: 72,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatQuantity(
                        donation.quantity,
                        donation.quantityUnit,
                      ),
                      style: const TextStyle(
                        fontSize: DonorTextSize.body,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DonationStatusBadge(status: donation.status),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: DonorTextSize.section,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (action != null && onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, kDonorTapHeight),
              foregroundColor: AppTheme.primaryGreenDark,
              textStyle: const TextStyle(
                fontSize: DonorTextSize.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(action),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const DonorLoadingView(message: 'Loading your dashboard...');
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppTheme.primaryGreen,
        child: DonorMessageView.error(
          title: 'Could not load your dashboard',
          message: _error!,
          onAction: () {
            setState(() => _isLoading = true);
            _loadDonations();
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonations,
      color: AppTheme.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        // Extra top spacing keeps the welcome card away
        // from the status bar.
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),

        children: [
          _welcomeCard(),
          const SizedBox(height: 24),
          _sectionHeader('Donation Overview'),
          const SizedBox(height: 12),
          _overviewCard(),
          const SizedBox(height: 20),
          _sectionHeader(
            'Recent Donations',
            action: _donations.isEmpty ? null : 'See all',
            onTap: () => widget.onViewDonations?.call('ALL'),
          ),
          const SizedBox(height: 8),
          if (_donations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 42,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No donations yet',
                    style: TextStyle(
                      fontSize: DonorTextSize.body,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your donations will show up here after you '
                    'create one from the Donations tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: DonorTextSize.body,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._donations.take(5).map(_recentDonationCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.fieldFill,
      child: SafeArea(
        top: true,
        bottom: false,
        child: _buildContent(),
      ),
    );
  }
}
