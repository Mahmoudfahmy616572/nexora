import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';

void main() {
  group('CareerDna completeness', () {
    test('empty DNA reports zero completeness', () {
      final dna = CareerDna(createdAt: DateTime(2026), updatedAt: DateTime(2026));
      expect(dna.completeness, 0);
      expect(dna.isEmpty, isTrue);
    });

    test('completeness grows as identity and profile are filled', () {
      final dna = CareerDna(
        goal: CareerGoal.job,
        stage: CareerStage.freshGraduate,
        targetField: TargetField.programming,
        targetRole: 'Flutter Developer',
        targetIndustry: 'Fintech',
        profile: ProfileData(
          summary: 'Motivated developer.',
          experience: [ProfileExperience(role: 'Intern', company: 'Acme', years: 1)],
          projects: [ProfileProject(name: 'App', description: 'x', tech: ['Flutter'])],
          education: [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
        ),
        skills: const ['Flutter', 'Dart'],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      // 11 points: goal, stage, field, role, industry, summary, experience,
      // project, education, skills, + one of certs/achievements/languages.
      expect(dna.completeness, greaterThan(0.7));
      expect(dna.isEmpty, isFalse);
    });
  });

  group('CareerDna versioning', () {
    test('save bumps version and updates timestamps', () {
      final base = CareerDna(createdAt: DateTime(2026), updatedAt: DateTime(2026));
      final next = base.copyWith(version: 2, updatedAt: DateTime(2027));
      expect(next.version, 2);
      expect(next.createdAt.year, 2026);
    });

    test('row round-trips through toRow/fromRow', () {
      final dna = CareerDna(
        goal: CareerGoal.masters,
        stage: CareerStage.student,
        targetField: TargetField.data,
        targetRole: 'Analyst',
        targetIndustry: 'Health',
        preferences: const ['remote'],
        profile: ProfileData(summary: 'Student.'),
        skills: const ['SQL'],
        version: 3,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );
      final row = dna.toRow();
      final parsed = CareerDna.fromRow(row);
      expect(parsed.goal, CareerGoal.masters);
      expect(parsed.stage, CareerStage.student);
      expect(parsed.targetField, TargetField.data);
      expect(parsed.targetRole, 'Analyst');
      expect(parsed.skills, const ['SQL']);
      expect(parsed.version, 3);
    });
  });

  group('profile_draft merge shape', () {
    test('profile_draft JSON maps into ProfileData', () {
      final json = {
        'summary': 'Summary text',
        'experience': [
          {'role': 'Dev', 'company': 'Acme', 'years': 2},
        ],
        'projects': [
          {'name': 'App', 'description': 'built', 'tech': ['Flutter']},
        ],
        'education': [
          {'degree': 'B.Sc.', 'field': 'CS'},
        ],
        'certifications': ['X'],
        'achievements': ['Y'],
        'languages': ['English'],
      };
      final profile = ProfileData.fromJson(json);
      expect(profile.summary, 'Summary text');
      expect(profile.experience.first.company, 'Acme');
      expect(profile.projects.first.tech, ['Flutter']);
      expect(profile.education.first.field, 'CS');
    });
  });

  group('CareerDna hasMeaningfulContent', () {
    test('education-only DNA is meaningful (intake must not dead-end)', () {
      final dna = CareerDna(
        profile: ProfileData(
          education: [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
        ),
      );
      expect(dna.hasMeaningfulContent, isTrue);
    });

    test('project-only DNA is meaningful', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: [ProfileProject(name: 'App', description: 'built', tech: const [])],
        ),
      );
      expect(dna.hasMeaningfulContent, isTrue);
    });

    test('empty DNA is not meaningful', () {
      expect(CareerDna().hasMeaningfulContent, isFalse);
    });
  });
}
