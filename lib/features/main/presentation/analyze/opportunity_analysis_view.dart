import 'package:flutter/material.dart';

import '../../../../domain/entities/opportunity_analysis.dart';
import '../../../../l10n/app_localizations.dart';

/// Renders the full, explainable [OpportunityAnalysis] produced by the
/// deterministic [OpportunityMatchEngine]. Every score and every requirement is
/// shown with its supporting evidence so the user can trust the result.
class OpportunityAnalysisView extends StatelessWidget {
  const OpportunityAnalysisView({super.key, required this.analysis});

  final OpportunityAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final category = analysis.recommendationCategory;
    final categoryColor = switch (category) {
      MatchCategory.strong => Colors.green,
      MatchCategory.good => Colors.teal,
      MatchCategory.moderate => Colors.amber,
      MatchCategory.weak => Colors.red,
    };
    final categoryLabel = switch (category) {
      MatchCategory.strong => l10n.analyzeCatStrong,
      MatchCategory.good => l10n.analyzeCatGood,
      MatchCategory.moderate => l10n.analyzeCatModerate,
      MatchCategory.weak => l10n.analyzeCatWeak,
    };

    // Experience/education are resolved as their own requirements; fold them
    // into the matching category sections so explicit gaps are always visible.
    final exp = analysis.experienceItem;
    final edu = analysis.educationItem;
    List<JobRequirement> mergeFor(RequirementStatus s, List<JobRequirement> base) {
      final extra = <JobRequirement>[];
      if (exp?.status == s) extra.add(exp!);
      if (edu?.status == s) extra.add(edu!);
      return [...base, ...extra];
    }

    final strongList = mergeFor(RequirementStatus.strongMatch, analysis.strongMatches);
    final partialList = mergeFor(RequirementStatus.partialMatch, analysis.partialMatches);
    final mismatchList = mergeFor(RequirementStatus.requirementMismatch, analysis.requirementMismatches);
    final notEvidencedList = mergeFor(RequirementStatus.notEvidenced, analysis.notEvidenced);
    final unclearList = mergeFor(RequirementStatus.unknown, analysis.unknowns);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: categoryColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: categoryColor.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.analyzeMatchScore,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        categoryLabel,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      analysis.overall.toStringAsFixed(0),
                      style: theme.textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        '/ 100',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SubScores(
                  items: [
                    (l10n.analyzeSkills, analysis.skillsScore),
                    (l10n.analyzeExperience, analysis.experienceScore),
                    (l10n.analyzeEducation, analysis.educationScore),
                    (l10n.analyzeKeywords, analysis.keywordsScore),
                  ],
                  color: categoryColor,
                ),
                if (analysis.recommendationText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.analyzeRecommendation,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.recommendationText,
                    key: const ValueKey('analysis_recommendation'),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _RequirementSection(
          title: l10n.analyzeStrongMatches,
          requirements: strongList,
          color: Colors.green,
          icon: Icons.check_circle_outline,
        ),
        if (partialList.isNotEmpty)
          _RequirementSection(
            title: l10n.analyzePartialMatches,
            requirements: partialList,
            color: Colors.amber.shade700,
            icon: Icons.star_outline,
          ),
        if (mismatchList.isNotEmpty)
          _RequirementSection(
            title: l10n.analyzeMismatch,
            requirements: mismatchList,
            color: Colors.red,
            icon: Icons.warning_amber_outlined,
          ),
        if (notEvidencedList.isNotEmpty)
          _RequirementSection(
            title: l10n.analyzeNotEvidenced,
            requirements: notEvidencedList,
            color: Colors.grey,
            icon: Icons.circle_outlined,
          ),
        if (unclearList.isNotEmpty)
          _RequirementSection(
            title: l10n.analyzeUnclear,
            requirements: unclearList,
            color: Colors.blueGrey,
            icon: Icons.help_outline,
          ),
        _SimpleSection(title: l10n.analyzeTechnologies, items: analysis.technologies),
        _SimpleSection(title: l10n.analyzeResponsibilities, items: analysis.responsibilities),
        _SimpleSection(title: l10n.analyzeCertifications, items: analysis.certifications),
        _SimpleSection(title: l10n.analyzeLanguages, items: analysis.languages),
        _SimpleSection(title: l10n.analyzeSoftSkills, items: analysis.softSkills),
        _SimpleSection(title: l10n.analyzeDomainKnowledge, items: analysis.domainKnowledge),
        _SimpleSection(title: l10n.analyzeKeywordsList, items: analysis.keywords),
      ],
    );
  }
}

class _SubScores extends StatelessWidget {
  const _SubScores({required this.items, required this.color});

  final List<(String, double)> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 92, child: Text(label, style: theme.textTheme.bodySmall)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    value.toStringAsFixed(0),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RequirementSection extends StatelessWidget {
  const _RequirementSection({
    required this.title,
    required this.requirements,
    required this.color,
    required this.icon,
  });

  final String title;
  final List<JobRequirement> requirements;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(width: 8),
              Text('(${requirements.length})',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            for (final req in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.label + (req.required ? '' : '  · ${AppLocalizations.of(context)!.analyzePreferred}'),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (req.evidenceText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                req.evidenceText,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor, height: 1.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SimpleSection extends StatelessWidget {
  const _SimpleSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(
                  label: Text(item),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
