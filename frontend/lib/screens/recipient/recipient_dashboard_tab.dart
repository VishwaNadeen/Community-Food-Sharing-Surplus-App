
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/donation_service.dart';
import '../../services/food_request_service.dart';

class RecipientDashboardTab extends StatefulWidget {
  final VoidCallback onBrowse;
  final VoidCallback onRequests;

  const RecipientDashboardTab({
    super.key,
    required this.onBrowse,
    required this.onRequests,
  });

  @override
  State<RecipientDashboardTab> createState() =>
      _RecipientDashboardTabState();
}

class _RecipientDashboardTabState extends State<RecipientDashboardTab> {
  int? _donationCount;
  int? _requestCount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;

    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    setState(() => _isLoading = true);

    try {
      final donations = await DonationService.browseDonations(
        token: token,
        category: '',
        location: '',
      );

      if (mounted) {
        setState(() => _donationCount = donations.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _donationCount = null);
      }
    }

    try {
      final requests = await FoodRequestService.getMyRequests(
        token: token,
      );

      if (mounted) {
        setState(() => _requestCount = requests.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _requestCount = null);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadSummary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.waving_hand_outlined,
                  color: AppTheme.primaryGreenDark,
                  size: 32,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Welcome to FoodLink!',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover available food donations and '
                  'manage your food requests in one place.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onBrowse,
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Donations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Your Overview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Available Donations',
                  count: _donationCount,
                  icon: Icons.volunteer_activism_outlined,
                  onTap: widget.onBrowse,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'My Requests',
                  count: _requestCount,
                  icon: Icons.list_alt_outlined,
                  onTap: widget.onRequests,
                ),
              ),
            ],
          ),

          if (_isLoading) ...[
            const SizedBox(height: 18),
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ),
          ],

          const SizedBox(height: 28),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),

          const SizedBox(height: 14),

          _QuickActionTile(
            icon: Icons.restaurant_menu,
            title: 'Browse Donations',
            subtitle: 'Find food available near you',
            onTap: widget.onBrowse,
          ),

          const SizedBox(height: 12),

          _QuickActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Food Requests',
            subtitle: 'View the status of your requests',
            onTap: widget.onRequests,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int? count;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                count?.toString() ?? '—',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyText,
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
        ),
      ),
    );
  }
}
