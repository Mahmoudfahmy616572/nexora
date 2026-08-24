import 'package:flutter/material.dart';

/// Visual template configuration for the CV Engine.
///
/// Templates are a CODE REGISTRY, not a database table. Switching templates
/// never changes [CvContent] — only how it is rendered. Each template belongs
/// to Nexora's own visual identity.
class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.fontFamily,
    required this.accent,
    required this.bodyColor,
    required this.mutedColor,
    required this.dividerColor,
    required this.surfaceColor,
    required this.baseTextSize,
    required this.headerNameSize,
    required this.sectionTitleSize,
    required this.metaTextSize,
    required this.spacing,
    required this.sectionSpacing,
    required this.itemSpacing,
    required this.bulletSpacing,
    required this.marginHorizontal,
    required this.marginVertical,
    required this.radius,
    required this.showHeaderBar,
    required this.showSectionDivider,
    required this.layout,
  });

  final String id;
  final String name;
  final String description;
  final String fontFamily;

  /// Primary accent color (section titles, links, emphasis).
  final Color accent;

  /// Main body text color.
  final Color bodyColor;

  /// Muted/meta text color (dates, locations, secondary info).
  final Color mutedColor;

  /// Section divider line color.
  final Color dividerColor;

  /// Subtle background for header bar or skill chips.
  final Color surfaceColor;

  /// Base body text size in logical pixels.
  final double baseTextSize;

  /// Header name size in logical pixels.
  final double headerNameSize;

  /// Section title text size.
  final double sectionTitleSize;

  /// Metadata text size (dates, locations, tech stack).
  final double metaTextSize;

  /// General vertical spacing multiplier.
  final double spacing;

  /// Spacing between major sections.
  final double sectionSpacing;

  /// Spacing between items within a section.
  final double itemSpacing;

  /// Spacing between bullet lines.
  final double bulletSpacing;

  /// Horizontal page margins.
  final double marginHorizontal;

  /// Vertical page margins.
  final double marginVertical;

  /// Corner radius for the CV card.
  final double radius;

  /// Whether the header is drawn inside an accent-tinted bar.
  final bool showHeaderBar;

  /// Whether to show a divider line under section titles.
  final bool showSectionDivider;

  /// One of: 'classic' | 'modern' | 'compact'.
  final String layout;
}

class CvTemplateRegistry {
  const CvTemplateRegistry._();

  static const List<CvTemplate> templates = [
    // ──────────────────────────────────────────────────────────────
    // NEXORA MINIMAL — Editorial / Premium / Professional
    // ──────────────────────────────────────────────────────────────
    CvTemplate(
      id: 'nexoraMinimal',
      name: 'Nexora Minimal',
      description: 'Clean, editorial layout with strong typography hierarchy.',
      fontFamily: 'Inter',
      accent: Color(0xFF1A1A2E),
      bodyColor: Color(0xFF2D2D3A),
      mutedColor: Color(0xFF6B7280),
      dividerColor: Color(0xFFD1D5DB),
      surfaceColor: Color(0xFFF9FAFB),
      baseTextSize: 10.5,
      headerNameSize: 22,
      sectionTitleSize: 11,
      metaTextSize: 9.5,
      spacing: 14,
      sectionSpacing: 14,
      itemSpacing: 8,
      bulletSpacing: 2,
      marginHorizontal: 24,
      marginVertical: 20,
      radius: 0,
      showHeaderBar: false,
      showSectionDivider: true,
      layout: 'classic',
    ),

    // ──────────────────────────────────────────────────────────────
    // NEXORA MODERN — Modern Professional with Personality
    // ──────────────────────────────────────────────────────────────
    CvTemplate(
      id: 'nexoraModern',
      name: 'Nexora Modern',
      description: 'Modern professional with accent color and visual grouping.',
      fontFamily: 'Inter',
      accent: Color(0xFF6C63FF),
      bodyColor: Color(0xFF1F2937),
      mutedColor: Color(0xFF6B7280),
      dividerColor: Color(0xFFE5E7EB),
      surfaceColor: Color(0xFFF0EEFF),
      baseTextSize: 10.5,
      headerNameSize: 22,
      sectionTitleSize: 11,
      metaTextSize: 9.5,
      spacing: 12,
      sectionSpacing: 12,
      itemSpacing: 6,
      bulletSpacing: 2,
      marginHorizontal: 22,
      marginVertical: 18,
      radius: 4,
      showHeaderBar: true,
      showSectionDivider: false,
      layout: 'modern',
    ),

    // ──────────────────────────────────────────────────────────────
    // NEXORA COMPACT — High Information Density
    // ──────────────────────────────────────────────────────────────
    CvTemplate(
      id: 'nexoraCompact',
      name: 'Nexora Compact',
      description: 'Dense, efficient layout for extensive experience.',
      fontFamily: 'Inter',
      accent: Color(0xFF0F766E),
      bodyColor: Color(0xFF1E293B),
      mutedColor: Color(0xFF64748B),
      dividerColor: Color(0xFFCBD5E1),
      surfaceColor: Color(0xFFF1F5F9),
      baseTextSize: 9.5,
      headerNameSize: 18,
      sectionTitleSize: 10,
      metaTextSize: 8.5,
      spacing: 9,
      sectionSpacing: 10,
      itemSpacing: 4,
      bulletSpacing: 1,
      marginHorizontal: 20,
      marginVertical: 16,
      radius: 0,
      showHeaderBar: false,
      showSectionDivider: true,
      layout: 'compact',
    ),
  ];

  static List<CvTemplate> get all => templates;

  static const String defaultTemplateId = 'nexoraMinimal';

  static CvTemplate get(String id) => byId(id);

  static CvTemplate byId(String id) =>
      templates.firstWhere((t) => t.id == id, orElse: () => templates.first);

  static bool isValid(String id) => templates.any((t) => t.id == id);
}
