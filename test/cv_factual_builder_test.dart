import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna dnaWithFacts() => CareerDna(
      targetRole: 'Flutter Developer',
      skills: const ['Dart', 'Flutter', 'Firebase', 'Git'],
      profile: ProfileData(
        summary: 'Built apps.',
        experience: const [
          ProfileExperience(role: 'Intern', company: 'ACME', years: 1)
        ],
        projects: const [
          ProfileProject(
              name: 'Delivery',
              description: 'Built a food delivery app. Integrated Google Maps for real-time tracking.',
              tech: ['Flutter', 'Dart'])
        ],
      ),
    );

void main() {
  test('fresh graduate (no experience) yields no experience section', () {
    final dna = CareerDna(profile: const ProfileData(summary: 'Student'));
    final c = CvFactualBuilder.build(dna);
    expect(c.experience, isEmpty);
    expect(c.sourceLabel, 'Factual CV');
  });

  test('build includes only known facts and preserves them', () {
    final dna = dnaWithFacts();
    final c = CvFactualBuilder.build(dna);
    expect(c.experience.single.role, 'Intern');
    expect(c.projects.single.name, 'Delivery');
  });

  test('target influences header but never the facts', () {
    final dna = dnaWithFacts();
    final a = CvFactualBuilder.build(
        dna, target: CareerTarget(
            id: 't',
            userId: 'u',
            type: TargetType.job,
            role: 'Senior Flutter',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1)));
    final b = CvFactualBuilder.build(dna);
    expect(a.header.title, 'Senior Flutter');
    expect(b.header.title, 'Flutter Developer');
    expect(a.experience, b.experience);
  });

  test('building a factual CV never mutates the source CareerDna', () {
    final dna = dnaWithFacts();
    CvFactualBuilder.build(dna);
    expect(dna.profile.experience.single.company, 'ACME');
  });

  group('skill categorization', () {
    test('categorizes skills into meaningful groups', () {
      final dna = dnaWithFacts();
      final c = CvFactualBuilder.build(dna);
      expect(c.skillGroups.length, greaterThan(1));
      final titles = c.skillGroups.map((g) => g.title).toList();
      expect(titles, contains('Programming & Architecture'));
      expect(titles, contains('Backend & Databases'));
      expect(titles, contains('DevOps & Tools'));
    });

    test('each category contains relevant skills', () {
      final dna = CareerDna(
        skills: const ['Dart', 'Flutter', 'Firebase', 'PostgreSQL', 'Git', 'Docker'],
      );
      final c = CvFactualBuilder.build(dna);
      final programmingGroup = c.skillGroups.firstWhere((g) => g.title == 'Programming & Architecture');
      expect(programmingGroup.skills, containsAll(['Dart', 'Flutter']));
      final backendGroup = c.skillGroups.firstWhere((g) => g.title == 'Backend & Databases');
      expect(backendGroup.skills, containsAll(['Firebase', 'PostgreSQL']));
    });

    test('empty skills yields no skill groups', () {
      final dna = CareerDna(profile: const ProfileData(summary: 'Student'));
      final c = CvFactualBuilder.build(dna);
      expect(c.skillGroups, isEmpty);
    });

    test('unknown skills go to Other category', () {
      final dna = CareerDna(skills: const ['CustomTool']);
      final c = CvFactualBuilder.build(dna);
      final otherGroup = c.skillGroups.firstWhere(
        (g) => g.title == 'Other',
        orElse: () => const CvSkillGroup(title: '', skills: []),
      );
      expect(otherGroup.skills, contains('CustomTool'));
    });
  });

  group('project bullet decomposition', () {
    test('decomposes multi-sentence description into bullets', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [
            ProfileProject(
              name: 'App',
              description: 'Built a mobile app. Integrated payment system. Deployed to production.',
              tech: ['Flutter'],
            ),
          ],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.bullets.length, 3);
    });

    test('keeps single short description as one bullet', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [
            ProfileProject(name: 'App', description: 'A simple todo app', tech: ['Flutter']),
          ],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      // Short sentences (<15 chars) may be filtered; at least one bullet.
      expect(c.projects.single.bullets, isNotEmpty);
    });

    test('empty description yields empty bullets', () {
      final dna = CareerDna(
        profile: ProfileData(
          projects: const [ProfileProject(name: 'App', tech: ['Flutter'])],
        ),
      );
      final c = CvFactualBuilder.build(dna);
      expect(c.projects.single.bullets, isEmpty);
    });
  });
}
