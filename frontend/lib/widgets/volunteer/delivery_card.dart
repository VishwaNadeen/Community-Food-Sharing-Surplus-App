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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isAvailablePool ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.border,
              width: isAvailablePool ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with food item and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      delivery.foodItem,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: delivery.status),
                ],
              ),
              const SizedBox(height: 12),

              // Quantity and expiry urgency
              Row(
                children: [
                  _InfoIcon(
                    icon: Icons.scale_outlined,
                    text: '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
                    color: AppTheme.darkText,
                  ),
                  const SizedBox(width: 16),
                  _InfoIcon(
                    icon: Icons.access_time_outlined,
                    text: urgencyText,
                    color: urgencyColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup location
              _LocationRow(
                icon: Icons.storefront_outlined,
                label: 'Pickup',
                address: delivery.pickupAddress ?? 'Donor location',
                iconColor: AppTheme.primaryGreenDark,
              ),
              const SizedBox(height: 8),

              // Dropoff location
              _LocationRow(
                icon: Icons.location_on_outlined,
                label: 'Dropoff',
                address: delivery.dropoffAddress ?? 'Recipient location',
                iconColor: Colors.redAccent,
              ),
              const SizedBox(height: 12),

              // Distance and expiry date
              Row(
                children: [
                  if (delivery.distanceKm != null) ...[
                    Icon(Icons.route_outlined, size: 16, color: AppTheme.greyText),
                    const SizedBox(width: 6),
                    Text(
                      '${delivery.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.greyText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Expiry: ${_formatDate(delivery.foodExpiryDate)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                    ),
                  ),
                ],
              ),

              // Action button for available deliveries
              if (isAvailablePool) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text(
                      'Accept Task',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
