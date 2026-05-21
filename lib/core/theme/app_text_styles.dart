import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const fontFamily = 'Tajawal';

  static TextTheme apply(
    TextTheme base,
    Color primaryText,
    Color secondaryText,
  ) {
    final tajawal = GoogleFonts.tajawalTextTheme(base);
    return tajawal.copyWith(
      displayLarge: tajawal.displayLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: tajawal.displayMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: tajawal.displaySmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: tajawal.headlineLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: tajawal.headlineMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: tajawal.headlineSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: tajawal.titleLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: tajawal.titleMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: tajawal.titleSmall?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: tajawal.bodyLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: tajawal.bodyMedium?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: tajawal.bodySmall?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: tajawal.labelLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: tajawal.labelMedium?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: tajawal.labelSmall?.copyWith(
        color: secondaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
