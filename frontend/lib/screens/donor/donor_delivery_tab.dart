
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DonorDeliveryTab extends StatelessWidget {
  const DonorDeliveryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.fieldFill,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Delivery',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your food donation delivery.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 20),

            // Example delivery card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 32,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEL-001',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Food Donation',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'In Transit',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  _infoRow('Food Items', 'Rice and vegetables'),
                  _infoRow('Quantity', '10 kg'),
                  _infoRow('Recipient', 'Hope Community Centre'),
                  _infoRow('Pickup Date', '12 October 2026'),
                  _infoRow('Expected Arrival', '4:30 PM'),
                  _infoRow('Delivery Address', 'Main Street, Colombo'),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  const Text(
                    'Delivery Status',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Food collected from donor',
                        style: TextStyle(color: AppTheme.darkText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Volunteer is on the way',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.radio_button_unchecked,
                        color: AppTheme.greyText,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Waiting for delivery confirmation',
                        style: TextStyle(color: AppTheme.greyText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
