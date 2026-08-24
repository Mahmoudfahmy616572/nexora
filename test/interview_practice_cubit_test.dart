import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/interview_practice_session.dart';
import 'package:nexora/domain/entities/interview_prep.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/practice/interview_practice_engine.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/domain/repositories/career_target_repository.dart';
import 'package:nexora/domain/repositories/interview_practice_repository.dart';
import 'package:nexora/domain/repositories/job_analysis_repository.dart';
import 'package:nexora/features/main/presentation/prep/interview_practice_cubit.dart';

CareerDna _sampleDna() => CareerDna(
      stage: CareerStage.freshGraduate,
      targetRole: 'Flutter Developer',
      targetField: TargetField.programming,
      skills: const ['Dart', 'Flutter'],
      profile: const ProfileData(
        education: [ProfileEducation(degree: 'BSc', field: 'CS')],
      ),
    );

class _FakeDna implements CareerDnaRepository {
  bool mockThrows = false;

  @override
  Future<CareerDna?> load() async => _sampleDna();

  @override
  Future<InterviewPrepPlan> generateInterviewPlan({
    required Map<String, dynamic> context,
    required List<String> focusAreas,
    required String language,
    String? targetRole,
    String? company,
  }) async =>
      InterviewPrepPlan(
        focusAreas: const [
          PrepFocusArea(
            requirement: 'System design',
            question: 'Design a URL shortener.',
          ),
          PrepFocusArea(
            requirement: 'Behavioral',
            question: 'Tell me about a hard bug.',
          ),
          PrepFocusArea(
            requirement: 'Flutter',
            question: 'How do you manage state?',
          ),
        ],
      );

  @override
  Future<Map<String, dynamic>> generateMockFeedback({
    required Map<String, dynamic> context,
    required String question,
    required String answer,
    required String focusArea,
    String? targetRole,
    String? company,
    required String language,
  }) async {
    if (mockThrows) throw StateError('ai down');
    return {
      'strengths': ['Clear example'],
      'improvements': ['Add a metric'],
      'coaching': 'Use STAR.',
      'sketch': 'I once...',
    };
  }

  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeTarget implements CareerTargetRepository {
  @override
  Future<List<CareerTarget>> loadAll() async => [
        CareerTarget(
          id: 't1',
          userId: 'u',
          type: TargetType.job,
          role: 'Flutter Developer',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeAnalysis implements JobAnalysisRepository {
  @override
  Future<List<JobAnalysis>?> load() async => const [];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

InterviewPracticeCubit _build(
  _FakeDna dna, {
  required InterviewPracticeRepository practiceRepo,
}) =>
    InterviewPracticeCubit(
      dnaRepository: dna,
      targetRepository: _FakeTarget(),
      analysisRepository: _FakeAnalysis(),
      practiceRepository: practiceRepo,
      userId: 'u',
      role: 'Flutter Developer',
      company: 'Acme',
      language: 'en',
    );

const _strong = 'When we launched, I led the migration which improved '
    'performance by 40% using Flutter.';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('start builds a queue and submit/next/finish produces a scored session',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final practiceRepo = InterviewPracticeRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    final dna = _FakeDna();
    final cubit = _build(dna, practiceRepo: practiceRepo);

    await cubit.start();
    expect(cubit.state.status, InterviewPracticeStatus.ready);
    expect(cubit.state.queue.length, 3);
    expect(cubit.state.aiUnavailable, isFalse);

    // Answer every question.
    for (var i = 0; i < cubit.state.queue.length; i++) {
      expect(cubit.state.status, InterviewPracticeStatus.ready);
      await cubit.submitAnswer(_strong);
      expect(cubit.state.status, InterviewPracticeStatus.feedback);
      final turn = cubit.state.lastTurn!;
      expect(turn.compositeScore, inInclusiveRange(0, 100));
      expect(turn.coachingSketch, contains('STAR'));
      await cubit.next();
    }

    expect(cubit.state.status, InterviewPracticeStatus.completed);
    expect(cubit.state.session!.status, PracticeStatus.completed);
    expect(cubit.state.session!.overallScore, inInclusiveRange(0, 100));

    // Persisted: a completed session is now in the store.
    final recent = await practiceRepo.loadRecent(10);
    expect(recent, isNotEmpty);
    expect(recent.first.status, PracticeStatus.completed);
  });

  test('AI failure falls back to deterministic coaching (no throw)', () async {
    final prefs = await SharedPreferences.getInstance();
    final practiceRepo = InterviewPracticeRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    final dna = _FakeDna()..mockThrows = true;
    final cubit = _build(dna, practiceRepo: practiceRepo);

    await cubit.start();
    await cubit.submitAnswer('I think I did a good job.');
    expect(cubit.state.aiUnavailable, isTrue);
    expect(cubit.state.lastTurn!.coachingSketch,
        InterviewPracticeEngine.deterministicCoachingHint);
  });
}
