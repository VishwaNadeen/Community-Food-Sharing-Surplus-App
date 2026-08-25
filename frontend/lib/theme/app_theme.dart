import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Colors.white;

  static const Color primaryGreen = Color(0xFF2FAE60);
  static const Color primaryGreenDark = Color(0xFF1F8F4C);
  static const Color lightGreen = Color(0xFFE7F7EC);

  // Kept for backward compatibility with any old references
  static const Color primaryRed = primaryGreen;

  static const Color darkText = Color(0xFF1A1D1F);
  static const Color greyText = Color(0xFF8A8F98);
  static const Color fieldFill = Color(0xFFF6F8F7);
  static const Color border = Color(0xFFE7EAEC);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: lightGreen,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}