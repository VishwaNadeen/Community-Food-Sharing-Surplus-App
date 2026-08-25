import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon('https://logo.clearbit.com/google.com'),
        const SizedBox(width: 18),
        _buildIcon('https://logo.clearbit.com/apple.com'),
        const SizedBox(width: 18),
        _buildIcon('https://logo.clearbit.com/facebook.com'),
      ],
    );
  }

  Widget _buildIcon(String url) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppTheme.border),
      ),
      child: Image.network(
        url,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, color: Colors.grey, size: 20);
        },
      ),
    );
  }
}