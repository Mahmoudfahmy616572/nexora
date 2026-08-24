import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/cv_content.dart';
import 'cv_section_ordering.dart';
import 'cv_template_registry.dart';

/// Generates a real A4 PDF from [CvContent] using the selected [CvTemplate].
///
/// Renders the same structured content as the screen preview but produces a
/// printable, ATS-friendly PDF document. Supports multi-page, grouped skills,
/// structured bullets, and RTL layout.
class CvPdfRenderer {
  const CvPdfRenderer._();

  static const double a4Width = 595.28;
  static const double a4Height = 841.89;
  static pw.Font? _arabicFont;
  static bool _isRtl = false;

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

  static bool _detectRtl(CvContent content) {
    final text = content.header.name + content.summary;
    final arabicCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    return arabicCount > text.length * 0.3;
  }

  static String _sectionTitle(String title) {
    if (_isRtl) return _arabicSectionTitles[title] ?? title;
    return title;
  }

  /// Generates a PDF byte array from the given CV content and template.
  static Future<Uint8List> render({
    required CvContent content,
    required String templateId,
  }) async {
    final template = CvTemplateRegistry.get(templateId);
    final font = await _loadFont('assets/fonts/Inter-Variable.ttf');
    final arabicFont = await _loadFont('assets/fonts/NotoSansArabic-Variable.ttf');
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    _arabicFont = arabicFont;
    _isRtl = _detectRtl(content);
    final sections = CvSectionOrdering.orderedSections(content: content);
    final marginH = template.marginHorizontal * 0.75;
    final marginV = template.marginVertical * 0.75;

    final allWidgets = <pw.Widget>[
      _buildPdfHeader(content, template),
      pw.SizedBox(height: template.sectionSpacing * 0.5),
      _buildPdfDivider(template),
    ];
    for (final section in sections) {
      allWidgets.add(_buildPdfSection(section, content, template));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: marginH, vertical: marginV),
        textDirection: _isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (context) => allWidgets,
      ),
    );

    return pdf.save();
  }

  static Future<String> renderToFile({
    required CvContent content,
    required String templateId,
    required String outputPath,
  }) async {
    final bytes = await render(content: content, templateId: templateId);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return outputPath;
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data.buffer.asByteData());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildPdfHeader(CvContent content, CvTemplate t) {
    final h = content.header;
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (h.name.isNotEmpty)
          pw.Text(
            h.name,
            textDirection: td,
            style: _textStyle(
              fontSize: t.headerNameSize,
              fontWeight: pw.FontWeight.bold,
              color: t.bodyColor,
            ),
          ),
        if (h.title.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            h.title,
            textDirection: td,
            style: _textStyle(
              fontSize: t.baseTextSize + 1.5,
              fontWeight: pw.FontWeight.bold,
              color: t.accent,
            ),
          ),
        ],
        if (h.subtitle.isNotEmpty && h.subtitle != h.title) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            h.subtitle,
            textDirection: td,
            style: _textStyle(
              fontSize: t.metaTextSize,
              color: t.mutedColor,
            ),
          ),
        ],
        if (h.email.isNotEmpty || h.phone.isNotEmpty || h.location.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            [h.email, h.phone, h.location].where((s) => s.isNotEmpty).join('  •  '),
            textDirection: td,
            style: _textStyle(
              fontSize: t.metaTextSize,
              color: t.mutedColor,
            ),
          ),
        ],
        if (h.links.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            h.links.join('  •  '),
            textDirection: td,
            style: _textStyle(
              fontSize: t.metaTextSize,
              color: t.mutedColor,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPdfDivider(CvTemplate t) {
    if (!t.showSectionDivider) return pw.SizedBox.shrink();
    return pw.Container(
      height: 0.5,
      color: _pdfColor(t.dividerColor),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Section title
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildPdfSectionTitle(String title, CvTemplate t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _sectionTitle(title),
          textDirection: _isRtl ? pw.TextDirection.rtl : null,
          style: _textStyle(
            fontSize: t.sectionTitleSize,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
            color: t.accent,
          ),
        ),
        if (t.showSectionDivider) ...[
          pw.SizedBox(height: 2),
          pw.Container(height: 0.3, color: _pdfColor(t.dividerColor)),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sections
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildPdfSection(
    CvSection section,
    CvContent content,
    CvTemplate t,
  ) {
    switch (section) {
      case CvSection.summary:
        return _pdfSummary(content, t);
      case CvSection.experience:
        return _pdfExperience(content, t);
      case CvSection.projects:
        return _pdfProjects(content, t);
      case CvSection.education:
        return _pdfEducation(content, t);
      case CvSection.skills:
        return _pdfSkills(content, t);
      case CvSection.certifications:
        return _pdfCertifications(content, t);
      case CvSection.achievements:
        return _pdfAchievements(content, t);
      case CvSection.languages:
        return _pdfLanguages(content, t);
    }
  }

  static pw.Widget _pdfSummary(CvContent c, CvTemplate t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('PROFILE', t),
        pw.SizedBox(height: t.spacing * 0.3),
        pw.Text(
          c.summary,
          textDirection: _isRtl ? pw.TextDirection.rtl : null,
          style: _textStyle(
            fontSize: t.baseTextSize,
            color: t.bodyColor,
            lineSpacing: t.baseTextSize * 0.45,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfExperience(CvContent c, CvTemplate t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('EXPERIENCE', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (int i = 0; i < c.experience.length; i++) ...[
          _pdfExperienceItem(c.experience[i], t),
          if (i < c.experience.length - 1) pw.SizedBox(height: t.itemSpacing),
        ],
      ],
    );
  }

  static pw.Widget _pdfExperienceItem(CvExperience e, CvTemplate t) {
    final bullets = e.effectiveBullets;
    final dateStr = [e.startDate, e.endDate].where((s) => s.isNotEmpty).join(' – ');
    final finalDate = dateStr.isEmpty ? e.yearsLabel : dateStr;
    final td = _isRtl ? pw.TextDirection.rtl : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                e.company.isNotEmpty ? '${e.role} — ${e.company}' : e.role,
                textDirection: td,
                style: _textStyle(
                  fontSize: t.baseTextSize,
                  fontWeight: pw.FontWeight.bold,
                  color: t.bodyColor,
                ),
              ),
            ),
            if (finalDate.isNotEmpty)
              pw.Text(
                finalDate,
                textDirection: td,
                style: _textStyle(
                  fontSize: t.metaTextSize,
                  color: t.mutedColor,
                ),
              ),
          ],
        ),
        if (e.location.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            e.location,
            textDirection: td,
            style: _textStyle(
              fontSize: t.metaTextSize,
              color: t.mutedColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
        if (bullets.isNotEmpty) ...[
          pw.SizedBox(height: t.bulletSpacing + 1),
          for (final b in bullets)
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: t.bulletSpacing),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _isRtl ? '  •' : '•  ',
                    textDirection: td,
                    style: _textStyle(
                      fontSize: t.baseTextSize,
                      color: t.mutedColor,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      b,
                      textDirection: td,
                      style: _textStyle(
                        fontSize: t.baseTextSize,
                        color: t.bodyColor,
                        lineSpacing: t.baseTextSize * 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else if (e.description.isNotEmpty) ...[
          pw.SizedBox(height: t.bulletSpacing + 1),
          pw.Text(
            e.description,
            textDirection: td,
            style: _textStyle(
              fontSize: t.baseTextSize,
              color: t.bodyColor,
              lineSpacing: t.baseTextSize * 0.45,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _pdfProjects(CvContent c, CvTemplate t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('PROJECTS', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (int i = 0; i < c.projects.length; i++) ...[
          _pdfProjectItem(c.projects[i], t),
          if (i < c.projects.length - 1) pw.SizedBox(height: t.itemSpacing),
        ],
      ],
    );
  }

  static pw.Widget _pdfProjectItem(CvProject p, CvTemplate t) {
    final bullets = p.effectiveBullets;
    final links = p.effectiveLinks;
    final titleLine = [
      if (p.role.isNotEmpty) '${p.role} — ${p.name}',
      if (p.role.isEmpty) p.name,
    ].join();
    final techLine = p.tech.isNotEmpty ? '  |  ${p.tech.join(', ')}' : '';
    final td = _isRtl ? pw.TextDirection.rtl : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                '$titleLine$techLine',
                textDirection: td,
                style: _textStyle(
                  fontSize: t.baseTextSize,
                  color: t.bodyColor,
                ),
              ),
            ),
            if (links.isNotEmpty)
              pw.Text(
                links.join(' | '),
                textDirection: td,
                style: _textStyle(
                  fontSize: t.metaTextSize,
                  color: t.accent,
                ),
              ),
          ],
        ),
        if (bullets.isNotEmpty) ...[
          pw.SizedBox(height: t.bulletSpacing + 1),
          for (final b in bullets)
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: t.bulletSpacing),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _isRtl ? '  •' : '•  ',
                    textDirection: td,
                    style: _textStyle(
                      fontSize: t.baseTextSize,
                      color: t.mutedColor,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      b,
                      textDirection: td,
                      style: _textStyle(
                        fontSize: t.baseTextSize,
                        color: t.bodyColor,
                        lineSpacing: t.baseTextSize * 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else if (p.description.isNotEmpty) ...[
          pw.SizedBox(height: t.bulletSpacing + 1),
          pw.Text(
            p.description,
            textDirection: td,
            style: _textStyle(
              fontSize: t.baseTextSize,
              color: t.bodyColor,
              lineSpacing: t.baseTextSize * 0.45,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _pdfEducation(CvContent c, CvTemplate t) {
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('EDUCATION', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (final e in c.education)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                [e.degree, e.field].where((s) => s.isNotEmpty).join(' in '),
                textDirection: td,
                style: _textStyle(
                  fontSize: t.baseTextSize,
                  fontWeight: pw.FontWeight.bold,
                  color: t.bodyColor,
                ),
              ),
              pw.Text(
                [e.institution, e.year].where((s) => s.isNotEmpty).join('  •  '),
                textDirection: td,
                style: _textStyle(
                  fontSize: t.metaTextSize,
                  color: t.accent,
                ),
              ),
              pw.SizedBox(height: t.itemSpacing),
            ],
          ),
      ],
    );
  }

  static pw.Widget _pdfSkills(CvContent c, CvTemplate t) {
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('SKILLS', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (int i = 0; i < c.skillGroups.length; i++) ...[
          pw.Text(
            '${c.skillGroups[i].title}:  ${c.skillGroups[i].skills.join(' / ')}',
            textDirection: td,
            style: _textStyle(
              fontSize: t.baseTextSize,
              color: t.bodyColor,
            ),
          ),
          if (i < c.skillGroups.length - 1)
            pw.SizedBox(height: t.bulletSpacing + 1),
        ],
      ],
    );
  }

  static pw.Widget _pdfCertifications(CvContent c, CvTemplate t) {
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('CERTIFICATIONS', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (final cert in c.certifications)
          pw.Text(
            cert.display,
            textDirection: td,
            style: _textStyle(
              fontSize: t.baseTextSize,
              color: t.bodyColor,
            ),
          ),
      ],
    );
  }

  static pw.Widget _pdfAchievements(CvContent c, CvTemplate t) {
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('ACHIEVEMENTS', t),
        pw.SizedBox(height: t.spacing * 0.3),
        for (final a in c.achievements)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _isRtl ? '  •' : '•  ',
                textDirection: td,
                style: _textStyle(
                  fontSize: t.baseTextSize,
                  color: t.mutedColor,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  a.text,
                  textDirection: td,
                  style: _textStyle(
                    fontSize: t.baseTextSize,
                    color: t.bodyColor,
                    lineSpacing: t.baseTextSize * 0.45,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _pdfLanguages(CvContent c, CvTemplate t) {
    final td = _isRtl ? pw.TextDirection.rtl : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfSectionTitle('LANGUAGES', t),
        pw.SizedBox(height: t.spacing * 0.3),
        pw.Text(
          c.languages.map((l) => l.display).join('  •  '),
          textDirection: td,
          style: _textStyle(
            fontSize: t.baseTextSize,
            color: t.bodyColor,
          ),
        ),
      ],
    );
  }

  static PdfColor _pdfColor(Color c) => PdfColor(c.r / 255, c.g / 255, c.b / 255);

  static pw.TextStyle _textStyle({
    required double fontSize,
    required Color color,
    pw.FontWeight? fontWeight,
    double? lineSpacing,
    pw.FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      color: _pdfColor(color),
      fontWeight: fontWeight,
      lineSpacing: lineSpacing,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      fontFallback: _arabicFont != null ? <pw.Font>[_arabicFont!] : const <pw.Font>[],
    );
  }
}
