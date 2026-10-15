import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';

// ---------------------------------------------------------------------------
// STATUS HELPERS (shared with the My Requests tab for filtering)
// ---------------------------------------------------------------------------

enum RequestStage { pending, approved, onTheWay, received, rejected }

class RequestStatusInfo {
  final RequestStage stage;
  final String label;
  final String message;
  final Color color;
  final IconData icon;

  const RequestStatusInfo({
    required this.stage,
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  /// The recipient can confirm receipt once the request is approved and
  /// until it is completed. This includes "collected", "delivery started"
  /// and "delivered", so the button no longer disappears when the delivery
  /// partner changes the status.
  bool get canConfirm =>
      stage == RequestStage.approved || stage == RequestStage.onTheWay;
}

String _prettyStatus(String s) {
  final words = s.toLowerCase().split(RegExp(r'[_\s]+'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Maps any backend status string to a stage the UI understands.
/// Unknown statuses are treated as "approved" so they never lock the user out.
RequestStatusInfo requestStatusInfo(FoodRequestModel r) {
  final s = r.status.toUpperCase();
  bool has(List<String> keys) => keys.any(s.contains);

  const blue = Color(0xFF1E88E5);

  if (r.isCompleted || has(['COMPLETED', 'RECEIVED'])) {
    return const RequestStatusInfo(
      stage: RequestStage.received,
      label: 'Received',
      message: 'Delivered and confirmed. Enjoy your meal!',
      color: AppTheme.primaryGreenDark,
      icon: Icons.task_alt_rounded,
    );
  }

  if (r.isRejected || has(['REJECT', 'CANCEL', 'DECLINE', 'EXPIRE'])) {
    return RequestStatusInfo(
      stage: RequestStage.rejected,
      label: s.contains('CANCEL') ? 'Cancelled' : 'Rejected',
      message: 'This request was not approved.',
      color: Colors.red,
      icon: Icons.cancel_outlined,
    );
  }

  if (r.isPending || has(['PENDING', 'SUBMIT'])) {
    return const RequestStatusInfo(
      stage: RequestStage.pending,
      label: 'Pending',
      message: 'Waiting for the donor to review your request.',
      color: Colors.orange,
      icon: Icons.hourglass_top_rounded,
    );
  }

  if (s.contains('DELIVERED')) {
    return const RequestStatusInfo(
      stage: RequestStage.onTheWay,
      label: 'Delivered',
      message: 'Your food has arrived. Please confirm that you received it.',
      color: blue,
      icon: Icons.inventory_2_rounded,
    );
  }

  if (has(['DELIVER', 'TRANSIT', 'WAY', 'DISPATCH', 'SHIP'])) {
    return const RequestStatusInfo(
      stage: RequestStage.onTheWay,
      label: 'Delivery started',
      message: 'The delivery partner is on the way with your food.',
      color: blue,
      icon: Icons.delivery_dining_rounded,
    );
  }

  if (has(['COLLECT', 'PICK'])) {
    return const RequestStatusInfo(
      stage: RequestStage.onTheWay,
      label: 'Collected',
      message: 'The delivery partner has collected your food.',
      color: blue,
      icon: Icons.shopping_bag_rounded,
    );
  }

  return RequestStatusInfo(
    stage: RequestStage.approved,
    label: r.isApproved ? 'Approved' : _prettyStatus(s),
    message: 'Your request is approved. A delivery partner will pick it up soon.',
    color: AppTheme.primaryGreen,
    icon: Icons.check_circle_outline_rounded,
  );
}

// ---------------------------------------------------------------------------
// REQUEST CARD
// ---------------------------------------------------------------------------

class RequestCard extends StatelessWidget {
  final FoodRequestModel request;

  final String token;

  final VoidCallback onConfirmed;

  const RequestCard({
    super.key,
    required this.request,
    required this.token,
    required this.onConfirmed,
  });

  Future<void> _confirmReceipt(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm receipt'),
        content: const Text(
          'Confirm that you have received this food delivery. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FoodRequestService.confirmReceived(token: token, id: request.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt confirmed. Thank you!'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      onConfirmed();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _statusBadge(RequestStatusInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  // 4-step tracker: Requested > Approved > On the way > Received
  Widget _tracker(RequestStatusInfo info) {
    const labels = ['Requested', 'Approved', 'On the way', 'Received'];

    final current = switch (info.stage) {
      RequestStage.pending => 0,
      RequestStage.approved => 1,
      RequestStage.onTheWay => 2,
      RequestStage.received => 3,
      RequestStage.rejected => 0,
    };
    final allDone = info.stage == RequestStage.received;

    Widget step(int i) {
      final done = i < current || allDone;
      final active = i == current && !allDone;
      final color = (done || active) ? info.color : AppTheme.border;

      return SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : active
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 5),
            Text(
              labels[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: (done || active) ? AppTheme.darkText : AppTheme.greyText,
              ),
            ),
          ],
        ),
      );
    }

    Widget line(int i) {
      final filled = i < current || allDone;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: filled ? info.color : AppTheme.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        step(0),
        line(0),
        step(1),
        line(1),
        step(2),
        line(2),
        step(3),
      ],
    );
  }

  Widget _messageStrip(RequestStatusInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.icon, size: 18, color: info.color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              info.message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectionBox() {
    final reason = request.rejectionReason;
    final hasReason = reason != null && reason.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasReason ? 'Reason: $reason' : 'This request was not approved.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.fieldFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              size: 17, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deliver to',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.greyText),
                ),
                const SizedBox(height: 1),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final info = requestStatusInfo(request);
    final hasAddress =
        request.deliveryAddress != null && request.deliveryAddress!.isNotEmpty;

    final meta = <String>[
      if (request.customRequestId != null) '#${request.customRequestId}',
      if (request.createdAt != null) _formatDate(request.createdAt!),
    ].join('  •  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.foodItem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 13, color: AppTheme.primaryGreenDark),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Qty: ${request.quantityRequested}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(info),
            ],
          ),

          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.greyText),
            ),
          ],

          const SizedBox(height: 16),

          // ── Progress / rejection ──
          if (info.stage == RequestStage.rejected)
            _rejectionBox()
          else ...[
            _tracker(info),
            const SizedBox(height: 14),
            _messageStrip(info),
          ],

          if (hasAddress) ...[
            const SizedBox(height: 10),
            _addressRow(request.deliveryAddress!),
          ],

          // ── Confirm receipt ──
          if (info.canConfirm) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReceipt(context),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Confirm food received'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          if (info.stage == RequestStage.received &&
              request.receivedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.task_alt_outlined,
                    size: 14, color: AppTheme.primaryGreenDark),
                const SizedBox(width: 5),
                Text(
                  'Received on ${_formatDate(request.receivedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}