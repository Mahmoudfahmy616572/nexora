import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/features/main/presentation/studio/cv_preview.dart';

CareerDna dna() => CareerDna(
      targetRole: 'Flutter Dev',
      skills: const ['Dart', 'Flutter', 'Firebase', 'Git'],
      profile: ProfileData(
        summary: 'Built apps.',
        experience: const [
          ProfileExperience(role: 'Intern', company: 'ACME', years: 1)
        ],
        projects: const [
          ProfileProject(
            name: 'Delivery',
            description: 'Food delivery app with real-time tracking and payments.',
            tech: ['Flutter'],
          )
        ],
      ),
    );

Widget previewFor(String template, {TextDirection dir = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: dir,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              child: CvPreview(
                key: const Key('cvPreview'),
                content: CvFactualBuilder.build(dna()),
                templateId: template,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final t in ['nexoraMinimal', 'nexoraModern', 'nexoraCompact']) {
    testWidgets('preview renders for $t', (tester) async {
      await tester.pumpWidget(previewFor(t));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cvPreview')), findsOneWidget);
      // Project name is in a RichText — use finder for text containing 'Delivery'.
      expect(find.byWidgetPredicate((w) =>
          w is RichText && w.toDiagnosticsNode().toStringDeep().contains('Delivery')),
          findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('preview renders RTL without overflow', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal', dir: TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview shows factual skills grouped', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dart'), findsOneWidget);
    expect(find.textContaining('Programming'), findsOneWidget);
  });

  testWidgets('preview renders experience bullets', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Intern'), findsOneWidget);
    expect(find.textContaining('ACME'), findsOneWidget);
  });

  testWidgets('preview renders section titles', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal'));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('SKILLS'), findsOneWidget);
  });

  testWidgets('preview renders education', (tester) async {
    final content = CvFactualBuilder.build(CareerDna(
      profile: ProfileData(
        education: const [
          ProfileEducation(degree: 'BSc', field: 'Computer Science'),
        ],
      ),
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CvPreview(content: content, templateId: 'nexoraMinimal'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('BSc'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
  });

  testWidgets('preview renders certifications and languages', (tester) async {
    final content = CvFactualBuilder.build(CareerDna(
      profile: ProfileData(
        certifications: const [ProfileCertification(name: 'AWS Certified')],
        languages: const ['English', 'Arabic'],
      ),
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CvPreview(content: content, templateId: 'nexoraMinimal'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('AWS'), findsOneWidget);
    expect(find.textContaining('Arabic'), findsWidgets);
  });
}
