import '../entities/career_dna.dart';
import '../entities/career_intelligence.dart';
import '../entities/profile_data.dart';

/// Deterministic Career Intelligence engine.
///
/// Given the user's real Career DNA identity, structured profile evidence, and
/// declared skills, it produces an explainable [CareerIntelligence] assessment.
/// It never calls any AI or external service and never invents claims — only
/// verified data is reflected.
CareerIntelligence computeCareerIntelligence({
  required CareerDna dna,
  required ProfileData profile,
  required List<String> skills,
}) {
  final stage = dna.stage;

  // Skills split into "evidenced" (appear in a project's tech list) and
  // "supporting" (declared but not yet backed by project evidence).
  final evidencedTech = <String>{
    for (final project in profile.projects)
      for (final tech in project.tech) tech.trim().toLowerCase(),
  };
  final strongest = <String>[];
  final supporting = <String>[];
  for (final skill in skills) {
    final key = skill.trim().toLowerCase();
    if (key.isEmpty) continue;
    if (evidencedTech.contains(key)) {
      strongest.add(skill.trim());
    } else {
      supporting.add(skill.trim());
    }
  }

  final experience = _experienceStrength(profile);
  final education = _educationStrength(profile);

  final hasClearDirection =
      dna.targetRole.trim().isNotEmpty || dna.targetField != null;

  final requiredGaps = _requiredGapsForStage(stage);
  final missingInformation = <ProfileGap>[
    for (final gap in requiredGaps)
      if (!_isSatisfied(gap, dna: dna, profile: profile, skills: skills, strongest: strongest))
        gap,
  ];

  final weaknesses = <ProfileGap>[];
  if (_requiresExperience(stage) && experience == ExperienceStrength.none) {
    weaknesses.add(ProfileGap.experience);
  }
  if (skills.isNotEmpty && strongest.isEmpty) {
    weaknesses.add(ProfileGap.skillEvidence);
  }
  if (education == EducationStrength.none) {
    weaknesses.add(ProfileGap.education);
  }

  final completeness = _completeness(
    stage: stage,
    profile: profile,
    skills: skills,
    requiresExperience: _requiresExperience(stage),
  );

  return CareerIntelligence(
    completeness: completeness,
    readiness: _readinessFor(completeness),
    strongestSkills: strongest,
    supportingSkills: supporting,
    experience: experience,
    education: education,
    hasClearDirection: hasClearDirection,
    missingInformation: missingInformation,
    weaknesses: weaknesses,
  );
}

bool _requiresExperience(CareerStage? stage) =>
    stage == CareerStage.earlyCareer ||
    stage == CareerStage.experienced ||
    stage == CareerStage.careerChanger;

ExperienceStrength _experienceStrength(ProfileData profile) {
  if (profile.experience.isEmpty) return ExperienceStrength.none;
  final count = profile.experience.length;
  final years = profile.experience.fold<double>(
    0,
    (sum, e) => sum + e.effectiveMonths / 12.0,
  );
  if (count >= 3 || years >= 4) return ExperienceStrength.strong;
  if (count >= 2 || years >= 2) return ExperienceStrength.moderate;
  return ExperienceStrength.limited;
}

EducationStrength _educationStrength(ProfileData profile) {
  final count = profile.education.length;
  if (count == 0) return EducationStrength.none;
  if (count == 1) return EducationStrength.basic;
  if (count == 2) return EducationStrength.standard;
  return EducationStrength.strong;
}

List<ProfileGap> _requiredGapsForStage(CareerStage? stage) {
  switch (stage) {
    case CareerStage.student:
      return const [ProfileGap.targetRole, ProfileGap.skills, ProfileGap.projects, ProfileGap.education];
    case CareerStage.freshGraduate:
      return const [ProfileGap.targetRole, ProfileGap.skills, ProfileGap.education, ProfileGap.projects];
    case CareerStage.earlyCareer:
      return const [
        ProfileGap.targetRole,
        ProfileGap.skills,
        ProfileGap.experience,
        ProfileGap.education,
        ProfileGap.projects,
      ];
    case CareerStage.experienced:
      return const [
        ProfileGap.targetRole,
        ProfileGap.skills,
        ProfileGap.experience,
        ProfileGap.education,
        ProfileGap.projects,
        ProfileGap.achievements,
      ];
    case CareerStage.careerChanger:
      return const [
        ProfileGap.targetRole,
        ProfileGap.skills,
        ProfileGap.experience,
        ProfileGap.education,
      ];
    case null:
      return const [
        ProfileGap.targetRole,
        ProfileGap.skills,
        ProfileGap.experience,
        ProfileGap.education,
        ProfileGap.projects,
      ];
  }
}

bool _isSatisfied(
  ProfileGap gap, {
  required CareerDna dna,
  required ProfileData profile,
  required List<String> skills,
  required List<String> strongest,
}) {
  switch (gap) {
    case ProfileGap.targetRole:
      return dna.targetRole.trim().isNotEmpty;
    case ProfileGap.summary:
      return profile.summary.trim().isNotEmpty;
    case ProfileGap.skills:
      return skills.isNotEmpty;
    case ProfileGap.experience:
      return profile.experience.isNotEmpty;
    case ProfileGap.projects:
      return profile.projects.isNotEmpty;
    case ProfileGap.education:
      return profile.education.isNotEmpty;
    case ProfileGap.certifications:
      return profile.certifications.isNotEmpty;
    case ProfileGap.achievements:
      return profile.achievements.isNotEmpty;
    case ProfileGap.languages:
      return profile.languages.isNotEmpty;
    case ProfileGap.skillEvidence:
      return strongest.isNotEmpty;
  }
}

int _completeness({
  required CareerStage? stage,
  required ProfileData profile,
  required List<String> skills,
  required bool requiresExperience,
}) {
  const int summaryWeight = 12;
  const int skillsWeight = 18;
  const int educationWeight = 18;
  const int projectsWeight = 22;
  const int certWeight = 5;
  const int achievementWeight = 5;
  const int languageWeight = 5;
  const int experienceWeight = 15;

  int earned = 0;
  int total = 0;

  // Summary
  total += summaryWeight;
  if (profile.summary.trim().isNotEmpty) earned += summaryWeight;

  // Skills (full weight only with 3+; partial for 1-2)
  total += skillsWeight;
  if (skills.length >= 3) {
    earned += skillsWeight;
  } else if (skills.isNotEmpty) {
    earned += 10;
  }

  // Education
  total += educationWeight;
  if (profile.education.isNotEmpty) earned += educationWeight;

  // Projects
  total += projectsWeight;
  if (profile.projects.isNotEmpty) earned += projectsWeight;

  // Certifications / achievements / languages
  total += certWeight;
  if (profile.certifications.isNotEmpty) earned += certWeight;
  total += achievementWeight;
  if (profile.achievements.isNotEmpty) earned += achievementWeight;
  total += languageWeight;
  if (profile.languages.isNotEmpty) earned += languageWeight;

  // Experience — only weighted when the user's stage requires it, so fresh
  // graduates / students are not penalized for having no experience yet.
  if (requiresExperience) {
    total += experienceWeight;
    if (profile.experience.isNotEmpty) earned += experienceWeight;
  }

  if (total == 0) return 0;
  return ((earned / total) * 100).round().clamp(0, 100);
}

ReadinessLevel _readinessFor(int completeness) {
  if (completeness >= 90) return ReadinessLevel.interviewReady;
  if (completeness >= 70) return ReadinessLevel.strong;
  if (completeness >= 40) return ReadinessLevel.building;
  return ReadinessLevel.starter;
}
