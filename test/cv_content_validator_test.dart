import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_content_validator.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/cv_content.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna freshGrad() => CareerDna(profile: const ProfileData(summary: 'Student'));

void main() {
  test('rejects a fabricated experience not in Career DNA', () {
    final content =
        CvContent(experience: const [CvExperience(role: 'Engineer', company: 'Mystery')]);
    final r = CvContentValidator.validate(content, freshGrad());
    expect(r.valid, isFalse);
    expect(r.issues.any((i) => i.code == 'unknown_experience'), isTrue);
  });

  test('rejects an unknown technology', () {
    final dna = CareerDna(
      skills: const ['Dart'],
      profile: const ProfileData(
          projects: [ProfileProject(name: 'P', tech: ['Dart'])]),
    );
    final content = CvContent(
        projects: const [CvProject(name: 'P', tech: ['Kubernetes'])]);
    final r = CvContentValidator.validate(content, dna);
    expect(r.valid, isFalse);
    expect(r.issues.any((i) => i.code == 'unknown_technology'), isTrue);
  });

  test('rejects metric/scale claims in descriptions', () {
    final dna = CareerDna(
      profile: const ProfileData(
          experience: [ProfileExperience(role: 'Intern', company: 'ACME')]),
    );
    final content = CvContent(
      experience: const [
        CvExperience(
            role: 'Intern',
            company: 'ACME',
            description: 'Led a team of 5 engineers')
      ],
    );
    final r = CvContentValidator.validate(content, dna);
    expect(r.valid, isFalse);
    expect(r.issues.any((i) => i.code == 'unsupported_metric'), isTrue);
  });

  test('accepts a reworded project that keeps the same name', () {
    final dna = CareerDna(
      profile: const ProfileData(projects: [
        ProfileProject(
            name: 'Delivery App',
            description: 'Built a food delivery app',
            tech: ['Flutter'])
      ]),
    );
    final content = CvContent(
      projects: const [
        CvProject(
            name: 'Delivery App',
            description: 'Developed a Flutter-based delivery application.',
            tech: ['Flutter'])
      ],
    );
    final r = CvContentValidator.validate(content, dna);
    expect(r.valid, isTrue);
  });

  test('fresh graduate plus fabricated experience is rejected', () {
    final content = CvContent(
        experience: const [CvExperience(role: 'CEO', company: 'Startup')]);
    final r = CvContentValidator.validate(content, freshGrad());
    expect(r.valid, isFalse);
  });

  test('a project is not mistaken for experience', () {
    final dna = CareerDna(
      profile: const ProfileData(projects: [ProfileProject(name: 'P')]),
    );
    final content = CvContent(
        experience: const [CvExperience(role: 'Fake', company: 'Co')]);
    final r = CvContentValidator.validate(content, dna);
    expect(r.valid, isFalse);
  });

  group('bullet validation', () {
    test('rejects metric claims in experience bullets', () {
      final dna = CareerDna(
        profile: const ProfileData(
            experience: [ProfileExperience(role: 'Dev', company: 'Co')]),
      );
      final content = CvContent(
        experience: const [
          CvExperience(
            role: 'Dev',
            company: 'Co',
            bullets: ['Led a team of 10 engineers'],
          ),
        ],
      );
      final r = CvContentValidator.validate(content, dna);
      expect(r.valid, isFalse);
      expect(r.issues.any((i) => i.code == 'unsupported_metric'), isTrue);
    });

    test('rejects metric claims in project bullets', () {
      final dna = CareerDna(
        profile: const ProfileData(
            projects: [ProfileProject(name: 'App', tech: ['Flutter'])]),
      );
      final content = CvContent(
        projects: const [
          CvProject(
            name: 'App',
            tech: ['Flutter'],
            bullets: ['Increased users by 50%'],
          ),
        ],
      );
      final r = CvContentValidator.validate(content, dna);
      expect(r.valid, isFalse);
      expect(r.issues.any((i) => i.code == 'unsupported_metric'), isTrue);
    });

    test('accepts valid factual bullets', () {
      final dna = CareerDna(
        profile: const ProfileData(
            projects: [ProfileProject(name: 'App', tech: ['Flutter'])]),
      );
      final content = CvContent(
        projects: const [
          CvProject(
            name: 'App',
            tech: ['Flutter'],
            bullets: [
              'Built a cross-platform mobile application using Flutter.',
              'Integrated Google Maps for real-time tracking.',
            ],
          ),
        ],
      );
      final r = CvContentValidator.validate(content, dna);
      expect(r.valid, isTrue);
    });

    test('validates bullets alongside description', () {
      final dna = CareerDna(
        profile: const ProfileData(
            experience: [ProfileExperience(role: 'Dev', company: 'Co')]),
      );
      final content = CvContent(
        experience: const [
          CvExperience(
            role: 'Dev',
            company: 'Co',
            description: 'Managed a team of 5',
            bullets: ['Built the app'],
          ),
        ],
      );
      final r = CvContentValidator.validate(content, dna);
      expect(r.valid, isFalse);
      expect(r.issues.any((i) => i.code == 'unsupported_metric'), isTrue);
    });
  });
}
