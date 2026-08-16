import 'dart:convert';

import '../../domain/entities/cv_profile.dart';
import '../../domain/entities/job_analysis.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/entities/profile_section.dart';
import '../../domain/repositories/cv_repository.dart';
import '../../domain/repositories/job_analysis_repository.dart';
import '../../domain/repositories/job_application_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/profile_section_repository.dart';
import '../../domain/repositories/profile_skills_repository.dart';
import '../data_sources/career_local_data_source.dart';
import '../data_sources/career_remote_data_source.dart';

/// Shared behavior for the career repositories.
///
/// Supabase is the source of truth when reachable; when it is not (signed
/// out, offline, unconfigured), the same data falls back to [SharedPreferences]
/// so the app keeps working. A `null` result from [load] means nothing has
/// been stored anywhere yet.
abstract class _FallbackRepository<T> {
  _FallbackRepository(
    CareerRemoteDataSource remote,
    CareerLocalDataSource local, {
    required this.table,
    required this.key,
  })  : _remote = remote,
        _local = local;

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;
  final String table;
  final String key;

  T fromJson(Map<String, dynamic> json);

  Map<String, Object> toJson(T item);

  Future<List<T>?> load() async {
    try {
      final rows = await _remote.fetchAll(table);
      return [for (final row in rows) fromJson(row)];
    } catch (_) {
      // Supabase unavailable: fall back to local storage below.
    }
    final stored = await _local.readList(key);
    if (stored == null) return null;
    final list = <T>[];
    for (final raw in stored) {
      if (raw.isEmpty) continue;
      try {
        list.add(fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return list;
  }

  Future<void> saveAll(List<T> items) async {
    try {
      await _remote.replaceAll(table, [for (final item in items) toJson(item)]);
      return;
    } catch (_) {
      // Supabase unavailable: persist locally instead.
    }
    await _local.writeList(key, [for (final item in items) jsonEncode(toJson(item))]);
  }
}

class JobApplicationRepositoryImpl extends _FallbackRepository<JobApplication>
    implements JobApplicationRepository {
  JobApplicationRepositoryImpl(super.remote, super.local)
      : super(table: 'job_applications', key: 'tracker.apps');

  @override
  JobApplication fromJson(Map<String, dynamic> json) => JobApplication.fromJson(json);

  @override
  Map<String, Object> toJson(JobApplication item) => item.toJson();
}

class JobAnalysisRepositoryImpl extends _FallbackRepository<JobAnalysis>
    implements JobAnalysisRepository {
  JobAnalysisRepositoryImpl(super.remote, super.local)
      : super(table: 'job_analyses', key: 'analyze.analyses');

  @override
  JobAnalysis fromJson(Map<String, dynamic> json) => JobAnalysis.fromJson(json);

  @override
  Map<String, Object> toJson(JobAnalysis item) => item.toJson();

  @override
  Future<JobAnalysis> analyze({
    required String description,
    required List<String> skills,
    int? yearsOfExperience,
    String? education,
    ProfileData? profile,
  }) async {
    final data = await _remote.runAiAnalysis({
      'description': description,
      'skills': skills,
      'yearsOfExperience': ?yearsOfExperience,
      'education': ?education,
      'profile': ?profile?.toJson(),
    });
    return JobAnalysis.fromJson(data);
  }
}

class CvRepositoryImpl extends _FallbackRepository<CvProfile> implements CvRepository {
  CvRepositoryImpl(super.remote, super.local)
      : super(table: 'cvs', key: 'studio.cvs');

  @override
  CvProfile fromJson(Map<String, dynamic> json) => CvProfile.fromJson(json);

  @override
  Map<String, Object> toJson(CvProfile item) => item.toJson();
}

class ProfileSectionRepositoryImpl extends _FallbackRepository<ProfileSection>
    implements ProfileSectionRepository {
  ProfileSectionRepositoryImpl(super.remote, super.local)
      : super(table: 'profile_sections', key: 'dna.custom.sections');

  @override
  ProfileSection fromJson(Map<String, dynamic> json) => ProfileSection.fromJson(json);

  @override
  Map<String, Object> toJson(ProfileSection item) => item.toJson();
}

/// The user's real career profile — stored as a single `profile_content` row
/// when Supabase is reachable, with a SharedPreferences fallback for offline.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._local);

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;

  @override
  Future<ProfileData?> load() async {
    try {
      final row = await _remote.fetchProfile();
      if (row != null) return ProfileData.fromJson(row);
    } catch (_) {
      // Supabase unavailable: fall back to local storage below.
    }
    final stored = await _local.readString('profile.content');
    if (stored == null || stored.isEmpty) return null;
    try {
      return ProfileData.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ProfileData profile) async {
    try {
      await _remote.saveProfile(profile.toJson());
      return;
    } catch (_) {
      // Supabase unavailable: persist locally instead.
    }
    await _local.writeString('profile.content', jsonEncode(profile.toJson()));
  }
}

/// The user's declared skills — stored on their `profiles` row when Supabase
/// is reachable, with a SharedPreferences fallback for offline use.
class ProfileSkillsRepositoryImpl implements ProfileSkillsRepository {
  ProfileSkillsRepositoryImpl(this._remote, this._local);

  final CareerRemoteDataSource _remote;
  final CareerLocalDataSource _local;

  @override
  Future<List<String>?> load() async {
    try {
      return await _remote.fetchSkills();
    } catch (_) {
      // Supabase unavailable: fall back to local storage below.
    }
    return _local.readList('dna.skills');
  }

  @override
  Future<void> save(List<String> skills) async {
    try {
      await _remote.saveSkills(skills);
      return;
    } catch (_) {
      // Supabase unavailable: persist locally instead.
    }
    await _local.writeList('dna.skills', skills);
  }
}
