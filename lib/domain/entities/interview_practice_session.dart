import 'package:equatable/equatable.dart';

/// Outcome band for a single answered question.
///
/// Derived deterministically from the composite score — never from AI.
enum PracticeVerdict { strong, good, needsImprovement }

/// Lifecycle of a practice session.
enum PracticeStatus { inProgress, completed }

/// One answered question inside a practice session.
///
/// Holds the deterministic scores plus the qualitative feedback bullets. The AI
/// may contribute [coachingSketch] only; it never sets any numeric score.
class InterviewPracticeTurn extends Equatable {
  const InterviewPracticeTurn({
    required this.id,
    required this.question,
    required this.answer,
    required this.focusArea,
    required this.relevanceScore,
    required this.specificityScore,
    required this.structureScore,
    required this.profileConsistencyScore,
    required this.compositeScore,
    required this.verdict,
    required this.feedbackStrengths,
    required this.feedbackImprove,
    required this.coachingSketch,
    required this.unverifiedClaims,
    required this.createdAt,
  });

  final String id;
  final String question;
  final String answer;
  final String focusArea;
  final int relevanceScore;
  final int specificityScore;
  final int structureScore;
  final int profileConsistencyScore;
  final int compositeScore;
  final PracticeVerdict verdict;
  final List<String> feedbackStrengths;
  final List<String> feedbackImprove;

  /// Optional AI-authored response pattern. Never a fabricated user fact.
  final String coachingSketch;

  /// Terms/claims in the answer not found in the known profile — marked
  /// "New / Unverified" so the user can verify them. Empty when consistent.
  final List<String> unverifiedClaims;

  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'focus_area': focusArea,
        'relevance_score': relevanceScore,
        'specificity_score': specificityScore,
        'structure_score': structureScore,
        'profile_consistency_score': profileConsistencyScore,
        'composite_score': compositeScore,
        'verdict': verdict.name,
        'feedback_strengths': feedbackStrengths,
        'feedback_improve': feedbackImprove,
        'coaching_sketch': coachingSketch,
        'unverified_claims': unverifiedClaims,
        'created_at': createdAt.toIso8601String(),
      };

  factory InterviewPracticeTurn.fromJson(Map<String, dynamic> json) =>
      InterviewPracticeTurn(
        id: json['id'] as String,
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        focusArea: json['focus_area'] as String? ?? '',
        relevanceScore: json['relevance_score'] as int? ?? 0,
        specificityScore: json['specificity_score'] as int? ?? 0,
        structureScore: json['structure_score'] as int? ?? 0,
        profileConsistencyScore: json['profile_consistency_score'] as int? ?? 0,
        compositeScore: json['composite_score'] as int? ?? 0,
        verdict: PracticeVerdict.values.firstWhere(
          (v) => v.name == json['verdict'],
          orElse: () => PracticeVerdict.needsImprovement,
        ),
        feedbackStrengths: List<String>.from(json['feedback_strengths'] ?? const []),
        feedbackImprove: List<String>.from(json['feedback_improve'] ?? const []),
        coachingSketch: json['coaching_sketch'] as String? ?? '',
        unverifiedClaims: List<String>.from(json['unverified_claims'] ?? const []),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime(2024),
      );

  @override
  List<Object?> get props => [
        id,
        question,
        answer,
        focusArea,
        relevanceScore,
        specificityScore,
        structureScore,
        profileConsistencyScore,
        compositeScore,
        verdict,
        feedbackStrengths,
        feedbackImprove,
        coachingSketch,
        unverifiedClaims,
        createdAt,
      ];
}

/// A completed (or in-progress) practice session, persisted additively.
class InterviewPracticeSession extends Equatable {
  const InterviewPracticeSession({
    required this.id,
    required this.userId,
    this.targetId,
    this.applicationId,
    this.analysisId,
    this.role,
    this.company,
    required this.startedAt,
    this.completedAt,
    this.status = PracticeStatus.inProgress,
    this.questionCount = 0,
    this.answeredCount = 0,
    this.completedCount = 0,
    this.relevanceScore = 0,
    this.specificityScore = 0,
    this.structureScore = 0,
    this.profileConsistencyScore = 0,
    this.overallScore = 0,
    this.recommendedNextArea,
    this.focusAreas = const [],
    this.turns = const [],
  });

  final String id;
  final String userId;
  final String? targetId;
  final String? applicationId;
  final String? analysisId;
  final String? role;
  final String? company;
  final DateTime startedAt;
  final DateTime? completedAt;
  final PracticeStatus status;
  final int questionCount;
  final int answeredCount;
  final int completedCount;
  final int relevanceScore;
  final int specificityScore;
  final int structureScore;
  final int profileConsistencyScore;
  final int overallScore;
  final String? recommendedNextArea;
  final List<String> focusAreas;
  final List<InterviewPracticeTurn> turns;

  InterviewPracticeSession copyWith({
    String? role,
    String? company,
    PracticeStatus? status,
    int? questionCount,
    int? answeredCount,
    int? completedCount,
    int? relevanceScore,
    int? specificityScore,
    int? structureScore,
    int? profileConsistencyScore,
    int? overallScore,
    String? recommendedNextArea,
    List<String>? focusAreas,
    List<InterviewPracticeTurn>? turns,
    DateTime? completedAt,
  }) =>
      InterviewPracticeSession(
        id: id,
        userId: userId,
        targetId: targetId,
        applicationId: applicationId,
        analysisId: analysisId,
        role: role ?? this.role,
        company: company ?? this.company,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        status: status ?? this.status,
        questionCount: questionCount ?? this.questionCount,
        answeredCount: answeredCount ?? this.answeredCount,
        completedCount: completedCount ?? this.completedCount,
        relevanceScore: relevanceScore ?? this.relevanceScore,
        specificityScore: specificityScore ?? this.specificityScore,
        structureScore: structureScore ?? this.structureScore,
        profileConsistencyScore:
            profileConsistencyScore ?? this.profileConsistencyScore,
        overallScore: overallScore ?? this.overallScore,
        recommendedNextArea:
            recommendedNextArea ?? this.recommendedNextArea,
        focusAreas: focusAreas ?? this.focusAreas,
        turns: turns ?? this.turns,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'user_id': userId,
        'target_id': targetId,
        'application_id': applicationId,
        'analysis_id': analysisId,
        'role': role,
        'company': company,
        'status': status.name,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'question_count': questionCount,
        'answered_count': answeredCount,
        'completed_count': completedCount,
        'relevance_score': relevanceScore,
        'specificity_score': specificityScore,
        'structure_score': structureScore,
        'profile_consistency_score': profileConsistencyScore,
        'overall_score': overallScore,
        'recommended_next_area': recommendedNextArea,
        'focus_areas': focusAreas,
        'turns': [for (final t in turns) t.toJson()],
      };

  factory InterviewPracticeSession.fromJson(Map<String, dynamic> json) =>
      InterviewPracticeSession(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
        targetId: json['target_id'] as String?,
        applicationId: json['application_id'] as String?,
        analysisId: json['analysis_id'] as String?,
        role: json['role'] as String?,
        company: json['company'] as String?,
        startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
            DateTime(2024),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.tryParse(json['completed_at'] as String),
        status: PracticeStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PracticeStatus.inProgress,
        ),
        questionCount: json['question_count'] as int? ?? 0,
        answeredCount: json['answered_count'] as int? ?? 0,
        completedCount: json['completed_count'] as int? ?? 0,
        relevanceScore: json['relevance_score'] as int? ?? 0,
        specificityScore: json['specificity_score'] as int? ?? 0,
        structureScore: json['structure_score'] as int? ?? 0,
        profileConsistencyScore:
            json['profile_consistency_score'] as int? ?? 0,
        overallScore: json['overall_score'] as int? ?? 0,
        recommendedNextArea: json['recommended_next_area'] as String?,
        focusAreas: List<String>.from(json['focus_areas'] ?? const []),
        turns: [
          for (final t in (json['turns'] as List? ?? const []))
            InterviewPracticeTurn.fromJson(t as Map<String, dynamic>)
        ],
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        targetId,
        applicationId,
        analysisId,
        role,
        company,
        startedAt,
        completedAt,
        status,
        questionCount,
        answeredCount,
        completedCount,
        relevanceScore,
        specificityScore,
        structureScore,
        profileConsistencyScore,
        overallScore,
        recommendedNextArea,
        focusAreas,
        turns,
      ];
}
