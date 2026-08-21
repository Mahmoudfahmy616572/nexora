import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:nexora/features/main/presentation/studio/cv_export_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cvToText includes the main sections', () {
    final content = CvFactualBuilder.build(CareerDna(
      profile: ProfileData(
        summary: 'Summary here.',
        projects: const [ProfileProject(name: 'Delivery', description: 'Food app')],
      ),
    ));
    final text = cvToText(content);
    expect(text, contains('SUMMARY'));
    expect(text, contains('PROJECTS'));
    expect(text, contains('Delivery'));
  });

  testWidgets('export sheet shows copy button', (tester) async {
    final content = CvFactualBuilder.build(CareerDna(
      profile: ProfileData(
          projects: const [ProfileProject(name: 'Delivery')]),
    ));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CvExportSheet(content: content)),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cvCopy')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
