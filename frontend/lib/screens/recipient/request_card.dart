import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';

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

  Color _chipColor(String status) {

    switch (status) {

      case 'APPROVED':

        return AppTheme.primaryGreen;

      case 'REJECTED':

        return Colors.red;

      case 'COMPLETED':

        return Colors.blue;

      default:

        return Colors.orange;

    }

  }

  String _chipLabel(String status) {

    switch (status) {

      case 'APPROVED':

        return '✓ Approved';

      case 'REJECTED':

        return '✕ Rejected';

      default:

        return '⏳ Pending';

    }

  }

  @override

  Widget build(BuildContext context) {

    final color = _chipColor(request.status);

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppTheme.border),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.05),

            blurRadius: 6,

            offset: const Offset(0, 2),

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

                  request.foodItem,

                  style: const TextStyle(

                    fontSize: 15,

                    fontWeight: FontWeight.w700,

                    color: AppTheme.darkText,

                  ),

                ),

              ),

              Container(

                padding: const EdgeInsets.symmetric(

                  horizontal: 10,

                  vertical: 4,

                ),

                decoration: BoxDecoration(

                  color: color.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(20),

                ),

                child: Text(

                  request.isCompleted ? 'Received' : _chipLabel(request.status),

                  style: TextStyle(

                    fontSize: 11.5,

                    fontWeight: FontWeight.w600,

                    color: color,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 6),

          _infoLine(Icons.scale_outlined, 'Qty: ${request.quantityRequested}'),

          if (request.deliveryAddress != null &&

              request.deliveryAddress!.isNotEmpty)

            _infoLine(Icons.location_on_outlined, request.deliveryAddress!),

          if (request.customRequestId != null)

            _infoLine(Icons.tag, 'ID: ${request.customRequestId}'),

          if (request.createdAt != null)

            _infoLine(

              Icons.access_time_outlined,

              _formatDate(request.createdAt!),

            ),

          if (request.isRejected &&

              request.rejectionReason != null &&

              request.rejectionReason!.isNotEmpty)

            Container(

              margin: const EdgeInsets.only(top: 8),

              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(

                color: Colors.red.shade50,

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: Colors.red.shade200),

              ),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Icon(

                    Icons.info_outline,

                    size: 15,

                    color: Colors.red.shade700,

                  ),

                  const SizedBox(width: 6),

                  Expanded(

                    child: Text(

                      'Reason: ${request.rejectionReason}',

                      style: TextStyle(

                        fontSize: 12.5,

                        color: Colors.red.shade700,

                      ),

                    ),

                  ),

                ],

              ),

            ),

          if (request.isApproved) ...[

            const SizedBox(height: 12),

            SizedBox(

              width: double.infinity,

              child: OutlinedButton.icon(

                onPressed: () => _confirmReceipt(context),

                icon: const Icon(Icons.check_circle_outline),

                label: const Text('Confirm food received'),

                style: OutlinedButton.styleFrom(

                  foregroundColor: AppTheme.primaryGreenDark,

                  side: const BorderSide(color: AppTheme.primaryGreen),

                ),

              ),

            ),

          ],

          if (request.isCompleted && request.receivedAt != null)

            _infoLine(

              Icons.task_alt_outlined,

              'Received: ${_formatDate(request.receivedAt!)}',

            ),

        ],

      ),

    );

  }

  Widget _infoLine(IconData icon, String text) {

    return Padding(

      padding: const EdgeInsets.only(top: 4),

      child: Row(

        children: [

          Icon(icon, size: 13, color: AppTheme.greyText),

          const SizedBox(width: 5),

          Expanded(

            child: Text(

              text,

              style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),

            ),

          ),

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

// ---------------------------------------------------------------------------

// SHARED HELPER WIDGETS

// ---------------------------------------------------------------------------
