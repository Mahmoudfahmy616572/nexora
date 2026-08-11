import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Global Nexora theme. All screens inherit these tokens.
abstract final class AppTheme {
  static ThemeData get dark => _buildDark();

  static ThemeData _buildDark() {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.teal,
      onPrimary: AppColors.background,
      secondary: AppColors.purple,
      tertiary: AppColors.green,
      surface: AppColors.card,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(76),
        bodyMedium: AppTextStyles.description,
        bodySmall: AppTextStyles.featureSubtitle,
        labelLarge: AppTextStyles.primaryButton,
      ),
    );
  }
}
