import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/profile_data.dart';
import 'package:nexora/domain/profile_generator.dart';

void main() {
  group('generateProfile', () {
    test('builds a complete, non-empty profile from a single interest', () {
      final result = generateProfile(
        interests: {Interest.programming},
        goals: {Goal.internship},
      );

      expect(result.skills, isNotEmpty);
      expect(result.data.summary, contains('Flutter'));
      expect(result.data.experience, hasLength(1));
      expect(result.data.projects, hasLength(1));
      expect(result.data.education, hasLength(1));
      expect(result.data.certifications, hasLength(1));
      expect(result.data.achievements, hasLength(1));
      expect(result.data.languages, contains('English'));
    });

    test('merges skills and entries across multiple interests', () {
      final result = generateProfile(
        interests: {Interest.programming, Interest.design},
        goals: {Goal.internship, Goal.job},
      );

      expect(result.skills, containsAll(['Flutter', 'Figma']));
      expect(result.data.experience, hasLength(2));
      expect(result.data.projects, hasLength(2));
      // No duplicates in the flat skills list.
      expect(result.skills, equals(result.skills.toSet().toList()));
    });

    test('extracts skills from a free-text sentence', () {
      final result = generateProfile(
        interests: {Interest.programming},
        goals: const {},
        sentence: 'I love python and building rest apis with flutter',
      );

      expect(result.skills, containsAll(['Python', 'REST APIs', 'Flutter']));
    });

    test('summary reflects the selected goal', () {
      final result = generateProfile(
        interests: {Interest.writing},
        goals: {Goal.freelance},
      );

      expect(result.data.summary.toLowerCase(), contains('freelance'));
    });

    test('falls back to a default interest when none are selected', () {
      final result = generateProfile(interests: const {}, goals: const {});

      expect(result.data.experience, isNotEmpty);
      expect(result.skills, isNotEmpty);
    });

    test('round-trips through ProfileData json', () {
      final result = generateProfile(interests: {Interest.data}, goals: {Goal.scholarship});
      final decoded = ProfileData.fromJson(result.data.toJson());

      expect(decoded.summary, result.data.summary);
      expect(decoded.experience, hasLength(result.data.experience.length));
      expect(decoded.projects, hasLength(result.data.projects.length));
      expect(decoded.languages, equals(result.data.languages));
    });

    test('builds a draft from a custom (user-typed) domain', () {
      final result = generateProfile(
        interests: const {},
        customInterests: ['Robotics'],
        goals: const {},
      );

      expect(result.data.summary.toLowerCase(), contains('robotics'));
      expect(result.data.experience, isNotEmpty);
      expect(result.skills, contains('Robotics'));
    });

    test('infers a whole domain from the free-text sentence', () {
      final result = generateProfile(
        interests: const {},
        goals: const {},
        sentence: 'I am studying medicine and want to help patients',
      );

      // "medicine" in the sentence expands to the Medicine blueprint.
      expect(result.data.summary.toLowerCase(), contains('healthcare'));
      expect(result.skills, contains('Patient Care'));
    });

    test('does not leak Flutter into the summary for a custom-only pick', () {
      final result = generateProfile(
        interests: const {},
        customInterests: ['Nursing'],
        goals: const {},
      );

      expect(result.data.summary.toLowerCase(), isNot(contains('flutter')));
      expect(result.data.summary.toLowerCase(), contains('nursing'));
    });

    test('suggestion prompts are tailored to the chosen domain', () {
      final sportsPrompts = buildSuggestionPrompts(
        interests: {Interest.sports},
        customInterests: const [],
        goals: const {},
      );
      expect(sportsPrompts.join(' ').toLowerCase(), contains('team'));
      expect(sportsPrompts.join(' ').toLowerCase(), isNot(contains('building apps')));

      final roboticsPrompts = buildSuggestionPrompts(
        interests: const {},
        customInterests: ['Robotics'],
        goals: const {},
      );
      expect(roboticsPrompts.join(' ').toLowerCase(), contains('robotics'));
    });

    test('custom domain yields domain-relevant skills, not just generic', () {
      final result = generateProfile(
        interests: const {},
        customInterests: ['Robotics'],
        goals: const {},
      );

      expect(result.skills, contains('Robotics'));
      expect(result.skills, containsAll(['Arduino', 'Circuit Design']));
      // The generic filler should not dominate a recognised domain.
      expect(result.data.education.first.field, 'Robotics Engineering');
    });

    test('custom domain works for Arabic input', () {
      final result = generateProfile(
        interests: const {},
        customInterests: ['روبوتات'],
        goals: const {},
      );

      expect(result.skills, contains('Robotics'));
      expect(result.skills, contains('Arduino'));
    });

    test('unrecognised custom domain falls back to a generic skill set', () {
      final result = generateProfile(
        interests: const {},
        customInterests: ['Underwater Basket Weaving'],
        goals: const {},
      );

      expect(result.skills, contains('Underwater Basket Weaving'));
      expect(result.skills, containsAll(['Communication', 'Problem Solving', 'Teamwork']));
    });
  });

  group('parseAiProfile', () {
    const aiJson = {
      'skills': ['Flutter', 'Dart', 'Firebase'],
      'profile': {
        'summary': 'Aspiring mobile developer.',
        'experience': [
          {'role': 'Intern', 'company': 'Campus App Lab', 'years': 0, 'description': 'Built a club app.'}
        ],
        'projects': [
          {'name': 'Budget App', 'description': 'Tracked spend.', 'tech': ['Flutter', 'Dart']}
        ],
        'education': [
          {'degree': 'B.Sc.', 'field': 'Computer Science', 'school': 'State University', 'year': 2026}
        ],
        'certifications': ['Flutter Bootcamp'],
        'achievements': ['Shipped to Play Store'],
        'languages': ['Arabic', 'English'],
      },
    };

    test('parses a valid AI response into a GeneratedProfile', () {
      final result = parseAiProfile(aiJson);

      expect(result.skills, equals(['Flutter', 'Dart', 'Firebase']));
      expect(result.data.summary, 'Aspiring mobile developer.');
      expect(result.data.experience, hasLength(1));
      expect(result.data.experience.first.role, 'Intern');
      expect(result.data.projects, hasLength(1));
      expect(result.data.education.first.field, 'Computer Science');
      expect(result.data.certifications, equals(['Flutter Bootcamp']));
      expect(result.data.languages, equals(['Arabic', 'English']));
    });

    test('throws when the AI response is missing profile or skills', () {
      expect(
        () => parseAiProfile({'skills': ['X']}),
        throwsA(isA<StateError>()),
      );
      expect(
        () => parseAiProfile({'profile': {'summary': 'x'}}),
        throwsA(isA<StateError>()),
      );
    });
  });
}
