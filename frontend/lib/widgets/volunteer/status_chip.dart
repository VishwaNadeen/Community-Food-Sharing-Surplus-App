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
        return const Color(0xFF16A34A);
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'IN_TRANSIT':
        return const Color(0xFF2563EB);
      case 'PICKED_UP':
        return const Color(0xFFD97706);
      case 'ACCEPTED':
        return const Color(0xFF9333EA);
      case 'PENDING_ASSIGNMENT':
        return AppTheme.primaryGreenDark;
      case 'ASSIGNED':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF64748B);
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
        return Icons.schedule_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String get _displayStatus {
    final raw = status.replaceAll('_', ' ').toLowerCase();
    if (raw.isEmpty) return '';
    return raw.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            _displayStatus,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
