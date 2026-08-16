import '../../domain/entities/career_dna.dart';
import '../../domain/entities/intake_question.dart';
import '../../domain/entities/profile_data.dart';

/// The full adaptive-intake question bank, expressed as structured configuration.
///
/// Visibility is driven by [IntakeQuestion.stages] / [goals] / [fields] plus
/// optional [IntakeQuestion.condition] callbacks — never by branching inside the
/// UI. `buildIntakeQuestions()` returns every question; `questionsFor(...)` filters
/// to what a given user should actually see.
List<IntakeQuestion> buildIntakeQuestions() => [
      // ---- Identity (always) ----
      IntakeQuestion(
        id: 'target_role',
        category: IntakeCategory.identity,
        key: 'targetRole',
        inputType: IntakeInputType.shortText,
        question: (l) => l.intakeTargetRole,
        placeholder: (l) => l.intakeTargetRoleHint,
      ),
      IntakeQuestion(
        id: 'target_industry',
        category: IntakeCategory.identity,
        key: 'targetIndustry',
        inputType: IntakeInputType.shortText,
        question: (l) => l.intakeTargetIndustry,
        placeholder: (l) => l.intakeTargetIndustryHint,
        options: const [
          'Software Engineering',
          'Data & AI',
          'Product Management',
          'UX/UI Design',
          'Digital Marketing',
          'Finance & Banking',
          'Healthcare',
          'Education',
          'Sales & Business Dev',
          'Operations & Logistics',
        ],
      ),
      IntakeQuestion(
        id: 'summary',
        category: IntakeCategory.identity,
        key: 'summary',
        inputType: IntakeInputType.longText,
        question: (l) => l.intakeAboutYou,
        placeholder: (l) => l.intakeAboutYouHint,
      ),
      IntakeQuestion(
        id: 'skills',
        category: IntakeCategory.skills,
        key: 'skills',
        inputType: IntakeInputType.tags,
        question: (l) => l.intakeSkills,
        placeholder: (l) => l.intakeSkillsHint,
        options: const [
          'Flutter',
          'Dart',
          'React',
          'Python',
          'SQL',
          'Figma',
          'Excel',
          'Project Management',
          'Communication',
          'Leadership',
          'Data Analysis',
          'Machine Learning',
          'UI/UX',
          'SEO',
          'Content Writing',
        ],
      ),

      // ---- Education (everyone) ----
      IntakeQuestion(
        id: 'education',
        category: IntakeCategory.education,
        key: 'education',
        inputType: IntakeInputType.structuredList,
        question: (l) => l.intakeEducation,
        listSchema: [
          ListField(name: 'degree', inputType: IntakeInputType.shortText, label: (l) => l.intakeDegree),
          ListField(name: 'field', inputType: IntakeInputType.shortText, label: (l) => l.intakeFieldStudy),
        ],
      ),

      // ---- Experience (early / experienced / career changer) ----
      IntakeQuestion(
        id: 'experience',
        category: IntakeCategory.experience,
        key: 'experience',
        inputType: IntakeInputType.structuredList,
        stages: [CareerStage.earlyCareer, CareerStage.experienced, CareerStage.careerChanger],
        question: (l) => l.intakeExperience,
        listSchema: [
          ListField(name: 'role', inputType: IntakeInputType.shortText, label: (l) => l.intakePlaceholderRole),
          ListField(name: 'company', inputType: IntakeInputType.shortText, label: (l) => l.intakeCompany),
          ListField(name: 'years', inputType: IntakeInputType.shortText, label: (l) => l.intakeYears),
        ],
      ),

      // ---- Projects (everyone) ----
      IntakeQuestion(
        id: 'projects',
        category: IntakeCategory.projects,
        key: 'projects',
        inputType: IntakeInputType.structuredList,
        question: (l) => l.intakeProjects,
        listSchema: [
          ListField(name: 'name', inputType: IntakeInputType.shortText, label: (l) => l.intakeProjectName),
          ListField(name: 'description', inputType: IntakeInputType.longText, label: (l) => l.intakeProjectDesc),
          ListField(name: 'tech', inputType: IntakeInputType.tags, label: (l) => l.intakeProjectTech),
        ],
      ),

      // ---- Student-specific ----
      IntakeQuestion(
        id: 'expected_graduation',
        category: IntakeCategory.education,
        key: 'expectedGraduation',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.student],
        question: (l) => l.intakeExpectedGraduation,
      ),
      IntakeQuestion(
        id: 'coursework',
        category: IntakeCategory.education,
        key: 'coursework',
        inputType: IntakeInputType.stringList,
        stages: [CareerStage.student, CareerStage.freshGraduate],
        question: (l) => l.intakeCoursework,
        help: (l) => l.intakeAltEvidence,
      ),

      // ---- Fresh-graduate-specific ----
      IntakeQuestion(
        id: 'internships',
        category: IntakeCategory.experience,
        key: 'internships',
        inputType: IntakeInputType.stringList,
        stages: [CareerStage.student, CareerStage.freshGraduate],
        question: (l) => l.intakeInternships,
      ),
      IntakeQuestion(
        id: 'graduation_status',
        category: IntakeCategory.education,
        key: 'graduationStatus',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.freshGraduate],
        question: (l) => l.intakeGraduationStatus,
        options: const ['Graduated', 'Expected to graduate', 'Currently enrolled'],
      ),

      // ---- Early-career-specific ----
      IntakeQuestion(
        id: 'current_role',
        category: IntakeCategory.experience,
        key: 'currentRole',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.earlyCareer, CareerStage.experienced],
        question: (l) => l.intakeCurrentRole,
      ),
      IntakeQuestion(
        id: 'career_direction',
        category: IntakeCategory.context,
        key: 'careerDirection',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.earlyCareer],
        question: (l) => l.intakeCareerDirection,
        options: const ['Individual contributor', 'Team lead', 'Manager', 'Founder'],
      ),

      // ---- Experienced-specific ----
      IntakeQuestion(
        id: 'leadership',
        category: IntakeCategory.experience,
        key: 'leadership',
        inputType: IntakeInputType.stringList,
        stages: [CareerStage.experienced],
        question: (l) => l.intakeLeadership,
      ),
      IntakeQuestion(
        id: 'measurable_impact',
        category: IntakeCategory.achievements,
        key: 'measurableImpact',
        inputType: IntakeInputType.stringList,
        stages: [CareerStage.experienced],
        question: (l) => l.intakeMeasurableImpact,
      ),
      IntakeQuestion(
        id: 'career_progression',
        category: IntakeCategory.context,
        key: 'careerProgression',
        inputType: IntakeInputType.longText,
        stages: [CareerStage.experienced],
        question: (l) => l.intakeCareerProgression,
      ),

      // ---- Career-changer-specific ----
      IntakeQuestion(
        id: 'previous_career',
        category: IntakeCategory.careerChanger,
        key: 'previousCareer',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.careerChanger],
        question: (l) => l.intakePreviousCareer,
      ),
      IntakeQuestion(
        id: 'previous_role',
        category: IntakeCategory.careerChanger,
        key: 'previousRole',
        inputType: IntakeInputType.shortText,
        stages: [CareerStage.careerChanger],
        question: (l) => l.intakePreviousRole,
      ),
      IntakeQuestion(
        id: 'transferable_skills',
        category: IntakeCategory.careerChanger,
        key: 'transferableSkills',
        inputType: IntakeInputType.tags,
        stages: [CareerStage.careerChanger],
        question: (l) => l.intakeTransferableSkills,
        placeholder: (l) => l.intakeSkillsHint,
      ),
      IntakeQuestion(
        id: 'reason_transition',
        category: IntakeCategory.careerChanger,
        key: 'reasonForTransition',
        inputType: IntakeInputType.longText,
        stages: [CareerStage.careerChanger],
        question: (l) => l.intakeReasonTransition,
      ),

      // ---- Evidence (everyone) ----
      IntakeQuestion(
        id: 'certifications',
        category: IntakeCategory.certifications,
        key: 'certifications',
        inputType: IntakeInputType.stringList,
        question: (l) => l.intakeCerts,
        options: const ['IELTS', 'TOEFL', 'AWS', 'Microsoft Azure', 'Google Analytics', 'PMP', 'Scrum', 'Six Sigma'],
      ),
      IntakeQuestion(
        id: 'achievements',
        category: IntakeCategory.achievements,
        key: 'achievements',
        inputType: IntakeInputType.stringList,
        question: (l) => l.intakeAchievements,
        options: const ['Employee of the Year', 'Top Sales', 'Published Paper', 'Hackathon Winner'],
      ),
      IntakeQuestion(
        id: 'languages',
        category: IntakeCategory.languages,
        key: 'languages',
        inputType: IntakeInputType.stringList,
        question: (l) => l.intakeLanguages,
        options: const [
          'Arabic',
          'English',
          'French',
          'Spanish',
          'German',
          'Mandarin',
          'Turkish',
          'Italian',
          'Russian',
          'Japanese',
        ],
      ),
    ];

/// Questions visible for the given user context at this moment. [answers] lets
/// conditional questions appear/disappear as the user types.
List<IntakeQuestion> questionsFor({
  required CareerStage? stage,
  required CareerGoal? goal,
  required TargetField? field,
  required Map<String, dynamic> answers,
}) =>
    buildIntakeQuestions()
        .where((q) => q.appliesTo(stage: stage, goal: goal, field: field, answers: answers))
        .toList();

/// Builds a [CareerDna] from the raw intake [answers] plus the pre-auth [choices].
CareerDna applyAnswersToDna({
  required CareerDna base,
  required Map<String, dynamic> answers,
}) {
  final education = _asEducation(answers['education']);
  final experience = _asExperience(answers['experience']);
  final projects = _asProjects(answers['projects']);
  final skills = _asList(answers['skills']);
  final certifications = _asList(answers['certifications']);
  final achievements = _asList(answers['achievements']);
  final languages = _asList(answers['languages']);

  final v1 = answers['expectedGraduation'] as String? ?? '';
  final v2 = answers['graduationStatus'] as String? ?? '';
  final v3 = answers['currentRole'] as String? ?? '';
  final v4 = answers['careerDirection'] as String? ?? '';
  final v5 = answers['careerProgression'] as String? ?? '';
  final v6 = answers['previousCareer'] as String? ?? '';
  final v7 = answers['previousRole'] as String? ?? '';
  final v8 = answers['reasonForTransition'] as String? ?? '';

  final extras = <String, dynamic>{
    if (_asList(answers['coursework']).isNotEmpty) 'coursework': _asList(answers['coursework']),
    if (_asList(answers['internships']).isNotEmpty) 'internships': _asList(answers['internships']),
    if (_asList(answers['leadership']).isNotEmpty) 'leadership': _asList(answers['leadership']),
    if (_asList(answers['measurableImpact']).isNotEmpty)
      'measurableImpact': _asList(answers['measurableImpact']),
    if (_asList(answers['transferableSkills']).isNotEmpty)
      'transferableSkills': _asList(answers['transferableSkills']),
    if (v1.trim().isNotEmpty) 'expectedGraduation': v1.trim(),
    if (v2.trim().isNotEmpty) 'graduationStatus': v2.trim(),
    if (v3.trim().isNotEmpty) 'currentRole': v3.trim(),
    if (v4.trim().isNotEmpty) 'careerDirection': v4.trim(),
    if (v5.trim().isNotEmpty) 'careerProgression': v5.trim(),
    if (v6.trim().isNotEmpty) 'previousCareer': v6.trim(),
    if (v7.trim().isNotEmpty) 'previousRole': v7.trim(),
    if (v8.trim().isNotEmpty) 'reasonForTransition': v8.trim(),
  };

  return base.copyWith(
    targetRole: (answers['targetRole'] as String? ?? '').trim(),
    targetIndustry: (answers['targetIndustry'] as String? ?? '').trim(),
    skills: skills,
    profile: ProfileData(
      summary: (answers['summary'] as String? ?? '').trim(),
      education: education,
      experience: experience,
      projects: projects,
      certifications: certifications,
      achievements: achievements,
      languages: languages,
    ),
    extras: extras,
  );
}

List<String> _asList(Object? value) {
  if (value is List<String>) return value.where((e) => e.trim().isNotEmpty).toList();
  if (value is List) return [for (final e in value) e.toString().trim()].where((e) => e.isNotEmpty).toList();
  return const [];
}

List<ProfileEducation> _asEducation(Object? value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is Map)
        ProfileEducation(
          degree: (e['degree'] as String? ?? '').trim(),
          field: (e['field'] as String? ?? '').trim(),
        )
  ].where((e) => e.degree.isNotEmpty || e.field.isNotEmpty).toList();
}

List<ProfileExperience> _asExperience(Object? value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is Map)
        ProfileExperience(
          role: (e['role'] as String? ?? '').trim(),
          company: (e['company'] as String? ?? '').trim(),
          years: int.tryParse((e['years'] as String? ?? '').trim()) ?? 0,
        )
  ].where((e) => e.role.isNotEmpty).toList();
}

List<ProfileProject> _asProjects(Object? value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is Map)
        ProfileProject(
          name: (e['name'] as String? ?? '').trim(),
          description: (e['description'] as String? ?? '').trim(),
          tech: _asList(e['tech']),
        )
  ].where((e) => e.name.isNotEmpty).toList();
}
