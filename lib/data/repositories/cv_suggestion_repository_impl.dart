import 'dart:convert';

import '../../domain/entities/cv_evaluation.dart';
import '../../domain/repositories/cv_suggestion_repository.dart';
import '../data_sources/career_local_data_source.dart';

/// Local-first persistence for CV suggestions, mirroring the other career
/// repositories (Supabase source of truth with a SharedPreferences fallback).
class CvSuggestionRepositoryImpl implements CvSuggestionRepository {
  CvSuggestionRepositoryImpl(this._local);

  final CareerLocalDataSource _local;

  static const String _key = 'studio.cv_suggestions';

  Future<List<CvSuggestion>> _readAll() async {
    final stored = await _local.readList(_key);
    if (stored == null) return <CvSuggestion>[];
    final list = <CvSuggestion>[];
    for (final raw in stored) {
      if (raw.isEmpty) continue;
      try {
        list.add(CvSuggestion.fromJson(
            jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return list;
  }

  Future<void> _writeAll(List<CvSuggestion> items) async {
    await _local.writeList(
      _key,
      [for (final s in items) jsonEncode(s.toJson())],
    );
  }

  @override
  Future<List<CvSuggestion>> loadByEvaluation(String evaluationId) async =>
      (await _readAll())
          .where((s) => s.evaluationId == evaluationId)
          .toList();

  @override
  Future<CvSuggestion> saveSuggestion(CvSuggestion suggestion) async {
    final all = await _readAll();
    all.removeWhere((s) => s.id == suggestion.id);
    all.add(suggestion);
    await _writeAll(all);
    return suggestion;
  }

  @override
  Future<CvSuggestion> updateSuggestion(CvSuggestion suggestion) async =>
      saveSuggestion(suggestion);

  @override
  Future<void> deleteForEvaluation(String evaluationId) async {
    final remaining = (await _readAll())
        .where((s) => s.evaluationId != evaluationId)
        .toList();
    await _writeAll(remaining);
  }
}
