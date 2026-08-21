import 'dart:convert';
import 'dart:math';

import '../../domain/entities/career_dna.dart';
import '../../domain/entities/career_target.dart';
import '../../domain/entities/cv_content.dart';
import '../../domain/entities/cv_document.dart';
import '../../domain/entities/cv_profile.dart';
import '../../domain/entities/job_analysis.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/entities/profile_data.dart';
import '../../domain/entities/profile_section.dart';
import '../../domain/analysis/job_analyzer.dart';
import '../../domain/analysis/opportunity_match_engine.dart';
import '../../domain/entities/job_extraction.dart';
import '../../domain/repositories/career_target_repository.dart';
import '../../domain/repositories/cv_document_repository.dart';
import '../../domain/repositories/cv_generation_repository.dart';
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
    required CareerDna dna,
    CareerTarget? target,
  }) async {
    JobExtraction extraction;
    String? aiRecommendation;
    try {
      final data = await _remote.runAiAnalysis({
        'description': description,
        'skills': dna.skills,
        'yearsOfExperience': dna.profile.yearsTotal,
        'education': _highestDegree(dna.profile),
        'stage': dna.stage?.name,
        'profile': dna.profile.toJson(),
        'target': target?.toJson(),
      });
      extraction = JobExtraction.fromJson(
          Map<String, dynamic>.from(data['detail'] as Map? ?? {}));
      aiRecommendation = data['ai_recommendation'] as String?;
    } catch (_) {
      // Offline / AI unavailable: use the offline deterministic extraction.
      extraction = OpportunityMatchEngine().extract(description);
    }
    final analysis = OpportunityMatchEngine().compute(
      dna: dna,
      extraction: extraction,
      target: target,
      aiRecommendation: aiRecommendation,
    );
    return JobAnalysis(
      id: CareerTarget.newId(),
      title: extraction.role.isNotEmpty
          ? extraction.role
          : (target?.role.isNotEmpty == true ? target!.role : 'Opportunity'),
      company: extraction.company,
      timeAgo: 'Just now',
      overall: analysis.overall,
      skills: analysis.skillsScore,
      experience: analysis.experienceScore,
      education: analysis.educationScore,
      keywords: analysis.keywordsScore,
      strong: analysis.strongMatches.map((r) => r.label).toList(),
      missing: analysis.requiredGaps.map((r) => r.label).toList(),
      aiRecommendation: analysis.recommendationText,
      targetId: analysis.targetId,
      jobDescription: analysis.jobDescription,
      detail: analysis,
    );
  }

  String _highestDegree(ProfileData profile) {
    var rank = 0;
    for (final e in profile.education) {
      final r = JobAnalyzer.educationRank[e.degree.toLowerCase()] ?? 0;
      if (r > rank) rank = r;
    }
    switch (rank) {
      case 5:
        return 'phd';
      case 4:
        return 'master';
      case 3:
        return 'bachelor';
      case 2:
        return 'associate';
      case 1:
        return 'high school';
      default:
        return '';
    }
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

/// The user's Career Targets — a small list per user, so the list-based
/// load/save-all contract of the base class fits exactly. Supabase is the
/// source of truth (scoped by the signed-in user via RLS); local storage is the
/// offline fallback.
class CareerTargetRepositoryImpl extends _FallbackRepository<CareerTarget>
    implements CareerTargetRepository {
  CareerTargetRepositoryImpl(super.remote, super.local)
      : super(table: 'career_targets', key: 'career_targets_v1');

  @override
  CareerTarget fromJson(Map<String, dynamic> json) => CareerTarget.fromJson(json);

  @override
  Map<String, Object> toJson(CareerTarget value) => value.toJson();

  @override
  Future<List<CareerTarget>> loadAll() async => (await load()) ?? <CareerTarget>[];

  @override
  Future<CareerTarget?> loadById(String id) async {
    final all = await loadAll();
    for (final target in all) {
      if (target.id == id) return target;
    }
    return null;
  }

  @override
  Future<CareerTarget> create(CareerTarget target) async {
    await saveAll([...await loadAll(), target]);
    return target;
  }

  @override
  Future<CareerTarget> update(CareerTarget target) async {
    final updated = [
      for (final existing in await loadAll())
        if (existing.id == target.id) target else existing,
    ];
    await saveAll(updated);
    return target;
  }

  @override
  Future<void> delete(String id) async {
    await saveAll([
      for (final existing in await loadAll())
        if (existing.id != id) existing,
    ]);
  }
}

class CvDocumentRepositoryImpl extends _FallbackRepository<CvDocument>
    implements CvDocumentRepository {
  CvDocumentRepositoryImpl(super.remote, super.local)
      : super(table: 'cv_documents', key: 'studio.cv_documents');

  @override
  CvDocument fromJson(Map<String, dynamic> json) => CvDocument.fromJson(json);
  @override
  Map<String, Object> toJson(CvDocument item) => item.toJson();

  static const String _versionKey = 'studio.cv_versions';

  Future<List<CvVersion>> _readVersions() async {
    final stored = await _local.readList(_versionKey);
    if (stored == null) return <CvVersion>[];
    final list = <CvVersion>[];
    for (final raw in stored) {
      if (raw.isEmpty) continue;
      try {
        list.add(CvVersion.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed version entries.
      }
    }
    return list;
  }

  Future<void> _writeVersions(List<CvVersion> versions) async {
    await _local.writeList(
      _versionKey,
      [for (final v in versions) jsonEncode(v.toJson())],
    );
  }

  @override
  Future<CvDocument> createDocument(CvDocument document) async {
    final docs = await loadDocuments();
    docs.removeWhere((d) => d.id == document.id);
    docs.insert(0, document);
    await saveAll(docs);
    return document;
  }

  @override
  Future<List<CvDocument>> loadDocuments() async => (await load()) ?? [];

  @override
  Future<CvDocument?> loadDocument(String id) async {
    final docs = await loadDocuments();
    for (final d in docs) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<void> deleteDocument(String id) async {
    final docs = await loadDocuments();
    docs.removeWhere((d) => d.id == id);
    await saveAll(docs);
    final versions =
        (await _readVersions()).where((v) => v.documentId != id).toList();
    await _writeVersions(versions);
  }

  @override
  Future<CvVersion> createVersion(CvVersion version) async {
    final all = await _readVersions();
    final existing =
        all.where((v) => v.documentId == version.documentId).toList();
    final next =
        existing.isEmpty ? 1 : existing.map((v) => v.version).reduce(max) + 1;
    final saved = version.copyWith(version: next);
    all.removeWhere((v) => v.id == saved.id);
    all.add(saved);
    await _writeVersions(all);
    return saved;
  }

  @override
  Future<List<CvVersion>> loadVersions(String documentId) async =>
      (await _readVersions())
          .where((v) => v.documentId == documentId)
          .toList();

  @override
  Future<CvVersion?> loadLatestVersion(String documentId) async {
    final versions = await loadVersions(documentId);
    if (versions.isEmpty) return null;
    versions.sort((a, b) => a.version.compareTo(b.version));
    return versions.last;
  }

  @override
  Future<CvVersion?> loadVersion(String versionId) async {
    for (final v in await _readVersions()) {
      if (v.id == versionId) return v;
    }
    return null;
  }

  @override
  Future<void> saveVersion(CvVersion version) async {
    final all = await _readVersions();
    all.removeWhere((v) => v.id == version.id);
    all.add(version);
    await _writeVersions(all);
  }
}

class CvGenerationRepositoryImpl implements CvGenerationRepository {
  CvGenerationRepositoryImpl(this._remote);
  final CareerRemoteDataSource _remote;

  @override
  Future<CvContent> generate({
    required CareerDna dna,
    required CareerTarget target,
    JobAnalysis? analysis,
    required String templateId,
    required String language,
  }) async {
    final input = <String, Object>{
      'career_dna': dna.toContext(),
      'target': target.toJson(),
      if (analysis != null) 'opportunity': analysis.toJson(),
      'template': {'id': templateId},
      'language': language,
    };
    final data = await _remote.runCvGenerate(input);
    final content = CvContent.fromJson(
      Map<String, dynamic>.from(data['content'] as Map),
    );
    return content;
  }
}
