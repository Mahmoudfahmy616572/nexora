import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../../core/platform/file_io.dart';
import '../../../../domain/cv/cv_pdf_renderer.dart';
import '../../../../domain/entities/career_dna.dart' show CareerStage;
import '../../../../domain/entities/career_target.dart' show TargetType;
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
  ].join('  •  ');
  if (contact.isNotEmpty) buffer.writeln(contact);
  if (h.links.isNotEmpty) {
    buffer.writeln(h.links.map((l) => l.label).join('  •  '));
  }
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
      for (final b in e.effectiveBullets) {
        buffer.writeln('  • $b');
      }
    }
  }
  if (content.projects.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('PROJECTS');
    for (final p in content.projects) {
      final tech = p.tech.isNotEmpty ? ' | ${p.tech.join(", ")}' : '';
      final role = p.role.isNotEmpty ? '${p.role} — ' : '';
      final links = p.effectiveLinks;
      final linksStr = links.isNotEmpty ? ' | ${links.join(' | ')}' : '';
      buffer.writeln('- $role${p.name}$tech$linksStr');
      for (final b in p.effectiveBullets) {
        buffer.writeln('  • $b');
      }
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

/// Export sheet: copy as plain text, generate PDF, save/share PDF.
class CvExportSheet extends StatelessWidget {
  const CvExportSheet({
    required this.content,
    required this.templateId,
    this.stage,
    this.targetType,
    super.key,
  });

  final CvContent content;
  final String templateId;

  /// Drives the same target-aware section ordering as the on-screen preview.
  final CareerStage? stage;
  final TargetType? targetType;

  Future<Uint8List> _renderPdf() => CvPdfRenderer.render(
        content: content,
        templateId: templateId,
        stage: stage,
        targetType: targetType,
      );

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
          const SizedBox(height: 8),
          ElevatedButton.icon(
            key: const Key('cvPdfPreview'),
            onPressed: () async {
              try {
                final bytes = await _renderPdf();
                if (context.mounted) {
                  await Printing.layoutPdf(
                    onLayout: (_) => bytes,
                    name: '${content.header.name}_CV',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF preview failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.preview),
            label: const Text('Preview PDF'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            key: const Key('cvPdfSave'),
            onPressed: () async {
              try {
                final bytes = await _renderPdf();
                final name = content.header.name.replaceAll(' ', '_');
                if (kIsWeb) {
                  await Printing.layoutPdf(
                    onLayout: (_) => bytes,
                    name: '${name}_CV',
                  );
                } else {
                  await _savePdfNative(bytes, name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF saved')),
                    );
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF save failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save PDF'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            key: const Key('cvPdfShare'),
            onPressed: () async {
              try {
                final bytes = await _renderPdf();
                final name = content.header.name.replaceAll(' ', '_');
                await Printing.sharePdf(bytes: bytes, filename: '${name}_CV.pdf');
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF share failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePdfNative(List<int> bytes, String name) async {
    final dir = await getDocumentsPath();
    await writeBytesToFile('$dir/${name}_CV.pdf', bytes);
  }
}
