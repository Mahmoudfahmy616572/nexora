import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/data/data_sources/career_local_data_source.dart';
import 'package:nexora/data/data_sources/career_remote_data_source.dart';
import 'package:nexora/data/repositories/career_dna_repository_impl.dart';
import 'package:nexora/data/repositories/career_repository_impl.dart';
import 'package:nexora/features/main/presentation/prep/interview_prep_screen.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote extends CareerRemoteDataSource {
  Map<String, dynamic>? interviewResult;
  bool runThrows = false;

  @override
  Future<Map<String, dynamic>> runAiInterview(Map<String, dynamic> body) async {
    if (runThrows) throw StateError('ai unavailable');
    return interviewResult ?? const {'done': true, 'profile': {}};
  }
}

class _FakeLocal extends CareerLocalDataSource {
  _FakeLocal() : super(null);
}

Widget _wrap(InterviewPrepScreen screen) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  InterviewPrepScreen buildScreen(_FakeRemote remote) => InterviewPrepScreen(
        extra: const {'role': 'Flutter Dev', 'company': 'Acme'},
        dnaRepository:
            CareerDnaRepositoryImpl(remote: remote, local: _FakeLocal()),
        targetRepository: CareerTargetRepositoryImpl(remote, _FakeLocal()),
        analysisRepository: JobAnalysisRepositoryImpl(remote, _FakeLocal()),
      );

  testWidgets('AI failure shows the deterministic fallback banner',
      (tester) async {
    final remote = _FakeRemote()..runThrows = true;

    await tester.pumpWidget(_wrap(buildScreen(remote)));
    await tester.pumpAndSettle();

    expect(find.byType(InterviewPrepScreen), findsOneWidget);
    expect(find.textContaining('AI is unavailable'), findsOneWidget);
    // Nothing fabricated: no focus areas without analysis/skills.
    expect(find.textContaining('Nothing to prepare yet'), findsOneWidget);
  });

  testWidgets('renders the grounded plan when AI responds', (tester) async {
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

    await tester.pumpWidget(_wrap(buildScreen(remote)));
    await tester.pumpAndSettle();

    expect(find.text('System design'), findsOneWidget);
    expect(find.textContaining('Tell me about a hard bug'), findsOneWidget);
    expect(find.textContaining('Be concrete about impact'), findsOneWidget);
    // No warning banner on the happy path.
    expect(find.textContaining('AI is unavailable'), findsNothing);
  });
}
