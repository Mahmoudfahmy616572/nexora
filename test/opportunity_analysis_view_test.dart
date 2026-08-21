import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:nexora/domain/entities/opportunity_analysis.dart';
import 'package:nexora/features/main/presentation/analyze/opportunity_analysis_view.dart';
import 'package:nexora/l10n/app_localizations.dart';

OpportunityAnalysis _sample() => OpportunityAnalysis(
      role: 'Flutter Engineer',
      company: 'Careem',
      requirements: [
        JobRequirement(
          label: 'Flutter',
          required: true,
          status: RequirementStatus.strongMatch,
          evidenceSource: EvidenceSource.declaredSkill,
          evidenceText: 'Declared skill: flutter',
        ),
        JobRequirement(
          label: 'AWS',
          required: false,
          status: RequirementStatus.partialMatch,
          evidenceSource: EvidenceSource.declaredSkill,
          evidenceText: 'Related skill: GCP (adjacent to aws).',
        ),
        JobRequirement(
          label: 'PhD',
          required: true,
          status: RequirementStatus.requirementMismatch,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Requires PhD; you hold Bachelor.',
        ),
        JobRequirement(
          label: 'Rust',
          required: true,
          status: RequirementStatus.notEvidenced,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'No evidence found in your Career DNA.',
        ),
        JobRequirement(
          label: 'GraphQL',
          required: false,
          status: RequirementStatus.unknown,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Not enough data in your Career DNA to evaluate this.',
        ),
      ],
      responsibilities: const ['Ship features'],
      technologies: const ['Flutter', 'Firebase'],
      experienceItem: JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.professionalExperience,
        evidenceText: '5 yrs professional experience',
      ),
      educationItem: JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.requirementMismatch,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'Requires PhD; you hold Bachelor.',
      ),
      experienceRequirement: '5+ years',
      educationRequirement: 'Bachelor',
      certifications: const ['CKAD'],
      languages: const ['Arabic'],
      softSkills: const ['Communication'],
      domainKnowledge: const ['Fintech'],
      keywords: const ['Flutter', 'Rust'],
      skillsScore: 75,
      experienceScore: 100,
      educationScore: 0,
      keywordsScore: 50,
      languageScore: 100,
      overall: 68,
      recommendationCategory: MatchCategory.good,
      recommendationText: 'Good match — apply after closing a few preferred gaps.',
    );

Widget _host(OpportunityAnalysis analysis, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: OpportunityAnalysisView(analysis: analysis),
        ),
      ),
    );

void main() {
  group('OpportunityAnalysisView', () {
    testWidgets('renders score, sections and recommendation (EN, 360px)', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_host(_sample(), const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Match score'), findsOneWidget);
      expect(find.text('Recommendation'), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis_recommendation')), findsOneWidget);
      // Each requirement category surfaces its representative label.
      expect(find.text('Flutter'), findsWidgets);
      expect(find.textContaining('AWS'), findsWidgets);
      expect(find.text('PhD'), findsWidgets);
      expect(find.text('Rust'), findsWidgets);
      expect(find.textContaining('GraphQL'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at 320px width (EN)', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_host(_sample(), const Locale('en')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception in Arabic (RTL)', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_host(_sample(), const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('analysis_recommendation')), findsOneWidget);
    });

    testWidgets('renders a minimal analysis without optional sections', (tester) async {
      const minimal = OpportunityAnalysis(
        role: 'Backend Engineer',
        requirements: [
          JobRequirement(
            label: 'Python',
            required: true,
            status: RequirementStatus.strongMatch,
            evidenceSource: EvidenceSource.declaredSkill,
            evidenceText: 'Declared skill: python',
          ),
        ],
        responsibilities: [],
        technologies: [],

        experienceItem: JobRequirement(
          label: 'Experience',
          required: true,
          status: RequirementStatus.unknown,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Experience requirement not specified.',
        ),
        educationItem: JobRequirement(
          label: 'Education',
          required: true,
          status: RequirementStatus.unknown,
          evidenceSource: EvidenceSource.none,
          evidenceText: 'Education requirement not specified.',
        ),
        skillsScore: 80,
        experienceScore: 60,
        educationScore: 70,
        keywordsScore: 70,
        languageScore: 100,
        overall: 72,
        recommendationCategory: MatchCategory.good,
        recommendationText: 'Good match — apply after closing a few preferred gaps.',
      );
      await tester.pumpWidget(_host(minimal, const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Python'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
