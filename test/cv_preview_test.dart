import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/features/main/presentation/studio/cv_preview.dart';

CareerDna dna() => CareerDna(
      targetRole: 'Flutter Dev',
      skills: const ['Dart', 'Flutter'],
      profile: ProfileData(
        summary: 'Built apps.',
        experience: const [
          ProfileExperience(role: 'Intern', company: 'ACME', years: 1)
        ],
        projects: const [
          ProfileProject(name: 'Delivery', description: 'Food app', tech: ['Flutter'])
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
      expect(find.textContaining('Delivery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('preview renders RTL without overflow', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal', dir: TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview shows factual skills', (tester) async {
    await tester.pumpWidget(previewFor('nexoraMinimal'));
    await tester.pumpAndSettle();
    expect(find.text('Dart'), findsOneWidget);
  });
}
