import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import 'donation_detail_screen.dart';
import 'submit_food_request_screen.dart';

class DonationCard extends StatefulWidget {
  final DonationModel donation;
  final String token;
  final VoidCallback onClaimed;

  const DonationCard({
    super.key,
    required this.donation,
    required this.token,
    required this.onClaimed,
  });

  @override
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  // Used for the small "press" animation.
  bool _pressed = false;

  DonationModel get donation => widget.donation;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
        return AppTheme.primaryGreen;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'COLLECTED':
      case 'COMPLETED':
        return Colors.blue;
      default:
        return AppTheme.greyText;
    }
  }

  // "AVAILABLE" -> "Available"
  String _statusLabel(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Future<void> _openDetails(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailScreen(
          donation: donation,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      widget.onClaimed();
    }
  }

  Future<void> _requestFood(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitFoodRequestScreen(
          donation: donation,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      widget.onClaimed();
    }
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _buildImage() {
    final hasImage =
        donation.imageUrl != null && donation.imageUrl!.isNotEmpty;

    if (!hasImage) {
      return const Center(
        child: Icon(
          Icons.restaurant,
          size: 44,
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return Image.network(
      donation.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Food image failed: ${donation.imageUrl}');
        debugPrint('Image error: $error');
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 44,
            color: AppTheme.primaryGreen,
          ),
        );
      },
    );
  }

  Widget _statusBadge(Color statusColor) {
    final label = _statusLabel(donation.status);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    FontWeight weight = FontWeight.w500,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor ?? AppTheme.greyText),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: weight,
              color: textColor ?? AppTheme.greyText,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(donation.status);

    final quantityText =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppTheme.border.withValues(alpha: 0.6),
              ),
            ),
            child: InkWell(
              onTap: () => _openDetails(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Food image with status badge ──
                  SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppTheme.lightGreen,
                          child: _buildImage(),
                        ),

                        // Soft gradient at the top so the badge stays readable.
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 50,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // "Open details" hint
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_outward_rounded,
                              size: 15,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Donation information and actions ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Icons.inventory_2_outlined,
                          text: quantityText,
                          iconColor: AppTheme.primaryGreenDark,
                          textColor: AppTheme.primaryGreenDark,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(height: 5),
                        _infoRow(
                          icon: Icons.location_on_outlined,
                          text: donation.pickupLocation,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () => _requestFood(context),
                            icon: const Icon(
                              Icons.volunteer_activism_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Request Food',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
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
          ),
        ),
      ),
    );
  }
}