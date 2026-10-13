import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

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
      case 'ASSIGNED':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _icon {
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
      case 'ASSIGNED':
        return Icons.assignment_rounded;
      default:
        return Icons.info_rounded;
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
          if (showIcon) ...[
            Icon(
              _icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
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
}
