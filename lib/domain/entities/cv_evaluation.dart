import 'package:equatable/equatable.dart';

/// Lifecycle of a single improvement suggestion.
enum CvSuggestionStatus {
  pending,
  accepted,
  rejected,
}

String _suggestionStatusName(CvSuggestionStatus s) => s.name;

CvSuggestionStatus _parseSuggestionStatus(String? s) =>
    CvSuggestionStatus.values.firstWhere((e) => e.name == s,
        orElse: () => CvSuggestionStatus.pending);

/// A version-specific, reproducible evaluation of a CV.
///
/// Every numeric score is produced by the deterministic [CvEvaluator] so the
/// result is reproducible from the same inputs. When the AI explanation/suggestion
/// step is unavailable, [deterministicOnly] is `true` and the UI must label the
/// result as deterministic structural checks rather than an AI evaluation.
class CvEvaluation extends Equatable {
  const CvEvaluation({
    required this.id,
    required this.userId,
    required this.versionId,
    required this.targetId,
    required this.overall,
    required this.ats,
    required this.targetAlignment,
    required this.contentStrength,
    required this.evidenceStrength,
    required this.readability,
    required this.clarity,
    required this.structure,
    required this.keywordAlignment,
    required this.skillAlignment,
    required this.sectionCompleteness,
    this.explanations = const {},
    this.deterministicOnly = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String versionId;

  /// May be empty when the CV was evaluated as a general CV (no target).
  final String targetId;
  final int overall;
  final int ats;
  final int targetAlignment;
  final int contentStrength;
  final int evidenceStrength;
  final int readability;
  final int clarity;
  final int structure;
  final int keywordAlignment;
  final int skillAlignment;
  final int sectionCompleteness;

  /// Category -> human-readable explanation. Populated deterministically and,
  /// when available, enriched by the AI explanation step.
  final Map<String, String> explanations;
  final bool deterministicOnly;
  final DateTime createdAt;

  CvEvaluation copyWith({
    String? id,
    String? userId,
    String? versionId,
    String? targetId,
    int? overall,
    int? ats,
    int? targetAlignment,
    int? contentStrength,
    int? evidenceStrength,
    int? readability,
    int? clarity,
    int? structure,
    int? keywordAlignment,
    int? skillAlignment,
    int? sectionCompleteness,
    Map<String, String>? explanations,
    bool? deterministicOnly,
    DateTime? createdAt,
  }) =>
      CvEvaluation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        versionId: versionId ?? this.versionId,
        targetId: targetId ?? this.targetId,
        overall: overall ?? this.overall,
        ats: ats ?? this.ats,
        targetAlignment: targetAlignment ?? this.targetAlignment,
        contentStrength: contentStrength ?? this.contentStrength,
        evidenceStrength: evidenceStrength ?? this.evidenceStrength,
        readability: readability ?? this.readability,
        clarity: clarity ?? this.clarity,
        structure: structure ?? this.structure,
        keywordAlignment: keywordAlignment ?? this.keywordAlignment,
        skillAlignment: skillAlignment ?? this.skillAlignment,
        sectionCompleteness: sectionCompleteness ?? this.sectionCompleteness,
        explanations: explanations ?? this.explanations,
        deterministicOnly: deterministicOnly ?? this.deterministicOnly,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'user_id': userId,
        'version_id': versionId,
        'target_id': targetId,
        'overall': overall,
        'ats': ats,
        'target_alignment': targetAlignment,
        'content_strength': contentStrength,
        'evidence_strength': evidenceStrength,
        'readability': readability,
        'clarity': clarity,
        'structure': structure,
        'keyword_alignment': keywordAlignment,
        'skill_alignment': skillAlignment,
        'section_completeness': sectionCompleteness,
        'explanations': explanations,
        'deterministic_only': deterministicOnly,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory CvEvaluation.fromJson(Map<String, dynamic> json) {
    final explanationsRaw = json['explanations'];
    final explanations = <String, String>{};
    if (explanationsRaw is Map) {
      for (final entry in explanationsRaw.entries) {
        explanations[entry.key.toString()] = entry.value.toString();
      }
    }
    return CvEvaluation(
      id: json['id'] as String? ?? '',
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      versionId: (json['version_id'] ?? json['versionId']) as String? ?? '',
      targetId: (json['target_id'] ?? json['targetId']) as String? ?? '',
      overall: (json['overall'] as num?)?.toInt() ?? 0,
      ats: (json['ats'] as num?)?.toInt() ?? 0,
      targetAlignment: (json['target_alignment'] as num?)?.toInt() ?? 0,
      contentStrength: (json['content_strength'] as num?)?.toInt() ?? 0,
      evidenceStrength: (json['evidence_strength'] as num?)?.toInt() ?? 0,
      readability: (json['readability'] as num?)?.toInt() ?? 0,
      clarity: (json['clarity'] as num?)?.toInt() ?? 0,
      structure: (json['structure'] as num?)?.toInt() ?? 0,
      keywordAlignment: (json['keyword_alignment'] as num?)?.toInt() ?? 0,
      skillAlignment: (json['skill_alignment'] as num?)?.toInt() ?? 0,
      sectionCompleteness: (json['section_completeness'] as num?)?.toInt() ?? 0,
      explanations: explanations,
      deterministicOnly: json['deterministic_only'] as bool? ?? false,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as num?)?.toInt() ?? 0),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        versionId,
        targetId,
        overall,
        ats,
        targetAlignment,
        contentStrength,
        evidenceStrength,
        readability,
        clarity,
        structure,
        keywordAlignment,
        skillAlignment,
        sectionCompleteness,
        explanations,
        deterministicOnly,
        createdAt,
      ];
}

/// A single, explainable improvement for one CV section.
///
/// Suggestions are first-class: they identify the exact [section] and [current]
/// content, explain the [problem] and [why], reference the affected
/// [targetRequirement], and propose a [suggested] rewording. Applying an accepted
/// (or manually edited) suggestion creates a NEW [CvVersion] — the original is
/// never overwritten.
class CvSuggestion extends Equatable {
  const CvSuggestion({
    required this.id,
    required this.userId,
    required this.evaluationId,
    required this.versionId,
    required this.section,
    required this.problem,
    required this.current,
    required this.suggested,
    required this.why,
    required this.targetRequirement,
    this.status = CvSuggestionStatus.pending,
    this.editedText,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String evaluationId;
  final String versionId;
  final String section;
  final String problem;
  final String current;
  final String suggested;
  final String why;
  final String targetRequirement;
  final CvSuggestionStatus status;

  /// Present only when the user manually edited the suggestion before applying.
  final String? editedText;
  final DateTime createdAt;

  CvSuggestion copyWith({
    String? id,
    String? userId,
    String? evaluationId,
    String? versionId,
    String? section,
    String? problem,
    String? current,
    String? suggested,
    String? why,
    String? targetRequirement,
    CvSuggestionStatus? status,
    String? editedText,
    bool clearEditedText = false,
    DateTime? createdAt,
  }) =>
      CvSuggestion(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        evaluationId: evaluationId ?? this.evaluationId,
        versionId: versionId ?? this.versionId,
        section: section ?? this.section,
        problem: problem ?? this.problem,
        current: current ?? this.current,
        suggested: suggested ?? this.suggested,
        why: why ?? this.why,
        targetRequirement: targetRequirement ?? this.targetRequirement,
        status: status ?? this.status,
        editedText: clearEditedText ? null : (editedText ?? this.editedText),
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'user_id': userId,
        'evaluation_id': evaluationId,
        'version_id': versionId,
        'section': section,
        'problem': problem,
        'current': current,
        'suggested': suggested,
        'why': why,
        'target_requirement': targetRequirement,
        'status': _suggestionStatusName(status),
        'edited_text': editedText,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory CvSuggestion.fromJson(Map<String, dynamic> json) => CvSuggestion(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
        evaluationId:
            json['evaluation_id'] as String? ?? json['evaluationId'] as String? ?? '',
        versionId: json['version_id'] as String? ?? json['versionId'] as String? ?? '',
        section: json['section'] as String? ?? '',
        problem: json['problem'] as String? ?? '',
        current: json['current'] as String? ?? '',
        suggested: json['suggested'] as String? ?? '',
        why: json['why'] as String? ?? '',
        targetRequirement: json['target_requirement'] as String? ??
            json['targetRequirement'] as String? ??
            '',
        status: _parseSuggestionStatus(
            json['status'] as String? ?? json['status'] as String?),
        editedText: json['edited_text'] as String? ?? json['editedText'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as num?)?.toInt() ?? 0),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        evaluationId,
        versionId,
        section,
        problem,
        current,
        suggested,
        why,
        targetRequirement,
        status,
        editedText,
        createdAt,
      ];
}
