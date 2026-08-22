import 'package:equatable/equatable.dart';

/// A single area the candidate should prepare for, derived deterministically
/// from the opportunity gap analysis.
///
/// [why] is deterministic (from the gap evidence). [question] and [coaching]
/// are AI-drafted advisory text only — never a source of truth.
class PrepFocusArea extends Equatable {
  const PrepFocusArea({
    required this.requirement,
    this.why = '',
    this.question = '',
    this.coaching = '',
  });

  final String requirement;
  final String why;
  final String question;
  final String coaching;

  @override
  List<Object?> get props => [requirement, why, question, coaching];

  Map<String, Object?> toJson() => {
        'requirement': requirement,
        'why': why,
        'question': question,
        'coaching': coaching,
      };

  factory PrepFocusArea.fromJson(Map<String, dynamic> json) => PrepFocusArea(
        requirement: json['requirement'] as String? ?? '',
        why: json['why'] as String? ?? '',
        question: json['question'] as String? ?? '',
        coaching: json['coaching'] as String? ?? '',
      );
}

/// A complete, AI-grounded interview readiness plan.
///
/// [deterministicOnly] is true when the AI was unavailable and only the
/// deterministic focus areas are present (no AI text, no fabrication).
class InterviewPrepPlan extends Equatable {
  const InterviewPrepPlan({
    required this.focusAreas,
    this.likelyQuestions = const [],
    this.tips = '',
    this.deterministicOnly = false,
  });

  final List<PrepFocusArea> focusAreas;
  final List<String> likelyQuestions;
  final String tips;
  final bool deterministicOnly;

  @override
  List<Object?> get props => [focusAreas, likelyQuestions, tips, deterministicOnly];

  Map<String, Object?> toJson() => {
        'focusAreas': [for (final f in focusAreas) f.toJson()],
        'likelyQuestions': likelyQuestions,
        'tips': tips,
        'deterministicOnly': deterministicOnly,
      };

  factory InterviewPrepPlan.fromJson(Map<String, dynamic> json) {
    final areas = json['focusAreas'];
    return InterviewPrepPlan(
      focusAreas: areas is List
          ? [for (final a in areas) PrepFocusArea.fromJson(Map<String, dynamic>.from(a))]
          : const [],
      likelyQuestions: [
        for (final s in json['likelyQuestions'] as List? ?? const []) s as String
      ],
      tips: json['tips'] as String? ?? '',
      deterministicOnly: json['deterministicOnly'] as bool? ?? false,
    );
  }
}
