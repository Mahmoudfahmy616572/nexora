import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/interview_prep.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/domain/repositories/career_target_repository.dart';
import 'package:nexora/domain/repositories/interview_practice_repository.dart';
import 'package:nexora/domain/repositories/job_analysis_repository.dart';
import 'package:nexora/features/main/presentation/prep/interview_practice_screen.dart';
import 'package:nexora/l10n/app_localizations.dart';

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
          PrepFocusArea(requirement: 'System design', question: 'Design X.'),
          PrepFocusArea(requirement: 'Behavioral', question: 'Hard bug?'),
          PrepFocusArea(requirement: 'Flutter', question: 'State mgmt?'),
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
  }) async =>
      {
        'strengths': ['Clear'],
        'improvements': ['Add metric'],
        'coaching': 'Use STAR.',
        'sketch': 'I once...',
      };

  @override
  Future<Map<String, dynamic>> aiIntake({
    required List<Map<String, dynamic>> history,
    String targetRole = '',
    String language = 'en',
    String mode = 'chat',
    String githubUsername = '',
  }) async => {};

  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeTarget implements CareerTargetRepository {
  @override
  Future<List<CareerTarget>> loadAll() async => const [];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeAnalysis implements JobAnalysisRepository {
  @override
  Future<List<JobAnalysis>?> load() async => const [];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required CareerDnaRepository dna,
  required InterviewPracticeRepository practiceRepo,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: InterviewPracticeScreen(
        extra: const {'role': 'Flutter Developer', 'company': 'Acme'},
        dnaRepository: dna,
        targetRepository: _FakeTarget(),
        analysisRepository: _FakeAnalysis(),
        practiceRepository: practiceRepo,
        userId: 'u',
      ),
    ),
  );
}

const _strong =
    'When we launched, I led the migration which improved performance by 40% '
    'using Flutter.';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('runs a full practice session and reaches the summary',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final practiceRepo = InterviewPracticeRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    await _pumpScreen(tester, dna: _FakeDna(), practiceRepo: practiceRepo);
    await tester.pumpAndSettle();

    // Ready: first question shown.
    expect(find.byType(TextField), findsOneWidget);

    // Answer all three questions. The feedback view has exactly one
    // FilledButton (Next question / See results) at the bottom of a scrollable
    // list, so scroll it into view before tapping.
    for (var i = 0; i < 3; i++) {
      await tester.enterText(find.byType(TextField), _strong);
      await tester.tap(find.widgetWithText(FilledButton, 'Submit answer'));
      await tester.pumpAndSettle();
      // Feedback view shows the coaching text from the AI.
      expect(find.textContaining('Use STAR'), findsWidgets);
      final nextBtn = find.byType(FilledButton, skipOffstage: false);
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
    }

    // Summary.
    expect(find.text('Practice summary'), findsOneWidget);
  });

  testWidgets('shows no-overflow with an empty/short answer', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final practiceRepo = InterviewPracticeRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    await _pumpScreen(tester, dna: _FakeDna(), practiceRepo: practiceRepo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I did my best.');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit answer'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Needs improvement'), findsWidgets);
  });
}
