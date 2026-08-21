/// Strength of the user's real work experience, derived from their Career DNA.
enum ExperienceStrength {
  none,
  limited,
  moderate,
  strong,
}

/// Strength of the user's education, derived from their Career DNA.
enum EducationStrength {
  none,
  basic,
  standard,
  strong,
}

/// Overall readiness to interview / apply, derived from the Career Intelligence
/// completeness score.
enum ReadinessLevel {
  starter,
  building,
  strong,
  interviewReady,
}

/// A specific area of the profile that is missing or weak. Used so the UI can
/// show localized, actionable guidance without hard-coding English strings in
/// the engine.
enum ProfileGap {
  targetRole,
  summary,
  skills,
  experience,
  projects,
  education,
  certifications,
  achievements,
  languages,
  skillEvidence,
}

/// Deterministic, AI-free assessment of a user's career profile.
///
/// Every field is computed purely from the user's real Career DNA + profile
/// evidence, so the result never fabricates experience, skills, or education.
class CareerIntelligence {
  const CareerIntelligence({
    required this.completeness,
    required this.readiness,
    required this.strongestSkills,
    required this.supportingSkills,
    required this.experience,
    required this.education,
    required this.hasClearDirection,
    required this.missingInformation,
    required this.weaknesses,
  });

  /// 0-100 measure of how ready the profile is for the user's stage.
  final int completeness;

  final ReadinessLevel readiness;

  /// Skills backed by at least one project's technology list.
  final List<String> strongestSkills;

  /// Declared skills with no project evidence yet.
  final List<String> supportingSkills;

  final ExperienceStrength experience;

  final EducationStrength education;

  /// True when the user has named a target role or field.
  final bool hasClearDirection;

  /// Required evidence that is still missing for the user's stage.
  final List<ProfileGap> missingInformation;

  /// Present-but-weak areas that hold the profile back.
  final List<ProfileGap> weaknesses;
}
