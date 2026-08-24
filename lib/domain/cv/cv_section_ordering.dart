import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/cv_content.dart';

/// Enumerates the possible CV sections in a fixed identity order.
///
/// The prioritization layer reorders these based on target and career stage,
/// but the enum itself never changes — ensuring stable serialization and
/// comparison.
enum CvSection {
  summary,
  experience,
  projects,
  education,
  skills,
  certifications,
  achievements,
  languages,
}

/// Deterministic, target-aware section ordering.
///
/// Inputs: [CareerDna] (career stage), optional [CareerTarget] (target type),
/// and the actual [CvContent] (available sections are never shown as empty).
///
/// Output: ordered list of [CvSection]s. Only sections with content are
/// included.
class CvSectionOrdering {
  const CvSectionOrdering._();

  /// Returns the ordered list of sections that should appear in the CV,
  /// filtered to only sections that have actual content.
  static List<CvSection> orderedSections({
    required CvContent content,
    CareerDna? dna,
    CareerTarget? target,
  }) {
    final stage = dna?.stage;
    final targetType = target?.type;

    // Determine the priority ordering based on stage + target.
    final ordering = _orderingForStageAndTarget(stage, targetType);

    // Filter to sections that actually have content.
    return ordering.where((s) => _hasContent(s, content)).toList();
  }

  /// Returns the project ordering: projects with target-relevant tech first,
  /// then remaining projects by original order.
  static List<CvProject> prioritizeProjects({
    required List<CvProject> projects,
    CareerTarget? target,
  }) {
    if (target == null || projects.isEmpty) return projects;

    final targetRole = target.role.toLowerCase();
    final targetIndustry = (target.industry ?? '').toLowerCase();
    final targetJobDesc = (target.jobDescription ?? '').toLowerCase();
    final targetText = '$targetRole $targetIndustry $targetJobDesc';

    if (targetText.trim().isEmpty) return projects;

    // Score each project by relevance to target.
    final scored = <(CvProject, int)>[];
    for (final p in projects) {
      int score = 0;
      final nameText = p.name.toLowerCase();
      final techText = p.tech.join(' ').toLowerCase();
      final descText = p.description.toLowerCase();
      final bulletText = p.bullets.join(' ').toLowerCase();
      final allText = '$nameText $techText $descText $bulletText';

      // Tech match is strongest signal.
      for (final tech in p.tech) {
        if (targetText.contains(tech.toLowerCase())) score += 3;
      }
      // Role/name match.
      if (targetRole.isNotEmpty && allText.contains(targetRole)) score += 2;
      // Industry match.
      if (targetIndustry.isNotEmpty && allText.contains(targetIndustry)) score++;
      // Any keyword overlap.
      final keywords = targetText.split(RegExp(r'\s+')).where((w) => w.length > 2);
      for (final kw in keywords) {
        if (allText.contains(kw)) score++;
      }
      scored.add((p, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  /// Returns the skill groups ordered by relevance to the target, with
  /// target-relevant categories first.
  static List<CvSkillGroup> prioritizeSkills({
    required List<CvSkillGroup> groups,
    CareerTarget? target,
  }) {
    if (target == null || groups.isEmpty) return groups;

    final targetText = '${target.role} ${target.industry ?? ''} ${target.jobDescription ?? ''}'.toLowerCase();
    if (targetText.trim().isEmpty) return groups;

    // Score each group by how many of its skills appear in target context.
    final scored = <(CvSkillGroup, int)>[];
    for (final g in groups) {
      int score = 0;
      for (final skill in g.skills) {
        if (targetText.contains(skill.toLowerCase())) score++;
      }
      scored.add((g, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  /// Returns experience entries sorted: entries with more target-relevant
  /// content first.
  static List<CvExperience> prioritizeExperience({
    required List<CvExperience> experience,
    CareerTarget? target,
  }) {
    if (target == null || experience.isEmpty) return experience;

    final targetText = '${target.role} ${target.industry ?? ''} ${target.jobDescription ?? ''}'.toLowerCase();
    if (targetText.trim().isEmpty) return experience;

    final scored = <(CvExperience, int)>[];
    for (final e in experience) {
      int score = 0;
      final allText = '${e.role} ${e.company} ${e.description} ${e.bullets.join(' ')}'.toLowerCase();
      if (targetText.contains(e.role.toLowerCase())) score += 3;
      for (final tech in e.bullets) {
        if (targetText.contains(tech.toLowerCase())) score++;
      }
      final keywords = targetText.split(RegExp(r'\s+')).where((w) => w.length > 2);
      for (final kw in keywords) {
        if (allText.contains(kw)) score++;
      }
      scored.add((e, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static bool _hasContent(CvSection section, CvContent c) {
    switch (section) {
      case CvSection.summary:
        return c.summary.trim().isNotEmpty;
      case CvSection.experience:
        return c.experience.isNotEmpty;
      case CvSection.projects:
        return c.projects.isNotEmpty;
      case CvSection.education:
        return c.education.isNotEmpty;
      case CvSection.skills:
        return c.skillGroups.isNotEmpty && c.skillGroups.any((g) => g.skills.isNotEmpty);
      case CvSection.certifications:
        return c.certifications.isNotEmpty;
      case CvSection.achievements:
        return c.achievements.isNotEmpty;
      case CvSection.languages:
        return c.languages.isNotEmpty;
    }
  }

  /// Returns the full section ordering for a given career stage + target type.
  static List<CvSection> _orderingForStageAndTarget(
    CareerStage? stage,
    TargetType? targetType,
  ) {
    // Academic/graduate targets: education first.
    if (targetType == TargetType.academicApplication ||
        targetType == TargetType.graduateProgram) {
      return const [
        CvSection.summary,
        CvSection.education,
        CvSection.projects,
        CvSection.skills,
        CvSection.experience,
        CvSection.certifications,
        CvSection.achievements,
        CvSection.languages,
      ];
    }

    // Fresh graduate / student: projects and education first.
    if (stage == CareerStage.freshGraduate || stage == CareerStage.student) {
      return const [
        CvSection.summary,
        CvSection.projects,
        CvSection.education,
        CvSection.skills,
        CvSection.experience,
        CvSection.certifications,
        CvSection.achievements,
        CvSection.languages,
      ];
    }

    // Career changer: skills and transferable projects first.
    if (stage == CareerStage.careerChanger) {
      return const [
        CvSection.summary,
        CvSection.skills,
        CvSection.projects,
        CvSection.experience,
        CvSection.education,
        CvSection.certifications,
        CvSection.achievements,
        CvSection.languages,
      ];
    }

    // Default (experienced / early career / job target): experience first.
    return const [
      CvSection.summary,
      CvSection.experience,
      CvSection.projects,
      CvSection.skills,
      CvSection.education,
      CvSection.certifications,
      CvSection.achievements,
      CvSection.languages,
    ];
  }
}
