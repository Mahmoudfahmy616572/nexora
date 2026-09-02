import 'dart:convert';

/// One role the user actually held.
class ProfileExperience {
  const ProfileExperience({
    this.role = '',
    this.company = '',
    this.years = 0,
    this.durationMonths = 0,
    this.startDate = '',
    this.endDate = '',
    this.location = '',
    this.description = '',
    this.bullets = const [],
    this.technologies = const [],
    this.achievements = const [],
  });

  final String role;
  final String company;
  final int years;
  final int durationMonths;
  final String startDate;
  final String endDate;
  final String location;
  final String description;
  final List<String> bullets;
  final List<String> technologies;
  final List<String> achievements;

  /// Canonical duration in months (years * 12 if only years provided).
  int get effectiveMonths =>
      durationMonths > 0 ? durationMonths : years * 12;

  /// Human-readable duration: "10 months", "1 year", "1.5 years".
  String get durationLabel {
    final m = effectiveMonths;
    if (m <= 0) return '';
    if (m < 12) return '$m month${m == 1 ? '' : 's'}';
    final y = m / 12.0;
    return y == y.roundToDouble()
        ? '${y.toInt()} year${y.toInt() == 1 ? '' : 's'}'
        : '${y.toStringAsFixed(1)} years';
  }

  /// For CV display: role line with duration.
  String get durationDisplay {
    final label = durationLabel;
    if (startDate.isNotEmpty || endDate.isNotEmpty) {
      final range = [startDate, endDate].where((s) => s.isNotEmpty).join(' – ');
      return label.isNotEmpty ? '$range ($label)' : range;
    }
    return label;
  }

  Map<String, Object> toJson() => {
        'role': role,
        'company': company,
        'years': years,
        'duration_months': effectiveMonths,
        'start_date': startDate,
        'end_date': endDate,
        'location': location,
        'description': description,
        'bullets': bullets,
        'technologies': technologies,
        'achievements': achievements,
      };

  factory ProfileExperience.fromJson(Map<String, dynamic> json) =>
      ProfileExperience(
        role: (json['role'] as String?) ?? '',
        company: (json['company'] as String?) ?? '',
        years: (json['years'] as num?)?.toInt() ?? 0,
        durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
        startDate: (json['start_date'] as String?) ?? '',
        endDate: (json['end_date'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        bullets: [
          for (final b in json['bullets'] as List? ?? const []) b as String,
        ],
        technologies: [
          for (final t in json['technologies'] as List? ?? const []) t as String,
        ],
        achievements: [
          for (final a in json['achievements'] as List? ?? const []) a as String,
        ],
      );
}

/// A single, optionally-labeled link attached to a project (e.g. a live demo,
/// app-store page, or source repository). When [label] is empty the renderer
/// falls back to an auto-detected label derived from the URL / project name.
class ProjectLink {
  const ProjectLink({this.label = '', this.url = ''});

  final String label;
  final String url;

  Map<String, Object> toJson() => {'label': label, 'url': url};

  factory ProjectLink.fromJson(Map<String, dynamic> json) => ProjectLink(
        label: (json['label'] as String?) ?? '',
        url: (json['url'] as String?) ?? '',
      );

  ProjectLink copyWith({String? label, String? url}) =>
      ProjectLink(label: label ?? this.label, url: url ?? this.url);

  /// Picks a friendly fallback label from a URL's host, or the project name, or
  /// a generic "Link".
  static String autoLabel(String url, [String? projectName]) {
    final u = url.trim();
    if (u.isEmpty) return '';
    final lower = u.toLowerCase();
    if (lower.contains('github.com')) return 'GitHub';
    if (lower.contains('gitlab.com')) return 'GitLab';
    if (lower.contains('play.google.com') || lower.contains('apps.apple.com')) {
      return 'App Store';
    }
    if (lower.contains('behance.net')) return 'Behance';
    if (lower.contains('dribbble.com')) return 'Dribbble';
    if (lower.contains('kaggle.com')) return 'Kaggle';
    if (lower.contains('huggingface.co')) return 'Hugging Face';
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) return 'YouTube';
    if (lower.contains('linkedin.com')) return 'LinkedIn';
    if (lower.contains('medium.com')) return 'Medium';
    final name = (projectName ?? '').trim();
    return name.isNotEmpty ? name : 'Link';
  }

  /// Serialises a list of links to a JSON string (used for embedded storage).
  static String listToJson(List<ProjectLink> links) =>
      jsonEncode([for (final l in links) {'label': l.label, 'url': l.url}]);

  /// Parses a JSON string produced by [listToJson]; tolerant of bad input.
  static List<ProjectLink> listFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is Map && (e['url']?.toString().isNotEmpty ?? false))
            ProjectLink(
              label: (e['label'] as String?) ?? '',
              url: (e['url'] as String?) ?? '',
            ),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// One project the user actually shipped.
class ProfileProject {
  const ProfileProject({
    this.name = '',
    this.role = '',
    this.description = '',
    this.tech = const [],
    this.keyFeatures = '',
    this.challenges = '',
    this.integrations = '',
    this.outcome = '',
    this.links = const [],
  });

  final String name;
  final String role;
  final String description;
  final List<String> tech;
  final String keyFeatures;
  final String challenges;
  final String integrations;
  final String outcome;
  final List<ProjectLink> links;

  Map<String, Object> toJson() => {
        'name': name,
        'role': role,
        'description': description,
        'tech': tech,
        'key_features': keyFeatures,
        'challenges': challenges,
        'integrations': integrations,
        'outcome': outcome,
        'links': [for (final l in links) l.toJson()],
      };

  factory ProfileProject.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['links'];
    final List<ProjectLink> parsedLinks;
    if (linksRaw is List && linksRaw.isNotEmpty) {
      parsedLinks = [
        for (final l in linksRaw)
          l is Map
              ? ProjectLink.fromJson(Map<String, dynamic>.from(l))
              : ProjectLink(url: l.toString()),
      ];
    } else {
      final legacy = (json['link'] as String?) ?? '';
      parsedLinks = legacy.trim().isNotEmpty
          ? [ProjectLink(url: legacy.trim())]
          : const [];
    }
    return ProfileProject(
      name: (json['name'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      tech: [for (final t in json['tech'] as List? ?? const []) t as String],
      keyFeatures: (json['key_features'] as String?) ?? '',
      challenges: (json['challenges'] as String?) ?? '',
      integrations: (json['integrations'] as String?) ?? '',
      outcome: (json['outcome'] as String?) ?? '',
      links: parsedLinks,
    );
  }
}

/// One degree the user holds.
class ProfileEducation {
  const ProfileEducation({this.degree = '', this.field = ''});

  final String degree;
  final String field;

  Map<String, Object> toJson() => {'degree': degree, 'field': field};

  factory ProfileEducation.fromJson(Map<String, dynamic> json) =>
      ProfileEducation(
        degree: (json['degree'] as String?) ?? '',
        field: (json['field'] as String?) ?? '',
      );
}

class ProfileCertification {
  const ProfileCertification({
    this.name = '',
    this.link = '',
  });

  final String name;
  final String link;

  Map<String, Object> toJson() => {
        'name': name,
        if (link.isNotEmpty) 'link': link,
      };

  factory ProfileCertification.fromJson(Map<String, dynamic> json) =>
      ProfileCertification(
        name: (json['name'] as String?) ?? '',
        link: (json['link'] as String?) ?? '',
      );

  factory ProfileCertification.fromString(String s) =>
      ProfileCertification(name: s);
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
  final List<ProfileCertification> certifications;
  final List<String> achievements;
  final List<String> languages;

  /// Total years summed across all experience entries.
  int get yearsTotal =>
      experience.fold(0, (sum, entry) => sum + entry.effectiveMonths ~/ 12);

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
        'certifications': [for (final c in certifications) c.toJson()],
        'achievements': achievements,
        'languages': languages,
      };

  ProfileData copyWith({
    String? summary,
    List<ProfileExperience>? experience,
    List<ProfileProject>? projects,
    List<ProfileEducation>? education,
    List<ProfileCertification>? certifications,
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
          for (final c in json['certifications'] as List? ?? const [])
            c is String
                ? ProfileCertification.fromString(c)
                : ProfileCertification.fromJson(
                    Map<String, dynamic>.from(c as Map)),
        ],
        achievements: [
          for (final a in json['achievements'] as List? ?? const []) a as String,
        ],
        languages: [
          for (final l in json['languages'] as List? ?? const []) l as String,
        ],
      );
}
