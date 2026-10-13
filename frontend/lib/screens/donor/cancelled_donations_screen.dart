
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';

class CancelledDonationsScreen extends StatefulWidget {
  const CancelledDonationsScreen({super.key});

  @override
  State<CancelledDonationsScreen> createState() =>
      _CancelledDonationsScreenState();
}

class _CancelledDonationsScreenState
    extends State<CancelledDonationsScreen> {
  List<DonationModel> _donations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCancelledDonations();
  }

  Future<void> _loadCancelledDonations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      final allDonations =
          await DonationService.getMyDonations(token: token);

      final cancelled = allDonations
          .where(
            (donation) =>
                donation.status.toUpperCase() == 'CANCELLED',
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _donations = cancelled;
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

  Widget _donationImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.fastfood_outlined,
          size: 34,
          color: AppTheme.greyText,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          height: 90,
          color: Colors.grey.shade100,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: AppTheme.greyText,
          ),
        ),
      ),
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

  void _showDetails(DonationModel donation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(sheetContext).size.height * 0.80,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: donation.imageUrl != null &&
                          donation.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          donation.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 45,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.fastfood_outlined,
                            size: 45,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  donation.category,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CANCELLED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                  _formatDate(donation.pickupDateTime),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This donation has been cancelled and cannot be '
                  'edited from this page.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 115,
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

  Widget _buildDonationTile(DonationModel donation) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(donation),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _donationImage(donation.imageUrl),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 6),
                    Text(
                      '${donation.quantity} ${donation.quantityUnit}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.greyText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            donation.pickupLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CANCELLED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
                onPressed: _loadCancelledDonations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_donations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCancelledDonations,
        color: AppTheme.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.greyText,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No cancelled donations',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Your cancelled donations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.greyText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCancelledDonations,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _donations.length,
        itemBuilder: (_, index) =>
            _buildDonationTile(_donations[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'Cancelled Donations',
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
      ),
      body: _buildBody(),
    );
  }
}
