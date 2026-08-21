import 'package:equatable/equatable.dart';

import '../entities/career_dna.dart';
import '../entities/career_intelligence.dart';
import '../entities/career_target.dart';
import '../entities/cv_document.dart';
import '../entities/cv_evaluation.dart';
import '../entities/job_analysis.dart';

/// The single, deterministic "next best action" the app recommends.
enum ActionType {
  completeDna,
  defineTarget,
  analyzeOpportunity,
  createCv,
  evaluateCv,
  improveCv,
  trackApplications,

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
}
