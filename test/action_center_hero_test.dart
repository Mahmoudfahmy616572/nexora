import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/action_center/action_center.dart';
import 'package:nexora/domain/action_center/action_center_engine.dart';
import 'package:nexora/domain/analysis/career_intelligence_engine.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_document.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_evaluation.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/job_application.dart';
import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/repositories/career_dna_repository.dart';
import 'package:nexora/domain/repositories/career_target_repository.dart';
import 'package:nexora/domain/repositories/cv_document_repository.dart';
import 'package:nexora/domain/repositories/cv_evaluation_repository.dart';
import 'package:nexora/domain/repositories/cv_suggestion_repository.dart';
import 'package:nexora/domain/repositories/job_analysis_repository.dart';
import 'package:nexora/domain/repositories/job_application_repository.dart';
import 'package:nexora/features/main/presentation/home/action_center_cubit.dart';
import 'package:nexora/features/main/presentation/home/action_center_hero.dart';
import 'package:nexora/l10n/app_localizations.dart';

// --- fixtures ---------------------------------------------------------------

CareerDna _dna() => CareerDna(
      stage: CareerStage.freshGraduate,
      targetRole: 'Flutter Developer',
      targetField: TargetField.programming,
      skills: const ['Dart'],
      profile: const ProfileData(
        education: [ProfileEducation(degree: 'BSc', field: 'CS')],
        projects: [ProfileProject(name: 'P')],
      ),
    );

CareerTarget _target() => CareerTarget(
      id: 't1',
      userId: 'u',
      type: TargetType.job,
      role: 'Flutter Developer',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

JobAnalysis _analysis() => JobAnalysis(
      id: 'a1',
      title: 'Senior Flutter Dev',
      company: 'Acme',
      timeAgo: '1d',
      overall: 0.8,
      skills: 0.7,
      experience: 0.6,
      education: 0.7,
      keywords: 0.6,
      strong: const [],
      missing: const [],
      targetId: 't1',
    );

CvDocument _document() => CvDocument(
      id: 'doc1',
      userId: 'u',
      targetId: 't1',
      templateId: 'minimal',
      title: 'My CV',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      analysisId: 'a1',
    );

CvVersion _version() => CvVersion(
      id: 'v1',
      documentId: 'doc1',
      userId: 'u',
      version: 1,
      content: const CvContent(),
      templateId: 'minimal',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      evaluationId: 'e1',
    );

CvEvaluation _evaluation() => CvEvaluation(
      id: 'e1',
      userId: 'u',
      versionId: 'v1',
      targetId: 't1',
      overall: 72,
      ats: 70,
      targetAlignment: 70,
      contentStrength: 70,
      evidenceStrength: 70,
      readability: 70,
      clarity: 70,
      structure: 70,
      keywordAlignment: 70,
      skillAlignment: 70,
      sectionCompleteness: 70,
      createdAt: DateTime(2024, 1, 1),
    );

ActionCenterState _readyDecision() {
  final dna = _dna();
  return ActionCenterEngine.derive(ActionCenterInput(
    dna: dna,
    intelligence: computeCareerIntelligence(
      dna: dna,
      profile: dna.profile,
      skills: dna.skills,
    ),
    targets: [_target()],
    analyses: [_analysis()],
    documents: [_document()],
    versionsByDoc: {'doc1': [_version()]},
    evaluations: [_evaluation()],
    suggestions: const [],
  ));
}

// --- fakes ------------------------------------------------------------------

class _FakeDna implements CareerDnaRepository {
  @override
  Future<CareerDna?> load() async => _dna();
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeTarget implements CareerTargetRepository {
  @override
  Future<List<CareerTarget>> loadAll() async => [_target()];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeAnalysis implements JobAnalysisRepository {
  @override
  Future<List<JobAnalysis>?> load() async => [_analysis()];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeDoc implements CvDocumentRepository {
  @override
  Future<List<CvDocument>> loadDocuments() async => [_document()];
  @override
  Future<List<CvVersion>> loadVersions(String documentId) async => [_version()];
  @override
  Future<CvVersion?> loadLatestVersion(String documentId) async => _version();
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeEval implements CvEvaluationRepository {
  @override
  Future<CvEvaluation?> loadEvaluation(String versionId) async => _evaluation();
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeSuggestion implements CvSuggestionRepository {
  @override
  Future<List<CvSuggestion>> loadByEvaluation(String evaluationId) async => const [];
  @override
  dynamic noSuchMethod(_) => throw UnimplementedError();
}

class _FakeApplication implements JobApplicationRepository {
  @override
  Future<List<JobApplication>?> load() async => const [];
  @override
  Future<void> saveAll(List<JobApplication> apps) async {}
}

// --- tests ------------------------------------------------------------------

Future<void> _pumpCard(
  WidgetTester tester, {
  required ActionCenterState decision,
  required Locale locale,
  Size size = const Size(320, 640),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: ActionCenterCard(decision: decision, onAction: () {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ActionCenterCard responsive', () {
    final sizes = <String, Size>{
      '320': const Size(320, 640),
      '360': const Size(360, 740),
      '414': const Size(414, 896),
      '768': const Size(768, 1024),
      '1024': const Size(1024, 768),
    };

    for (final size in sizes.entries) {
      testWidgets('no overflow (EN) at ${size.key}', (tester) async {
        await _pumpCard(tester, decision: _readyDecision(), locale: const Locale('en'), size: size.value);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('acPrimaryCta')), findsOneWidget);
      });

      testWidgets('no overflow (AR/RTL) at ${size.key}', (tester) async {
        await _pumpCard(tester, decision: _readyDecision(), locale: const Locale('ar'), size: size.value);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('acPrimaryCta')), findsOneWidget);
      });
    }
  });

  group('ActionCenterCard localization + interaction', () {
    testWidgets('shows English CTA for evaluateCv', (tester) async {
      final decision = _readyDecision();
      await _pumpCard(tester, decision: decision, locale: const Locale('en'));
      expect(find.text('Track Applications'), findsOneWidget);
    });

    testWidgets('shows Arabic CTA for the same decision', (tester) async {
      final decision = _readyDecision();
      await _pumpCard(tester, decision: decision, locale: const Locale('ar'));
      expect(find.text('تتبّع الطلبات'), findsOneWidget);
    });

    testWidgets('shows the Practice Interview CTA for practiceInterview', (tester) async {
      final decision = _readyDecision().copyWith(actionType: ActionType.practiceInterview);
      await _pumpCard(tester, decision: decision, locale: const Locale('en'));
      expect(find.text('Practice Interview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invokes onAction when CTA tapped', (tester) async {
      var tapped = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: ActionCenterCard(
                decision: _readyDecision(),
                onAction: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('acPrimaryCta')));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('ActionCenterHero', () {
    testWidgets('shows loading spinner before data is assembled', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final cubit = ActionCenterCubit(
        dnaRepo: _FakeDna(),
        targetRepo: _FakeTarget(),
        analysisRepo: _FakeAnalysis(),
        docRepo: _FakeDoc(),
        evalRepo: _FakeEval(),
        suggestionRepo: _FakeSuggestion(),
        applicationRepo: _FakeApplication(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<ActionCenterCubit>(
              create: (_) => cubit,
              child: const ActionCenterHero(onOpenTab: _noopTab),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Track Applications'), findsNothing);
    });

    testWidgets('renders the derived action once ready', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final cubit = ActionCenterCubit(
        dnaRepo: _FakeDna(),
        targetRepo: _FakeTarget(),
        analysisRepo: _FakeAnalysis(),
        docRepo: _FakeDoc(),
        evalRepo: _FakeEval(),
        suggestionRepo: _others(),
        applicationRepo: _FakeApplication(),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<ActionCenterCubit>(
              create: (_) => cubit,
              child: const ActionCenterHero(onOpenTab: _noopTab),
            ),
          ),
        ),
      );
      await cubit.load();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Practice Interview'), findsOneWidget);
    });
  });
}

void _noopTab(_) {}

CvSuggestionRepository _others() => _FakeSuggestion();
