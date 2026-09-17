import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import 'submit_food_request_screen.dart';

class DonationDetailScreen extends StatelessWidget {
  final DonationModel donation;
  final String token;

  const DonationDetailScreen({
    super.key,
    required this.donation,
    required this.token,
  });

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}  •  $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.primaryGreen;
      case 'COLLECTED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qtyDisplay =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with optional hero image ──
          SliverAppBar(
            expandedHeight:
                (donation.imageUrl != null && donation.imageUrl!.isNotEmpty)
                    ? 240.0
                    : kToolbarHeight,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: AppTheme.darkText,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  (donation.imageUrl != null && donation.imageUrl!.isNotEmpty)
                      ? Image.network(
                          donation.imageUrl!,
                          fit: BoxFit.cover,
                          height: 240,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: AppTheme.lightGreen,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                          errorBuilder: (_, _, _) => Container(
                            height: 240,
                            color: AppTheme.lightGreen,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppTheme.greyText,
                              size: 48,
                            ),
                          ),
                        )
                      : null,
            ),
            title: const Text(
              'Donation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ),

          // ── Detail body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category title
                  Text(
                    donation.category,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _statusColor(donation.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donation.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(donation.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 16),

                  // Info rows
                  _infoRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: donation.category,
                  ),
                  _infoRow(
                    icon: Icons.scale_outlined,
                    label: 'Quantity',
                    value: qtyDisplay,
                  ),
                  _infoRow(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    value: donation.description,
                  ),
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup Location',
                    value: donation.pickupLocation,
                  ),
                  _infoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Pickup Date/Time',
                    value: _formatDateTime(donation.pickupDateTime),
                  ),
                  _infoRow(
                    icon: Icons.event_outlined,
                    label: 'Expiry Date',
                    value: _formatDate(donation.expiryDate),
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 8),

                  // Additional info chip row
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppTheme.greyText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          donation.isAvailable
                              ? 'This donation is available. Request it before it expires!'
                              : 'This donation is no longer available.',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.greyText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating bottom action ──
      bottomNavigationBar: donation.isAvailable
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubmitFoodRequestScreen(
                        donation: donation,
                        token: token,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 2,
                  shadowColor:
                      AppTheme.primaryGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Request This Food',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.lightGreen,
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: AppTheme.primaryGreenDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greyText,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
