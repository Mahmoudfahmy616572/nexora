import 'dart:ui';

/// Nexora design tokens — extracted from the approved UI/UX source.
///
/// These are the ONLY colors the app uses. Do not hard-code raw color
/// values in widgets; always reference a token here.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFF020617);
  static const Color backgroundGradientMid = Color(0xFF030719);
  static const Color backgroundSoft = Color(0xFF070B20);

  /// Surface used by glass panels (feature panel, dna label, topbar).
  static const Color surfaceGlass = Color(0x0F0F172A); // rgba(15,23,42,0.48)

  // ---------------------------------------------------------------------------
  // Brand accents
  // ---------------------------------------------------------------------------
  static const Color purple = Color(0xFFA855F7);
  static const Color purpleLight = Color(0xFFC084FC);
  static const Color violet = Color(0xFF7C3AED);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF60A5FA);

  static const Color cyan = Color(0xFF22D3EE);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFFA7AFC4);

  static const Color eyebrow = Color(0xFFA970FF);
  static const Color brandSubtitle = Color(0xFF9F67FF);
  static const Color description = Color(0xFFAEB7CB);

  // ---------------------------------------------------------------------------
  // Icon accents
  // ---------------------------------------------------------------------------
  static const Color iconPurple = Color(0xFFBD76FF);
  static const Color iconBlue = Color(0xFF5C8FFF);
  static const Color iconCyan = Color(0xFF28D9E8);

  // ---------------------------------------------------------------------------
  // Borders
  // ---------------------------------------------------------------------------
  static const Color border = Color(0x2E94A0B8); // rgba(148,163,184,0.18)
  static const Color borderViolet = Color(0x738B5CF6); // violet @ 0.45

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const List<Color> brandMarkLeft = [purpleLight, violet];
  static const List<Color> brandMarkRight = [blueLight, blue];

  static const List<Color> headlineGradient = [
    Color(0xFFB45CFF),
    Color(0xFF8056FF),
    Color(0xFF567CFF),
  ];

  static const List<Color> primaryButtonGradient = [
    purple,
    violet,
    blue,
  ];

  static const List<Color> strandLeftGradient = [
    violet,
    purpleLight,
    blue,
  ];

  static const List<Color> strandRightGradient = [
    blue,
    blueLight,
    purple,
  ];

  static const List<Color> rungGradient = [purple, blueLight];

  // ---------------------------------------------------------------------------
  // Glows / shadows
  // ---------------------------------------------------------------------------
  static const Color dnaLabelShadow = Color(0x387C3AED); // violet @ 0.22
  static const Color primaryShadow = Color(0x477C3AED); // violet @ 0.28
  static const Color primaryShadowHover = Color(0x667C3AED); // violet @ 0.40
  static const Color panelShadow = Color(0x40000000); // black @ 0.25
  static const Color platformShadow = Color(0x407C3AED); // violet @ 0.25
}
