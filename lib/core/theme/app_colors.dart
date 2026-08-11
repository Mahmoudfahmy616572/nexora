import 'dart:ui';

/// Nexora design tokens — extracted from the approved UI/UX source
/// (Figma "Career DNA" app design).
///
/// These are the ONLY colors the app uses. Do not hard-code raw color
/// values in widgets; always reference a token here.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------
  /// App background (#080C1F).
  static const Color background = Color(0xFF080C1F);

  /// Ambient app-shell background gradient (lighter navy).
  static const Color backgroundGradientMid = Color(0xFF060919);

  /// Card surface (#0F1430).
  static const Color card = Color(0xFF0F1430);

  /// Elevated card / input surface (#141A38).
  static const Color cardHi = Color(0xFF141A38);

  /// Glass surface used by pills / buttons.
  static const Color surfaceGlass = Color(0xFF141A38);

  // ---------------------------------------------------------------------------
  // Brand accents
  // ---------------------------------------------------------------------------
  /// Primary / success (teal #00D4AA).
  static const Color teal = Color(0xFF00D4AA);

  /// Accent purple (#8B7EFF).
  static const Color purple = Color(0xFF8B7EFF);

  /// Amber / warning (#F59E0B).
  static const Color amber = Color(0xFFF59E0B);

  /// Red / destructive (#FF6B6B).
  static const Color red = Color(0xFFFF6B6B);

  /// Green / positive (#34D399).
  static const Color green = Color(0xFF34D399);

  // Backwards-compatible aliases used by pre-design widgets.
  static const Color blue = teal;
  static const Color cyan = green;
  static const Color purpleLight = purple;
  static const Color violet = purple;
  static const Color blueLight = teal;

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFE8EEFF);

  /// Secondary text rgba(232,238,255,0.52).
  static const Color textSub = Color(0x85E8EEFF);

  /// Muted text rgba(232,238,255,0.27).
  static const Color textMuted = Color(0x45E8EEFF);

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
  // Borders
  // ---------------------------------------------------------------------------
  /// rgba(255,255,255,0.07).
  static const Color border = Color(0x12FFFFFF);

  /// rgba(255,255,255,0.13).
  static const Color borderMed = Color(0x21FFFFFF);

  static const Color borderViolet = purpleBdr;

  // ---------------------------------------------------------------------------
  // Tinted backgrounds / borders (10% fill, 22% stroke)
  // ---------------------------------------------------------------------------
  static const Color tealBg = Color(0x1A00D4AA);
  static const Color tealBdr = Color(0x3800D4AA);
  static const Color purpleBg = Color(0x1A8B7EFF);
  static const Color purpleBdr = Color(0x388B7EFF);
  static const Color amberBg = Color(0x1AF59E0B);
  static const Color amberBdr = Color(0x38F59E0B);
  static const Color redBg = Color(0x1AFF6B6B);
  static const Color redBdr = Color(0x38FF6B6B);
  static const Color greenBg = Color(0x1A34D399);
  static const Color greenBdr = Color(0x3834D399);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const List<Color> brandMarkLeft = [teal, teal];
  static const List<Color> brandMarkRight = [purple, purple];

  static const List<Color> headlineGradient = [teal, purple];

  static const List<Color> primaryButtonGradient = [teal, teal];

  static const List<Color> strandLeftGradient = [teal, purple];
  static const List<Color> strandRightGradient = [purple, teal];
  static const List<Color> rungGradient = [teal, purple];

  /// Signature teal→purple gradient used for avatars, fills, and accents.
  static const List<Color> signatureGradient = [teal, purple];

  // ---------------------------------------------------------------------------
  // Glows / shadows
  // ---------------------------------------------------------------------------
  static const Color dnaLabelShadow = tealBg;
  static const Color primaryShadow = tealBg;
  static const Color primaryShadowHover = Color(0x6600D4AA);
  static const Color panelShadow = Color(0x40000000);
  static const Color platformShadow = purpleBg;

  /// Raised FAB shadow (design: 0 4px 20px rgba(0,212,170,0.45)).
  static const Color fabShadow = Color(0x7300D4AA);
}
