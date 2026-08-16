import 'package:flutter/material.dart';

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
}) async {
  final l10n = AppLocalizations.of(context)!;
  final current = [...items];
  final controller = TextEditingController();
  final result = await showModalBottomSheet<List<String>>(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.cardTitle),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SheetField(controller: controller, hint: hint ?? ''),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    setSheet(() {
                      current.add(text);
                      controller.clear();
                    });
                  },
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
            if (current.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in current)
                    Chip(
                      backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                      side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                      label: Text(item, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textSub),
                      onDeleted: () => setSheet(() => current.remove(item)),
                    ),
                ],
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
  );
  return result;
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
