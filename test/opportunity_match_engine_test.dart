import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/analysis/opportunity_match_engine.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/opportunity_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna _with({
  List<String> skills = const [],
  List<ProfileExperience> experience = const [],
  List<ProfileEducation> education = const [],
  CareerStage? stage,
  Map<String, Object> extras = const {},
}) =>
    CareerDna(
      skills: skills,
      stage: stage,
      extras: extras,
      profile: ProfileData(
        experience: experience,
        education: education,
      ),
    );

void main() {
  const engine = OpportunityMatchEngine();

  group('OpportunityMatchEngine.extract', () {
    test('parses skills, years and education from a job description', () {
      final ext = engine.extract(
        'Senior Flutter Engineer\n3+ years experience required.\n'
        'Bachelor degree required.\nStrong Python and AWS skills.',
      );

      expect(ext.role, 'Senior Flutter Engineer');
      expect(ext.requiredSkills, contains('Flutter'));
      expect(ext.requiredSkills, contains('Python'));
      expect(ext.experienceYearsRequired, 3);
      expect(ext.educationRequired, 'bachelor');
      expect(ext.technologies, contains('Flutter'));
    });

    test('infers remote requirement', () {
      final ext = engine.extract('Backend developer, remote position.');
      expect(ext.locationRemote, 'remote');
    });

    test('returns an empty extraction for blank input', () {
      final ext = engine.extract('');
      expect(ext.requiredSkills, isEmpty);
      expect(ext.experienceYearsRequired, isNull);
    });
  });

  group('OpportunityMatchEngine.compute — evidence & status', () {
    test('no candidate data yields unknown (not wrong) requirements', () {
      final dna = _with();
      final ext = engine.extract('Flutter and GraphQL required.');
      final a = engine.compute(dna: dna, extraction: ext);

      final flutter = a.requirements.firstWhere((r) => r.label == 'Flutter');
      expect(flutter.status, RequirementStatus.unknown);
      expect(flutter.evidenceText, contains('Not enough data'));
    });

    test('declared skill becomes a strong match', () {
      final dna = _with(skills: ['Flutter', 'GraphQL']);
      final ext = engine.extract('Flutter and GraphQL required.');
      final a = engine.compute(dna: dna, extraction: ext);

      expect(
        a.requirements.firstWhere((r) => r.label == 'Flutter').status,
        RequirementStatus.strongMatch,
      );
      expect(
        a.requirements.firstWhere((r) => r.label == 'GraphQL').status,
        RequirementStatus.strongMatch,
      );
    });

    test('missing skill with data present is "not evidenced"', () {
      final dna = _with(skills: ['Flutter']);
      final ext = engine.extract('Python required.');
      final a = engine.compute(dna: dna, extraction: ext);

      final python = a.requirements.firstWhere((r) => r.label == 'Python');
      expect(python.status, RequirementStatus.notEvidenced);
      expect(python.evidenceText, contains('No evidence'));
    });

    test('student vs senior-experience role is a requirement mismatch', () {
      final dna = _with(stage: CareerStage.student);
      final ext = engine.extract('5+ years required.');
      final a = engine.compute(dna: dna, extraction: ext);

      expect(a.experienceItem!.status, RequirementStatus.requirementMismatch);
    });

    test('education gap is a requirement mismatch', () {
      final dna = _with(education: [ProfileEducation(degree: 'High School')]);
      final ext = engine.extract('PhD required.');
      final a = engine.compute(dna: dna, extraction: ext);

      expect(a.educationItem!.status, RequirementStatus.requirementMismatch);
    });

    test('career changer gets partial credit via transferable skills', () {
      final dna = _with(
        stage: CareerStage.careerChanger,
        extras: {'transferableSkills': ['Flutter'], 'previousCareer': 'Teacher'},
      );
      final ext = engine.extract('Flutter required.');
      final a = engine.compute(dna: dna, extraction: ext);

      final flutter = a.requirements.firstWhere((r) => r.label == 'Flutter');
      expect(flutter.status, RequirementStatus.partialMatch);
      expect(flutter.evidenceText, contains('Transferable'));
    });

    test('professional experience is stronger evidence than declarations', () {
      final dna = _with(
        skills: ['Flutter'],
        experience: [ProfileExperience(role: 'Flutter Developer', years: 4)],
      );
      final ext = engine.extract('Flutter required.');
      final a = engine.compute(dna: dna, extraction: ext);

      final flutter = a.requirements.firstWhere((r) => r.label == 'Flutter');
      expect(flutter.status, RequirementStatus.strongMatch);
      expect(flutter.evidenceSource, EvidenceSource.professionalExperience);
    });
  });

  group('OpportunityMatchEngine.compute — scoring & category', () {
    test('full match produces a high overall and strong category', () {
      final dna = _with(
        skills: ['Flutter', 'GraphQL'],
        experience: [ProfileExperience(role: 'Flutter Developer', years: 5)],
        education: [ProfileEducation(degree: 'Bachelor')],
      );
      final ext = engine.extract('Senior Flutter Engineer. 5+ years. Bachelor required. Flutter and GraphQL.');
      final a = engine.compute(dna: dna, extraction: ext);

      expect(a.overall, greaterThanOrEqualTo(80));
      expect(a.recommendationCategory, MatchCategory.strong);
      expect(a.skillsScore, greaterThanOrEqualTo(80));
      expect(a.experienceScore, 100);
      expect(a.educationScore, 100);
    });

    test('empty candidate yields a low overall', () {
      final dna = _with();
      final ext = engine.extract('Senior Flutter Engineer. 5+ years. Bachelor required. Flutter and GraphQL.');
      final a = engine.compute(dna: dna, extraction: ext);

      expect(a.overall, lessThan(50));
      expect(a.recommendationCategory, isNot(MatchCategory.strong));
    });

    test('all scores are clamped to 0..100', () {
      final dna = _with();
      final ext = engine.extract('Anything.');
      final a = engine.compute(dna: dna, extraction: ext);

      for (final s in [
        a.skillsScore,
        a.experienceScore,
        a.educationScore,
        a.keywordsScore,
        a.languageScore,
        a.overall,
      ]) {
        expect(s, inInclusiveRange(0, 100));
      }
    });

    test('compute is deterministic for identical inputs', () {
      final dna = _with(skills: ['Flutter']);
      final ext = engine.extract('Flutter required.');
      final first = engine.compute(dna: dna, extraction: ext);
      final second = engine.compute(dna: dna, extraction: ext);

      expect(first.overall, second.overall);
      expect(first.requirements.length, second.requirements.length);
    });
  });

  group('OpportunityMatchEngine.compute — recommendation', () {
    test('ai recommendation overrides the generated one', () {
      final dna = _with();
      final ext = engine.extract('Flutter required.');
      final a = engine.compute(
        dna: dna,
        extraction: ext,
        aiRecommendation: 'Tailor your CV to this role.',
      );

      expect(a.recommendationText, 'Tailor your CV to this role.');
    });

    test('target role is mentioned in the recommendation', () {
      final dna = _with(skills: ['Flutter']);
      final ext = engine.extract('Flutter required.');
      final target = CareerTarget(
        id: 't1',
        userId: 'u',
        type: TargetType.job,
        role: 'Mobile Lead',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final a = engine.compute(dna: dna, extraction: ext, target: target);

      expect(a.targetId, 't1');
      expect(a.recommendationText, contains('Mobile Lead'));
    });
  });
}
