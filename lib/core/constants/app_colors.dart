import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF67577E);
  static const Color primaryVariant = Color(0xFF9D8BB5);
  static const Color background = Color(0xFFFFF7FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3EEF8);

  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF7B757E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF146C3B);
  static const Color warning = Color(0xFFF59E0B);

  static const Color divider = Color(0xFFE8E0EC);
  static const Color shimmer = Color(0xFFE0D8EC);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFF7FF), Color(0xFFF3EEF8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status colors for attendance
  static const Color present = Color(0xFF146C3B);
  static const Color absent = Color(0xFFBA1A1A);
  static const Color late = Color(0xFFF59E0B);
  static const Color excused = Color(0xFF006398);

  // Card background
  static const Color cardBackground = Color(0xFFFFFBFF);
}
