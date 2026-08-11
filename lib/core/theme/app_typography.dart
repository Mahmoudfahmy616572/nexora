import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nexora typography — extracted from the approved UI/UX source.
///
/// The design uses three families:
/// * [displayFont] — Bricolage Grotesque (headings / display)
/// * [fontFamily] — Inter (body)
/// * [monoFont] — DM Mono (numbers, timestamps, uppercase labels)
abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';
  static const String displayFont = 'Bricolage Grotesque';
  static const String monoFont = 'DM Mono';

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
  // Display (Bricolage Grotesque)
  // ---------------------------------------------------------------------------
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    fontFamily: displayFont,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFamily: displayFont,
  );

  static const TextStyle cardTitleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    fontFamily: displayFont,
  );

  static TextStyle display(double size, {double letterSpacing = -3}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacing,
        height: 0.99,
        color: AppColors.text,
        fontFamily: displayFont,
      );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------
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

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle bodySub = TextStyle(
    fontSize: 12,
    color: AppColors.textSub,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    color: AppColors.textSub,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 10,
    color: AppColors.textMuted,
  );

  // ---------------------------------------------------------------------------
  // Hero (legacy welcome screen)
  // ---------------------------------------------------------------------------
  static const TextStyle eyebrow = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AppColors.eyebrow,
  );

  static const TextStyle trustTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFFF5F7FB),
  );

  static const TextStyle trustSubtitle = TextStyle(
    fontSize: 9,
    height: 1.45,
    color: AppColors.textSub,
  );

  static const TextStyle featureTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle featureSubtitle = TextStyle(
    fontSize: 10,
    height: 1.45,
    color: AppColors.textSub,
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
    color: AppColors.textSub,
  );

  // ---------------------------------------------------------------------------
  // DNA visualization (legacy welcome screen)
  // ---------------------------------------------------------------------------
  static const TextStyle dnaLabelTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle dnaLabelSubtitle = TextStyle(
    fontSize: 10,
    color: AppColors.textSub,
  );

  static const TextStyle dnaNode = TextStyle(
    fontSize: 11,
    color: Color(0xFFDCE1EB),
  );

  // ---------------------------------------------------------------------------
  // Micro / mono (DM Mono)
  // ---------------------------------------------------------------------------
  static const TextStyle privacyNote = TextStyle(
    fontSize: 10,
    color: AppColors.textMuted,
  );

  static const TextStyle privacyNoteStrong = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.teal,
  );

  /// Uppercase mono section label (design: 10px, 0.1em tracking).
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10,
    color: AppColors.textMuted,
    fontFamily: monoFont,
    letterSpacing: 1,
    fontWeight: FontWeight.w400,
  );

  /// Big mono metric value (e.g. DNA score, ATS score).
  static const TextStyle metric = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    color: AppColors.teal,
    fontFamily: monoFont,
  );

  /// Small mono timestamp / meta.
  static const TextStyle mono = TextStyle(
    fontSize: 10,
    color: AppColors.textMuted,
    fontFamily: monoFont,
  );
}
