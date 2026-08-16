import 'package:flutter/foundation.dart';

import '../../domain/entities/career_dna.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/profile_generator.dart';
import '../../domain/repositories/career_dna_repository.dart';
import '../data_sources/career_local_data_source.dart';
import '../data_sources/career_remote_data_source.dart';

/// Default implementation of [CareerDnaRepository].
///
/// Tries Supabase first and falls back to SharedPreferences when the backend is
/// unreachable. When saving an existing DNA, the version is bumped and a
/// snapshot is recorded. Structured content is also mirrored into the legacy
/// `profile_content` / `profiles.skills` so the Phase 2 tabs stay consistent.
class CareerDnaRepositoryImpl implements CareerDnaRepository {
  CareerDnaRepositoryImpl({
    required this._remote,
    required this._local,
  });

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;

  @override
  Future<CareerDna?> load() async {
    try {
      final row = await _remote.fetchCareerDna();
      if (row != null) {
        await _local.writeCareerDna(row);
        return CareerDna.fromRow(row);
      }
    } on Object catch (e) {
      debugPrint('CareerDna load remote failed, using local: $e');
    }
    final localRow = await _local.readCareerDna();
    if (localRow == null) return null;
    return CareerDna.fromRow(localRow);
  }

  @override
  Future<CareerDna> save(CareerDna dna) async {
    final existing = await load();
    final version = existing == null ? 1 : existing.version + 1;
    final updated = dna.copyWith(version: version, updatedAt: DateTime.now());

    // Mirror into legacy stores so the existing SmartBuilder / Analyze tabs
    // reflect the same data.
    try {
      await _remote.saveProfile(updated.profile.toJson());
      await _remote.saveSkills(updated.skills);
      await _remote.upsertCareerDna(updated.toRow());
      await _remote.insertVersion(updated.toVersionRow());
    } on Object catch (e) {
      debugPrint('CareerDna remote save failed, caching locally: $e');
      throw Exception('Could not save Career DNA: $e');
    } finally {
      await _local.writeCareerDna(updated.toRow());
      final versions = await _local.readVersions();
      versions.insert(0, updated.toVersionRow());
      await _local.writeVersions(versions.take(20).toList());
    }
    return updated;
  }

  @override
  Future<List<CareerDna>> versions() async {
    try {
      final rows = await _remote.fetchVersions();
      if (rows.isNotEmpty) {
        return [
          for (final row in rows) _fromVersionRow(row),
        ];
      }
    } on Object catch (e) {
      debugPrint('CareerDna versions remote failed: $e');
    }
    final local = await _local.readVersions();
    return [for (final row in local) _fromVersionRow(row)];
  }

  @override
  Future<GeneratedProfile> draftProfile({
    required String target,
    required String education,
    required String experience,
    required String skills,
  }) async {
    try {
      final data = await _remote.runAiProfileDraft({
        'target': target,
        'education': education,
        'experience': experience,
        'skills': skills,
      });
      final profileJson = data['profile'] as Map<String, dynamic>;
      final skillsJson = data['skills'];
      return GeneratedProfile(
        data: ProfileData.fromJson(profileJson),
        skills: skillsJson is List
            ? [for (final s in skillsJson) s as String]
            : const [],
      );
    } on Object catch (e) {
      debugPrint('draftProfile AI failed, using local fallback: $e');
      throw Exception('AI draft failed: $e');
    }
  }

  @override
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  }) async {
    try {
      final data = await _remote.runAiInterview({
        'context': context,
        'history': history,
        'language': language,
        'finish': finish,
      });
      final done = data['done'] == true;
      if (!done) {
        final question = data['question'] as String? ?? '';
        return InterviewResult(done: false, question: question);
      }
      final profileJson = data['profile'];
      final profile = profileJson is Map
          ? ProfileData.fromJson(Map<String, dynamic>.from(profileJson))
          : const ProfileData();
      return InterviewResult(done: true, profile: profile);
    } on Object catch (e) {
      debugPrint('interview AI failed: $e');
      throw Exception('AI interview failed: $e');
    }
  }
}

CareerDna _fromVersionRow(Map<String, dynamic> row) {
  final content = row['content'];
  final profile = content is Map
      ? ProfileData.fromJson(Map<String, dynamic>.from(content))
      : const ProfileData();
  return CareerDna(
    goal: _enum(CareerGoal.values, row['goal']),
    stage: _enum(CareerStage.values, row['career_stage']),
    targetField: _enum(TargetField.values, row['target_field']),
    targetRole: (row['target_role'] as String?) ?? '',
    targetIndustry: (row['target_industry'] as String?) ?? '',
    preferences: [
      for (final p in (row['preferences'] as List? ?? const [])) p as String,
    ],
    profile: profile,
    skills: [for (final s in (row['skills'] as List? ?? const [])) s as String],
    version: (row['version'] as num?)?.toInt() ?? 1,
  );
}

T? _enum<T>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return null;
}
