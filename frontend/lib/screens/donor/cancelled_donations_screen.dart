
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import 'donor_ui.dart';

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
      _isLoading = _donations.isEmpty;
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
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
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
                MediaQuery.of(sheetContext).size.height * 0.85,
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
                DonationImage(
                  url: donation.imageUrl,
                  height: 200,
                  radius: 14,
                ),
                const SizedBox(height: 16),
                Text(
                  donation.category,
                  style: const TextStyle(
                    fontSize: DonorTextSize.title,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                DonationStatusBadge(status: donation.status),
                const SizedBox(height: 20),
                DonorDetailRow(
                  icon: Icons.scale_outlined,
                  label: 'Amount',
                  value: formatQuantity(
                    donation.quantity,
                    donation.quantityUnit,
                  ),
                ),
                DonorDetailRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: donation.description,
                ),
                DonorDetailRow(
                  icon: Icons.event_outlined,
                  label: 'Expiry date',
                  value: formatApiDate(donation.expiryDate),
                ),
                DonorDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Pickup address',
                  value: donation.pickupLocation,
                ),
                DonorDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Pickup date and time',
                  value: formatApiDate(
                    donation.pickupDateTime,
                    withTime: true,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cancelled donations cannot be changed. To share this '
                  'food again, create a new donation.',
                  style: TextStyle(
                    fontSize: DonorTextSize.body,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: donorFilledButtonStyle(),
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

  Widget _buildDonationTile(DonationModel donation) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(donation),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DonationImage(
                url: donation.imageUrl,
                width: 84,
                height: 84,
              ),
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
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    DonationStatusBadge(status: donation.status),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const DonorLoadingView(
        message: 'Loading cancelled donations...',
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadCancelledDonations,
        color: AppTheme.primaryGreen,
        child: DonorMessageView.error(
          title: 'Could not load cancelled donations',
          message: _error!,
          onAction: () {
            setState(() => _isLoading = true);
            _loadCancelledDonations();
          },
        ),
      );
    }

    if (_donations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCancelledDonations,
        color: AppTheme.primaryGreen,
        child: const DonorMessageView(
          icon: Icons.inventory_2_outlined,
          title: 'No cancelled donations',
          message: 'Donations you cancel will appear here.',
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
      appBar: donorAppBar('Cancelled Donations'),
      body: _buildBody(),
    );
  }
}
