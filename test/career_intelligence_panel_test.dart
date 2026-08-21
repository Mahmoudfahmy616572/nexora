import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:nexora/presentation/career_intelligence/career_intelligence_panel.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget panel(CareerDna dna, ProfileData profile, List<String> skills) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CareerIntelligencePanel(dna: dna, profile: profile, skills: skills)),
      );

  testWidgets('panel renders for an interview-ready profile without overflow', (tester) async {
    final profile = ProfileData(
      summary: 'Flutter engineer.',
      education: const [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
      experience: const [ProfileExperience(role: 'Dev', company: 'A', years: 4)],
      projects: const [ProfileProject(name: 'P', description: 'd', tech: ['Flutter'])],
      certifications: const ['AWS'],
      achievements: const ['X'],
      languages: const ['Arabic'],
    );
    final dna = CareerDna(
      stage: CareerStage.experienced,
      targetRole: 'Flutter Lead',
      profile: profile,
      skills: const ['Flutter'],
    );

    for (final size in const [Size(320, 640), Size(1024, 768)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(panel(dna, profile, const ['Flutter']));
      await tester.pumpAndSettle();
      expect(find.text('Career Intelligence'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
    }
  });

  testWidgets('panel handles an empty profile gracefully', (tester) async {
    final dna = CareerDna(stage: CareerStage.freshGraduate);
    await tester.pumpWidget(panel(dna, const ProfileData(), const []));
    await tester.pumpAndSettle();
    expect(find.text('Career Intelligence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
