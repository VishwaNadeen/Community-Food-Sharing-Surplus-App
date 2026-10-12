
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';

class DonorHomeTab extends StatefulWidget {
  const DonorHomeTab({super.key});

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
      _isLoading = true;
      _error = null;
    });

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      final donations =
          await DonationService.getMyDonations(token: token);

      if (!mounted) return;

      final activeDonations = donations
          .where(
            (donation) =>
                donation.status.toUpperCase() != 'CANCELLED',
          )
          .toList();

      // Show the newest donations first.
      activeDonations.sort((a, b) {
        final dateA = a.createdAt;
        final dateB = b.createdAt;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      setState(() {
        _donations = activeDonations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFF3CD);
      case 'APPROVED':
      case 'AVAILABLE':
        return const Color(0xFFD1FAE5);
      case 'REJECTED':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFF92400E);
      case 'APPROVED':
      case 'AVAILABLE':
        return const Color(0xFF166534);
      case 'REJECTED':
        return const Color(0xFFB91C1C);
      default:
        return Colors.black87;
    }
  }

  Widget _statCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D2B)
                .withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_outlined,
        size: 30,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _recentDonationCard(DonationModel donation) {
    final status = donation.status.toUpperCase();
    final imageUrl = donation.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EEE9),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173D2B)
                .withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null && imageUrl.trim().isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${donation.quantity} ${donation.quantityUnit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusTextColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.greyText,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDonations,
                child: const Text('Try Again'),
              ),
            ],
          ),
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
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 35,
                ),
                SizedBox(height: 14),
                Text(
                  'Welcome, Donor!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your food donations can make a difference '
                  'in your community.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Donation Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard(
                title: 'Total Donations',
                count: _donations.length,
                icon: Icons.volunteer_activism_outlined,
                color: AppTheme.primaryGreen,
              ),
              _statCard(
                title: 'Pending',
                count: _countByStatus('PENDING'),
                icon: Icons.hourglass_empty,
                color: Colors.orange,
              ),
              _statCard(
                title: 'Approved',
                count: _countByStatus('APPROVED') +
                    _countByStatus('AVAILABLE'),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              _statCard(
                title: 'Rejected',
                count: _countByStatus('REJECTED'),
                icon: Icons.cancel_outlined,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Donations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 14),
          if (_donations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 42,
                    color: AppTheme.greyText,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No donations yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create your first donation to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                ],
              ),
            )
          else
            ..._donations.take(5).map(_recentDonationCard),
          const SizedBox(height: 80),
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
