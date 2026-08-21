import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/cv_content.dart';
import '../../../../l10n/app_localizations.dart';

String cvToText(CvContent content) {
  final buffer = StringBuffer();
  final h = content.header;
  if (h.name.isNotEmpty) buffer.writeln(h.name);
  if (h.title.isNotEmpty) buffer.writeln(h.title);
  if (h.subtitle.isNotEmpty) buffer.writeln(h.subtitle);
  final contact = [
    if (h.email.isNotEmpty) h.email,
    if (h.phone.isNotEmpty) h.phone,
    if (h.location.isNotEmpty) h.location,
    ...h.links,
  ].join('  •  ');
  if (contact.isNotEmpty) buffer.writeln(contact);
  if (content.summary.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('SUMMARY');
    buffer.writeln(content.summary);
  }
  if (content.experience.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('EXPERIENCE');
    for (final e in content.experience) {
      buffer.writeln('- ${e.role} — ${e.company} ${e.yearsLabel}');
      if (e.description.isNotEmpty) buffer.writeln('  ${e.description}');
    }
  }
  if (content.projects.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('PROJECTS');
    for (final p in content.projects) {
      final tech = p.tech.isNotEmpty ? ' (${p.tech.join(", ")})' : '';
      buffer.writeln('- ${p.name}$tech');
      if (p.description.isNotEmpty) buffer.writeln('  ${p.description}');
    }
  }
  if (content.education.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('EDUCATION');
    for (final e in content.education) {
      final title = [if (e.degree.isNotEmpty) e.degree, if (e.field.isNotEmpty) e.field].join(' ');
      final sub = [if (e.institution.isNotEmpty) e.institution, if (e.year.isNotEmpty) e.year].join('  •  ');
      buffer.writeln('- $title${sub.isNotEmpty ? ' — $sub' : ''}');
    }
  }
  if (content.skillGroups.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('SKILLS');
    for (final g in content.skillGroups) {
      buffer.writeln('${g.title}: ${g.skills.join(", ")}');
    }
  }
  if (content.certifications.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('CERTIFICATIONS');
    for (final c in content.certifications) {
      buffer.writeln('- ${c.display}');
    }
  }
  if (content.achievements.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('ACHIEVEMENTS');
    for (final a in content.achievements) {
      buffer.writeln('- ${a.text}');
    }
  }
  if (content.languages.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('LANGUAGES');
    buffer.writeln(content.languages.map((l) => l.display).join(' · '));
  }
  return buffer.toString().trim();
}

/// Lightweight export: copy the structured CV as plain text. PDF/print is
/// intentionally omitted because no export dependency is available.
class CvExportSheet extends StatelessWidget {
  const CvExportSheet({required this.content, super.key});
  final CvContent content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = cvToText(content);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.cvExportText, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(child: Text(text)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('cvCopy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.cvCopy)),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.cvCopy),
          ),
        ],
      ),
    );
  }
}
