import 'package:flutter/material.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class RequestDetailScreen extends StatefulWidget {
  final FoodRequestModel request;
  final String token;

  const RequestDetailScreen({
    super.key,
    required this.request,
    required this.token,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isActioning = false;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'APPROVED':
        return AppTheme.primaryGreen;
      case 'REJECTED':
        return Colors.red.shade600;
      default:
        return AppTheme.greyText;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _approve() async {
    setState(() => _isActioning = true);
    try {
      await FoodRequestService.approveRequest(
        token: widget.token,
        id: widget.request.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved successfully.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rejection reason cannot be empty.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isActioning = true);
    try {
      await FoodRequestService.rejectRequest(
        token: widget.token,
        id: widget.request.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                trailing ??
                    Text(
                      value.isNotEmpty ? value : '—',
                      style: const TextStyle(
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isPending = req.status.toUpperCase() == 'PENDING';

    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.tag_outlined,
                    label: 'Request ID',
                    value: req.customRequestId?.isNotEmpty == true
                        ? req.customRequestId!
                        : req.id,
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.fastfood_outlined,
                    label: 'Food Item',
                    value: req.foodItem,
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Quantity Requested',
                    value: req.quantityRequested,
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Delivery Address',
                    value: req.deliveryAddress ?? '',
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: req.notes ?? '',
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: '',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(req.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(req.status),
                        ),
                      ),
                    ),
                  ),
                  if (req.status.toUpperCase() == 'REJECTED' &&
                      req.rejectionReason != null &&
                      req.rejectionReason!.isNotEmpty) ...[
                    _divider(),
                    _infoRow(
                      icon: Icons.block_outlined,
                      label: 'Rejection Reason',
                      value: req.rejectionReason!,
                    ),
                  ],
                  _divider(),
                  _infoRow(
                    icon: Icons.email_outlined,
                    label: 'Recipient Email',
                    value: req.recipientEmail ?? 'N/A',
                  ),
                  if (req.reviewedBy != null && req.reviewedBy!.isNotEmpty) ...[
                    _divider(),
                    _infoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Reviewed By',
                      value: req.reviewedBy!,
                    ),
                  ],
                  _divider(),
                  _infoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Created At',
                    value: _formatDate(req.createdAt),
                  ),
                ],
              ),
            ),

            // Action buttons (only for PENDING)
            if (isPending)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _isActioning
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          )
                        : PrimaryButton(text: 'Approve', onPressed: _approve),
                    const SizedBox(height: 12),
                    if (!_isActioning)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _reject,
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: AppTheme.border);
}
