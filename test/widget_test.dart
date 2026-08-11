import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/app.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/features/main/presentation/analyze_screen.dart';
import 'package:nexora/features/main/presentation/dna_screen.dart';
import 'package:nexora/features/main/presentation/home_screen.dart';
import 'package:nexora/features/main/presentation/studio_screen.dart';
import 'package:nexora/features/main/presentation/tracker_screen.dart';

void main() {
  setUpAll(() async {
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
    appRouter.go(Routes.main);
    await tester.pumpWidget(const NexoraApp());
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

  testWidgets('Career DNA screen renders sections', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'DNA');

    expect(inScreen<DnaScreen>('Career DNA'), findsOneWidget);
    expect(inScreen<DnaScreen>('Personal Profile'), findsOneWidget);
    expect(inScreen<DnaScreen>('Achievements'), findsWidgets);
    expect(find.textContaining('Add Volunteering'), findsWidgets);
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

  testWidgets('CV Studio renders CVs and templates', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await tapNav(tester, 'Studio');

    expect(inScreen<StudioScreen>('CV Studio'), findsOneWidget);
    expect(inScreen<StudioScreen>('Flutter Engineer'), findsWidgets);
    expect(inScreen<StudioScreen>('ATS Minimal'), findsOneWidget);
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

  testWidgets('App shell renders on narrow device without overflow', (tester) async {
    await pumpAt(tester, const Size(320, 700));

    expect(inScreen<HomeScreen>('Ahmed Al-Rashidi'), findsOneWidget);
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

  testWidgets('Pre-auth screens render on narrow device without overflow', (tester) async {
    await pumpAt(tester, const Size(320, 700), path: Routes.onboarding);

    expect(find.text('01 · ANALYZE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    appRouter.go(Routes.login);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
