import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.tajawal(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.12,
      );

  static TextStyle get displayMedium => GoogleFonts.tajawal(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.16,
      );

  static TextStyle get headlineLarge => GoogleFonts.tajawal(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.tajawal(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.29,
        letterSpacing: -0.7,
      );

  static TextStyle get headlineSmall => GoogleFonts.tajawal(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.33,
      );

  static TextStyle get titleLarge => GoogleFonts.tajawal(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.27,
      );

  static TextStyle get titleMedium => GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyMedium => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.33,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.33,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.tajawal(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.45,
        letterSpacing: 0.5,
      );
}
