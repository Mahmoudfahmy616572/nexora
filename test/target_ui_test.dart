import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:nexora/presentation/target/target_form_screen.dart';
import 'package:nexora/presentation/target/target_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget withLocales(Widget child, [Locale locale = const Locale('en')]) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  group('Target screens render without overflow', () {
    testWidgets('empty list at mobile + desktop (EN)', (tester) async {
      for (final size in const [Size(320, 640), Size(1024, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(withLocales(const TargetListScreen()));
        await tester.pumpAndSettle();
        expect(find.text('No targets yet'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow at $size');
      }
    });

    testWidgets('list with a target renders the card (EN)', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final target = CareerTarget(
        id: CareerTarget.newId(),
        userId: 'u',
        type: TargetType.internship,
        role: 'Flutter Intern',
        industry: 'Fintech',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await prefs.setStringList('career_targets_v1', [jsonEncode(target.toJson())]);
      await tester.pumpWidget(withLocales(const TargetListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Flutter Intern'), findsOneWidget);
      expect(find.text('Internship'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('form (edit mode) at mobile + desktop (EN + AR/RTL)', (tester) async {
      final target = CareerTarget(
        id: CareerTarget.newId(),
        userId: 'u',
        type: TargetType.job,
        role: 'Backend Engineer',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      for (final (size, locale) in const [
        (Size(320, 1400), Locale('en')),
        (Size(1024, 1600), Locale('en')),
        (Size(360, 1400), Locale('ar')),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(withLocales(TargetFormScreen(target: target), locale));
        await tester.pumpAndSettle();
        // The save action is the only FilledButton in the form; assert on the
        // widget type so the check is locale-independent.
        expect(find.byType(FilledButton), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow at $size/${locale.languageCode}');
      }
    });
  });
}
