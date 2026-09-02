import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/intake_question.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom-sheet editor for a simple list of strings (skills, certifications,
/// achievements, languages, etc.). Returns the edited list or `null` if cancelled.
Future<List<String>?> showStringListSheet(
  BuildContext context, {
  required String title,
  required List<String> items,
  String? hint,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardHi,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _StringListSheet(
      title: title,
      items: items,
      hint: hint ?? '',
    ),
  );
}

/// Stateful bottom sheet for editing a list of strings. Owns the text field
/// controller inside [State.initState] and disposes it in [State.dispose], which
/// runs after the sheet's exit animation completes — avoiding the "used after
/// being disposed" crash.
class _StringListSheet extends StatefulWidget {
  const _StringListSheet({
    required this.title,
    required this.items,
    required this.hint,
  });

  final String title;
  final List<String> items;
  final String hint;

  @override
  State<_StringListSheet> createState() => _StringListSheetState();
}

class _StringListSheetState extends State<_StringListSheet> {
  final TextEditingController _controller = TextEditingController();
  late final List<String> _current = [...widget.items];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _current.add(text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTextStyles.cardTitle),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SheetField(controller: _controller, hint: widget.hint),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.violet.withValues(alpha: 0.45)),
                    ),
                    child: Center(
                      child: Text(l10n.addLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.violet)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_current.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _current)
                    Chip(
                      backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                      side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                      label: Text(item, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textSub),
                      onDeleted: () => setState(() => _current.remove(item)),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_current),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet editor for a structured list (education / experience / projects).
/// Returns the edited list of maps or `null` if cancelled.
Future<List<Map<String, String>>?> showStructListSheet(
  BuildContext context, {
  required String title,
  required List<ListField> schema,
  required List<Map<String, String>> items,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final current = [for (final i in items) {...i}];
  final result = await showModalBottomSheet<List<Map<String, String>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardHi,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(title, style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            for (var i = 0; i < current.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in schema) ...[
                      if (field.inputType == IntakeInputType.links)
                        LinksEditor(
                          initial: current[i][field.name] ?? '',
                          hint: field.label(l10n),
                          onChanged: (v) => current[i] = {...current[i], field.name: v},
                        )
                      else
                        _SheetField(
                          initial: current[i][field.name] ?? '',
                          hint: field.label(l10n),
                          onChanged: (v) => current[i] = {...current[i], field.name: v},
                        ),
                      const SizedBox(height: 8),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => setSheet(() => current.removeAt(i)),
                        child: Text(l10n.dnaEdit, style: const TextStyle(color: AppColors.textSub)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: () => setSheet(() => current.add({for (final f in schema) f.name: ''})),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
                ),
                alignment: Alignment.center,
                child: Text(l10n.addLabel, style: const TextStyle(color: AppColors.violet, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(current),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
  return result;
}

class _SheetField extends StatefulWidget {
  const _SheetField({this.controller, this.initial, this.hint, this.onChanged});

  final TextEditingController? controller;
  final String? initial;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController(text: widget.initial ?? '');

  @override
  void initState() {
    super.initState();
    if (widget.onChanged != null) {
      _ctrl.addListener(() => widget.onChanged!(_ctrl.text));
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: _ctrl,
        cursorColor: AppColors.violet,
        style: const TextStyle(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: AppTextStyles.bodySub,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

/// Editor for a project's list of (label, url) links. The value is serialised
/// as a JSON string (a `List<Map<String, String>>`) into the parent sheet map.
class LinksEditor extends StatefulWidget {
  const LinksEditor({super.key, this.initial = '', this.hint = '', this.onChanged});

  final String initial;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<LinksEditor> createState() => LinksEditorState();
}

class LinksEditorState extends State<LinksEditor> {
  late List<TextEditingController> _urlCtrls;
  late List<TextEditingController> _labelCtrls;

  @override
  void initState() {
    super.initState();
    final rows = _decode(widget.initial);
    _urlCtrls = [for (final r in rows) TextEditingController(text: r.url)];
    _labelCtrls = [for (final r in rows) TextEditingController(text: r.label)];
  }

  List<_LinkRow> _decode(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final rows = <_LinkRow>[];
      for (final e in decoded) {
        if (e is Map) {
          rows.add(
            _LinkRow(
              url: (e['url'] as String?) ?? '',
              label: (e['label'] as String?) ?? '',
            ),
          );
        }
      }
      return rows;
    } catch (_) {
      return const [];
    }
  }

  void _emit() => widget.onChanged?.call(jsonEncode([
        for (var i = 0; i < _urlCtrls.length; i++)
          {'label': _labelCtrls[i].text, 'url': _urlCtrls[i].text},
      ]));

  void _add() => setState(() {
        _urlCtrls.add(TextEditingController());
        _labelCtrls.add(TextEditingController());
        _emit();
      });

  void _remove(int i) => setState(() {
        _urlCtrls[i].dispose();
        _labelCtrls[i].dispose();
        _urlCtrls.removeAt(i);
        _labelCtrls.removeAt(i);
        _emit();
      });

  @override
  void dispose() {
    for (final c in _urlCtrls) {
      c.dispose();
    }
    for (final c in _labelCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<Widget> _linkRows() {
    final rows = <Widget>[];
    for (var i = 0; i < _urlCtrls.length; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrls[i],
                  onChanged: (_) => _emit(),
                  cursorColor: AppColors.violet,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'URL',
                    hintStyle: AppTextStyles.bodySub,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.borderViolet.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _labelCtrls[i],
                  onChanged: (_) => _emit(),
                  cursorColor: AppColors.violet,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Label (optional)',
                    hintStyle: AppTextStyles.bodySub,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.borderViolet.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _remove(i),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSub,
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.hint, style: AppTextStyles.bodySub),
        const SizedBox(height: 6),
        ..._linkRows(),
        OutlinedButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add link'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.violet,
            side: BorderSide(color: AppColors.violet.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _LinkRow {
  const _LinkRow({this.url = '', this.label = ''});
  final String url;
  final String label;
}
