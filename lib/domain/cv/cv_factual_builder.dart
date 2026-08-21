import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/cv_content.dart';

/// Builds a [CvContent] directly from verified [CareerDna] facts.
///
/// This is the deterministic fallback used when AI generation is unavailable
/// or fails validation. It contains ONLY known facts and is clearly labelled
/// as a "Factual CV". It never invents experience, employers, metrics, dates,
/// or any other information, and the [CareerTarget] only influences ordering
/// and emphasis — never the facts themselves.
class CvFactualBuilder {
  const CvFactualBuilder._();

  static const String factualLabel = 'Factual CV';

  static CvContent build(CareerDna dna, {CareerTarget? target}) {
    final profile = dna.profile;

    final experience = [
      for (final e in profile.experience)
        CvExperience(
          role: e.role,
          company: e.company,
          years: e.years,
          source: CvSource.careerDna,
        ),
    ];

    final projects = [
      for (final p in profile.projects)
        CvProject(
          name: p.name,
          description: p.description,
          tech: p.tech,
          source: CvSource.careerDna,
        ),
    ];

    final education = [
      for (final e in profile.education)
        CvEducation(
          degree: e.degree,
          field: e.field,
          source: CvSource.careerDna,
        ),
    ];

    final skillGroups = dna.skills.isEmpty
        ? const <CvSkillGroup>[]
        : [
            CvSkillGroup(
              title: 'Skills',
              skills: dna.skills,
              source: CvSource.careerDna,
            ),
          ];

    final certifications = [
      for (final c in profile.certifications)
        CvCertification(name: c, source: CvSource.careerDna),
    ];

    final achievements = [
      for (final a in profile.achievements)
        CvAchievement(text: a, source: CvSource.careerDna),
    ];

    final languages = [
      for (final l in profile.languages)
        CvLanguage(name: l, source: CvSource.careerDna),
    ];

    final header = CvHeader(
      title: target?.role ?? dna.targetRole,
      subtitle: _emphasisFor(dna, target),
    );

    return CvContent(
      header: header,
      summary: profile.summary,
      experience: experience,
      projects: projects,
      education: education,
      skillGroups: skillGroups,
      certifications: certifications,
      achievements: achievements,
      languages: languages,
      sourceLabel: factualLabel,
    );
  }

  /// Target may influence which factual sections are emphasized, never invented.
  static String _emphasisFor(CareerDna dna, CareerTarget? target) {
    if (target?.role.isNotEmpty == true) return target!.role;
    if (dna.targetRole.isNotEmpty) return dna.targetRole;
    if (dna.stage != null) return dna.stage!.name;
    return '';
  }
}
