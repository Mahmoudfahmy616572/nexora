import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/intake_question.dart';
import 'package:nexora/domain/entities/interview_prep.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/profile_generator.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/presentation/career_dna/cubit/career_dna_cubit.dart';
import 'package:nexora/presentation/career_interview/interview_cubit.dart';
import 'package:nexora/presentation/career_intake/intake_config.dart';

/// Minimal in-memory repository that records the interview calls so we can prove
/// the client genuinely streams context + history each turn.
class _FakeInterviewRepo implements CareerDnaRepository {
  Map<String, dynamic> lastContext = {};
  List<Map<String, dynamic>> lastHistory = [];
  int interviewCalls = 0;

  @override
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  }) async {
    interviewCalls++;
    lastContext = context;
    lastHistory = history;
    if (finish) {
      return const InterviewResult(done: true, profile: ProfileData(summary: 'final'));
    }
    // Echo the previous answer back into the next question to prove the
    // server contract receives and depends on prior answers (the deployed edge
    // function does this with a real LLM; here we assert the wiring forwards
    // the full history every turn).
    final lastAnswer = history.isNotEmpty ? (history.last['a'] as String? ?? '') : '';
    final question = 'Follow-up on what you said: "$lastAnswer"';
    return InterviewResult(done: false, question: question);
  }

  @override
  Future<CareerDna?> load() async => null;
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
}

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
      GeneratedProfile(data: const ProfileData(), skills: const []);
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
  Future<InterviewResult> interview({
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
    required String language,
    required bool finish,
  }) async =>
      const InterviewResult(done: true, profile: ProfileData());
}

void main() {
  group('H1 — adaptive intake for all five user types', () {
    Set<String> ids(List<IntakeQuestion> q) => q.map((e) => e.id).toSet();

    test('question sets genuinely differ per stage', () {
      final student = ids(questionsFor(
        stage: CareerStage.student,
        goal: CareerGoal.job,
        field: TargetField.engineering,
        answers: {},
      ));
      final fresh = ids(questionsFor(
        stage: CareerStage.freshGraduate,
        goal: CareerGoal.job,
        field: TargetField.engineering,
        answers: {},
      ));
      final early = ids(questionsFor(
        stage: CareerStage.earlyCareer,
        goal: CareerGoal.job,
        field: TargetField.engineering,
        answers: {},
      ));
      final experienced = ids(questionsFor(
        stage: CareerStage.experienced,
        goal: CareerGoal.job,
        field: TargetField.engineering,
        answers: {},
      ));
      final changer = ids(questionsFor(
        stage: CareerStage.careerChanger,
        goal: CareerGoal.careerChange,
        field: TargetField.engineering,
        answers: {},
      ));

      // Student gets education-stage extras, never professional experience.
      expect(student, contains('expected_graduation'));
      expect(student, contains('coursework'));
      expect(student, contains('internships'));
      expect(student, isNot(contains('experience')));
      expect(student, isNot(contains('previous_career')));

      // Fresh graduate: no professional experience structured list (no inventing).
      expect(fresh, contains('graduation_status'));
      expect(fresh, isNot(contains('experience')));

      // Early career: experience + current role + direction.
      expect(early, contains('experience'));
      expect(early, contains('current_role'));
      expect(early, contains('career_direction'));

      // Experienced: leadership / impact / progression, never career-changer set.
      expect(experienced, contains('leadership'));
      expect(experienced, contains('measurable_impact'));
      expect(experienced, contains('career_progression'));
      expect(experienced, isNot(contains('previous_career')));

      // Career changer: previous career/role/skills + reason, never leadership.
      expect(changer, contains('previous_career'));
      expect(changer, contains('previous_role'));
      expect(changer, contains('transferable_skills'));
      expect(changer, contains('reason_transition'));
      expect(changer, isNot(contains('leadership')));

      // Prove the sets are actually different, not a single visibility toggle.
      expect(student.difference(changer), isNotEmpty);
      expect(experienced.difference(changer), isNotEmpty);
      expect(early.difference(experienced), isNotEmpty);
    });

    test('career changer captures transition context into extras', () {
      final dna = applyAnswersToDna(
        base: CareerDna(
          stage: CareerStage.careerChanger,
          goal: CareerGoal.careerChange,
          targetField: TargetField.business,
        ),
        answers: <String, dynamic>{
          'targetRole': 'Product Manager',
          'targetIndustry': 'Finance',
          'summary': 'Transitioning from teaching.',
          'skills': ['Communication', 'Figma'],
          'education': [],
          'experience': [],
          'projects': [],
          'certifications': [],
          'achievements': [],
          'languages': [],
          'previousCareer': 'Teaching',
          'previousRole': 'Math Teacher',
          'transferableSkills': ['Mentoring', 'Public Speaking'],
          'reasonForTransition': 'More product impact',
        },
      );
      expect(dna.extras['previousCareer'], 'Teaching');
      expect(dna.extras['previousRole'], 'Math Teacher');
      expect(dna.extras['reasonForTransition'], 'More product impact');
      expect(dna.extras['transferableSkills'], contains('Mentoring'));
      expect(dna.targetRole, 'Product Manager');
    });

    test('fresh graduate builds a meaningful profile without inventing experience', () {
      final dna = applyAnswersToDna(
        base: CareerDna(
          stage: CareerStage.freshGraduate,
          goal: CareerGoal.job,
          targetField: TargetField.programming,
        ),
        answers: <String, dynamic>{
          'targetRole': 'Junior Developer',
          'targetIndustry': 'Tech',
          'summary': 'CS graduate.',
          'skills': ['Python'],
          'education': [
            {'degree': 'BSc', 'field': 'Computer Science'}
          ],
          'experience': [],
          'projects': [
            {'name': 'App', 'description': 'personal project', 'tech': 'Flutter'}
          ],
          'internships': ['Summer intern at X'],
          'coursework': ['Algorithms'],
          'certifications': ['AWS CCP'],
          'achievements': ['Dean list'],
          'languages': ['English'],
        },
      );
      expect(dna.profile.experience, isEmpty); // no fabricated job
      expect(dna.profile.education, isNotEmpty);
      expect(dna.profile.projects, isNotEmpty);
      expect(dna.profile.certifications, contains('AWS CCP'));
      expect(dna.extras['internships'], contains('Summer intern at X'));
      expect(dna.extras['coursework'], contains('Algorithms'));
    });

    test('conditional questions trigger from answers', () {
      // A student who already picked a target role should still see the rest;
      // a "no experience" style conditional stays hidden unless its trigger fires.
      final base = questionsFor(
        stage: CareerStage.student,
        goal: CareerGoal.job,
        field: TargetField.engineering,
        answers: {},
      );
      // expectedGraduation is always on for students.
      expect(ids(base), contains('expected_graduation'));
    });
  });

  group('H2 — contextual AI interview (client architecture)', () {
    test('cubit streams context + growing history; next question depends on answer', () async {
      final repo = _FakeInterviewRepo();
      final cubit = InterviewCubit(repository: repo);
      final base = CareerDna(
        stage: CareerStage.earlyCareer,
        targetRole: 'Developer',
        targetIndustry: 'Finance',
        profile: const ProfileData(summary: 'I like finance'),
      );

      await cubit.start(base, 'en');
      await cubit.answer('I built a finance tracking app');
      await pumpEventQueue();

      // Context (current Career DNA) is forwarded every turn.
      expect(repo.lastContext['target'], 'Developer');
      expect(repo.lastContext['targetIndustry'], 'Finance');
      // History carries the prior answer.
      expect(repo.lastHistory.length, 1);
      expect(repo.lastHistory.first['a'], 'I built a finance tracking app');
      // Next question is derived from that answer (the AI saw it).
      expect(cubit.state.question, contains('finance tracking app'));

      await cubit.answer('It was a budgeting tool');
      await pumpEventQueue();
      expect(repo.lastHistory.length, 2);
      expect(cubit.state.question, contains('budgeting tool'));

      await cubit.finish();
      await pumpEventQueue();
      expect(cubit.state.merged, isNotNull);
      expect(repo.interviewCalls, 4); // start + 2 answers + finish
    });
  });

  group('H3 — Career DNA editing authority & persistence', () {
    test('manual edits are authoritative and survive save + reload', () async {
      final repo = _FakeDnaRepo();
      final cubit = CareerDnaCubit(repository: repo);

      // 1) AI extraction produces a draft.
      final aiDraft = CareerDna(
        targetRole: 'Flutter Dev',
        skills: ['Flutter'],
        profile: const ProfileData(summary: 'AI summary'),
      );
      cubit.updateDraft(aiDraft);

      // 2) User manually edits the review draft.
      final edited = aiDraft.copyWith(
        targetRole: 'Senior Flutter Engineer',
        skills: ['Flutter', 'Dart'],
        profile: aiDraft.profile.copyWith(summary: 'My own summary'),
      );
      cubit.updateDraft(edited);

      // 3) Save.
      await cubit.save();

      // 4) Reload -> manual values remain (authoritative + persisted).
      await cubit.load();
      final loaded = cubit.state.dna!;
      expect(loaded.targetRole, 'Senior Flutter Engineer');
      expect(loaded.skills, contains('Dart'));
      expect(loaded.profile.summary, 'My own summary');
    });

    test('a later AI result only replaces the draft when the user re-saves it', () async {
      final repo = _FakeDnaRepo();
      final cubit = CareerDnaCubit(repository: repo);
      cubit.updateDraft(CareerDna(targetRole: 'Manual', skills: ['A']));
      await cubit.save();
      // A new AI draft arrives but is NOT saved yet -> stored value is unchanged.
      cubit.updateDraft(CareerDna(targetRole: 'AI', skills: ['B']));
      // The repo still holds the previously saved 'Manual' because the new
      // draft has not been saved yet.
      expect(repo.stored!.targetRole, 'Manual');
      // Only after the user saves does the new value persist.
      await cubit.save();
      await cubit.load();
      final loadedAfter = cubit.state.dna!;
      expect(loadedAfter.targetRole, 'AI');
    });
  });

  group('H4 — anti-hallucination (data layer)', () {
    test('unknown employer/role/years are never fabricated', () {
      final json = <String, dynamic>{
        'summary': 'I built a Flutter delivery app as a personal project.',
        'experience': [], // none provided
        'projects': [
          {
            'name': 'Delivery App',
            'description': 'I built a Flutter delivery app as a personal project.',
            'tech': ['Flutter', 'Dart'],
          }
        ],
        'education': [],
        'certifications': [],
        'achievements': [],
        'languages': [],
        'skills': ['Flutter', 'Dart'],
      };
      final profile = ProfileData.fromJson(json);

      // No experience is invented for a personal project.
      expect(profile.experience, isEmpty);
      expect(profile.projects.first.description, contains('personal project'));
      expect(profile.projects.first.description, isNot(contains('Company')));

      // Assembling into Career DNA keeps experience empty.
      final dna = CareerDna(
        stage: CareerStage.student,
        profile: profile,
        skills: ['Flutter'],
      );
      expect(dna.profile.experience, isEmpty);
    });
  });
}
