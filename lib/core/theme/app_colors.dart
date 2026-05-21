import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Brand
  static const primaryGold = Color(0xFFF4C95D);
  static const secondaryGold = Color(0xFFD4AF37);

  // Light
  static const lightBackground = Color(0xFFF8F6F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSoft = Color(0xFFF3EFE6);
  static const lightTextPrimary = Color(0xFF111111);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFE5D8B8);

  // Dark
  static const darkBackground = Color(0xFF111111);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceSoft = Color(0xFF2A2A2A);
  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkBorder = Color.fromRGBO(212, 175, 55, 0.25);

  // States
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
  });

  final Color success;
  final Color info;
  final Color warning;
  final Color danger;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t) ?? success,
      info: Color.lerp(info, other.info, t) ?? info,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}
