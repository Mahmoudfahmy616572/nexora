import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/domain/analysis/career_intelligence_engine.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_intelligence.dart';
import 'package:nexora/domain/entities/profile_data.dart';

CareerDna dna({
  CareerStage? stage,
  String targetRole = '',
  ProfileData profile = const ProfileData(),
  List<String> skills = const [],
}) =>
    CareerDna(stage: stage, targetRole: targetRole, profile: profile, skills: skills);

void main() {
  group('Career Intelligence engine', () {
    test('empty fresh graduate scores 0 and never penalizes missing experience', () {
      final intel = computeCareerIntelligence(
        dna: dna(stage: CareerStage.freshGraduate),
        profile: const ProfileData(),
        skills: const [],
      );
      expect(intel.completeness, 0);
      expect(intel.readiness, ReadinessLevel.starter);
      expect(intel.experience, ExperienceStrength.none);
      // Experience is not required for fresh grads, so it must not appear as
      // missing or as a weakness.
      expect(intel.missingInformation, isNot(contains(ProfileGap.experience)));
      expect(intel.weaknesses, isNot(contains(ProfileGap.experience)));
      expect(intel.hasClearDirection, isFalse);
    });

    test('experienced developer with strong evidence is interview-ready', () {
      final profile = ProfileData(
        summary: 'Flutter engineer.',
        education: const [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
        experience: const [
          ProfileExperience(role: 'Flutter Dev', company: 'A', years: 2),
          ProfileExperience(role: 'Senior Flutter Dev', company: 'B', years: 3),
        ],
        projects: const [
          ProfileProject(name: 'P1', description: 'd', tech: ['Flutter', 'Dart']),
          ProfileProject(name: 'P2', description: 'd', tech: ['Dart']),
          ProfileProject(name: 'P3', description: 'd', tech: ['Firebase']),
        ],
        certifications: const [ProfileCertification(name: 'AWS')],
        achievements: const ['Hackathon'],
        languages: const ['Arabic'],
      );
      final intel = computeCareerIntelligence(
        dna: dna(stage: CareerStage.experienced, targetRole: 'Flutter Lead', profile: profile),
        profile: profile,
        skills: const ['Flutter', 'Dart', 'Firebase'],
      );
      expect(intel.completeness, greaterThanOrEqualTo(90));
      expect(intel.readiness, ReadinessLevel.interviewReady);
      expect(intel.strongestSkills, contains('Flutter'));
      expect(intel.strongestSkills, contains('Dart'));
      expect(intel.strongestSkills, contains('Firebase'));
      expect(intel.supportingSkills, isEmpty);
      expect(intel.experience, ExperienceStrength.strong);
      expect(intel.weaknesses, isEmpty);
    });

    test('skills without project evidence are flagged as a weakness', () {
      final profile = ProfileData(
        summary: 'Student.',
        education: const [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
        projects: const [],
      );
      final intel = computeCareerIntelligence(
        dna: dna(stage: CareerStage.student, targetRole: 'Data Scientist', profile: profile),
        profile: profile,
        skills: const ['Python', 'SQL'],
      );
      expect(intel.strongestSkills, isEmpty);
      expect(intel.supportingSkills, contains('Python'));
      expect(intel.weaknesses, contains(ProfileGap.skillEvidence));
    });

    test('missing target role is reported when direction is unclear', () {
      final intel = computeCareerIntelligence(
        dna: dna(stage: CareerStage.earlyCareer, targetRole: ''),
        profile: const ProfileData(
          summary: 'Dev.',
          education: [ProfileEducation(degree: 'B.Sc.', field: 'CS')],
          experience: [ProfileExperience(role: 'Dev', company: 'A', years: 1)],
          projects: [ProfileProject(name: 'P', description: 'd', tech: ['TS'])],
        ),
        skills: const ['TypeScript'],
      );
      expect(intel.hasClearDirection, isFalse);
      expect(intel.missingInformation, contains(ProfileGap.targetRole));
    });
  });
}
