import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_document.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/user_identity.dart';
import 'package:nexora/domain/entities/interview_prep.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/profile_generator.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/domain/repositories/cv_document_repository.dart';
import 'package:nexora/domain/repositories/cv_generation_repository.dart';
import 'package:nexora/domain/repositories/career_target_repository.dart';
import 'package:nexora/domain/repositories/job_analysis_repository.dart';
import 'package:nexora/domain/repositories/user_identity_repository.dart';
import 'package:nexora/features/main/presentation/studio/cubit/cv_cubit.dart';

class _FakeDnaRepo implements CareerDnaRepository {
  CareerDna? stored;
  @override
  Future<CareerDna?> load() async => stored;
  @override
  Future<CareerDna> save(CareerDna dna) async {
    stored = dna;
    return dna;
  }

  @override
  Future<List<CareerDna>> versions() async => const [];
  @override
  Future<GeneratedProfile> draftProfile({
    required String target,
    required String education,
    required String experience,
    required String skills,
  }) async =>
      throw UnimplementedError();
  @override
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  }) async =>
      throw UnimplementedError();
  @override
  Future<InterviewPrepPlan> generateInterviewPlan({
    required Map<String, dynamic> context,
    required List<String> focusAreas,
    required String language,
    String? targetRole,
    String? company,
  }) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> generateMockFeedback({
    required Map<String, dynamic> context,
    required String question,
    required String answer,
    required String focusArea,
    String? targetRole,
    String? company,
    required String language,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> aiIntake({
    required List<Map<String, dynamic>> history,
    String targetRole = '',
    String language = 'en',
    String mode = 'chat',
    String githubUsername = '',
  }) async => {};
}

class _FakeDocRepo implements CvDocumentRepository {
  @override
  Future<List<CvDocument>> loadDocuments() async => const [];
  @override
  Future<CvDocument?> loadDocument(String id) async => null;
  @override
  Future<void> deleteDocument(String id) async {}
  @override
  Future<List<CvVersion>> loadVersions(String documentId) async => const [];
  @override
  Future<CvVersion?> loadLatestVersion(String documentId) async => null;
  @override
  Future<CvVersion?> loadVersion(String versionId) async => null;
  @override
  Future<void> saveVersion(CvVersion version) async {}
  @override
  Future<CvDocument> createDocument(CvDocument document) async => document;
  @override
  Future<CvVersion> createVersion(CvVersion version) async => version;
}

class _FakeGenRepo implements CvGenerationRepository {
  @override
  Future<CvContent> generate({
    required CareerDna dna,
    required CareerTarget target,
    JobAnalysis? analysis,
    required String templateId,
    required String language,
    UserIdentity? identity,
  }) async =>
      throw UnimplementedError();
}

class _FakeTargetRepo implements CareerTargetRepository {
  @override
  Future<List<CareerTarget>> loadAll() async => const [];
  @override
  Future<CareerTarget?> loadById(String id) async => null;
  @override
  Future<CareerTarget> create(CareerTarget target) async => target;
  @override
  Future<CareerTarget> update(CareerTarget target) async => target;
  @override
  Future<void> delete(String id) async {}
}

class _FakeAnalysisRepo implements JobAnalysisRepository {
  @override
  Future<List<JobAnalysis>?> load() async => const [];
  @override
  Future<void> saveAll(List<JobAnalysis> analyses) async {}
  @override
  Future<JobAnalysis> analyze({
    required String description,
    required CareerDna dna,
    CareerTarget? target,
  }) async =>
      throw UnimplementedError();
}

class _FakeIdentityRepo implements UserIdentityRepository {
  @override
  Future<UserIdentity?> load() async => null;
  @override
  Future<void> save(UserIdentity identity) async {}
}

void main() {
  test('Factual CV reflects profile links after CareerDna sync', () async {
    final dnaRepo = _FakeDnaRepo();
    final cubit = CvCubit(
      _FakeDocRepo(),
      _FakeGenRepo(),
      dnaRepo,
      _FakeTargetRepo(),
      _FakeAnalysisRepo(),
      identityRepo: _FakeIdentityRepo(),
    );

    dnaRepo.stored = CareerDna(
      profile: ProfileData(
        projects: [
          ProfileProject(
            name: 'ShipLink',
            description: 'Shipping app',
            tech: const ['Flutter'],
            links: [ProjectLink(url: 'https://github.com/me/app')],
          ),
        ],
      ),
    );

    await cubit.load();
    await cubit.useFactual();

    final content = cubit.state.content!;
    expect(content.projects, hasLength(1));
    expect(content.projects.single.links, hasLength(1));
    expect(content.projects.single.links.single.url, 'https://github.com/me/app');

    await cubit.close();
  });
}
