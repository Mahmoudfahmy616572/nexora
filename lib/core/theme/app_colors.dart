import 'dart:ui';

/// Nexora visual identity — VISUAL REBUILD.
///
/// Editorial "career operating system" language: deep ink grounds, warm bone
/// type, one dominant brand tone (mint), one intelligent accent (cobalt),
/// one energetic progress tone (amber). Surfaces are SOLID editorial panels,
/// not glass. Gradients are rare and intentional.
///
/// Widgets must reference these tokens only — never raw color literals.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Ink / surfaces (solid editorial panels — no glassmorphism)
  // ---------------------------------------------------------------------------
  /// Deep ink app background.
  static const Color background = Color(0xFF0B0C0E);

  /// Kept equal to [background] so the ambient gradient collapses to flat ink.
  static const Color backgroundGradientMid = Color(0xFF0B0C0E);

  /// Primary solid panel surface.
  static const Color card = Color(0xFF15171B);

  /// Elevated solid surface (inputs, raised modules).
  static const Color cardHi = Color(0xFF1C1F24);

  /// Legacy "glass" token — now a solid surface so old refs stay safe.
  static const Color surfaceGlass = Color(0xFF1C1F24);

  /// Semantic surface aliases.
  static const Color ink = background;
  static const Color surface = card;
  static const Color surfaceHi = cardHi;

  // ---------------------------------------------------------------------------
  // Brand / semantic accents
  // ---------------------------------------------------------------------------
  /// Dominant brand tone — Electric Mint.
  static const Color teal = Color(0xFF46E6B0);

  /// Intelligent accent — Soft Cobalt.
  static const Color purple = Color(0xFF6C8CFF);

  /// Energetic progress / next-move tone — Warm Amber.
  static const Color amber = Color(0xFFF5A524);

  /// Destructive / problem tone.
  static const Color red = Color(0xFFFF6B6B);

  /// Positive / success / growth tone.
  static const Color green = Color(0xFF3DDC97);

  /// Semantic role tokens (use these by meaning, not by hue).
  static const Color brand = teal;
  static const Color accent = purple;
  static const Color progress = amber;
  static const Color focus = purple;
  static const Color selection = teal;
  static const Color growth = green;
  static const Color attention = amber;
  static const Color success = green;
  static const Color danger = red;
  static const Color info = purple;

  // Backwards-compatible aliases used by pre-rebuild widgets.
  static const Color blue = teal;
  static const Color cyan = green;
  static const Color purpleLight = purple;
  static const Color violet = purple;
  static const Color blueLight = teal;

  // ---------------------------------------------------------------------------
  // Type / ink tones
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);

  /// Warm bone — primary text.
  static const Color text = Color(0xFFF4F1EA);

  /// Secondary text (bone ~62%).
  static const Color textSub = Color(0x9EF4F1EA);

  /// Muted text (bone ~38%).
  static const Color textMuted = Color(0x61F4F1EA);

  static const Color bone = text;
  static const Color muted = textSub;
  static const Color eyebrow = textMuted;
  static const Color brandSubtitle = teal;
  static const Color description = textSub;

  // ---------------------------------------------------------------------------
  // Icon accents
  // ---------------------------------------------------------------------------
  static const Color iconPurple = purple;
  static const Color iconBlue = teal;
  static const Color iconCyan = green;

  // ---------------------------------------------------------------------------
  // Structural lines (hairlines instead of floating cards)
  // ---------------------------------------------------------------------------
  static const Color border = Color(0x14F4F1EA);
  static const Color borderMed = Color(0x26F4F1EA);
  static const Color hairline = border;
  static const Color hairlineStrong = borderMed;

  static const Color borderViolet = purpleBdr;

  // ---------------------------------------------------------------------------
  // Tinted fills / strokes (10% fill, 22% stroke)
  // ---------------------------------------------------------------------------
  static const Color tealBg = Color(0x1A46E6B0);
  static const Color tealBdr = Color(0x3846E6B0);
  static const Color purpleBg = Color(0x1A6C8CFF);
  static const Color purpleBdr = Color(0x386C8CFF);
  static const Color amberBg = Color(0x1AF5A524);
  static const Color amberBdr = Color(0x38F5A524);
  static const Color redBg = Color(0x1AFF6B6B);
  static const Color redBdr = Color(0x38FF6B6B);
  static const Color greenBg = Color(0x1A3DDC97);
  static const Color greenBdr = Color(0x383DDC97);

  // ---------------------------------------------------------------------------
  // Gradients — rare & intentional only.
  // ---------------------------------------------------------------------------
  static const List<Color> brandMarkLeft = [teal, teal];
  static const List<Color> brandMarkRight = [purple, purple];
  static const List<Color> headlineGradient = [teal, purple];
  static const List<Color> primaryButtonGradient = [teal, teal];
  static const List<Color> strandLeftGradient = [teal, purple];
  static const List<Color> strandRightGradient = [purple, teal];
  static const List<Color> rungGradient = [teal, purple];

  /// Reserved for the single most important brand moment (e.g. score lock-in).
  static const List<Color> signatureGradient = [teal, purple];

  // ---------------------------------------------------------------------------
  // Shadows / elevation (controlled, not glowy)
  // ---------------------------------------------------------------------------
  static const Color dnaLabelShadow = tealBg;
  static const Color primaryShadow = tealBg;
  static const Color primaryShadowHover = Color(0x6646E6B0);
  static const Color panelShadow = Color(0x40000000);
  static const Color platformShadow = purpleBg;
  static const Color fabShadow = Color(0x7346E6B0);
}
