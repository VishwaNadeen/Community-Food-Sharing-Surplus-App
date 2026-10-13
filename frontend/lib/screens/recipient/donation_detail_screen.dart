
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

      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
        'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '${dt.day} ${months[dt.month]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();

      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
        'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
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

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
        return 'Available';
      case 'COLLECTED':
        return 'Collected';
      case 'CANCELLED':
        return 'Cancelled';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qtyDisplay =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    final claimable = donation.isClaimable;
    final statusColor = _statusColor(donation.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      body: CustomScrollView(
        slivers: [
          // Food image with back button.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 285,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildFoodImage(),

                  // Image gradient.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Colors.transparent,
                          Color(0x66000000),
                        ],
                      ),
                    ),
                  ),

                  // Back button and title.
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _roundIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Donation Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity label over the image.
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            donation.category,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status and quantity card.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              donation.category,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _statusLabel(donation.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.scale_outlined,
                                color: AppTheme.primaryGreen,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available quantity',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.greyText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    qtyDisplay,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description.
                _sectionTitle('About this donation'),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Text(
                    donation.description.trim().isNotEmpty
                        ? donation.description
                        : 'No description provided for this donation.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: AppTheme.greyText,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Pickup information.
                _sectionTitle('Pickup information'),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _detailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Pickup location',
                        value: donation.pickupLocation,
                      ),
                      _rowDivider(),
                      _detailRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Pickup date & time',
                        value: _formatDateTime(donation.pickupDateTime),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Expiry information.
                _sectionTitle('Food safety'),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: _detailRow(
                    icon: Icons.event_available_outlined,
                    label: 'Expiry date',
                    value: _formatDate(donation.expiryDate),
                    iconColor: Colors.orange.shade700,
                    iconBackground: const Color(0xFFFFF3E0),
                  ),
                ),

                const SizedBox(height: 18),

                // Availability message.
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: claimable
                        ? AppTheme.lightGreen
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: claimable
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        claimable
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        size: 20,
                        color: claimable
                            ? AppTheme.primaryGreen
                            : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          claimable
                              ? 'This donation is available. Submit a food request before it expires.'
                              : 'This donation is no longer available for claiming.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),

      // Fixed claim button.
      bottomNavigationBar: claimable
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final claimed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubmitFoodRequestScreen(
                            donation: donation,
                            token: token,
                          ),
                        ),
                      );

                      if (claimed == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Claim This Food',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFoodImage() {
    final imageUrl = donation.imageUrl?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        color: AppTheme.lightGreen,
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 70,
            color: AppTheme.primaryGreen,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: AppTheme.lightGreen,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.lightGreen,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 55,
              color: AppTheme.greyText,
            ),
          ),
        );
      },
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.30),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkText,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppTheme.border.withValues(alpha: 0.7),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Divider(
        height: 1,
        color: AppTheme.border.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? iconBackground,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground ?? AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.primaryGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value.trim().isNotEmpty ? value : 'Not provided',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
