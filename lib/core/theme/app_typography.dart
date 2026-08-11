import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora typography — extracted from the approved UI/UX source.
///
/// Base family is Inter (bundled as a variable font). Sizes follow the
/// design spec exactly; screen code may scale the display size via
/// [AppTextStyles.displaySize].
abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const TextStyle brandName = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: AppColors.text,
  );

  static const TextStyle brandNameCompact = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: AppColors.text,
  );

  static const TextStyle brandSubtitle = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AppColors.brandSubtitle,
  );

  // ---------------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------------
  static const TextStyle eyebrow = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AppColors.eyebrow,
  );

  static TextStyle display(double size, {double letterSpacing = -3}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacing,
        height: 0.99,
        color: AppColors.text,
      );

  static const TextStyle description = TextStyle(
    fontSize: 18,
    height: 1.65,
    color: AppColors.description,
  );

  static const TextStyle descriptionCompact = TextStyle(
    fontSize: 15,
    height: 1.65,
    color: AppColors.description,
  );

  // ---------------------------------------------------------------------------
  // Trust row
  // ---------------------------------------------------------------------------
  static const TextStyle trustTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFFF5F7FB),
  );

  static const TextStyle trustSubtitle = TextStyle(
    fontSize: 9,
    height: 1.45,
    color: Color(0xFF7F8AA3),
  );

  // ---------------------------------------------------------------------------
  // Feature tiles
  // ---------------------------------------------------------------------------
  static const TextStyle featureTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle featureSubtitle = TextStyle(
    fontSize: 10,
    height: 1.45,
    color: Color(0xFF8C96AA),
  );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------
  static const TextStyle primaryButton = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static const TextStyle secondaryButton = TextStyle(
    fontSize: 14,
    color: Color(0xFFE4E7EF),
  );

  // ---------------------------------------------------------------------------
  // DNA visualization
  // ---------------------------------------------------------------------------
  static const TextStyle dnaLabelTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle dnaLabelSubtitle = TextStyle(
    fontSize: 10,
    color: Color(0xFF8993A9),
  );

  static const TextStyle dnaNode = TextStyle(
    fontSize: 11,
    color: Color(0xFFDCE1EB),
  );

  // ---------------------------------------------------------------------------
  // Micro / notes
  // ---------------------------------------------------------------------------
  static const TextStyle privacyNote = TextStyle(
    fontSize: 10,
    color: Color(0xFF778198),
  );

  static const TextStyle privacyNoteStrong = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(0xFF9E75E7),
  );
}
