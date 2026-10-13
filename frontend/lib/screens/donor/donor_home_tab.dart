
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import 'donor_ui.dart';

class DonorHomeTab extends StatefulWidget {
  /// Switches to the Donations tab.
  final VoidCallback? onViewDonations;

  /// Opens the create donation form.
  final VoidCallback? onCreateDonation;

  const DonorHomeTab({
    super.key,
    this.onViewDonations,
    this.onCreateDonation,
  });

  @override
  State<DonorHomeTab> createState() => _DonorHomeTabState();
}

class _DonorHomeTabState extends State<DonorHomeTab> {
  List<DonationModel> _donations = [];
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

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

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

  int _countByStatus(String status) {
    return _donations
        .where(
          (donation) =>
              donation.status.toUpperCase() == status,
        )
        .length;
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: DonorTextSize.body,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusStatCard(String title, String status, int count) {
    final style = DonationStatusStyle.of(status);

    return _statCard(
      title: title,
      count: count,
      icon: style.icon,
      color: style.foreground,
      background: style.background,
    );
  }

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
        onTap: widget.onViewDonations,
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

  Widget _welcomeCard() {
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
          const Icon(
            Icons.volunteer_activism,
            color: Colors.white,
            size: 35,
          ),
          const SizedBox(height: 14),
          const Text(
            'Welcome, Donor!',
            style: TextStyle(
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
          if (widget.onCreateDonation != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.onCreateDonation,
              style: donorFilledButtonStyle(color: Colors.white).copyWith(
                foregroundColor: const WidgetStatePropertyAll(
                  AppTheme.primaryGreenDark,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create a donation'),
            ),
          ],
        ],
      ),
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
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard(
                title: 'Total',
                count: _donations.length,
                icon: Icons.volunteer_activism_outlined,
                color: AppTheme.primaryGreenDark,
                background: AppTheme.lightGreen,
              ),
              _statusStatCard(
                'Pending',
                'PENDING',
                _countByStatus('PENDING'),
              ),
              _statusStatCard(
                'Approved',
                'APPROVED',
                _countByStatus('APPROVED') + _countByStatus('AVAILABLE'),
              ),
              _statusStatCard(
                'Rejected',
                'REJECTED',
                _countByStatus('REJECTED'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionHeader(
            'Recent Donations',
            action: _donations.isEmpty ? null : 'See all',
            onTap: widget.onViewDonations,
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
                    'create one.',
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
