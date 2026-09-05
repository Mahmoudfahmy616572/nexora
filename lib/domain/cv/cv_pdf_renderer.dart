import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/career_dna.dart' show CareerStage;
import '../entities/career_target.dart' show TargetType;
import '../entities/cv_content.dart';
import '../../core/platform/file_io.dart';
import 'cv_section_ordering.dart';
import 'cv_template_registry.dart';

/// Generates a real A4 PDF from [CvContent] using the selected [CvTemplate].
///
/// The renderer applies an editorial composition system on top of the
/// structured content:
///   * a strict PDF-local type scale per template personality where
///     name > professional title > section titles > body > metadata;
///   * a print-safe ink palette with strategic accent use (professional
///     title, section rules, links, bullet markers) and no decorative
///     cards, pills or gradients;
///   * true hanging-indent bullets;
///   * atomic experience/project/education/certification items that never
///     split across page breaks ([pw.Wrap] spanning);
///   * a discreet footer with page numbers on multi-page documents;
///   * full RTL layout driven by content detection.
class CvPdfRenderer {
  const CvPdfRenderer._();

  static const double a4Width = 595.28;
  static const double a4Height = 841.89;

  static Future<_Fonts>? _fontsFuture;

  static const _arabicSectionTitles = <String, String>{
    'PROFILE': 'الملف الشخصي',
    'EXPERIENCE': 'الخبرة',
    'PROJECTS': 'المشاريع',
    'EDUCATION': 'التعليم',
    'SKILLS': 'المهارات',
    'CERTIFICATIONS': 'الشهادات',
    'ACHIEVEMENTS': 'الإنجازات',
    'LANGUAGES': 'اللغات',
  };

  /// The PDF-local type scale used when rendering a given engine template.
  @visibleForTesting
  static CvTypeScale typeScaleFor(String templateId) =>
      _CvStyle.forTemplate(CvTemplateRegistry.get(templateId)).scale;

  static bool detectRtl(CvContent content) {
    final text = content.header.name + content.summary;
    final arabicCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    return arabicCount > text.length * 0.3;
  }

  /// Generates a PDF byte array from the given CV content and template.
  ///
  /// [stage] and [targetType] drive target-aware section ordering (fresh
  /// graduates lead with projects, career changers with skills, academic
  /// targets with education). When omitted the default job-target ordering
  /// is used.
  static Future<Uint8List> render({
    required CvContent content,
    required String templateId,
    CareerStage? stage,
    TargetType? targetType,
  }) async {
    final template = CvTemplateRegistry.get(templateId);
    final fonts = await _loadFonts();
    final style = _CvStyle.forTemplate(template);
    final rt = _Rt(
      fonts: fonts,
      s: style,
      rtl: detectRtl(content),
    );

    final sections = CvSectionOrdering.orderedSectionsForStages(
      content: content,
      stage: stage,
      targetType: targetType,
    );

    final widgets = <pw.Widget>[
      _header(rt, content),
      pw.SizedBox(height: style.headerGap),
    ];
    var firstSection = true;
    for (final section in sections) {
      if (!firstSection) {
        widgets.add(pw.SizedBox(height: style.sectionGap));
      }
      widgets.addAll(_section(rt, section, content));
      firstSection = false;
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(
          horizontal: style.marginH,
          vertical: style.marginV,
        ),
        textDirection: rt.textDirection,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (context) => widgets,
        footer: (context) => _footer(rt, context, content),
      ),
    );

    return pdf.save();
  }

  static Future<String> renderToFile({
    required CvContent content,
    required String templateId,
    required String outputPath,
    CareerStage? stage,
    TargetType? targetType,
  }) async {
    final bytes = await render(
      content: content,
      templateId: templateId,
      stage: stage,
      targetType: targetType,
    );
    await writeBytesToFile(outputPath, bytes);
    return outputPath;
  }

  static Future<_Fonts> _loadFonts() {
    return _fontsFuture ??= () async {
      Future<pw.Font> load(String path) async {
        final data = await rootBundle.load(path);
        return pw.Font.ttf(data.buffer.asByteData());
      }

      return _Fonts(
        regular: await load('assets/fonts/Inter-Regular.ttf'),
        medium: await load('assets/fonts/Inter-Medium.ttf'),
        semibold: await load('assets/fonts/Inter-SemiBold.ttf'),
        bold: await load('assets/fonts/Inter-Bold.ttf'),
        arabic: await load('assets/fonts/NotoSansArabic-Variable.ttf'),
      );
    }();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _header(_Rt rt, CvContent c) {
    final h = c.header;
    final s = rt.s;
    final sc = s.scale;

    final contactParts = [
      if (h.email.isNotEmpty) h.email,
      if (h.phone.isNotEmpty) h.phone,
      if (h.location.isNotEmpty) h.location,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (h.name.isNotEmpty)
          pw.Text(
            h.name,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.nameSize,
              weight: 700,
              color: s.ink,
              tracking: sc.nameTracking,
            ),
          ),
        if (h.title.isNotEmpty) ...[
          pw.SizedBox(height: sc.nameSize * 0.12),
          pw.Text(
            h.title,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.titleSize,
              weight: 600,
              color: s.accent,
              tracking: 0.3,
            ),
          ),
        ],
        if (h.subtitle.isNotEmpty && h.subtitle != h.title) ...[
          pw.SizedBox(height: 1.5),
          pw.Text(
            h.subtitle,
            textDirection: rt.textDirection,
            style: _style(rt, size: sc.metaSize + 0.7, color: s.secondary),
          ),
        ],
        if (contactParts.isNotEmpty) ...[
          pw.SizedBox(height: sc.nameSize * 0.24),
          pw.Text(
            contactParts.join('   ·   '),
            textDirection: rt.textDirection,
            style: _style(rt, size: sc.metaSize, color: s.muted),
          ),
        ],
        if (h.links.isNotEmpty) ...[
          pw.SizedBox(height: 2.5),
          pw.Text(
            h.links.join('  ·  '),
            textDirection: rt.textDirection,
            style: _style(rt, size: sc.metaSize, color: s.accent),
          ),
        ],
        pw.SizedBox(height: s.headerGap * 0.55),
        pw.Container(
          height: s.headerRuleHeight,
          color: s.headerRuleColor,
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Section scaffolding
  // ───────────────────────────────────────────────────────────────────────────

  static List<pw.Widget> _section(
    _Rt rt,
    CvSection section,
    CvContent content,
  ) {
    final head = _sectionHead(rt, section);
    switch (section) {
      case CvSection.summary:
        return _summaryBody(rt, content, head);
      case CvSection.experience:
        return _experienceBody(rt, content, head);
      case CvSection.projects:
        return _projectsBody(rt, content, head);
      case CvSection.education:
        return _educationBody(rt, content, head);
      case CvSection.skills:
        return _skillsBody(rt, content, head);
      case CvSection.certifications:
        return _certificationsBody(rt, content, head);
      case CvSection.achievements:
        return _achievementsBody(rt, content, head);
      case CvSection.languages:
        return _languagesBody(rt, content, head);
    }
  }

  /// Keeps a section heading glued to its first content unit: the heading and
  /// the first unit are laid out as one atomic block inside a spanning
  /// [pw.Wrap], so MultiPage either fits both on the current page or moves
  /// them together to the next one. No manual pagination involved.
  static pw.Widget _keepWithHead(pw.Widget head, List<pw.Widget> firstUnit) {
    return pw.Wrap(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            head,
            ...firstUnit,
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionHead(_Rt rt, CvSection section) {
    final englishTitle = switch (section) {
      CvSection.summary => 'PROFILE',
      CvSection.experience => 'EXPERIENCE',
      CvSection.projects => 'PROJECTS',
      CvSection.education => 'EDUCATION',
      CvSection.skills => 'SKILLS',
      CvSection.certifications => 'CERTIFICATIONS',
      CvSection.achievements => 'ACHIEVEMENTS',
      CvSection.languages => 'LANGUAGES',
    };
    final label =
        rt.rtl ? (_arabicSectionTitles[englishTitle] ?? englishTitle) : englishTitle;
    final s = rt.s;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          textDirection: rt.textDirection,
          style: _style(
            rt,
            size: s.scale.sectionTitleSize,
            weight: 700,
            color: s.sectionTitleColor,
            tracking: s.scale.sectionTracking,
          ),
        ),
        pw.SizedBox(height: 3),
        if (s.barSectionRule)
          pw.Container(
            width: s.barLength,
            height: s.headerRuleHeight,
            color: s.accent,
          )
        else
          pw.Container(
            height: s.ruleHeight,
            color: s.ruleColor,
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Section bodies
  // ───────────────────────────────────────────────────────────────────────────

  static List<pw.Widget> _summaryBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    if (c.summary.trim().isEmpty) return const [];
    return [
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        pw.Text(
          c.summary.trim(),
          textDirection: rt.textDirection,
          style: _style(
            rt,
            size: rt.s.scale.bodySize,
            color: rt.s.secondary,
            lineSpacing: rt.s.scale.bodyLead,
          ),
        ),
      ]),
    ];
  }

  static List<pw.Widget> _experienceBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    final out = <pw.Widget>[
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _experienceItem(rt, c.experience[0]),
      ]),
    ];
    for (var i = 1; i < c.experience.length; i++) {
      out.add(pw.SizedBox(height: rt.s.itemGap));
      out.add(pw.Wrap(children: [_experienceItem(rt, c.experience[i])]));
    }
    return out;
  }

  static pw.Widget _experienceItem(_Rt rt, CvExperience e) {
    final sc = rt.s.scale;
    final headline = e.company.isNotEmpty ? e.company : e.role;
    final roleLine =
        e.company.isNotEmpty && e.role.isNotEmpty ? e.role : '';
    final dates = [e.startDate, e.endDate].where((s) => s.isNotEmpty).join(' – ');
    final dateLabel = dates.isNotEmpty ? dates : e.yearsLabel;
    final rightMeta = [
      if (dateLabel.isNotEmpty) dateLabel,
      if (e.location.isNotEmpty) e.location,
    ].join('   ·   ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                headline,
                textDirection: rt.textDirection,
                style: _style(
                  rt,
                  size: sc.bodySize + 0.7,
                  weight: 700,
                  color: rt.s.ink,
                ),
              ),
            ),
            if (rightMeta.isNotEmpty)
              pw.Text(
                rightMeta,
                textDirection: rt.textDirection,
                style: _style(rt, size: sc.metaSize, color: rt.s.muted),
              ),
          ],
        ),
        if (roleLine.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            roleLine,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.metaSize + 0.6,
              weight: 500,
              color: rt.s.secondary,
            ),
          ),
        ],
        ..._itemDetail(rt, e.effectiveBullets),
      ],
    );
  }

  static List<pw.Widget> _projectsBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    final out = <pw.Widget>[
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _projectItem(rt, c.projects[0]),
      ]),
    ];
    for (var i = 1; i < c.projects.length; i++) {
      out.add(pw.SizedBox(height: rt.s.itemGap));
      out.add(pw.Wrap(children: [_projectItem(rt, c.projects[i])]));
    }
    return out;
  }

  static pw.Widget _projectItem(_Rt rt, CvProject p) {
    final sc = rt.s.scale;
    final links = p.effectiveLinks;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    p.name,
                    textDirection: rt.textDirection,
                    style: _style(
                      rt,
                      size: sc.bodySize + 0.7,
                      weight: 700,
                      color: rt.s.ink,
                    ),
                  ),
                  if (p.date.isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      p.date,
                      textDirection: rt.textDirection,
                      style: _style(rt, size: sc.metaSize, color: rt.s.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (links.isNotEmpty)
              pw.Text(
                links.join('  ·  '),
                textDirection: rt.textDirection,
                style: _style(rt, size: sc.metaSize, color: rt.s.accent),
              ),
          ],
        ),
        if (p.role.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            p.role,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.metaSize + 0.6,
              weight: 500,
              color: rt.s.secondary,
            ),
          ),
        ],
        if (p.tech.isNotEmpty) ...[
          pw.SizedBox(height: 1.5),
          pw.Text(
            p.tech.join('  ·  '),
            textDirection: rt.textDirection,
            style: _style(rt, size: sc.metaSize + 0.3, color: rt.s.secondary),
          ),
        ],
        ..._itemDetail(rt, p.effectiveBullets),
      ],
    );
  }

  static List<pw.Widget> _itemDetail(_Rt rt, List<String> bullets) {
    if (bullets.isEmpty) return const [];
    return [
      pw.SizedBox(height: rt.s.bulletGap + 1.5),
      for (final b in bullets) _bullet(rt, b),
    ];
  }

  static pw.Widget _bullet(_Rt rt, String text) {
    final sc = rt.s.scale;
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: rt.s.bulletGap),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: rt.s.markerWidth,
            padding: pw.EdgeInsets.only(top: sc.bodySize * 0.09),
            child: pw.Text(
              '•',
              textAlign: pw.TextAlign.center,
              style: _style(
                rt,
                size: sc.bodySize - 0.5,
                weight: 700,
                color: rt.s.accent,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              textDirection: rt.textDirection,
              style: _style(
                rt,
                size: sc.bodySize,
                color: rt.s.secondary,
                lineSpacing: sc.bodyLead,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _educationBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    final out = <pw.Widget>[
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _educationItem(rt, c.education[0]),
      ]),
    ];
    for (var i = 1; i < c.education.length; i++) {
      out.add(pw.SizedBox(height: rt.s.itemGap - 2));
      out.add(pw.Wrap(children: [_educationItem(rt, c.education[i])]));
    }
    return out;
  }

  static pw.Widget _educationItem(_Rt rt, CvEducation e) {
    final sc = rt.s.scale;
    final degreeLine = [e.degree, e.field].where((s) => s.isNotEmpty).join(' · ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                degreeLine,
                textDirection: rt.textDirection,
                style: _style(
                  rt,
                  size: sc.bodySize + 0.5,
                  weight: 600,
                  color: rt.s.ink,
                ),
              ),
            ),
            if (e.year.isNotEmpty)
              pw.Text(
                e.year,
                textDirection: rt.textDirection,
                style: _style(rt, size: sc.metaSize, color: rt.s.muted),
              ),
          ],
        ),
        if (e.institution.isNotEmpty)
          pw.Text(
            e.institution,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.metaSize + 0.6,
              color: rt.s.secondary,
            ),
          ),
      ],
    );
  }

  static List<pw.Widget> _skillsBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    final sc = rt.s.scale;
    final groups =
        c.skillGroups.where((g) => g.skills.isNotEmpty).toList(growable: false);
    final out = <pw.Widget>[
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _skillGroupRow(rt, sc, groups[0]),
      ]),
    ];
    for (var i = 1; i < groups.length; i++) {
      out.add(pw.SizedBox(height: rt.s.bulletGap + 1));
      out.add(_skillGroupRow(rt, sc, groups[i]));
    }
    return out;
  }

  static pw.Widget _skillGroupRow(_Rt rt, CvTypeScale sc, CvSkillGroup g) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: rt.s.skillCategoryWidth,
          child: pw.Text(
            g.title.toUpperCase(),
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.metaSize + 0.6,
              weight: 600,
              color: rt.s.ink,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            g.skills.join('  ·  '),
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.bodySize - 0.2,
              color: rt.s.secondary,
              lineSpacing: sc.metaLead,
            ),
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _certificationsBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    final sc = rt.s.scale;
    final out = <pw.Widget>[
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _certificationRow(rt, sc, c.certifications[0]),
      ]),
    ];
    for (var i = 1; i < c.certifications.length; i++) {
      out.add(pw.SizedBox(height: rt.s.bulletGap + 1));
      out.add(pw.Wrap(children: [_certificationRow(rt, sc, c.certifications[i])]));
    }
    return out;
  }

  static pw.Widget _certificationRow(_Rt rt, CvTypeScale sc, CvCertification cert) {
    final rest = [
      if (cert.issuer.isNotEmpty) cert.issuer,
      if (cert.year.isNotEmpty) cert.year,
    ].join('  ·  ');
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            cert.name,
            textDirection: rt.textDirection,
            style: _style(
              rt,
              size: sc.bodySize - 0.2,
              weight: 600,
              color: rt.s.ink,
            ),
          ),
        ),
        if (rest.isNotEmpty)
          pw.Text(
            rest,
            textDirection: rt.textDirection,
            style: _style(rt, size: sc.metaSize, color: rt.s.muted),
          ),
      ],
    );
  }

  static List<pw.Widget> _achievementsBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    if (c.achievements.isEmpty) return const [];
    return [
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        _bullet(rt, c.achievements[0].text),
      ]),
      for (var i = 1; i < c.achievements.length; i++)
        _bullet(rt, c.achievements[i].text),
    ];
  }

  static List<pw.Widget> _languagesBody(
    _Rt rt,
    CvContent c,
    pw.Widget head,
  ) {
    if (c.languages.isEmpty) return const [];
    return [
      _keepWithHead(head, [
        pw.SizedBox(height: rt.s.afterTitleGap),
        pw.Text(
          c.languages.map((l) => l.display).join('   ·   '),
          textDirection: rt.textDirection,
          style: _style(
            rt,
            size: rt.s.scale.bodySize,
            color: rt.s.secondary,
          ),
        ),
      ]),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Footer
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _footer(
    _Rt rt,
    pw.Context context,
    CvContent content,
  ) {
    if (context.pagesCount <= 1) return pw.SizedBox.shrink();
    final name = content.header.name;
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: rt.s.ruleColor, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (name.isNotEmpty)
            pw.Text(
              rt.rtl ? name : name.toUpperCase(),
              textDirection: rt.textDirection,
              style: _style(
                rt,
                size: rt.s.scale.metaSize - 1.3,
                color: rt.s.muted,
                tracking: 0.8,
              ),
            ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: _style(
              rt,
              size: rt.s.scale.metaSize - 1.3,
              color: rt.s.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Style primitives
  // ───────────────────────────────────────────────────────────────────────────

  static pw.TextStyle _style(
    _Rt rt, {
    required double size,
    required PdfColor color,
    int weight = 400,
    double? tracking,
    double? lineSpacing,
  }) {
    final font = switch (weight) {
      500 => rt.fonts.medium,
      600 => rt.fonts.semibold,
      700 => rt.fonts.bold,
      _ => rt.fonts.regular,
    };
    return pw.TextStyle(
      fontSize: size,
      color: color,
      letterSpacing: tracking,
      lineSpacing: lineSpacing,
      fontWeight: weight >= 600 ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontNormal: font,
      fontBold: font,
      fontFallback: [rt.fonts.arabic],
    );
  }
}

/// The resolved typography + spacing values for one CV document.
@visibleForTesting
class CvTypeScale {
  const CvTypeScale({
    required this.nameSize,
    required this.nameTracking,
    required this.titleSize,
    required this.sectionTitleSize,
    required this.sectionTracking,
    required this.bodySize,
    required this.bodyLead,
    required this.metaSize,
    required this.metaLead,
    required this.marginH,
    required this.marginV,
    required this.headerGap,
    required this.sectionGap,
    required this.afterTitleGap,
    required this.itemGap,
    required this.bulletGap,
    required this.markerWidth,
    required this.skillCategoryWidth,
  });

  final double nameSize;
  final double nameTracking;
  final double titleSize;
  final double sectionTitleSize;
  final double sectionTracking;
  final double bodySize;
  final double bodyLead;
  final double metaSize;
  final double metaLead;
  final double marginH;
  final double marginV;
  final double headerGap;
  final double sectionGap;
  final double afterTitleGap;
  final double itemGap;
  final double bulletGap;
  final double markerWidth;
  final double skillCategoryWidth;
}

class _Fonts {
  const _Fonts({
    required this.regular,
    required this.medium,
    required this.semibold,
    required this.bold,
    required this.arabic,
  });

  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semibold;
  final pw.Font bold;
  final pw.Font arabic;
}

class _Rt {
  const _Rt({
    required this.fonts,
    required this.s,
    required this.rtl,
  });

  final _Fonts fonts;
  final _CvStyle s;
  final bool rtl;

  pw.TextDirection? get textDirection =>
      rtl ? pw.TextDirection.rtl : null;
}

enum _SectionRuleStyle { fullHairline, accentBar }

class _CvStyle {
  const _CvStyle({
    required this.scale,
    required this.ink,
    required this.secondary,
    required this.muted,
    required this.accent,
    required this.sectionTitleColor,
    required this.ruleColor,
    required this.headerRuleColor,
    required this.headerRuleHeight,
    required this.ruleHeight,
    required this.barLength,
    required _SectionRuleStyle sectionRuleStyle,
  })  : barSectionRule = sectionRuleStyle == _SectionRuleStyle.accentBar;

  factory _CvStyle.forTemplate(CvTemplate t) {
    switch (t.id) {
      case 'nexoraMinimal':
        return _CvStyle(
          scale: const CvTypeScale(
            nameSize: 25,
            nameTracking: 1.2,
            titleSize: 12,
            sectionTitleSize: 11,
            sectionTracking: 2.0,
            bodySize: 10.5,
            bodyLead: 3.8,
            metaSize: 9,
            metaLead: 2.6,
            marginH: 44,
            marginV: 40,
            headerGap: 18,
            sectionGap: 16,
            afterTitleGap: 7,
            itemGap: 11,
            bulletGap: 3.2,
            markerWidth: 10,
            skillCategoryWidth: 108,
          ),
          ink: _hex(0xFF17181D),
          secondary: _hex(0xFF3B4048),
          muted: _hex(0xFF6E7480),
          accent: _pdf(t.accent),
          sectionTitleColor: _hex(0xFF17181D),
          ruleColor: _pdf(t.dividerColor),
          headerRuleColor: _hex(0xFF17181D),
          headerRuleHeight: 1.4,
          ruleHeight: 0.8,
          barLength: 26,
          sectionRuleStyle: _SectionRuleStyle.fullHairline,
        );
      case 'nexoraModern':
        return _CvStyle(
          scale: const CvTypeScale(
            nameSize: 23,
            nameTracking: 0.8,
            titleSize: 12,
            sectionTitleSize: 10.5,
            sectionTracking: 1.6,
            bodySize: 10.5,
            bodyLead: 3.5,
            metaSize: 9,
            metaLead: 2.4,
            marginH: 42,
            marginV: 38,
            headerGap: 16,
            sectionGap: 15,
            afterTitleGap: 6,
            itemGap: 10,
            bulletGap: 3,
            markerWidth: 10,
            skillCategoryWidth: 104,
          ),
          ink: _hex(0xFF1D2330),
          secondary: _hex(0xFF3A4252),
          muted: _hex(0xFF67707E),
          accent: _pdf(t.accent),
          sectionTitleColor: _pdf(t.accent),
          ruleColor: _pdf(t.dividerColor),
          headerRuleColor: _pdf(t.accent),
          headerRuleHeight: 2,
          ruleHeight: 2.2,
          barLength: 26,
          sectionRuleStyle: _SectionRuleStyle.accentBar,
        );
      default:
        return _CvStyle(
          scale: const CvTypeScale(
            nameSize: 19.5,
            nameTracking: 0.6,
            titleSize: 11,
            sectionTitleSize: 9.5,
            sectionTracking: 1.4,
            bodySize: 10,
            bodyLead: 3,
            metaSize: 8.5,
            metaLead: 2.2,
            marginH: 40,
            marginV: 34,
            headerGap: 14,
            sectionGap: 12,
            afterTitleGap: 5,
            itemGap: 8,
            bulletGap: 2.4,
            markerWidth: 9,
            skillCategoryWidth: 92,
          ),
          ink: _hex(0xFF19222B),
          secondary: _hex(0xFF3A4450),
          muted: _hex(0xFF66707A),
          accent: _pdf(t.accent),
          sectionTitleColor: _hex(0xFF19222B),
          ruleColor: _pdf(t.dividerColor),
          headerRuleColor: _hex(0xFF33414D),
          headerRuleHeight: 1.2,
          ruleHeight: 0.6,
          barLength: 26,
          sectionRuleStyle: _SectionRuleStyle.fullHairline,
        );
    }
  }

  final CvTypeScale scale;
  final PdfColor ink;
  final PdfColor secondary;
  final PdfColor muted;
  final PdfColor accent;
  final PdfColor sectionTitleColor;
  final PdfColor ruleColor;
  final PdfColor headerRuleColor;
  final double headerRuleHeight;
  final double ruleHeight;
  final bool barSectionRule;
  final double barLength;

  double get marginH => scale.marginH;
  double get marginV => scale.marginV;
  double get headerGap => scale.headerGap;
  double get sectionGap => scale.sectionGap;
  double get afterTitleGap => scale.afterTitleGap;
  double get itemGap => scale.itemGap;
  double get bulletGap => scale.bulletGap;
  double get markerWidth => scale.markerWidth;
  double get skillCategoryWidth => scale.skillCategoryWidth;

  static PdfColor _hex(int v) => PdfColor(
        ((v >> 16) & 255) / 255,
        ((v >> 8) & 255) / 255,
        (v & 255) / 255,
      );

  static PdfColor _pdf(Color c) {
    double ch(double v) => v <= 1.0 ? v : v / 255;
    return PdfColor(ch(c.r), ch(c.g), ch(c.b));
  }
}
