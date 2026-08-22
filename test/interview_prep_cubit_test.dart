import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_dna_repository_impl.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/features/main/presentation/prep/interview_prep_cubit.dart';

/// Remote that only implements the AI call; every other method hits the real
/// Supabase path and throws in tests, exercising the local fallback.
class _FakeRemote extends CareerRemoteDataSource {
  Map<String, dynamic>? interviewResult;
  bool runThrows = false;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> runAiInterview(Map<String, dynamic> body) async {
    lastBody = body;
    if (runThrows) throw StateError('ai unavailable');
    return interviewResult ?? const {'done': true, 'profile': {}};
  }
}

class _FakeLocal extends CareerLocalDataSource {
  _FakeLocal() : super(null);
}

void main() {
  InterviewPrepCubit buildCubit(_FakeRemote remote) => InterviewPrepCubit(
        dnaRepository: CareerDnaRepositoryImpl(remote: remote, local: _FakeLocal()),
        targetRepository: CareerTargetRepositoryImpl(remote, _FakeLocal()),
        analysisRepository: JobAnalysisRepositoryImpl(remote, _FakeLocal()),
      );

  test('prepare emits loading then the AI plan (interview_plan mode)', () async {
    final remote = _FakeRemote()
      ..interviewResult = {
        'done': true,
        'plan': {
          'focusAreas': [
            {
              'requirement': 'System design',
              'why': 'Senior roles expect it',
              'question': 'Design a URL shortener.',
              'coaching': 'Practice one design per day.',
            },
          ],
          'likelyQuestions': ['Tell me about a hard bug.'],
          'tips': 'Be concrete about impact.',
        },
      };
    final cubit = buildCubit(remote);
    final states = <InterviewPrepState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.prepare(role: 'Flutter Dev', company: 'Acme', language: 'en');

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.first.status, InterviewPrepStatus.loading);
    expect(states.last.status, InterviewPrepStatus.success);
    expect(states.last.analysisAvailable, isFalse);
    final plan = states.last.plan!;
    expect(plan.deterministicOnly, isFalse);
    expect(plan.focusAreas.single.requirement, 'System design');
    expect(plan.likelyQuestions, ['Tell me about a hard bug.']);
    // The AI request was grounded and labelled with the plan mode.
    expect(remote.lastBody?['mode'], 'interview_plan');
    expect(remote.lastBody?['targetRole'], 'Flutter Dev');
    expect(remote.lastBody?['company'], 'Acme');
  });

  test('AI failure falls back to a deterministic-only plan', () async {
    final remote = _FakeRemote()..runThrows = true;
    final cubit = buildCubit(remote);
    final states = <InterviewPrepState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.prepare(role: 'Data Analyst', company: '', language: 'ar');

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.last.status, InterviewPrepStatus.fallback);
    final plan = states.last.plan!;
    expect(plan.deterministicOnly, isTrue);
    expect(states.last.role, 'Data Analyst');
    expect(states.last.company, '');
  });

  test('store failures are contained: no DNA/targets still reaches AI', () async {
    // Base-class fetches throw because Supabase is not initialized; local
    // fallback has nothing stored. The pipeline must still call the AI once.
    final remote = _FakeRemote()
      ..interviewResult = {
        'done': true,
        'plan': {'focusAreas': <Map<String, dynamic>>[], 'tips': ''},
      };
    final cubit = buildCubit(remote);

    await cubit.prepare(role: 'Any Role', company: 'Any', language: 'en');

    expect(cubit.state.status, InterviewPrepStatus.success);
    expect(cubit.state.plan!.focusAreas, isEmpty);
  });
}
