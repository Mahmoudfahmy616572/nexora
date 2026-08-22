import '../entities/opportunity_analysis.dart';

/// Pure, deterministic selection of interview focus areas from an
/// [OpportunityAnalysis]. No AI, no HTTP — given the same analysis it always
/// returns the same ordered, de-duplicated focus requirements.
///
/// This is the client-controlled "what to prepare" logic; the AI only drafts
/// the questions/coaching text for these areas afterwards.
class InterviewPrepEngine {
  InterviewPrepEngine._();

  /// Requirements to prepare for, in priority order:
  /// required gaps -> partial matches -> requirement mismatches.
  /// De-duplicated by label and capped at [maxAreas].
  static List<String> selectFocusAreas(
    OpportunityAnalysis? analysis, {
    int maxAreas = 6,
  }) {
    if (analysis == null) return const [];
    final ordered = <JobRequirement>[
      ...analysis.requiredGaps,
      ...analysis.partialMatches,
      ...analysis.requirementMismatches,
    ];
    final seen = <String>{};
    final result = <String>[];
    for (final r in ordered) {
      final label = r.label.trim();
      if (label.isEmpty) continue;
      if (seen.contains(label)) continue;
      seen.add(label);
      result.add(label);
      if (result.length >= maxAreas) break;
    }
    return result;
  }

  /// Deterministic "why" rationale for a focus area, drawn from the requirement
  /// evidence (no AI). Returns '' when no analysis / no matching requirement.
  static String rationaleFor(OpportunityAnalysis? analysis, String requirement) {
    if (analysis == null) return '';
    final r = analysis.evidenceMap[requirement];
    if (r == null) return '';
    if (r.evidenceText.isNotEmpty) return r.evidenceText;
    switch (r.status) {
      case RequirementStatus.notEvidenced:
        return 'Listed for this role but not found in your Career DNA — prepare '
            'an honest story or be ready to address the gap.';
      case RequirementStatus.partialMatch:
        return 'You have related or transferable evidence — sharpen it into a '
            'clear, concrete example.';
      case RequirementStatus.requirementMismatch:
        return 'This requirement may conflict with your background — prepare an '
            'honest framing of your strengths.';
      default:
        return '';
    }
  }

  /// Fallback focus areas when no opportunity analysis is available: the
  /// candidate's own declared skills (deterministic, no fabrication).
  static List<String> focusFromSkills(List<String> skills, {int maxAreas = 6}) {
    final seen = <String>{};
    final result = <String>[];
    for (final s in skills) {
      final label = s.trim();
      if (label.isEmpty) continue;
      if (seen.contains(label)) continue;
      seen.add(label);
      result.add(label);
      if (result.length >= maxAreas) break;
    }
    return result;
  }
}
