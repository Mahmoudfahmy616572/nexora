import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/analysis/job_analyzer.dart';
import 'package:nexora/domain/entities/job_analysis.dart';
import 'package:nexora/domain/entities/profile_data.dart';

JobAnalysis analyze(String description, {List<String> skills = const [], int years = 0, String education = 'bachelor'}) {
  return const JobAnalyzer().analyze(
    description: description,
    candidateSkills: skills,
    yearsOfExperience: years,
    education: education,
  );
}

void main() {
  test('extracts required skills from a job description', () {
    final result = analyze(
      'Flutter Developer. Experience with Firebase and GraphQL required.',
      skills: ['Flutter', 'Dart'],
    );

    expect(result.strong, contains('Flutter'));
    expect(result.missing, containsAll(['Firebase', 'GraphQL']));
  });

  test('matches candidate skills case-insensitively and via aliases', () {
    final result = analyze(
      'Backend role needing REST APIs and CI/CD.',
      skills: ['rest api', 'cicd'],
    );

    expect(result.strong, containsAll(['REST APIs', 'CI/CD']));
    expect(result.missing, isEmpty);
  });

  test('recommends adding missing skills', () {
    final result = analyze(
      'Requires Python and AWS.',
      skills: ['Flutter'],
    );

    expect(result.aiRecommendation, contains('Python'));
    expect(result.aiRecommendation, contains('to your CV'));
  });

  test('scores experience against the required years', () {
    final junior = analyze('Engineer, 5+ years required.', years: 2);
    final senior = analyze('Engineer, 5+ years required.', years: 6);

    expect(junior.experience, lessThan(100));
    expect(senior.experience, 100);
  });

  test('overall score stays within 0..100 and is produced', () {
    final result = analyze(
      "Master's preferred. 3+ years. Needs Docker and Kubernetes.",
      skills: ['Flutter'],
      years: 1,
      education: 'high school',
    );

    expect(result.overall, inInclusiveRange(0, 100));
    expect(result.skills, inInclusiveRange(0, 100));
    expect(result.experience, inInclusiveRange(0, 100));
    expect(result.education, inInclusiveRange(0, 100));
    expect(result.keywords, inInclusiveRange(0, 100));
  });

  test('grounds the recommendation in a real project when it matches', () {
    final profile = ProfileData(
      projects: [
        ProfileProject(name: 'ShipLink', description: 'realtime systems', tech: ['Flutter', 'Supabase']),
      ],
    );
    final result = const JobAnalyzer().analyze(
      description: 'Needs Flutter and Supabase.',
      candidateSkills: ['Flutter', 'Supabase'],
      yearsOfExperience: 4,
      education: 'bachelor',
      profile: profile,
    );

    expect(result.aiRecommendation, contains('ShipLink'));
  });
}
