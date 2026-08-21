import 'package:flutter/material.dart';

import '../../../../domain/entities/cv_content.dart';
import '../../../../l10n/app_localizations.dart';

class CvEditSheet extends StatefulWidget {
  const CvEditSheet({required this.initial, required this.onSave, super.key});
  final CvContent initial;
  final ValueChanged<CvContent> onSave;

  @override
  State<CvEditSheet> createState() => _CvEditSheetState();
}

class _CvEditSheetState extends State<CvEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _summary;
  late final TextEditingController _skills;

  @override
  void initState() {
    super.initState();
    final h = widget.initial.header;
    _name = TextEditingController(text: h.name);
    _title = TextEditingController(text: h.title);
    _subtitle = TextEditingController(text: h.subtitle);
    _email = TextEditingController(text: h.email);
    _phone = TextEditingController(text: h.phone);
    _location = TextEditingController(text: h.location);
    _summary = TextEditingController(text: widget.initial.summary);
    final merged = widget.initial.skillGroups
        .expand((g) => g.skills)
        .toList();
    _skills = TextEditingController(text: merged.join(', '));
  }

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _subtitle.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _summary.dispose();
    _skills.dispose();
    super.dispose();
  }

  List<String> _parseSkills() => _skills.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.studioEdit, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _field(l10n.cvEditName, _name),
              _field(l10n.cvEditTitle, _title),
              _field(l10n.cvEditSubtitle, _subtitle),
              _field(l10n.cvEditEmail, _email),
              _field(l10n.cvEditPhone, _phone),
              _field(l10n.cvEditLocation, _location),
              _field(l10n.cvEditSummary, _summary, maxLines: 4),
              _field(l10n.cvEditSkills, _skills, maxLines: 3),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('cvEditSave'),
                onPressed: () {
                  final updated = widget.initial.copyWith(
                    header: widget.initial.header.copyWith(
                      name: _name.text.trim(),
                      title: _title.text.trim(),
                      subtitle: _subtitle.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim(),
                      location: _location.text.trim(),
                    ),
                    summary: _summary.text.trim(),
                    skillGroups: [
                      CvSkillGroup(title: l10n.cvFactualLabel, skills: _parseSkills()),
                    ],
                  );
                  widget.onSave(updated);
                  Navigator.pop(context);
                },
                child: Text(l10n.studioSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
