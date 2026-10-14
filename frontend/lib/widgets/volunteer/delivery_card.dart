import 'package:flutter/material.dart';
import '../../models/delivery_model.dart';
import '../../theme/app_theme.dart';

class DeliveryCard extends StatelessWidget {
  final VolunteerDelivery delivery;
  final VoidCallback onTap;
  final bool isAvailablePool;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onTap,
    this.isAvailablePool = true,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    final d = date.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatUrgency(double? hours) {
    if (hours == null) return 'No expiry info';
    if (hours < 0) return 'Expired';
    if (hours < 2) return 'Expires soon (<2h)';
    if (hours < 12) return 'Expires today';
    if (hours < 24) return 'Expires tomorrow';
    return '${hours.toStringAsFixed(0)}h remaining';
  }

  Color _getUrgencyColor(double? hours) {
    if (hours == null) return Colors.grey;
    if (hours < 0) return Colors.red;
    if (hours < 2) return Colors.red.shade700;
    if (hours < 12) return Colors.orange;
    if (hours < 24) return Colors.orange.shade300;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final urgencyHours = delivery.expiryUrgencyHours;
    final urgencyColor = _getUrgencyColor(urgencyHours);
    final urgencyText = _formatUrgency(urgencyHours);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: AppTheme.primaryGreen.withOpacity(0.1),
        highlightColor: AppTheme.primaryGreen.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isAvailablePool ? AppTheme.primaryGreen.withOpacity(0.4) : AppTheme.border,
              width: isAvailablePool ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with food item and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      delivery.foodItem,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(status: delivery.status),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity and expiry urgency
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _InfoIcon(
                      icon: Icons.scale_outlined,
                      text: '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
                      color: AppTheme.darkText,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 1,
                      height: 20,
                      color: AppTheme.border,
                    ),
                    const SizedBox(width: 20),
                    _InfoIcon(
                      icon: Icons.access_time_outlined,
                      text: urgencyText,
                      color: urgencyColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pickup location
              _LocationRow(
                icon: Icons.storefront_outlined,
                label: 'Pickup',
                address: delivery.pickupAddress ?? 'Donor location',
                iconColor: AppTheme.primaryGreenDark,
              ),
              const SizedBox(height: 12),

              // Dropoff location
              _LocationRow(
                icon: Icons.location_on_outlined,
                label: 'Dropoff',
                address: delivery.dropoffAddress ?? 'Recipient location',
                iconColor: Colors.redAccent,
              ),
              const SizedBox(height: 16),

              // Distance and expiry date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (delivery.distanceKm != null) ...[
                      Icon(Icons.route_outlined, size: 15, color: AppTheme.greyText),
                      const SizedBox(width: 8),
                      Text(
                        '${delivery.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.greyText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Expiry: ${_formatDate(delivery.foodExpiryDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppTheme.primaryGreen;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.redAccent;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'PICKED_UP':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.purple;
      case 'PENDING_ASSIGNMENT':
        return AppTheme.primaryGreenDark;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.cancel_rounded;
      case 'IN_TRANSIT':
        return Icons.local_shipping_rounded;
      case 'PICKED_UP':
        return Icons.inventory_2_rounded;
      case 'ACCEPTED':
        return Icons.thumb_up_rounded;
      case 'PENDING_ASSIGNMENT':
        return Icons.pending_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoIcon({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final Color iconColor;

  const _LocationRow({
    required this.icon,
    required this.label,
    required this.address,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.greyText,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
