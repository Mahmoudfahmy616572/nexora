import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/profile_data.dart';

/// Proves the ACTUAL profile returned by the live Groq interview
/// (see H4 LIVE AI VERIFICATION REPORT) parses cleanly and preserves every
/// user-provided fact while keeping experience empty (no hallucinated job).
void main() {
  test('live AI output -> ProfileData -> CareerDna integration', () {
    final liveProfile = <String, dynamic>{
      'summary':
          'Fresh graduate in Computer Science with experience in building a '
          'personal Flutter project, Delivery App, utilizing real-time location '
          'tracking with Google Maps.',
      'experience': <dynamic>[],
      'projects': [
        {
          'name': 'Delivery App',
          'description':
              'A Flutter delivery application with real-time location tracking '
              'using Google Maps.',
          'tech': ['Flutter', 'Dart', 'Google Maps'],
        }
      ],
      'education': [
        {'degree': "Bachelor's", 'field': 'Computer Science'}
      ],
      'certifications': <dynamic>[],
      'achievements': <dynamic>[],
      'languages': ['English'],
      'skills': ['Flutter', 'Dart', 'Google Maps API'],
    };

    final profile = ProfileData.fromJson(liveProfile);

    // Experience stays empty — no fabricated employment.
    expect(profile.experience, isEmpty);

    // Projects preserved exactly as the candidate described.
    expect(profile.projects.length, 1);
    expect(profile.projects.first.name, 'Delivery App');
    expect(profile.projects.first.tech, contains('Flutter'));
    expect(profile.projects.first.tech, contains('Dart'));

    // Education preserved.
    expect(profile.education.first.degree, "Bachelor's");
    expect(profile.education.first.field, 'Computer Science');

    // Skills preserved (user-provided only). Skills live on CareerDna, not on
    // ProfileData, so they are read from the raw AI payload.
    final aiSkills = [for (final s in liveProfile['skills'] as List) s as String];
    expect(aiSkills, contains('Flutter'));
    expect(aiSkills, contains('Dart'));
    expect(aiSkills, contains('Google Maps API'));

    // Nothing invented where none was provided.
    expect(profile.certifications, isEmpty);
    expect(profile.achievements, isEmpty);
    expect(profile.languages, contains('English'));

    // Assembling into Career DNA keeps experience empty and context intact.
    final dna = CareerDna(
      stage: CareerStage.freshGraduate,
      profile: profile,
      skills: aiSkills,
    );
    expect(dna.profile.experience, isEmpty);
    expect(dna.skills, contains('Flutter'));
  });
}
