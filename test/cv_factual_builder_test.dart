import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_factual_builder.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna dnaWithFacts() => CareerDna(
      targetRole: 'Flutter Developer',
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
    expect(c.skillGroups.single.skills, ['Dart', 'Flutter']);
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
}
