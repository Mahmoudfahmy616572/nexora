import 'dart:convert';

import '../../domain/cv/cv_evaluator.dart';
import '../../domain/entities/career_target.dart';
import '../../domain/entities/cv_content.dart';
import '../../domain/entities/cv_evaluation.dart';
import '../../domain/entities/job_analysis.dart';
import '../../domain/entities/opportunity_analysis.dart';
import '../../domain/repositories/cv_evaluation_repository.dart';
import '../../domain/repositories/cv_suggestion_repository.dart';
import '../data_sources/career_local_data_source.dart';
import '../data_sources/career_remote_data_source.dart';

/// Evaluates CVs: deterministic scores (source of truth) + optional AI
/// explanation/suggestion enrichment, then persists both.
class CvEvaluationRepositoryImpl implements CvEvaluationRepository {
  CvEvaluationRepositoryImpl(
    this._remote,
    this._local,
    this._suggestionRepo, {
    this.table = 'cv_evaluations',
    this.key = 'studio.cv_evaluations',
  });

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;
  final CvSuggestionRepository _suggestionRepo;
  final String table;
  final String key;

  CvEvaluation _fromJson(Map<String, dynamic> json) =>
      CvEvaluation.fromJson(json);
  Map<String, Object?> _toJson(CvEvaluation item) => item.toJson();

  Future<List<CvEvaluation>> _readAll() async {
    final stored = await _local.readList(key);
    if (stored == null) return <CvEvaluation>[];
    final list = <CvEvaluation>[];
    for (final raw in stored) {
      if (raw.isEmpty) continue;
      try {
        list.add(_fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return list;
  }

  Future<void> _writeAll(List<CvEvaluation> items) async {
    await _local.writeList(
      key,
      [for (final e in items) jsonEncode(_toJson(e))],
    );
  }

  CvSuggestion _suggestionFromAi(
    Map<String, dynamic> raw,
    String userId,
    String versionId,
    String evaluationId,
  ) {
    final section = raw['section'] as String? ?? '';
    final current = raw['current'] as String? ?? '';
    final suggested = raw['suggested'] as String? ?? '';
    return CvSuggestion(
      id: CareerTarget.newId(),
      userId: userId,
      evaluationId: evaluationId,
      versionId: versionId,
      section: section,
      problem: raw['problem'] as String? ?? '',
      current: current,
      suggested: suggested,
      why: raw['why'] as String? ?? '',
      targetRequirement: raw['targetRequirement'] as String? ?? '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CvEvaluationResult> evaluate({
    required CvContent content,
    CareerTarget? target,
    JobAnalysis? analysis,
    OpportunityAnalysis? opportunity,
    required String userId,
    required String versionId,
    required String targetId,
  }) async {
    final deterministic = CvEvaluator.evaluate(
      content: content,
      target: target,
      analysis: analysis,
      opportunity: opportunity,
      userId: userId,
      versionId: versionId,
      targetId: targetId,
    );

    CvEvaluation evaluation = deterministic.evaluation;
    List<CvSuggestion> suggestions = deterministic.suggestions;

    try {
      final data = await _remote.runCvEvaluate({
        'content': content.toJson(),
        if (target != null) 'target': target.toJson(),
        if (analysis != null) 'analysis': analysis.toJson(),
        if (opportunity != null) 'opportunity': opportunity.toJson(),
      });

      final aiExplanations = data['explanations'];
      if (aiExplanations is Map) {
        final map = <String, String>{};
        for (final entry in aiExplanations.entries) {
          map[entry.key.toString()] = entry.value.toString();
        }
        evaluation = evaluation.copyWith(explanations: map);
      }

      final aiSuggestions = data['suggestions'];
      if (aiSuggestions is List && aiSuggestions.isNotEmpty) {
        suggestions = [
          for (final s in aiSuggestions)
            if (s is Map)
              _suggestionFromAi(
                Map<String, dynamic>.from(s),
                userId,
                versionId,
                evaluation.id,
              ),
        ];
      }
    } on Object {
      // AI unavailable: keep the deterministic evaluation and its suggestions,
      // clearly labelled as deterministic-only structural checks.
      evaluation = evaluation.copyWith(deterministicOnly: true);
    }

    await saveEvaluation(evaluation);
    final persisted = <CvSuggestion>[];
    for (final s in suggestions) {
      final withEval = s.copyWith(evaluationId: evaluation.id);
      persisted.add(await _suggestionRepo.saveSuggestion(withEval));
    }

    return CvEvaluationResult(evaluation, persisted);
  }

  @override
  Future<CvEvaluation?> loadEvaluation(String versionId) async {
    final all = await _readAll();
    for (final e in all) {
      if (e.versionId == versionId) return e;
    }
    return null;
  }

  @override
  Future<void> saveEvaluation(CvEvaluation evaluation) async {
    final all = await _readAll();
    all.removeWhere((e) => e.id == evaluation.id);
    all.add(evaluation);
    await _writeAll(all);
  }
}
