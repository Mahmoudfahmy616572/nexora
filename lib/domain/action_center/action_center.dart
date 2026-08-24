import 'package:equatable/equatable.dart';

import '../entities/career_dna.dart';
import '../entities/career_intelligence.dart';
import '../entities/career_target.dart';
import '../entities/cv_document.dart';
import '../entities/cv_evaluation.dart';
import '../entities/job_analysis.dart';
import '../entities/job_application.dart';

/// The single, deterministic "next best action" the app recommends.
enum ActionType {
  completeDna,
  defineTarget,
  analyzeOpportunity,
  createCv,
  evaluateCv,
  improveCv,
  trackApplications,
  prepareInterview,

  /// Practice the interview for a role whose readiness plan already exists.
  /// Takes priority over [prepareInterview] once a plan can be built.
  practiceInterview,

  /// No specific action could be derived (degenerate input). The UI treats this
  /// as a safe default rather than a misleading "you're ready to apply".
  none,
}

/// Deterministic, canonical result of the Action Center engine.
///
/// Holds only structured data (no localized copy) so the engine stays free of
/// UI/network/l10n dependencies. Presentation layers resolve localized title,
/// description and CTA from [actionType] + [metadata].
class ActionCenterState extends Equatable {
  const ActionCenterState({
    required this.actionType,
    this.targetId,
    this.analysisId,
    this.documentId,
    this.versionId,
    this.evaluationId,
    required this.priority,
    this.metadata,
  });

  /// The one primary recommended action.
  final ActionType actionType;

  /// Convenience alias matching the product model's `primaryAction`.
  ActionType get primaryAction => actionType;

  final String? targetId;
  final String? analysisId;
  final String? documentId;
  final String? versionId;
  final String? evaluationId;

  /// Higher means more urgent. Used only for ordering/debugging.
  final int priority;

  /// Contextual facts for secondary display (target role, score, pending count…).
  final Map<String, dynamic>? metadata;

  ActionCenterState copyWith({
    ActionType? actionType,
    String? targetId,
    String? analysisId,
    String? documentId,
    String? versionId,
    String? evaluationId,
    int? priority,
    Map<String, dynamic>? metadata,
  }) =>
      ActionCenterState(
        actionType: actionType ?? this.actionType,
        targetId: targetId ?? this.targetId,
        analysisId: analysisId ?? this.analysisId,
        documentId: documentId ?? this.documentId,
        versionId: versionId ?? this.versionId,
        evaluationId: evaluationId ?? this.evaluationId,
        priority: priority ?? this.priority,
        metadata: metadata ?? this.metadata,
      );

  @override
  List<Object?> get props => [
        actionType,
        targetId,
        analysisId,
        documentId,
        versionId,
        evaluationId,
        priority,
        metadata,
      ];
}

/// All canonical application state needed to derive the next action.
///
/// Every field is sourced from existing repositories — no new source of truth.
class ActionCenterInput {
  const ActionCenterInput({
    this.dna,
    this.intelligence,
    this.targets = const [],
    this.analyses = const [],
    this.documents = const [],
    this.versionsByDoc = const {},
    this.evaluations = const [],
    this.suggestions = const [],
    this.applications = const [],
    this.hasInterviewPrep = false,
  });

  final CareerDna? dna;
  final CareerIntelligence? intelligence;
  final List<CareerTarget> targets;
  final List<JobAnalysis> analyses;
  final List<CvDocument> documents;

  /// docId -> versions (all versions of each document the user owns).
  final Map<String, List<CvVersion>> versionsByDoc;

  final List<CvEvaluation> evaluations;
  final List<CvSuggestion> suggestions;

  /// Tracked job applications, used to recommend interview preparation when one
  /// has reached an interview-stage status. Optional so existing callers (and
  /// tests) that omit it keep behaving exactly as before.
  final List<JobApplication> applications;

  /// True when the user already has everything needed to build an Interview
  /// Readiness plan (DNA complete, a target, and an analysis or skills). When
  /// set, the Action Center recommends [ActionType.practiceInterview].
  final bool hasInterviewPrep;

  ActionCenterInput copyWith({
    CareerDna? dna,
    CareerIntelligence? intelligence,
    List<CareerTarget>? targets,
    List<JobAnalysis>? analyses,
    List<CvDocument>? documents,
    Map<String, List<CvVersion>>? versionsByDoc,
    List<CvEvaluation>? evaluations,
    List<CvSuggestion>? suggestions,
    List<JobApplication>? applications,
    bool? hasInterviewPrep,
  }) =>
      ActionCenterInput(
        dna: dna ?? this.dna,
        intelligence: intelligence ?? this.intelligence,
        targets: targets ?? this.targets,
        analyses: analyses ?? this.analyses,
        documents: documents ?? this.documents,
        versionsByDoc: versionsByDoc ?? this.versionsByDoc,
        evaluations: evaluations ?? this.evaluations,
        suggestions: suggestions ?? this.suggestions,
        applications: applications ?? this.applications,
        hasInterviewPrep: hasInterviewPrep ?? this.hasInterviewPrep,
      );
}
