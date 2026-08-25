import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/app.dart';
import 'package:nexora/core/di/shared_prefs.dart';
import 'package:nexora/core/localization/locale_cubit.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/data/data_sources/locale_local_data_source.dart';
import 'package:nexora/data/repositories/locale_repository_impl.dart';
import 'package:nexora/domain/entities/app_language.dart';

Future<void> tapNav(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('nav_$label'.toLowerCase())), warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> pumpAt(WidgetTester tester, Size size, AppLanguage language) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final prefs = await SharedPreferences.getInstance();
  // Mirror the app bootstrap in main(): the onboarding choices cubit (and other
  // repositories) read the shared global instance.
  kPrefs = prefs;
  final repository = LocaleRepositoryImpl(LocaleLocalDataSource(prefs));
  appRouter.go(Routes.main);
  await tester.pumpWidget(NexoraApp(
    localeCubit: LocaleCubit(initialLanguage: language, repository: repository),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    for (final (family, asset) in [
      ('Inter', 'assets/fonts/Inter-Regular.ttf'),
      ('Bricolage Grotesque', 'assets/fonts/BricolageGrotesque-Variable.ttf'),
      ('DM Mono', 'assets/fonts/DMMono-Regular.ttf'),
    ]) {
      final data = await rootBundle.load(asset);
      final loader = FontLoader(family);
      loader.addFont(Future.value(data));
      await loader.load();
    }
  });

  final sizes = <String, Size>{
    '320x640': const Size(320, 640),
    '360x740': const Size(360, 740),
    '390x844': const Size(390, 844),
    '414x896': const Size(414, 896),
    '768x1024': const Size(768, 1024),
    '1024x768': const Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    for (final language in [AppLanguage.english, AppLanguage.arabic]) {
      final langTag = language == AppLanguage.english ? 'EN' : 'AR';
      final isEn = language == AppLanguage.english;

      testWidgets('No overflow ($langTag) across all tabs at ${entry.key}', (tester) async {
        await pumpAt(tester, entry.value, language);

        final tabs = [
          ('home', 'Next best action'),
          ('dna', 'Personal Profile'),
          ('analyze', 'My Analyses'),
          ('studio', 'CV Studio'),
          ('track', 'PIPELINE'),
        ];

        for (final (label, marker) in tabs) {
          await tapNav(tester, label);
          if (isEn) {
            expect(find.text(marker), findsWidgets, reason: '$marker not rendered at ${entry.key}');
          }
          final exc = tester.takeException();
          if (exc is FlutterError) {
            FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: exc), forceReport: true);
          }
          expect(exc, isNull, reason: 'Overflow on $label ($langTag) at ${entry.key}');
        }

        // Exercise the Analyze form + a result card (English strings only).
        if (isEn) {
          await tapNav(tester, 'analyze');
          await tester.tap(find.text('New Analysis'));
          await tester.pumpAndSettle();
          expect(find.text('Analyze with AI'), findsWidgets);
          expect(tester.takeException(), isNull, reason: 'Overflow on analyze form at ${entry.key}');

          await tester.enterText(
            find.byType(TextField).first,
            'Flutter Developer\nDocker, CI/CD, Kubernetes, Python and AWS required.',
          );
          await tester.ensureVisible(find.text('Analyze with AI'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Analyze with AI'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Overflow on analyze result at ${entry.key}');
        }

        // Auth screens at this size.
        appRouter.go(Routes.welcome);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow on welcome ($langTag) at ${entry.key}');

        appRouter.go(Routes.onboarding);
        await tester.pumpAndSettle();
        if (isEn) {
          expect(find.text('01 · ANALYZE'), findsOneWidget, reason: 'onboarding not rendered at ${entry.key}');
        }
        expect(tester.takeException(), isNull, reason: 'Overflow on onboarding ($langTag) at ${entry.key}');

        appRouter.go(Routes.login);
        await tester.pumpAndSettle();
        if (isEn) {
          expect(find.text('Welcome back'), findsOneWidget, reason: 'login not rendered at ${entry.key}');
        }
        expect(tester.takeException(), isNull, reason: 'Overflow on login ($langTag) at ${entry.key}');

        // New Phase 1 onboarding + creation flow screens.
        for (final route in [
          Routes.goal,
          Routes.stage,
          Routes.field,
          Routes.intake,
          Routes.interview,
          Routes.dna,
        ]) {
          appRouter.go(route);
          await tester.pumpAndSettle();
          final exc = tester.takeException();
          if (exc is FlutterError) {
            FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: exc), forceReport: true);
          }
          expect(exc, isNull, reason: 'Overflow on $route ($langTag) at ${entry.key}');
        }

        appRouter.go(Routes.verify);
        await tester.pumpAndSettle();
        if (isEn) {
          expect(find.text('Verify your email'), findsOneWidget, reason: 'verify not rendered at ${entry.key}');
        }
        expect(tester.takeException(), isNull, reason: 'Overflow on verify ($langTag) at ${entry.key}');
      });
    }
  }
}
