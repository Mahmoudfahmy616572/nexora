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
    required this.baseTextSize,
    required this.headerNameSize,
    required this.spacing,
    required this.radius,
    required this.showHeaderBar,
    required this.layout,
  });

  final String id;
  final String name;
  final String description;
  final String fontFamily;
  final Color accent;

  /// Base body text size in logical pixels.
  final double baseTextSize;

  /// Header name size in logical pixels.
  final double headerNameSize;

  /// Vertical rhythm multiplier for section spacing.
  final double spacing;

  /// Corner radius for the CV card.
  final double radius;

  /// Whether the header is drawn inside an accent-tinted bar.
  final bool showHeaderBar;

  /// One of: 'classic' | 'modern' | 'compact'.
  final String layout;
}

class CvTemplateRegistry {
  const CvTemplateRegistry._();

  static const List<CvTemplate> templates = [
    CvTemplate(
      id: 'nexoraMinimal',
      name: 'Nexora Minimal',
      description: 'Clean single-column layout with generous whitespace.',
      fontFamily: 'Inter',
      accent: Color(0xFF00D4AA),
      baseTextSize: 13,
      headerNameSize: 22,
      spacing: 14,
      radius: 8,
      showHeaderBar: false,
      layout: 'classic',
    ),
    CvTemplate(
      id: 'nexoraModern',
      name: 'Nexora Modern',
      description: 'Two-column header with a bold accent sidebar feel.',
      fontFamily: 'Bricolage Grotesque',
      accent: Color(0xFF8B7EFF),
      baseTextSize: 13.5,
      headerNameSize: 24,
      spacing: 12,
      radius: 16,
      showHeaderBar: true,
      layout: 'modern',
    ),
    CvTemplate(
      id: 'nexoraCompact',
      name: 'Nexora Compact',
      description: 'Dense, print-optimized layout for one-page CVs.',
      fontFamily: 'Inter',
      accent: Color(0xFFF59E0B),
      baseTextSize: 12,
      headerNameSize: 20,
      spacing: 9,
      radius: 6,
      showHeaderBar: false,
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
