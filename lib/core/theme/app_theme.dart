import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Global Nexora theme. All screens inherit these tokens.
abstract final class AppTheme {
  static ThemeData get dark => _buildDark();

  static ThemeData _buildDark() {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.brand,
      onPrimary: AppColors.background,
      secondary: AppColors.accent,
      tertiary: AppColors.success,
      surface: AppColors.card,
      onSurface: AppColors.text,
      outline: AppColors.border,
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
        headlineSmall: AppTextStyles.screenTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.description,
        bodySmall: AppTextStyles.featureSubtitle,
        labelLarge: AppTextStyles.primaryButton,
      ),
    );
  }
}

/// Global scroll behavior that disables the Material 3 stretching / rubber-band
/// overscroll and the edge glow, so screens settle cleanly at their ends
/// instead of stretching (the "pull" feel the user reported).
class NexoraScrollBehavior extends MaterialScrollBehavior {
  const NexoraScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(
      parent: RangeMaintainingScrollPhysics(),
    );
  }
}
