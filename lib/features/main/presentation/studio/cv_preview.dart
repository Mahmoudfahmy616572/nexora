import 'package:flutter/material.dart';

import '../../../../domain/cv/cv_template_registry.dart';
import '../../../../domain/entities/cv_content.dart';

/// Renders structured [CvContent] into a printable CV using the selected
/// template. The template changes only styling/priority — never the content.
class CvPreview extends StatelessWidget {
  const CvPreview({
    required this.content,
    required this.templateId,
    super.key,
  });

  final CvContent content;
  final String templateId;

  @override
  Widget build(BuildContext context) {
    final template = CvTemplateRegistry.get(templateId);
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme;
    final accent = template.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 794 ? constraints.maxWidth : 794.0;
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(template.radius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  content: content,
                  template: template,
                  accent: accent,
                  textTheme: headerStyle,
                ),
                if (content.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'SUMMARY', accent: accent),
                  const SizedBox(height: 4),
                  Text(
                    content.summary,
                    style: headerStyle.bodyMedium,
                    softWrap: true,
                  ),
                ],
                if (content.experience.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'EXPERIENCE', accent: accent),
                  const SizedBox(height: 4),
                  for (final e in content.experience) ...[
                    _ExperienceItem(item: e, template: template),
                    const SizedBox(height: 8),
                  ],
                ],
                if (content.projects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'PROJECTS', accent: accent),
                  const SizedBox(height: 4),
                  for (final p in content.projects) ...[
                    _ProjectItem(item: p, template: template),
                    const SizedBox(height: 8),
                  ],
                ],
                if (content.education.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'EDUCATION', accent: accent),
                  const SizedBox(height: 4),
                  for (final e in content.education)
                    _EducationItem(item: e, accent: accent),
                ],
                if (content.skillGroups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'SKILLS', accent: accent),
                  const SizedBox(height: 4),
                  for (final g in content.skillGroups) ...[
                    Text(
                      g.title,
                      style: headerStyle.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final s in g.skills)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(s),
                            backgroundColor: accent.withValues(alpha: 0.12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
                if (content.certifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'CERTIFICATIONS', accent: accent),
                  const SizedBox(height: 4),
                  for (final c in content.certifications)
                    Text(
                      c.display,
                      style: headerStyle.bodyMedium,
                      softWrap: true,
                    ),
                ],
                if (content.achievements.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'ACHIEVEMENTS', accent: accent),
                  const SizedBox(height: 4),
                  for (final a in content.achievements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• ${a.text}',
                        style: headerStyle.bodyMedium,
                        softWrap: true,
                      ),
                    ),
                ],
                if (content.languages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'LANGUAGES', accent: accent),
                  const SizedBox(height: 4),
                  Text(
                    content.languages.map((l) => l.display).join(' · '),
                    style: headerStyle.bodyMedium,
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.content,
    required this.template,
    required this.accent,
    required this.textTheme,
  });
  final CvContent content;
  final CvTemplate template;
  final Color accent;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final h = content.header;
    final contact = [
      if (h.email.isNotEmpty) h.email,
      if (h.phone.isNotEmpty) h.phone,
      if (h.location.isNotEmpty) h.location,
    ].join('  •  ');
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (h.name.isNotEmpty)
          Text(
            h.name,
            style: textTheme.titleLarge?.copyWith(
              fontSize: template.headerNameSize,
              fontWeight: FontWeight.w800,
            ),
            softWrap: true,
          ),
        if (h.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              h.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
              softWrap: true,
            ),
          ),
        if (h.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              h.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              softWrap: true,
            ),
          ),
        if (contact.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(contact, style: Theme.of(context).textTheme.bodySmall),
          ),
        if (h.links.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              h.links.join('  •  '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
    if (template.showHeaderBar) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }
    return child;
  }
}

class _ExperienceItem extends StatelessWidget {
  const _ExperienceItem({required this.item, required this.template});
  final CvExperience item;
  final CvTemplate template;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.role} — ${item.company}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                softWrap: true,
              ),
            ),
            if (item.yearsLabel.isNotEmpty)
              Text(item.yearsLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: template.accent)),
          ],
        ),
        if (item.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall,
              softWrap: true,
            ),
          ),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.tech.isNotEmpty
                    ? '${item.name} (${item.tech.join(", ")})'
                    : item.name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                softWrap: true,
              ),
            ),
            if (item.link.isNotEmpty)
              Text(item.link,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: template.accent)),
          ],
        ),
        if (item.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall,
              softWrap: true,
            ),
          ),
      ],
    );
  }
}

class _EducationItem extends StatelessWidget {
  const _EducationItem({required this.item, required this.accent});
  final CvEducation item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = [
      if (item.degree.isNotEmpty) item.degree,
      if (item.field.isNotEmpty) item.field,
    ].join(' ');
    final sub = [
      if (item.institution.isNotEmpty) item.institution,
      if (item.year.isNotEmpty) item.year,
    ].join('  •  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                softWrap: true),
          if (sub.isNotEmpty)
            Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: accent)),
        ],
      ),
    );
  }
}
