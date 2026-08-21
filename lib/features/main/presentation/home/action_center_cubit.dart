import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/action_center/action_center.dart';
import '../../../../domain/action_center/action_center_engine.dart';
import '../../../../domain/analysis/career_intelligence_engine.dart';
import '../../../../domain/entities/career_target.dart';
import '../../../../domain/entities/cv_document.dart';
import '../../../../domain/entities/cv_evaluation.dart';
import '../../../../domain/entities/job_analysis.dart';
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../domain/repositories/career_target_repository.dart';
import '../../../../domain/repositories/cv_document_repository.dart';
import '../../../../domain/repositories/cv_evaluation_repository.dart';
import '../../../../domain/repositories/cv_suggestion_repository.dart';
import '../../../../domain/repositories/job_analysis_repository.dart';
import 'action_center_state.dart';

/// Loads the canonical career state and derives the single next best action.
///
/// Each data source is isolated so a single failure degrades gracefully to the
/// safest meaningful action instead of crashing Home.
class ActionCenterCubit extends Cubit<ActionCenterCubitState> {
  ActionCenterCubit({
    required this.dnaRepo,
    required this.targetRepo,
    required this.analysisRepo,
    required this.docRepo,
    required this.evalRepo,
    required this.suggestionRepo,
  }) : super(const ActionCenterCubitState());

  final CareerDnaRepository dnaRepo;
  final CareerTargetRepository targetRepo;
  final JobAnalysisRepository analysisRepo;
  final CvDocumentRepository docRepo;
  final CvEvaluationRepository evalRepo;
  final CvSuggestionRepository suggestionRepo;

  Future<T> _safe<T>(Future<T> Function() run, T fallback) async {
    try {
      return await run();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> load() async {
    emit(const ActionCenterCubitState(status: ActionCenterStatus.loading));

    final dna = await _safe(() => dnaRepo.load(), null);
    final targets =
        await _safe(() => targetRepo.loadAll(), const <CareerTarget>[]);
    final analyses =
        await _safe(() => analysisRepo.load(), null) ?? const <JobAnalysis>[];
    final documents =
        await _safe(() => docRepo.loadDocuments(), const <CvDocument>[]);

    final intelligence = dna == null
        ? null
        : computeCareerIntelligence(
            dna: dna,
            profile: dna.profile,
            skills: dna.skills,
          );

    final versionsByDoc = <String, List<CvVersion>>{};
    for (final d in documents) {
      versionsByDoc[d.id] = await _safe(
        () => docRepo.loadVersions(d.id),
        const <CvVersion>[],
      );
    }

    final evaluations = <CvEvaluation>[];
    for (final versions in versionsByDoc.values) {
      for (final v in versions) {
        final e = await _safe(() => evalRepo.loadEvaluation(v.id), null);
        if (e != null) evaluations.add(e);
      }
    }

    final suggestions = <CvSuggestion>[];
    for (final e in evaluations) {
      final list = await _safe(
        () => suggestionRepo.loadByEvaluation(e.id),
        const <CvSuggestion>[],
      );
      suggestions.addAll(list);
    }

    final decision = ActionCenterEngine.derive(ActionCenterInput(
      dna: dna,
      intelligence: intelligence,
      targets: targets,
      analyses: analyses,
      documents: documents,
      versionsByDoc: versionsByDoc,
      evaluations: evaluations,
      suggestions: suggestions,
    ));

    emit(ActionCenterCubitState(
      status: ActionCenterStatus.ready,
      decision: decision,
    ));
  }
}
