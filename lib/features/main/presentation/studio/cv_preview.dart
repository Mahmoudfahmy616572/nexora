import 'package:flutter/material.dart';

import '../../../../domain/cv/cv_section_ordering.dart';
import '../../../../domain/cv/cv_template_registry.dart';
import '../../../../domain/entities/career_dna.dart';
import '../../../../domain/entities/career_target.dart';
import '../../../../domain/entities/cv_content.dart';
import 'link_launcher.dart';

/// Renders structured [CvContent] into a printable CV using the selected
/// template. The template changes only styling/priority — never the content.
///
/// Supports: structured bullets, grouped skills, target-aware section ordering,
/// multi-page content flow, RTL, and A4-appropriate layout.
class CvPreview extends StatelessWidget {
  const CvPreview({
    required this.content,
    required this.templateId,
    this.stage,
    this.targetType,
    super.key,
  });

  final CvContent content;
  final String templateId;

  /// Drives the same target-aware section ordering as PDF export.
  final CareerStage? stage;
  final TargetType? targetType;

  @override
  Widget build(BuildContext context) {
    final template = CvTemplateRegistry.get(templateId);
    final sections = CvSectionOrdering.orderedSectionsForStages(
      content: content,
      stage: stage,
      targetType: targetType,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 794 ? constraints.maxWidth : 794.0;
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(template.radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: _CvBody(
              content: content,
              template: template,
              sections: sections,
            ),
          ),
        );
      },
    );
  }
}

/// The main CV body — renders header + all sections with proper typography.
class _CvBody extends StatelessWidget {
  const _CvBody({
    required this.content,
    required this.template,
    required this.sections,
  });

  final CvContent content;
  final CvTemplate template;
  final List<CvSection> sections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: template.marginHorizontal,
        vertical: template.marginVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(content: content, template: template),
          for (final section in sections) ...[
            SizedBox(height: template.sectionSpacing),
            _SectionDivider(template: template),
            SizedBox(height: template.spacing * 0.4),
            _buildSection(section),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(CvSection section) {
    switch (section) {
      case CvSection.summary:
        return _SummarySection(content: content, template: template);
      case CvSection.experience:
        return _ExperienceSection(content: content, template: template);
      case CvSection.projects:
        return _ProjectsSection(content: content, template: template);
      case CvSection.education:
        return _EducationSection(content: content, template: template);
      case CvSection.skills:
        return _SkillsSection(content: content, template: template);
      case CvSection.certifications:
        return _CertificationsSection(content: content, template: template);
      case CvSection.achievements:
        return _AchievementsSection(content: content, template: template);
      case CvSection.languages:
        return _LanguagesSection(content: content, template: template);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Divider
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.template});
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    if (!template.showSectionDivider) return const SizedBox.shrink();
    return Container(
      height: 0.5,
      color: template.dividerColor,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.template});
  final String title;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: template.sectionTitleSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: template.accent,
        fontFamily: template.fontFamily,
        height: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final h = content.header;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name ──
        if (h.name.isNotEmpty)
          Text(
            h.name,
            style: TextStyle(
              fontSize: template.headerNameSize,
              fontWeight: FontWeight.w800,
              color: template.bodyColor,
              fontFamily: template.fontFamily,
              height: 1.15,
            ),
            textDirection: TextDirection.ltr,
          ),

        // ── Title / Role ──
        if (h.title.isNotEmpty) ...[
          SizedBox(height: template.spacing * 0.2),
          Text(
            h.title,
            style: TextStyle(
              fontSize: template.baseTextSize + 1.5,
              fontWeight: FontWeight.w600,
              color: template.accent,
              fontFamily: template.fontFamily,
              height: 1.3,
            ),
          ),
        ],

        // ── Subtitle ──
        if (h.subtitle.isNotEmpty && h.subtitle != h.title) ...[
          SizedBox(height: 1),
          Text(
            h.subtitle,
            style: TextStyle(
              fontSize: template.metaTextSize,
              color: template.mutedColor,
              fontFamily: template.fontFamily,
              height: 1.3,
            ),
          ),
        ],

        // ── Contact Row ──
        _ContactRow(template: template, header: h, isRtl: isRtl),

        // ── Links ──
        if (h.links.isNotEmpty) ...[
          SizedBox(height: template.spacing * 0.15),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < h.links.length; i++) ...[
                if (i > 0)
                  Text(
                    '·',
                    style: TextStyle(
                      fontSize: template.metaTextSize,
                      color: template.mutedColor,
                      fontFamily: template.fontFamily,
                      height: 1.3,
                    ),
                  ),
                GestureDetector(
                  onTap: h.links[i].url.trim().isNotEmpty
                      ? () => LinkLauncher.open(h.links[i].url.trim())
                      : null,
                  child: Text(
                    h.links[i].label.isNotEmpty
                        ? h.links[i].label
                        : h.links[i].url,
                    style: TextStyle(
                      fontSize: template.metaTextSize,
                      color: template.accent,
                      fontFamily: template.fontFamily,
                      decoration: TextDecoration.underline,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.template,
    required this.header,
    required this.isRtl,
  });
  final CvTemplate template;
  final CvHeader header;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final items = <_ContactItem>[];
    if (header.email.isNotEmpty) {
      items.add(_ContactItem(icon: Icons.email_outlined, text: header.email));
    }
    if (header.phone.isNotEmpty) {
      items.add(_ContactItem(icon: Icons.phone_outlined, text: header.phone));
    }
    if (header.location.isNotEmpty) {
      items.add(_ContactItem(icon: Icons.location_on_outlined, text: header.location));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: template.spacing * 0.25),
      child: Wrap(
        spacing: template.spacing * 0.6,
        runSpacing: 2,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: template.metaTextSize + 1, color: template.mutedColor),
                SizedBox(width: 3),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: template.metaTextSize,
                    color: template.mutedColor,
                    fontFamily: template.fontFamily,
                    height: 1.3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ContactItem {
  const _ContactItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Section
// ─────────────────────────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'PROFILE', template: template),
        SizedBox(height: template.spacing * 0.3),
        Text(
          content.summary,
          style: TextStyle(
            fontSize: template.baseTextSize,
            color: template.bodyColor,
            fontFamily: template.fontFamily,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Experience Section
// ─────────────────────────────────────────────────────────────────────────────

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'EXPERIENCE', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (int i = 0; i < content.experience.length; i++) ...[
          _ExperienceItem(item: content.experience[i], template: template),
          if (i < content.experience.length - 1)
            SizedBox(height: template.itemSpacing),
        ],
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  const _ExperienceItem({required this.item, required this.template});
  final CvExperience item;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final bullets = item.effectiveBullets;
    final dateStr = _formatDateRange(item.startDate, item.endDate, item.durationLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Role — Company ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.company.isNotEmpty ? '${item.role} — ${item.company}' : item.role,
                style: TextStyle(
                  fontSize: template.baseTextSize,
                  fontWeight: FontWeight.w700,
                  color: template.bodyColor,
                  fontFamily: template.fontFamily,
                  height: 1.3,
                ),
              ),
            ),
            if (dateStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: template.metaTextSize,
                    color: template.mutedColor,
                    fontFamily: template.fontFamily,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),

        // ── Location ──
        if (item.location.isNotEmpty) ...[
          SizedBox(height: 1),
          Text(
            item.location,
            style: TextStyle(
              fontSize: template.metaTextSize,
              color: template.mutedColor,
              fontStyle: FontStyle.italic,
              fontFamily: template.fontFamily,
              height: 1.3,
            ),
          ),
        ],

        // ── Bullets ──
        if (bullets.isNotEmpty) ...[
          SizedBox(height: template.bulletSpacing + 1),
          for (final b in bullets)
            Padding(
              padding: EdgeInsets.only(bottom: template.bulletSpacing, left: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      fontSize: template.baseTextSize,
                      color: template.mutedColor,
                      fontFamily: template.fontFamily,
                      height: 1.45,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: template.baseTextSize,
                        color: template.bodyColor,
                        fontFamily: template.fontFamily,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else if (item.description.isNotEmpty) ...[
          SizedBox(height: template.bulletSpacing + 1),
          Text(
            item.description,
            style: TextStyle(
              fontSize: template.baseTextSize,
              color: template.bodyColor,
              fontFamily: template.fontFamily,
              height: 1.45,
            ),
          ),
        ],

        // ── Per-experience achievements ──
        if (item.achievements.isNotEmpty) ...[
          SizedBox(height: template.bulletSpacing + 1),
          for (final ach in item.achievements)
            Padding(
              padding: EdgeInsets.only(bottom: template.bulletSpacing, left: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events_outlined, size: template.metaTextSize, color: template.mutedColor),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ach,
                      style: TextStyle(
                        fontSize: template.metaTextSize,
                        color: template.bodyColor,
                        fontFamily: template.fontFamily,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Projects Section
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'PROJECTS', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (int i = 0; i < content.projects.length; i++) ...[
          _ProjectItem(item: content.projects[i], template: template),
          if (i < content.projects.length - 1)
            SizedBox(height: template.itemSpacing),
        ],
      ],
    );
  }
}

class _ProjectItem extends StatelessWidget {
  const _ProjectItem({required this.item, required this.template});
  final CvProject item;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final bullets = item.effectiveBullets;
    final links = item.links;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name + Tech + Links ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    if (item.role.isNotEmpty)
                      TextSpan(
                        text: '${item.role} — ',
                        style: TextStyle(
                          fontSize: template.baseTextSize,
                          fontWeight: FontWeight.w600,
                          color: template.bodyColor,
                          fontFamily: template.fontFamily,
                          height: 1.3,
                        ),
                      ),
                    TextSpan(
                      text: item.name,
                      style: TextStyle(
                        fontSize: template.baseTextSize,
                        fontWeight: FontWeight.w700,
                        color: template.bodyColor,
                        fontFamily: template.fontFamily,
                        height: 1.3,
                      ),
                    ),
                    if (item.tech.isNotEmpty)
                      TextSpan(
                        text: '  |  ${item.tech.join(', ')}',
                        style: TextStyle(
                          fontSize: template.metaTextSize,
                          fontWeight: FontWeight.w400,
                          color: template.mutedColor,
                          fontFamily: template.fontFamily,
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < links.length; i++) ...[
                      if (i > 0)
                        Text(
                          '·',
                          style: TextStyle(
                            fontSize: template.metaTextSize,
                            color: template.mutedColor,
                            fontFamily: template.fontFamily,
                            height: 1.3,
                          ),
                        ),
                      GestureDetector(
                        onTap: () => LinkLauncher.open(links[i].url),
                        child: Text(
                          links[i].label.isNotEmpty
                              ? links[i].label
                              : links[i].url,
                          style: TextStyle(
                            fontSize: template.metaTextSize,
                            color: template.accent,
                            fontFamily: template.fontFamily,
                            decoration: TextDecoration.underline,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),

        // ── Bullets ──
        if (bullets.isNotEmpty) ...[
          SizedBox(height: template.bulletSpacing + 1),
          for (final b in bullets)
            Padding(
              padding: EdgeInsets.only(bottom: template.bulletSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      fontSize: template.baseTextSize,
                      color: template.mutedColor,
                      fontFamily: template.fontFamily,
                      height: 1.45,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: template.baseTextSize,
                        color: template.bodyColor,
                        fontFamily: template.fontFamily,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else if (item.description.isNotEmpty) ...[
          SizedBox(height: template.bulletSpacing + 1),
          Text(
            item.description,
            style: TextStyle(
              fontSize: template.baseTextSize,
              color: template.bodyColor,
              fontFamily: template.fontFamily,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Education Section
// ─────────────────────────────────────────────────────────────────────────────

class _EducationSection extends StatelessWidget {
  const _EducationSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'EDUCATION', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (final e in content.education)
          _EducationItem(item: e, template: template),
      ],
    );
  }
}

class _EducationItem extends StatelessWidget {
  const _EducationItem({required this.item, required this.template});
  final CvEducation item;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final title = [
      if (item.degree.isNotEmpty) item.degree,
      if (item.field.isNotEmpty) item.field,
    ].join(' in ');
    final sub = [
      if (item.institution.isNotEmpty) item.institution,
      if (item.year.isNotEmpty) item.year,
    ].join('  •  ');

    return Padding(
      padding: EdgeInsets.only(bottom: template.itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: template.baseTextSize,
                fontWeight: FontWeight.w700,
                color: template.bodyColor,
                fontFamily: template.fontFamily,
                height: 1.3,
              ),
            ),
          if (sub.isNotEmpty)
            Text(
              sub,
              style: TextStyle(
                fontSize: template.metaTextSize,
                color: template.accent,
                fontFamily: template.fontFamily,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skills Section — Grouped by category
// ─────────────────────────────────────────────────────────────────────────────

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'SKILLS', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (final g in content.skillGroups) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${g.title}:  ',
                style: TextStyle(
                  fontSize: template.baseTextSize,
                  fontWeight: FontWeight.w600,
                  color: template.bodyColor,
                  fontFamily: template.fontFamily,
                  height: 1.4,
                ),
              ),
              Expanded(
                child: Text(
                  g.skills.join(' / '),
                  style: TextStyle(
                    fontSize: template.baseTextSize,
                    color: template.bodyColor,
                    fontFamily: template.fontFamily,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (content.skillGroups.indexOf(g) < content.skillGroups.length - 1)
            SizedBox(height: template.bulletSpacing + 1),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Certifications Section
// ─────────────────────────────────────────────────────────────────────────────

class _CertificationsSection extends StatelessWidget {
  const _CertificationsSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'CERTIFICATIONS', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (final c in content.certifications)
          Padding(
            padding: EdgeInsets.only(bottom: template.bulletSpacing),
            child: GestureDetector(
              onTap: c.link.trim().isNotEmpty
                  ? () => LinkLauncher.open(c.link.trim())
                  : null,
              child: Text(
                c.display,
                style: TextStyle(
                  fontSize: template.baseTextSize,
                  color: c.link.trim().isNotEmpty
                      ? template.accent
                      : template.bodyColor,
                  fontFamily: template.fontFamily,
                  height: 1.4,
                  decoration: c.link.trim().isNotEmpty
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievements Section
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'ACHIEVEMENTS', template: template),
        SizedBox(height: template.spacing * 0.3),
        for (final a in content.achievements)
          Padding(
            padding: EdgeInsets.only(bottom: template.bulletSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    fontSize: template.baseTextSize,
                    color: template.mutedColor,
                    fontFamily: template.fontFamily,
                    height: 1.45,
                  ),
                ),
                Expanded(
                  child: Text(
                    a.text,
                    style: TextStyle(
                      fontSize: template.baseTextSize,
                      color: template.bodyColor,
                      fontFamily: template.fontFamily,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Languages Section
// ─────────────────────────────────────────────────────────────────────────────

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({required this.content, required this.template});
  final CvContent content;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'LANGUAGES', template: template),
        SizedBox(height: template.spacing * 0.3),
        Text(
          content.languages.map((l) => l.display).join('  •  '),
          style: TextStyle(
            fontSize: template.baseTextSize,
            color: template.bodyColor,
            fontFamily: template.fontFamily,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatDateRange(String start, String end, String yearsLabel) {
  final parts = <String>[];
  if (start.isNotEmpty) parts.add(start);
  if (end.isNotEmpty) parts.add(end);
  if (parts.isEmpty && yearsLabel.isNotEmpty) parts.add(yearsLabel);
  return parts.join(' – ');
}
