import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_evaluator.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/cv_evaluation.dart';

CvContent _rich() => CvContent(
      header: const CvHeader(
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1 555 0100',
        location: 'Remote',
      ),
      summary: 'Senior Flutter engineer with 6 years building mobile apps.',
      experience: const [
        CvExperience(
          role: 'Flutter Engineer',
          company: 'Acme',
          years: 4,
          description: 'Led the migration to a clean architecture and shipped '
              'the offline mode used by 200k users.',
        ),
      ],
      projects: const [
        CvProject(
          name: 'Payments SDK',
          tech: ['Flutter', 'Dart'],
          description: 'Built a reusable SDK that cut integration time in half.',
        ),
      ],
      education: const [CvEducation(degree: 'BSc Computer Science')],
      skillGroups: const [CvSkillGroup(title: 'Skills', skills: ['Flutter', 'Dart'])],
      certifications: const [CvCertification(name: 'Google Flutter')],
      achievements: const [CvAchievement(text: 'Reduced crash rate by 40%.')],
      languages: const [CvLanguage(name: 'English')],
      sourceLabel: 'Factual CV',
    );

CvContent _empty() => const CvContent(header: CvHeader(name: 'X'));

void main() {
  group('CvEvaluator determinism', () {
    test('scores are bounded and reproducible', () {
      final a = CvEvaluator.evaluate(
        content: _rich(),
        userId: 'u',
        versionId: 'v',
        targetId: 't',
      );
      final b = CvEvaluator.evaluate(
        content: _rich(),
        userId: 'u',
        versionId: 'v',
        targetId: 't',
      );
      for (final e in [a.evaluation, b.evaluation]) {
        expect(e.overall, inInclusiveRange(0, 100));
        expect(e.ats, inInclusiveRange(0, 100));
        expect(e.targetAlignment, inInclusiveRange(0, 100));
        expect(e.contentStrength, inInclusiveRange(0, 100));
        expect(e.evidenceStrength, inInclusiveRange(0, 100));
        expect(e.readability, inInclusiveRange(0, 100));
        expect(e.clarity, inInclusiveRange(0, 100));
        expect(e.structure, inInclusiveRange(0, 100));
        expect(e.keywordAlignment, inInclusiveRange(0, 100));
        expect(e.skillAlignment, inInclusiveRange(0, 100));
        expect(e.sectionCompleteness, inInclusiveRange(0, 100));
      }
      expect(a.evaluation.overall, b.evaluation.overall);
      expect(a.evaluation.ats, b.evaluation.ats);
      expect(a.suggestions.length, b.suggestions.length);
    });

    test('empty content scores low', () {
      final e = CvEvaluator.evaluate(
        content: _empty(),
        userId: 'u',
        versionId: 'v',
        targetId: 't',
      ).evaluation;
      expect(e.sectionCompleteness, lessThan(50));
      expect(e.contentStrength, lessThan(50));
    });
  });

  group('CvEvaluator.applySuggestion factuality guard', () {
    test('rewords an existing section substring', () {
      final content = CvContent(summary: 'I am a developer');
      final s = CvSuggestion(
        id: '1',
        userId: 'u',
        evaluationId: 'e',
        versionId: 'v',
        section: 'summary',
        problem: 'p',
        current: 'I am a developer',
        suggested: 'I am an experienced developer',
        why: 'w',
        targetRequirement: '',
        createdAt: DateTime.now(),
      );
      final updated = CvEvaluator.applySuggestion(content, s);
      expect(updated.summary, 'I am an experienced developer');
    });

    test('no-op when the current text is not present (never fabricates)', () {
      final content = CvContent(summary: 'I am a developer');
      final s = CvSuggestion(
        id: '1',
        userId: 'u',
        evaluationId: 'e',
        versionId: 'v',
        section: 'summary',
        problem: 'p',
        current: 'this text is not in the cv',
        suggested: 'replacement that must not appear',
        why: 'w',
        targetRequirement: '',
        createdAt: DateTime.now(),
      );
      final updated = CvEvaluator.applySuggestion(content, s);
      expect(updated.summary, 'I am a developer');
    });
  });

  group('CvEvaluation model', () {
    test('toJson/fromJson round-trips', () {
      final result = CvEvaluator.evaluate(
        content: _rich(),
        userId: 'u',
        versionId: 'v',
        targetId: 't',
      );
      final back = CvEvaluation.fromJson(result.evaluation.toJson());
      expect(back.overall, result.evaluation.overall);
      expect(back.ats, result.evaluation.ats);
      expect(back.deterministicOnly, result.evaluation.deterministicOnly);
    });

    test('explanation map round-trips', () {
      final e = CvEvaluation(
        id: 'e1',
        userId: 'u',
        versionId: 'v',
        targetId: 't',
        overall: 80,
        ats: 70,
        targetAlignment: 75,
        contentStrength: 80,
        evidenceStrength: 78,
        readability: 88,
        clarity: 85,
        structure: 90,
        keywordAlignment: 70,
        skillAlignment: 72,
        sectionCompleteness: 95,
        explanations: {'Structure': 'Strong'},
        deterministicOnly: false,
        createdAt: DateTime.now(),
      );
      final back = CvEvaluation.fromJson(e.toJson());
      expect(back.explanations['Structure'], 'Strong');
    });
  });
}
