import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/cv/cv_evaluator.dart';
import '../../../../../domain/entities/career_target.dart';
import '../../../../../domain/entities/cv_document.dart';
import '../../../../../domain/entities/cv_evaluation.dart';
import '../../../../../domain/entities/job_analysis.dart';
import '../../../../../domain/entities/opportunity_analysis.dart';
import '../../../../../domain/repositories/cv_document_repository.dart';
import '../../../../../domain/repositories/cv_evaluation_repository.dart';
import '../../../../../domain/repositories/cv_suggestion_repository.dart';
import '../../../../../domain/repositories/career_target_repository.dart';
import '../../../../../domain/repositories/job_analysis_repository.dart';
import 'cv_evaluation_state.dart';

/// Drives the CV Evaluation + Improvement Loop: deterministic scoring, optional
/// AI explanations/suggestions, accepting/rejecting suggestions (each accepted
/// suggestion produces a new, factually-safe CV version), and manual edits.
class CvEvaluationCubit extends Cubit<CvEvaluationState> {
  CvEvaluationCubit({
    required this.evalRepo,
    required this.suggestionRepo,
    required this.docRepo,
    required this.targetRepo,
    required this.analysisRepo,
    required this.documentId,
    required this.userId,
  }) : super(const CvEvaluationState());

  final CvEvaluationRepository evalRepo;
  final CvSuggestionRepository suggestionRepo;
  final CvDocumentRepository docRepo;
  final CareerTargetRepository targetRepo;
  final JobAnalysisRepository analysisRepo;
  final String documentId;
  final String userId;

  CareerTarget? _target;
  JobAnalysis? _analysis;
  OpportunityAnalysis? _opportunity;
  CvVersion? _version;

  static String _newId() => CareerTarget.newId();

  Future<void> evaluate() async {
    emit(state.copyWith(
      status: CvEvaluationStatus.loading,
      clearMessage: true,
    ));
    try {
      final version = await docRepo.loadLatestVersion(documentId);
      final doc = await docRepo.loadDocument(documentId);
      if (version == null || doc == null) {
        emit(state.copyWith(
          status: CvEvaluationStatus.failure,
          message: 'This CV could not be found.',
        ));
        return;
      }
      _version = version;

      final results = await Future.wait([
        targetRepo.loadAll(),
        analysisRepo.load(),
      ]);
      final targets = results[0] as List<CareerTarget>;
      final analyses = results[1] as List<JobAnalysis>? ?? const [];

      _target = _first(targets, (t) => t.id == doc.targetId);
      _analysis = doc.analysisId == null
          ? null
          : _first(analyses, (a) => a.id == doc.analysisId);
      _opportunity = _analysis?.detail;

      final result = await evalRepo.evaluate(
        content: version.content,
        target: _target,
        analysis: _analysis,
        opportunity: _opportunity,
        userId: userId,
        versionId: version.id,
        targetId: doc.targetId,
      );

      emit(state.copyWith(
        status: CvEvaluationStatus.ready,
        evaluation: result.evaluation,
        suggestions: result.suggestions,
        content: version.content,
        deterministicOnly: result.evaluation.deterministicOnly,
      ));
    } on Object {
      emit(state.copyWith(
        status: CvEvaluationStatus.failure,
        message: 'Could not evaluate the CV. Please try again.',
      ));
    }
  }

  /// Accepts a suggestion: rewords the relevant section (factuality-guarded),
  /// creates a NEW version, and records the suggestion as accepted.
  Future<void> acceptSuggestion(CvSuggestion suggestion) =>
      _applyAccepted(suggestion, suggestion.suggested);

  /// Accepts a suggestion with a manual tweak to the suggested wording.
  Future<void> acceptSuggestionWithEdit(
    CvSuggestion suggestion,
    String editedText,
  ) =>
      _applyAccepted(suggestion, editedText);

  Future<void> _applyAccepted(CvSuggestion suggestion, String replacement) async {
    if (_version == null || state.content == null) return;
    emit(state.copyWith(
      status: CvEvaluationStatus.applyingSuggestion,
      clearMessage: true,
    ));
    try {
      final updated = CvEvaluator.applySuggestion(
        state.content!,
        suggestion.copyWith(suggested: replacement),
      );
      final now = DateTime.now();
      final newVersion = CvVersion(
        id: _newId(),
        documentId: documentId,
        userId: userId,
        version: 0,
        content: updated,
        templateId: _version!.templateId,
        createdAt: now,
        updatedAt: now,
      );
      final savedVersion = await docRepo.createVersion(newVersion);
      _version = savedVersion;

      final accepted = suggestion.copyWith(
        status: CvSuggestionStatus.accepted,
        editedText: replacement,
      );
      await suggestionRepo.updateSuggestion(accepted);

      final recomputed = CvEvaluator.evaluate(
        content: updated,
        target: _target,
        analysis: _analysis,
        opportunity: _opportunity,
        userId: userId,
        versionId: savedVersion.id,
        targetId: _target?.id ?? '',
      );
      final evaluation = recomputed.evaluation.copyWith(
        explanations: state.evaluation?.explanations ?? const {},
        deterministicOnly: state.evaluation?.deterministicOnly ?? false,
      );
      await evalRepo.saveEvaluation(evaluation);

      final suggestions = state.suggestions
          .map((s) => s.id == accepted.id ? accepted : s)
          .toList();

      emit(state.copyWith(
        status: CvEvaluationStatus.ready,
        evaluation: evaluation,
        suggestions: suggestions,
        content: updated,
      ));
    } on Object {
      emit(state.copyWith(
        status: CvEvaluationStatus.failure,
        message: 'Could not apply the suggestion. Please try again.',
      ));
    }
  }

  /// Dismisses a suggestion without changing the CV.
  Future<void> rejectSuggestion(CvSuggestion suggestion) async {
    try {
      final rejected =
          suggestion.copyWith(status: CvSuggestionStatus.rejected);
      await suggestionRepo.updateSuggestion(rejected);
      final suggestions = state.suggestions
          .map((s) => s.id == rejected.id ? rejected : s)
          .toList();
      emit(state.copyWith(suggestions: suggestions, clearMessage: true));
    } on Object {
      emit(state.copyWith(
        status: CvEvaluationStatus.failure,
        message: 'Could not dismiss the suggestion.',
      ));
    }
  }

  /// Re-runs the full evaluation (including the AI enrichment step).
  Future<void> reEvaluate() => evaluate();

  T? _first<T>(List<T> list, bool Function(T) test) =>
      list.where(test).firstOrNull;
}
