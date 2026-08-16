import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/app.dart';
import 'package:nexora/core/localization/locale_cubit.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/data/data_sources/locale_local_data_source.dart';
import 'package:nexora/data/repositories/locale_repository_impl.dart';
import 'package:nexora/domain/entities/app_language.dart';
import 'package:nexora/features/main/presentation/analyze_screen.dart';
import 'package:nexora/features/main/presentation/dna_screen.dart';
import 'package:nexora/features/main/presentation/home_screen.dart';
import 'package:nexora/features/main/presentation/studio_screen.dart';
import 'package:nexora/features/main/presentation/tracker_screen.dart';

void main() {
  setUpAll(() async {
    // Isolate the language preference from any persisted device state.
    SharedPreferences.setMockInitialValues({});

    // Load the real fonts so text metrics match production devices
    // (the default test font renders every glyph as a full em square).
    for (final (family, asset) in [
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
      ('Bricolage Grotesque', 'assets/fonts/BricolageGrotesque-Variable.ttf'),
      ('DM Mono', 'assets/fonts/DMMono-Regular.ttf'),
    ]) {
      final data = await rootBundle.load(asset);
      final loader = FontLoader(family);
      loader.addFont(Future.value(data));
      await loader.load();
    }
  });

  Future<void> pumpAt(WidgetTester tester, Size size, {String path = Routes.main}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final prefs = await SharedPreferences.getInstance();
    final repository = LocaleRepositoryImpl(LocaleLocalDataSource(prefs));
    appRouter.go(Routes.main);
    await tester.pumpWidget(NexoraApp(
      localeCubit: LocaleCubit(
        initialLanguage: AppLanguage.english,
        repository: repository,
      ),
    ));
    if (path != Routes.main) {
      appRouter.go(path);
      await tester.pumpAndSettle();
    }
  }

  Finder inScreen<T>(String text) => find.descendant(
        of: find.byType(T),
        matching: find.text(text),
      );

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(ValueKey('nav_$label'.toLowerCase())));
    await tester.pumpAndSettle();
  }

  testWidgets('App shell renders all five nav destinations', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    for (final label in ['home', 'dna', 'analyze', 'studio', 'track']) {
      expect(find.byKey(ValueKey('nav_$label')), findsOneWidget);
    }

    // Home is the initial tab.
    expect(inScreen<HomeScreen>('Ahmed Al-Rashidi'), findsOneWidget);
    expect(inScreen<HomeScreen>('Career DNA Health'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home quick actions switch the active tab', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    Future<void> goHome() async {
      await tester.tap(find.byKey(const ValueKey('nav_home')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Analyze Job'));
    await tester.pumpAndSettle();
    expect(inScreen<AnalyzeScreen>('STRONG MATCHES ✓'), findsOneWidget);

    await goHome();
    await tester.tap(find.text('Create CV'));
    await tester.pumpAndSettle();
    expect(inScreen<StudioScreen>('CV Studio'), findsOneWidget);

    await goHome();
    await tester.tap(find.text('Track Apps'));
    await tester.pumpAndSettle();
    expect(inScreen<TrackerScreen>('Applications'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Career DNA screen renders sections', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'DNA');

    expect(inScreen<DnaScreen>('Career DNA'), findsOneWidget);
    expect(inScreen<DnaScreen>('Personal Profile'), findsOneWidget);
    expect(inScreen<DnaScreen>('Achievements'), findsWidgets);
    expect(find.textContaining('Add Volunteering'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Career DNA sections open real editors and can be added', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'DNA');

    // Tapping a base section opens its real-data editor.
    await tester.tap(find.text('Experience'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(inScreen<DnaScreen>('Experience'), findsWidgets);

    // Let the confirmation snackbar dismiss so it doesn't cover the add row.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Adding a new section is reflected in the section list.
    final addRow = find.textContaining('Add Volunteering');
    await tester.scrollUntilVisible(addRow, -80);
    await tester.pumpAndSettle();
    await tester.tap(addRow);
    await tester.pumpAndSettle();
    expect(find.text('Add a section'), findsOneWidget);
    await tester.tap(find.text('Add Section'));
    await tester.pumpAndSettle();
    expect(find.text('Volunteering'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit Profile opens the full-screen editor and saves', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'DNA');
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsWidgets);
    expect(find.text('Experience'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);

    // Save persists without errors.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(inScreen<DnaScreen>('Career DNA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opportunity analyzer shows matches and missing skills', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Analyze');

    expect(inScreen<AnalyzeScreen>('STRONG MATCHES ✓'), findsOneWidget);
    expect(inScreen<AnalyzeScreen>('MISSING SKILLS ✗'), findsOneWidget);
    expect(inScreen<AnalyzeScreen>('Flutter'), findsOneWidget);
    expect(inScreen<AnalyzeScreen>('Docker'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New analysis runs, extracts requirements, and can be removed', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Analyze');
    await tester.tap(find.text('New Analysis'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Senior Flutter Engineer\nDocker and CI/CD experience expected',
    );
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    expect(find.text('Analyzing…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Newest analysis is listed first with the derived title; skills that were
    // mentioned in the description move out of "missing".
    expect(inScreen<AnalyzeScreen>('Senior Flutter Engineer'), findsOneWidget);
    expect(find.text('CI/CD'), findsWidgets);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(inScreen<AnalyzeScreen>('Senior Flutter Engineer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New analysis scores requirements and writes a tailored recommendation', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Analyze');
    await tester.tap(find.text('New Analysis'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Senior Backend Engineer\n'
      'We need strong Python and AWS experience.\n'
      "Master's degree preferred. 5+ years required.",
    );
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    expect(find.text('Analyzing…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Requirements the candidate lacks surface as missing-skill chips.
    expect(find.text('Python'), findsWidgets);
    expect(find.text('AWS'), findsWidgets);

    // A candidate-specific (not hardcoded) recommendation is generated.
    expect(find.textContaining('to your CV'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Full flow: home opens analyze and runs a complete offline analysis', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    // Home -> Analyze via the quick action.
    await tester.tap(find.text('Analyze Job'));
    await tester.pumpAndSettle();
    expect(inScreen<AnalyzeScreen>('New Analysis'), findsOneWidget);

    // Switch to the new-analysis form and run a real offline analysis.
    await tester.tap(find.text('New Analysis'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Flutter Developer\nExperience with Firebase and GraphQL required.',
    );
    await tester.tap(find.text('Analyze with AI'));
    await tester.pump();
    expect(find.text('Analyzing…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // The newest analysis is listed first with the derived title.
    expect(inScreen<AnalyzeScreen>('Flutter Developer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CV Studio renders CVs and templates', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Studio');

    expect(inScreen<StudioScreen>('CV Studio'), findsOneWidget);
    expect(inScreen<StudioScreen>('Flutter Engineer'), findsWidgets);
    expect(inScreen<StudioScreen>('ATS Minimal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New CV is created and can be optimized', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Studio');

    await tester.tap(find.text('New CV'));
    await tester.pumpAndSettle();
    expect(find.text('Create a new CV'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Lead Engineer');
    await tester.tap(find.text('Create CV'));
    await tester.pumpAndSettle();

    // New CV appears first and the count is updated. ATS = 84 + (13 % 7) = 90.
    expect(inScreen<StudioScreen>('MY CVS (4)'), findsOneWidget);
    expect(inScreen<StudioScreen>('Lead Engineer'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);

    // Optimizing raises the ATS score (90 -> 96).
    await tester.tap(find.text('Optimize').first);
    await tester.pump();
    expect(find.text('Optimizing…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Optimization complete'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('96'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Application tracker renders pipeline and apps', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Track');

    expect(inScreen<TrackerScreen>('Applications'), findsOneWidget);
    expect(inScreen<TrackerScreen>('PIPELINE'), findsOneWidget);
    expect(inScreen<TrackerScreen>('Google'), findsWidgets);
    expect(inScreen<TrackerScreen>('Offer 🎉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tracker adds, advances, and removes an application', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Track');

    // Seed totals: 5 applications, none in the "Applied" stage.
    Text statText(String key) => tester.widget<Text>(find.byKey(ValueKey(key)));
    expect(statText('stat_total').data, '5');
    expect(statText('pipe_applied').data, '0');

    // Add a new application.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Tesla');
    await tester.enterText(find.byType(TextField).at(1), 'Flutter Developer');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Application'));
    await tester.pumpAndSettle();

    expect(inScreen<TrackerScreen>('Tesla'), findsOneWidget);
    expect(statText('stat_total').data, '6');
    expect(statText('pipe_applied').data, '1');

    // Advance it to the Interview stage.
    await tester.tap(find.text('Tesla'));
    await tester.pumpAndSettle();
    expect(find.text('Move to'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Interview'));
    await tester.pumpAndSettle();
    expect(statText('pipe_interview').data, '2');
    expect(statText('pipe_applied').data, '0');

    // Remove it again.
    await tester.tap(find.text('Tesla'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete application'));
    await tester.pumpAndSettle();
    expect(inScreen<TrackerScreen>('Tesla'), findsNothing);
    expect(statText('stat_total').data, '5');
    expect(tester.takeException(), isNull);
  });

  testWidgets('App shell renders on narrow device without overflow', (tester) async {
    await pumpAt(tester, const Size(320, 700));

    expect(inScreen<HomeScreen>('Ahmed Al-Rashidi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty Career DNA shows the build nudge and opens the Smart Builder', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    // Jump to the DNA tab via the bottom navigation.
    await tester.tap(find.byKey(const ValueKey('nav_dna')));
    await tester.pumpAndSettle();

    // With no profile stored, the hero empty-state nudge is shown.
    expect(inScreen<DnaScreen>('Your Career DNA is empty'), findsOneWidget);
    expect(inScreen<DnaScreen>('Build with Nexora'), findsOneWidget);

    // Tapping it launches the Smart Builder.
    await tester.tap(inScreen<DnaScreen>('Build with Nexora'));
    await tester.pumpAndSettle();

    expect(find.text('What do you enjoy?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding flows through all three slides', (tester) async {
    await pumpAt(tester, const Size(390, 844), path: Routes.onboarding);

    expect(find.text('01 · ANALYZE'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('02 · BUILD'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('03 · TRACK'), findsOneWidget);
    expect(find.text('Create my career DNA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sign in screen renders and toggles to create account', (tester) async {
    await pumpAt(tester, const Size(390, 844), path: Routes.login);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('FULL NAME'), findsNothing);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verify email screen renders OTP entry and auto-advance', (tester) async {
    await pumpAt(tester, const Size(390, 844), path: Routes.verify);

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('Resend in 0:30'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
    }
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Pre-auth screens render on narrow device without overflow', (tester) async {
    await pumpAt(tester, const Size(320, 700), path: Routes.onboarding);

    expect(find.text('01 · ANALYZE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    appRouter.go(Routes.login);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);

    appRouter.go(Routes.verify);
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
