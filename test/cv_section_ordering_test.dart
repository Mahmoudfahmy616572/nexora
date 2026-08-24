import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/cv/cv_section_ordering.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/domain/entities/career_target.dart';
import 'package:nexora/domain/entities/cv_content.dart';

CvContent _fullContent() => CvContent(
      header: const CvHeader(name: 'Test'),
      summary: 'Summary text',
      experience: const [CvExperience(role: 'Dev', company: 'Co')],
      projects: const [CvProject(name: 'App', tech: ['Flutter'])],
      education: const [CvEducation(degree: 'BSc')],
      skillGroups: const [CvSkillGroup(title: 'Skills', skills: ['Dart'])],
      certifications: const [CvCertification(name: 'C1')],
      achievements: const [CvAchievement(text: 'A1')],
      languages: const [CvLanguage(name: 'English')],
    );

void main() {
  group('CvSectionOrdering.orderedSections', () {
    test('default ordering for experienced developer', () {
      final sections = CvSectionOrdering.orderedSections(
        content: _fullContent(),
        dna: CareerDna(stage: CareerStage.experienced),
      );
      expect(sections.first, CvSection.summary);
      expect(sections, contains(CvSection.experience));
      expect(sections, contains(CvSection.projects));
      expect(sections, contains(CvSection.education));
    });

    test('fresh graduate gets projects before experience', () {
      final sections = CvSectionOrdering.orderedSections(
        content: _fullContent(),
        dna: CareerDna(stage: CareerStage.freshGraduate),
      );
      final projectIdx = sections.indexOf(CvSection.projects);
      final experienceIdx = sections.indexOf(CvSection.experience);
      expect(projectIdx, lessThan(experienceIdx));
    });

    test('student gets education and projects first', () {
      final sections = CvSectionOrdering.orderedSections(
        content: _fullContent(),
        dna: CareerDna(stage: CareerStage.student),
      );
      final projectIdx = sections.indexOf(CvSection.projects);
      final educationIdx = sections.indexOf(CvSection.education);
      expect(projectIdx, lessThan(3));
      expect(educationIdx, lessThan(4));
    });

    test('academic target puts education first', () {
      final sections = CvSectionOrdering.orderedSections(
        content: _fullContent(),
        dna: CareerDna(stage: CareerStage.student),
        target: CareerTarget(
          id: 't',
          userId: 'u',
          type: TargetType.academicApplication,
          role: 'PhD',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final educationIdx = sections.indexOf(CvSection.education);
      expect(educationIdx, lessThan(3));
    });

    test('career changer puts skills first', () {
      final sections = CvSectionOrdering.orderedSections(
        content: _fullContent(),
        dna: CareerDna(stage: CareerStage.careerChanger),
      );
      final skillsIdx = sections.indexOf(CvSection.skills);
      final experienceIdx = sections.indexOf(CvSection.experience);
      expect(skillsIdx, lessThan(experienceIdx));
    });

    test('empty sections are excluded', () {
      final content = CvContent(
        header: const CvHeader(name: 'Test'),
        summary: 'Summary',
        projects: const [CvProject(name: 'App')],
      );
      final sections = CvSectionOrdering.orderedSections(content: content);
      expect(sections, isNot(contains(CvSection.experience)));
      expect(sections, isNot(contains(CvSection.education)));
      expect(sections, contains(CvSection.summary));
      expect(sections, contains(CvSection.projects));
    });
  });

  group('CvSectionOrdering.prioritizeProjects', () {
    test('returns same list when no target', () {
      final projects = [
        const CvProject(name: 'A', tech: ['Flutter']),
        const CvProject(name: 'B', tech: ['React']),
      ];
      final result = CvSectionOrdering.prioritizeProjects(projects: projects);
      expect(result.map((p) => p.name).toList(), ['A', 'B']);
    });

    test('sorts by tech relevance to target', () {
      final projects = [
        const CvProject(name: 'Web App', tech: ['React', 'Node']),
        const CvProject(name: 'Mobile App', tech: ['Flutter', 'Dart']),
      ];
      final result = CvSectionOrdering.prioritizeProjects(
        projects: projects,
        target: CareerTarget(
          id: 't',
          userId: 'u',
          type: TargetType.job,
          role: 'Flutter Developer',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(result.first.name, 'Mobile App');
    });
  });

  group('CvSectionOrdering.prioritizeSkills', () {
    test('returns same groups when no target', () {
      final groups = [
        const CvSkillGroup(title: 'A', skills: ['Dart']),
        const CvSkillGroup(title: 'B', skills: ['React']),
      ];
      final result = CvSectionOrdering.prioritizeSkills(groups: groups);
      expect(result.length, 2);
    });

    test('prioritizes groups with target-relevant skills', () {
      final groups = [
        const CvSkillGroup(title: 'DevOps', skills: ['Docker', 'K8s']),
        const CvSkillGroup(title: 'Mobile', skills: ['Flutter', 'Dart']),
      ];
      final result = CvSectionOrdering.prioritizeSkills(
        groups: groups,
        target: CareerTarget(
          id: 't',
          userId: 'u',
          type: TargetType.job,
          role: 'Flutter Developer',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(result.first.title, 'Mobile');
    });
  });
}
