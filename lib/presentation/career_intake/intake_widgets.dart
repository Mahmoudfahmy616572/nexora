import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Card grouping a labeled section of the intake form.
class IntakeSection extends StatelessWidget {
  const IntakeSection({
    super.key,
    required this.title,
    this.note,
    required this.children,
  });

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: AppTextStyles.bodySub.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// A single-line input with an "Add" button that appends to [items].
class StringAdder extends StatefulWidget {
  const StringAdder({
    super.key,
    required this.hint,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String hint;
  final List<String> items;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<StringAdder> createState() => _StringAdderState();
}

class _StringAdderState extends State<StringAdder> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _UnderlineField(controller: _controller, hint: widget.hint),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                widget.onAdd(text);
                _controller.clear();
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
                  child: Text(
                    AppLocalizations.of(context)!.addLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.violet,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.items)
                Chip(
                  backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                  side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                  label: Text(item, style: const TextStyle(color: AppColors.text, fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textSub),
                  onDeleted: () => widget.onRemove(item),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labeled text field used across the intake form.
class IntakeTextField extends StatelessWidget {
  const IntakeTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTextStyles.monoFont,
              fontSize: 11,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            cursorColor: AppColors.violet,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.bodySub,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.violet,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTextStyles.bodySub,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
