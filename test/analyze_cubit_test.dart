import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/interview_prep.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/opportunity_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/profile_generator.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/domain/repositories/career_target_repository.dart';
import 'package:nexora/domain/repositories/job_analysis_repository.dart';
import 'package:nexora/features/main/presentation/analyze/cubit/analyze_cubit.dart';
import 'package:nexora/features/main/presentation/analyze/cubit/analyze_state.dart';

JobRequirement _req(String label, RequirementStatus status, {bool required = true}) =>
    JobRequirement(
      label: label,
      required: required,
      status: status,
      evidenceSource: EvidenceSource.none,
      evidenceText: 'x',
    );

JobAnalysis _analysis(String id) => JobAnalysis(
      id: id,
      title: 'Role $id',
      company: 'X',
      timeAgo: 'now',
      overall: 70,
      skills: 70,
      experience: 70,
      education: 70,
      keywords: 70,
      strong: const [],
      missing: const [],
      detail: OpportunityAnalysis(
        role: 'Role $id',
        requirements: const [],
        responsibilities: const [],
        technologies: const [],
        experienceItem: _req('Experience', RequirementStatus.unknown),
        educationItem: _req('Education', RequirementStatus.unknown),
        overall: 70,
        recommendationCategory: MatchCategory.good,
        recommendationText: 'Good match.',
      ),
    );

class FakeJobRepo implements JobAnalysisRepository {
  JobAnalysis? nextResult;
  String? lastDescription;
  List<JobAnalysis> saved = const [];
  final List<JobAnalysis> stored;

  FakeJobRepo({this.stored = const [], this.nextResult});

  @override
  Future<List<JobAnalysis>?> load() async => stored.isEmpty ? null : stored;

  @override
  Future<void> saveAll(List<JobAnalysis> items) async => saved = items;

  @override
  Future<JobAnalysis> analyze({
    required String description,
    CareerDna? dna,
    CareerTarget? target,
  }) async {
    lastDescription = description;
    return nextResult ?? _analysis('r1');
  }
}

class FakeDnaRepo implements CareerDnaRepository {
  CareerDna? next;
  @override
  Future<CareerDna?> load() async => next ?? CareerDna();
  @override
  Future<CareerDna> save(CareerDna dna) async => dna;
  @override
  Future<List<CareerDna>> versions() async => const [];
  @override
  Future<GeneratedProfile> draftProfile({
    required String target,
    required String education,
    required String experience,
    required String skills,
  }) async =>
      GeneratedProfile(data: const ProfileData(), skills: const []);
  @override
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  }) async =>
      const InterviewResult(done: true, profile: ProfileData());
  @override
  Future<InterviewPrepPlan> generateInterviewPlan({
    required Map<String, dynamic> context,
    required List<String> focusAreas,
    required String language,
    String? targetRole,
    String? company,
  }) async =>
      const InterviewPrepPlan(focusAreas: []);

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
      const {};

  @override
  Future<Map<String, dynamic>> aiIntake({
    required List<Map<String, dynamic>> history,
    String targetRole = '',
    String language = 'en',
    String mode = 'chat',
    String githubUsername = '',
  }) async => {};
}

class FakeTargetRepo implements CareerTargetRepository {
  List<CareerTarget> next;
  FakeTargetRepo([this.next = const []]);
  @override
  Future<List<CareerTarget>> loadAll() async => next;
  @override
  Future<CareerTarget?> loadById(String id) async =>
      next.where((t) => t.id == id).firstOrNull;
  @override
  Future<CareerTarget> create(CareerTarget target) async => target;
  @override
  Future<CareerTarget> update(CareerTarget target) async => target;
  @override
  Future<void> delete(String id) async {}
}

void main() {
  group('AnalyzeCubit', () {
    test('load with no stored analyses emits empty status', () async {
      final cubit = AnalyzeCubit(
        FakeJobRepo(),
        FakeTargetRepo(),
        FakeDnaRepo(),
      );
      await cubit.load();
      expect(cubit.state.status, AnalyzeStatus.empty);
      expect(cubit.state.analyses, isEmpty);
      await cubit.close();
    });

    test('load surfaces stored analyses and targets', () async {
      final existing = _analysis('a1');
      final targets = [
        CareerTarget(
          id: 't1',
          userId: 'u',
          type: TargetType.job,
          role: 'Mobile Lead',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];
      final cubit = AnalyzeCubit(
        FakeJobRepo(stored: [existing]),
        FakeTargetRepo(targets),
        FakeDnaRepo(),
      );
      await cubit.load();
      expect(cubit.state.status, AnalyzeStatus.loaded);
      expect(cubit.state.analyses, hasLength(1));
      expect(cubit.state.targets, hasLength(1));
      await cubit.close();
    });

    test('analyze emits loading then success and prepends the result', () async {
      final jobRepo = FakeJobRepo();
      final cubit = AnalyzeCubit(jobRepo, FakeTargetRepo(), FakeDnaRepo());
      final states = <AnalyzeStatus>[];
      final sub = cubit.stream.map((s) => s.status).listen(states.add);

      await cubit.analyze(description: 'Flutter Engineer, 3+ years.');

      expect(states, contains(AnalyzeStatus.loading));
      expect(cubit.state.status, AnalyzeStatus.success);
      expect(cubit.state.analyses, hasLength(1));
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.result!.detail, isNotNull);
      expect(jobRepo.saved, hasLength(1));
      expect(jobRepo.lastDescription, 'Flutter Engineer, 3+ years.');
      await sub.cancel();
      await cubit.close();
    });

    test('empty description does not analyze and shows a message', () async {
      final jobRepo = FakeJobRepo();
      final cubit = AnalyzeCubit(jobRepo, FakeTargetRepo(), FakeDnaRepo());
      await cubit.analyze(description: '   ');
      expect(cubit.state.status, isNot(AnalyzeStatus.success));
      expect(cubit.state.message, isNotNull);
      expect(jobRepo.lastDescription, isNull);
      await cubit.close();
    });

    test('selectTarget updates the selected target id', () async {
      final cubit = AnalyzeCubit(FakeJobRepo(), FakeTargetRepo(), FakeDnaRepo());
      cubit.selectTarget('t1');
      expect(cubit.state.selectedTargetId, 't1');
      await cubit.close();
    });

    test('deleteAnalysis removes the entry and persists', () async {
      final existing = _analysis('a1');
      final jobRepo = FakeJobRepo(stored: [existing]);
      final cubit = AnalyzeCubit(jobRepo, FakeTargetRepo(), FakeDnaRepo());
      await cubit.load();
      await cubit.deleteAnalysis('a1');
      expect(cubit.state.analyses, isEmpty);
      expect(cubit.state.status, AnalyzeStatus.empty);
      expect(jobRepo.saved, isEmpty);
      await cubit.close();
    });
  });
}
