
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import 'cancelled_donations_screen.dart';
import 'create_donation_screen.dart';
import 'donor_bottom_nav_bar.dart';
import 'donor_home_tab.dart';
import 'donor_delivery_tab.dart';
import 'donor_profile_tab.dart';

class _DonorDonationsTab extends StatefulWidget {
  const _DonorDonationsTab({super.key});

  @override
  State<_DonorDonationsTab> createState() => _DonorDonationsTabState();
}

class _DonorDonationsTabState extends State<_DonorDonationsTab> {
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

      // Show every donation except cancelled donations.
      // Pending, approved and rejected donations remain visible.
      final myDonations = donations
          .where(
            (donation) =>
                donation.status.toUpperCase() != 'CANCELLED',
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _donations = myDonations;
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFC107);
      case 'APPROVED':
      case 'AVAILABLE':
        return const Color(0xFF16803D);
      case 'REJECTED':
        return const Color(0xFFB91C1C);
      case 'CANCELLED':
        return const Color(0xFF424242);
      case 'COLLECTED':
        return const Color(0xFF1565C0);
      case 'EXPIRED':
        return const Color(0xFF9A3412);
      default:
        return AppTheme.greyText;
    }
  }

  Color _statusTextColor(String status) {
    return status.toUpperCase() == 'PENDING'
        ? const Color(0xFF332400)
        : Colors.white;
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _statusTextColor(status),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  bool _canEdit(DonationModel donation) =>
      donation.status.toUpperCase() == 'PENDING';

  Future<void> _openEdit(DonationModel donation) async {
    if (!_canEdit(donation)) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDonationScreen(
          donation: donation,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadDonations();
    }
  }

  Future<void> _openCancelledDonations() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const CancelledDonationsScreen(),
      ),
    );

    if (mounted) {
      await _loadDonations();
    }
  }

  Future<void> _cancelDonation(DonationModel donation) async {
    if (!_canEdit(donation)) return;

    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Donation'),
        content: Text(
          'Are you sure you want to cancel "${donation.category}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Donation'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DonationService.cancelDonation(
        token: token,
        id: donation.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Donation cancelled. It is now in Cancelled Donations.',
          ),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      await _loadDonations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel donation: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    await auth.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  String _formatTime(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _image(String? url, {double? height}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.fastfood_outlined,
          size: 42,
          color: AppTheme.primaryGreen.withValues(alpha: 0.7),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showDonationDetails(donation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _image(donation.imageUrl, height: 130),
                Positioned(
                  top: 9,
                  right: 9,
                  child: _statusBadge(donation.status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
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
                  const SizedBox(height: 6),
                  Text(
                    '${donation.quantity} ${donation.quantityUnit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.greyText,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          donation.pickupLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDonationDetails(
    DonationModel donation,
  ) async {
    final canManage = _canEdit(donation);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    bottom: 8,
                  ),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _image(
                            donation.imageUrl,
                            height: 210,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                donation.category,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ),
                            _statusBadge(donation.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _detailRow(
                          Icons.scale_outlined,
                          'Quantity',
                          '${donation.quantity} ${donation.quantityUnit}',
                        ),
                        _detailRow(
                          Icons.description_outlined,
                          'Description',
                          donation.description,
                        ),
                        _detailRow(
                          Icons.location_on_outlined,
                          'Pickup location',
                          donation.pickupLocation,
                        ),
                        _detailRow(
                          Icons.calendar_today_outlined,
                          'Expiry date',
                          _formatDate(donation.expiryDate),
                        ),
                        _detailRow(
                          Icons.access_time,
                          'Pickup date & time',
                          '${_formatDate(donation.pickupDateTime)} '
                              '${_formatTime(donation.pickupDateTime)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          canManage
                              ? 'You can edit or cancel while this donation is pending.'
                              : 'This donation can no longer be edited or cancelled.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canManage
                              ? () async {
                                  Navigator.pop(sheetContext);
                                  await _openEdit(donation);
                                }
                              : null,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            side: const BorderSide(
                              color: AppTheme.primaryGreen,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canManage
                              ? () async {
                                  Navigator.pop(sheetContext);
                                  await _cancelDonation(donation);
                                }
                              : null,
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 18,
                          ),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(
                              color: Colors.red.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationContent() {
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
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDonations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_donations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppTheme.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.volunteer_activism_outlined,
              size: 64,
              color: AppTheme.greyText,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No donations yet.',
                style: TextStyle(
                  color: AppTheme.greyText,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Tap + to create a donation.',
                style: TextStyle(
                  color: AppTheme.greyText,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonations,
      color: AppTheme.primaryGreen,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.70,
        ),
        itemCount: _donations.length,
        itemBuilder: (_, index) =>
            _buildDonationCard(_donations[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'My Donations',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.darkText,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateDonationScreen(),
            ),
          );

          if (result == true && mounted) {
            await _loadDonations();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadDonations,
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Donations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openCancelledDonations,
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(
                        color: Colors.red.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildDonationContent(),
          ),
        ],
      ),
    );
  }
}


/// Main donor screen. The Donations tab reuses the complete existing
/// My Donations implementation above, without requiring another Dart file.
class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  // Start on Donations to preserve the previous initial screen.
  int _currentIndex = 1;

  late final List<Widget> _tabs = [
    const DonorHomeTab(),
    const _DonorDonationsTab(),
    const DonorDeliveryTab(),
    const DonorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: DonorBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
