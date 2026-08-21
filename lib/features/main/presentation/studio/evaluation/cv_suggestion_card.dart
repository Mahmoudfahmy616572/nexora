import 'package:flutter/material.dart';

import '../../../../../domain/entities/cv_evaluation.dart';
import '../../../../../l10n/app_localizations.dart';

class CvSuggestionCard extends StatefulWidget {
  const CvSuggestionCard({
    required this.suggestion,
    required this.onAccept,
    required this.onAcceptEdit,
    required this.onReject,
    super.key,
  });
  final CvSuggestion suggestion;
  final void Function(CvSuggestion) onAccept;
  final void Function(CvSuggestion, String) onAcceptEdit;
  final void Function(CvSuggestion) onReject;

  @override
  State<CvSuggestionCard> createState() => _CvSuggestionCardState();
}

class _CvSuggestionCardState extends State<CvSuggestionCard> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.suggestion.suggested);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = widget.suggestion;

    if (s.status == CvSuggestionStatus.accepted) {
      return _banner(context, l10n, Colors.green.shade50, Colors.green.shade800,
          l10n.cvAppliedSuggestion);
    }
    if (s.status == CvSuggestionStatus.rejected) {
      return _banner(context, l10n, Colors.grey.shade100, Colors.grey.shade700,
          l10n.cvDismissSuggestion);
    }

    return Card(
      key: Key('cvSuggestion_${s.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.section.isNotEmpty)
              Chip(label: Text(s.section)),
            const SizedBox(height: 8),
            _row(l10n.cvSuggestionProblem, s.problem),
            const SizedBox(height: 8),
            if (s.current.isNotEmpty) _row(l10n.cvSuggestionCurrent, s.current),
            if (s.current.isNotEmpty) const SizedBox(height: 8),
            if (_editing)
              TextField(
                controller: _controller,
                key: const Key('suggestionEditField'),
                maxLines: 3,
                decoration:
                    InputDecoration(labelText: l10n.cvSuggestionSuggested),
              )
            else
              _row(l10n.cvSuggestionSuggested, s.suggested),
            const SizedBox(height: 8),
            if (s.why.isNotEmpty) _row(l10n.cvSuggestionWhy, s.why),
            if (s.targetRequirement.isNotEmpty) ...[
              const SizedBox(height: 8),
              _row(l10n.cvSuggestionTarget, s.targetRequirement),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('cvApplySuggestion'),
                  onPressed: () {
                    if (_editing) {
                      widget.onAcceptEdit(s, _controller.text.trim());
                    } else {
                      widget.onAccept(s);
                    }
                  },
                  child: Text(l10n.cvApplySuggestion),
                ),
                if (!_editing)
                  OutlinedButton.icon(
                    key: const Key('cvEditSuggestion'),
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.cvEditSuggestion),
                  ),
                if (_editing)
                  OutlinedButton(
                    key: const Key('cvCancelEdit'),
                    onPressed: () => setState(() => _editing = false),
                    child: Text(l10n.studioCancel),
                  ),
                TextButton(
                  key: const Key('cvDismissSuggestion'),
                  onPressed: () => widget.onReject(s),
                  child: Text(l10n.cvDismissSuggestion),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value),
        ],
      );

  Widget _banner(
    BuildContext context,
    AppLocalizations l10n,
    Color bg,
    Color fg,
    String text,
  ) =>
      Card(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: fg),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: TextStyle(color: fg))),
            ],
          ),
        ),
      );
}
