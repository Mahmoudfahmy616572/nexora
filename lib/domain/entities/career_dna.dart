import 'profile_data.dart';

/// What the user wants the platform to help them achieve.
enum CareerGoal {
  job,
  cv,
  internship,
  masters,
  scholarship,
  careerChange,
  improve,
  unsure,
}

/// Where the user is in their career journey. Drives the adaptive intake.
enum CareerStage {
  student,
  freshGraduate,
  earlyCareer,
  experienced,
  careerChanger,
}

/// The broad field the user is targeting. Mirrors the product's interest
/// domains so a single pick can seed the rest of the experience.
enum TargetField {
  programming,
  design,
  writing,
  data,
  marketing,
  teaching,
  business,
  engineering,
  medicine,
  law,
  finance,
  psychology,
  photography,
  music,
  sports,
  hospitality,
  agriculture,
  science,
  sales,
  other,
}

/// The user's evolving professional identity — the single source of truth for
/// Phases 1-3.
///
/// Wraps the structured [ProfileData] plus the lightweight identity captured up
/// front (goal, stage, target field/role/industry) and tracks a [version] so the
/// platform can detect meaningful career evolution over time.
class CareerDna {
  CareerDna({
    this.id,
    this.goal,
    this.stage,
    this.targetField,
    this.targetRole = '',
    this.targetIndustry = '',
    this.preferences = const [],
    this.profile = const ProfileData(),
    this.skills = const [],
    this.extras = const {},
    this.version = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String? id;
  final CareerGoal? goal;
  final CareerStage? stage;
  final TargetField? targetField;
  final String targetRole;
  final String targetIndustry;
  final List<String> preferences;
  final ProfileData profile;
  final List<String> skills;

  /// Persona-specific structured answers gathered by the adaptive intake
  /// (e.g. graduation status, coursework, previous career, transferable skills).
  /// Kept as a free-form map so the schema stays stable as questions evolve.
  final Map<String, dynamic> extras;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Reads a typed value from [extras], defaulting to [fallback].
  T? extra<T>(String key, [T? fallback]) => extras[key] as T? ?? fallback;

  CareerDna copyWith({
    String? id,
    CareerGoal? goal,
    CareerStage? stage,
    TargetField? targetField,
    String? targetRole,
    String? targetIndustry,
    List<String>? preferences,
    ProfileData? profile,
    List<String>? skills,
    Map<String, dynamic>? extras,
    int? version,
    DateTime? updatedAt,
  }) =>
      CareerDna(
        id: id ?? this.id,
        goal: goal ?? this.goal,
        stage: stage ?? this.stage,
        targetField: targetField ?? this.targetField,
        targetRole: targetRole ?? this.targetRole,
        targetIndustry: targetIndustry ?? this.targetIndustry,
        preferences: preferences ?? this.preferences,
        profile: profile ?? this.profile,
        skills: skills ?? this.skills,
        extras: extras ?? this.extras,
        version: version ?? this.version,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// 0..1 measure of how complete the identity is. Used by the Command Center
  /// to recommend the next best action ("complete your Career DNA").
  double get completeness {
    var points = 0;
    const total = 11;
    if (goal != null) points++;
    if (stage != null) points++;
    if (targetField != null) points++;
    if (targetRole.trim().isNotEmpty) points++;
    if (targetIndustry.trim().isNotEmpty) points++;
    if (profile.summary.trim().isNotEmpty) points++;
    if (profile.experience.isNotEmpty) points++;
    if (profile.projects.isNotEmpty) points++;
    if (profile.education.isNotEmpty) points++;
    if (skills.isNotEmpty) points++;
    if (profile.certifications.isNotEmpty ||
        profile.achievements.isNotEmpty ||
        profile.languages.isNotEmpty) {
      points++;
    }
    return points / total;
  }

  bool get isEmpty =>
      goal == null &&
      stage == null &&
      targetField == null &&
      targetRole.trim().isEmpty &&
      targetIndustry.trim().isEmpty &&
      profile.isEmpty &&
      skills.isEmpty;

  /// True when the user has entered at least some real evidence, so the intake
  /// can let them continue without forcing a specific field. Prevents dead ends
  /// for users who, e.g., only added education or a single project.
  bool get hasMeaningfulContent =>
      targetRole.trim().isNotEmpty ||
      skills.isNotEmpty ||
      profile.summary.trim().isNotEmpty ||
      profile.education.isNotEmpty ||
      profile.projects.isNotEmpty ||
      profile.experience.isNotEmpty ||
      profile.certifications.isNotEmpty ||
      profile.achievements.isNotEmpty ||
      profile.languages.isNotEmpty;

  Map<String, Object?> toRow() => {
        'goal': goal?.name,
        'career_stage': stage?.name,
        'target_field': targetField?.name,
        'target_role': targetRole,
        'target_industry': targetIndustry,
        'preferences': preferences,
        'content': {...profile.toJson(), '_extras': extras},
        'skills': skills,
        'version': version,
      };

  /// A snapshot row for the `career_dna_versions` history table.
  Map<String, Object?> toVersionRow() => {
        'goal': goal?.name,
        'career_stage': stage?.name,
        'target_field': targetField?.name,
        'target_role': targetRole,
        'target_industry': targetIndustry,
        'preferences': preferences,
        'content': {...profile.toJson(), '_extras': extras},
        'skills': skills,
        'version': version,
      };

  factory CareerDna.fromRow(Map<String, dynamic> row) {
    final content = row['content'];
    final profile = content is Map
        ? ProfileData.fromJson(Map<String, dynamic>.from(content))
        : const ProfileData();
    final extras = content is Map && content['_extras'] is Map
        ? Map<String, dynamic>.from(content['_extras'] as Map)
        : <String, dynamic>{};
    return CareerDna(
      id: row['user_id'] as String?,
      goal: _enum<CareerGoal>(CareerGoal.values, row['goal']),
      stage: _enum<CareerStage>(CareerStage.values, row['career_stage']),
      targetField: _enum<TargetField>(TargetField.values, row['target_field']),
      targetRole: (row['target_role'] as String?) ?? '',
      targetIndustry: (row['target_industry'] as String?) ?? '',
      preferences: [
        for (final p in (row['preferences'] as List? ?? const [])) p as String,
      ],
      profile: profile,
      skills: [for (final s in (row['skills'] as List? ?? const [])) s as String],
      extras: extras,
      version: (row['version'] as num?)?.toInt() ?? 1,
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
    );
  }

  /// A version snapshot, stored in `career_dna_versions` so the platform can
  /// show how the DNA evolved (Phase 3).
  /// A compact, AI-friendly view of the DNA used as the interview context.
  Map<String, dynamic> toContext() => {
        'target': targetRole,
        'targetIndustry': targetIndustry,
        'stage': stage?.name,
        'summary': profile.summary,
        'education': [
          for (final e in profile.education) {'degree': e.degree, 'field': e.field},
        ],
        'experience': [
          for (final e in profile.experience)
            {'role': e.role, 'company': e.company, 'years': e.years},
        ],
        'projects': [
          for (final p in profile.projects)
            {'name': p.name, 'description': p.description, 'tech': p.tech},
        ],
        'skills': skills,
        'certifications': profile.certifications,
        'achievements': profile.achievements,
        'languages': profile.languages,
      };
}

T? _enum<T>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.toString().split('.').last == name) return v;
  }
  return null;
}

DateTime _date(Object? value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  try {
    return DateTime.parse(value as String);
  } catch (_) {
    return DateTime.now();
  }
}
