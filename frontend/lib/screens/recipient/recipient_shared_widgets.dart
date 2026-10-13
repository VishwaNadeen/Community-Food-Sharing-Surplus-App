import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RecipientEmptyState extends StatelessWidget {

  final IconData icon;

  final String message;

  final VoidCallback onRetry;

  const RecipientEmptyState({

    required this.icon,

    required this.message,

    required this.onRetry,

  });

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(icon, size: 64, color: AppTheme.border),

          const SizedBox(height: 16),

          Text(

            message,

            textAlign: TextAlign.center,

            style: const TextStyle(color: AppTheme.greyText, fontSize: 15),

          ),

          const SizedBox(height: 20),

          TextButton.icon(

            onPressed: onRetry,

            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),

            label: const Text(

              'Refresh',

              style: TextStyle(color: AppTheme.primaryGreen),

            ),

          ),

        ],

      ),

    );

  }

}

class RecipientErrorState extends StatelessWidget {

  final String message;

  final VoidCallback onRetry;

  const RecipientErrorState({required this.message, required this.onRetry});

  @override

  Widget build(BuildContext context) {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),

            const SizedBox(height: 12),

            Text(

              message,

              textAlign: TextAlign.center,

              style: const TextStyle(color: AppTheme.greyText, fontSize: 14),

            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(

              onPressed: onRetry,

              icon: const Icon(Icons.refresh),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(

                backgroundColor: AppTheme.primaryGreen,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}
