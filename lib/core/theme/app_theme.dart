import 'package:my_accounts/core/theme/app_colors.dart';
import 'package:my_accounts/core/theme/app_radius.dart';
import 'package:my_accounts/core/theme/app_spacing.dart';
import 'package:my_accounts/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceSoft: AppColors.lightSurfaceSoft,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        border: AppColors.lightBorder,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceSoft: AppColors.darkSurfaceSoft,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        border: AppColors.darkBorder,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceSoft,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGold,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primaryGold,
      onPrimary: AppColors.lightTextPrimary,
      secondary: AppColors.secondaryGold,
      onSecondary: AppColors.lightTextPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      outline: border,
      surfaceContainerHighest: surfaceSoft,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
    );

    final textTheme = AppTextStyles.apply(base.textTheme, textPrimary, textSecondary);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: textSecondary),
      dividerTheme: DividerThemeData(color: border),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.lightTextPrimary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.lightTextPrimary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(46),
          foregroundColor: AppColors.primaryGold,
          side: const BorderSide(color: AppColors.primaryGold),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryGold,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceSoft : surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
          side: BorderSide(color: border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primaryGold.withOpacity(0.2),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(MaterialState.selected) ? textPrimary : textSecondary,
          ),
        ),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(MaterialState.selected) ? textPrimary : textSecondary,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: border),
        backgroundColor: surfaceSoft,
        labelStyle: textTheme.labelMedium,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        menuStyle: MenuStyle(
          backgroundColor: MaterialStatePropertyAll(surface),
          side: MaterialStatePropertyAll(BorderSide(color: border)),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: border),
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStatePropertyAll(surfaceSoft),
        dataRowColor: MaterialStatePropertyAll(surface),
        headingTextStyle: textTheme.titleSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        dividerThickness: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      extensions: const [
        AppStatusColors(
          success: AppColors.success,
          info: AppColors.info,
          warning: AppColors.warning,
          danger: AppColors.danger,
        ),
      ],
    );
  }
}
