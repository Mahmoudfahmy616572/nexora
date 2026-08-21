import 'package:flutter/material.dart';

import '../../../../../domain/entities/cv_evaluation.dart';
import '../../../../../l10n/app_localizations.dart';

class CvScoreBreakdown extends StatelessWidget {
  const CvScoreBreakdown({required this.evaluation, super.key});
  final CvEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = <(String, int)>[
      (l10n.cvScoreOverall, evaluation.overall),
      (l10n.cvScoreAts, evaluation.ats),
      (l10n.cvScoreTarget, evaluation.targetAlignment),
      (l10n.cvScoreContent, evaluation.contentStrength),
      (l10n.cvScoreEvidence, evaluation.evidenceStrength),
      (l10n.cvScoreReadability, evaluation.readability),
      (l10n.cvScoreClarity, evaluation.clarity),
      (l10n.cvScoreStructure, evaluation.structure),
      (l10n.cvScoreKeyword, evaluation.keywordAlignment),
      (l10n.cvScoreSkill, evaluation.skillAlignment),
      (l10n.cvScoreSection, evaluation.sectionCompleteness),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, score) in metrics)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 10,
                    color: _color(score),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  child: Text('$score',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _color(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
