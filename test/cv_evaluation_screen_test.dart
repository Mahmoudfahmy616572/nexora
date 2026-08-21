import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_document.dart';
import 'package:nexora/features/main/presentation/studio/evaluation/cv_evaluation_screen.dart';
import 'package:nexora/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final now = DateTime.now();
    final doc = CvDocument(
      id: 'd1',
      userId: 'u',
      targetId: 't1',
      templateId: 'minimal',
      title: 'CV',
      createdAt: now,
      updatedAt: now,
    );
    final version = CvVersion(
      id: 'v1',
      documentId: 'd1',
      userId: 'u',
      version: 1,
      content: CvContent(
        header: const CvHeader(name: 'Jane'),
        summary: 'Flutter engineer with strong mobile experience.',
        experience: const [
          CvExperience(role: 'Dev', company: 'Acme', years: 3),
        ],
      ),
      templateId: 'minimal',
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'studio.cv_documents': [jsonEncode(doc.toJson())],
      'studio.cv_versions': [jsonEncode(version.toJson())],
    });
  });

  testWidgets('renders deterministic evaluation when AI is unavailable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CvEvaluationScreen(documentId: 'd1'),
      ),
    );
    await tester.pumpAndSettle();

    // Title + deterministic-only banner (AI edge function unreachable in tests).
    expect(find.text('CV Evaluation'), findsOneWidget);
    expect(find.textContaining('structural checks only'), findsOneWidget);
    // Score bars are rendered.
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });
}
