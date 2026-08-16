/// One role the user actually held.
class ProfileExperience {
  const ProfileExperience({this.role = '', this.company = '', this.years = 0});

  final String role;
  final String company;
  final int years;

  Map<String, Object> toJson() => {'role': role, 'company': company, 'years': years};

  factory ProfileExperience.fromJson(Map<String, dynamic> json) => ProfileExperience(
        role: (json['role'] as String?) ?? '',
        company: (json['company'] as String?) ?? '',
        years: (json['years'] as num?)?.toInt() ?? 0,
      );
}

/// One project the user actually shipped.
class ProfileProject {
  const ProfileProject({this.name = '', this.description = '', this.tech = const []});

  final String name;
  final String description;
  final List<String> tech;

  Map<String, Object> toJson() => {
        'name': name,
        'description': description,
        'tech': tech,
      };

  factory ProfileProject.fromJson(Map<String, dynamic> json) => ProfileProject(
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        tech: [for (final t in json['tech'] as List? ?? const []) t as String],
      );
}

/// One degree the user holds.
class ProfileEducation {
  const ProfileEducation({this.degree = '', this.field = ''});

  final String degree;
  final String field;

  Map<String, Object> toJson() => {'degree': degree, 'field': field};

  factory ProfileEducation.fromJson(Map<String, dynamic> json) => ProfileEducation(
        degree: (json['degree'] as String?) ?? '',
        field: (json['field'] as String?) ?? '',
      );
}

/// The user's real, structured career data — the single source of truth for
/// AI match scoring on the Analyze tab.
class ProfileData {
  const ProfileData({
    this.summary = '',
    this.experience = const [],
    this.projects = const [],
    this.education = const [],
    this.certifications = const [],
    this.achievements = const [],
    this.languages = const [],
  });

  final String summary;
  final List<ProfileExperience> experience;
  final List<ProfileProject> projects;
  final List<ProfileEducation> education;
  final List<String> certifications;
  final List<String> achievements;
  final List<String> languages;

  /// Total years summed across all experience entries.
  int get yearsTotal =>
      experience.fold(0, (sum, entry) => sum + entry.years);

  bool get isEmpty =>
      summary.isEmpty &&
      experience.isEmpty &&
      projects.isEmpty &&
      education.isEmpty &&
      certifications.isEmpty &&
      achievements.isEmpty &&
      languages.isEmpty;

  Map<String, Object> toJson() => {
        'summary': summary,
        'experience': [for (final e in experience) e.toJson()],
        'projects': [for (final p in projects) p.toJson()],
        'education': [for (final e in education) e.toJson()],
        'certifications': certifications,
        'achievements': achievements,
        'languages': languages,
      };

  ProfileData copyWith({
    String? summary,
    List<ProfileExperience>? experience,
    List<ProfileProject>? projects,
    List<ProfileEducation>? education,
    List<String>? certifications,
    List<String>? achievements,
    List<String>? languages,
  }) =>
      ProfileData(
        summary: summary ?? this.summary,
        experience: experience ?? this.experience,
        projects: projects ?? this.projects,
        education: education ?? this.education,
        certifications: certifications ?? this.certifications,
        achievements: achievements ?? this.achievements,
        languages: languages ?? this.languages,
      );

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        summary: (json['summary'] as String?) ?? '',
        experience: [
          for (final e in json['experience'] as List? ?? const [])
            ProfileExperience.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
        projects: [
          for (final p in json['projects'] as List? ?? const [])
            ProfileProject.fromJson(Map<String, dynamic>.from(p as Map)),
        ],
        education: [
          for (final e in json['education'] as List? ?? const [])
            ProfileEducation.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
        certifications: [
          for (final c in json['certifications'] as List? ?? const []) c as String,
        ],
        achievements: [
          for (final a in json['achievements'] as List? ?? const []) a as String,
        ],
        languages: [
          for (final l in json['languages'] as List? ?? const []) l as String,
        ],
      );
}
