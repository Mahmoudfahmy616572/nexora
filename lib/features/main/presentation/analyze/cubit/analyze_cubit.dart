import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/career_dna.dart';
import '../../../../../domain/repositories/career_dna_repository.dart';
import '../../../../../domain/repositories/career_target_repository.dart';
import '../../../../../domain/repositories/job_analysis_repository.dart';
import 'analyze_state.dart';

/// Manages the Analyze screen: loading the target list, the user's past
/// analyses, selecting a target, running an analysis, and removing one.
class AnalyzeCubit extends Cubit<AnalyzeState> {
  AnalyzeCubit(
    this._jobRepo,
    this._targetRepo,
    this._dnaRepo,
  ) : super(const AnalyzeState());

  final JobAnalysisRepository _jobRepo;
  final CareerTargetRepository _targetRepo;
  final CareerDnaRepository _dnaRepo;

  Future<void> load() async {
    emit(state.copyWith(status: AnalyzeStatus.loading, clearMessage: true));
    try {
      final loaded = await _jobRepo.load();
      final targets = await _targetRepo.loadAll();
      final analyses = loaded ?? const [];
      emit(
        state.copyWith(
          status: analyses.isEmpty ? AnalyzeStatus.empty : AnalyzeStatus.loaded,
          analyses: analyses,
          targets: targets,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: AnalyzeStatus.failure,
          message: 'Could not load your analyses. Please try again.',
        ),
      );
    }
  }

  void selectTarget(String? id) =>
      emit(state.copyWith(selectedTargetId: id));

  Future<void> analyze({required String description}) async {
    final text = description.trim();
    if (text.isEmpty) {
      emit(state.copyWith(message: 'Paste a job description first.'));
      return;
    }
    emit(state.copyWith(status: AnalyzeStatus.loading, clearMessage: true));
    try {
      // Analyze against the stored Career DNA when present. When the user has
      // not built their DNA yet, fall back to an empty profile so the offline
      // engine still produces an (all-unclear) result instead of failing.
      final stored = await _dnaRepo.load();
      final dna = stored ?? CareerDna();
      final target = state.selectedTargetId == null
          ? null
          : state.targets
              .where((t) => t.id == state.selectedTargetId)
              .firstOrNull;
      final result = await _jobRepo.analyze(
        description: text,
        dna: dna,
        target: target,
      );
      final analyses = [result, ...state.analyses];
      await _jobRepo.saveAll(analyses);
      emit(
        state.copyWith(
          status: AnalyzeStatus.success,
          analyses: analyses,
          result: result,
          message: 'Analysis complete.',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: AnalyzeStatus.failure,
          message: 'Analysis failed. Please try again.',
        ),
      );
    }
  }

  Future<void> deleteAnalysis(String id) async {
    final previous = state.analyses;
    final current = state.result;
    try {
      final analyses = [for (final a in state.analyses) if (a.id != id) a];
      await _jobRepo.saveAll(analyses);
      emit(
        state.copyWith(
          analyses: analyses,
          result: current?.id == id ? null : current,
          status: analyses.isEmpty ? AnalyzeStatus.empty : AnalyzeStatus.loaded,
          message: 'Removed.',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          analyses: previous,
          message: 'Could not remove the analysis.',
        ),
      );
    }
  }
}
