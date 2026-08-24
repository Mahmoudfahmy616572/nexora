import 'package:equatable/equatable.dart';

/// Source of a CV fact. Used internally for validation and labelling; it is
/// never surfaced as user-facing content.
enum CvSource {
  careerDna,
  target,
  opportunity,
  derived,
  ai,
}

/// The structured, editable, exportable content of a CV.
///
/// A CV is a tailored snapshot of [CareerDna] + [CareerTarget] (+ optionally an
/// [OpportunityAnalysis]). Every factual field must trace back to one of those
/// sources; the [CvContentValidator] enforces that.
class CvContent extends Equatable {
  const CvContent({
    this.header = const CvHeader(),
    this.summary = '',
    this.experience = const [],
    this.projects = const [],
    this.education = const [],
    this.skillGroups = const [],
    this.certifications = const [],
    this.achievements = const [],
    this.languages = const [],
    this.sourceLabel = '',
  });

  final CvHeader header;
  final String summary;
  final List<CvExperience> experience;
  final List<CvProject> projects;
  final List<CvEducation> education;
  final List<CvSkillGroup> skillGroups;
  final List<CvCertification> certifications;
  final List<CvAchievement> achievements;
  final List<CvLanguage> languages;

  /// Human-readable provenance, e.g. "Factual CV" or "AI tailored". Not a fact.
  final String sourceLabel;

  CvContent copyWith({
    CvHeader? header,
    String? summary,
    List<CvExperience>? experience,
    List<CvProject>? projects,
    List<CvEducation>? education,
    List<CvSkillGroup>? skillGroups,
    List<CvCertification>? certifications,
    List<CvAchievement>? achievements,
    List<CvLanguage>? languages,
    String? sourceLabel,
  }) =>
      CvContent(
        header: header ?? this.header,
        summary: summary ?? this.summary,
        experience: experience ?? this.experience,
        projects: projects ?? this.projects,
        education: education ?? this.education,
        skillGroups: skillGroups ?? this.skillGroups,
        certifications: certifications ?? this.certifications,
        achievements: achievements ?? this.achievements,
        languages: languages ?? this.languages,
        sourceLabel: sourceLabel ?? this.sourceLabel,
      );

  Map<String, Object?> toJson() => {
        'header': header.toJson(),
        'summary': summary,
        'experience': [for (final e in experience) e.toJson()],
        'projects': [for (final p in projects) p.toJson()],
        'education': [for (final e in education) e.toJson()],
        'skillGroups': [for (final s in skillGroups) s.toJson()],
        'certifications': [for (final c in certifications) c.toJson()],
        'achievements': [for (final a in achievements) a.toJson()],
        'languages': [for (final l in languages) l.toJson()],
        'sourceLabel': sourceLabel,
      };

  factory CvContent.fromJson(Map<String, dynamic> json) => CvContent(
        header: json['header'] is Map
            ? CvHeader.fromJson(Map<String, dynamic>.from(json['header']))
            : const CvHeader(),
        summary: json['summary'] as String? ?? '',
        experience: json['experience'] is List
            ? [for (final e in json['experience']) CvExperience.fromJson(Map<String, dynamic>.from(e))]
            : const [],
        projects: json['projects'] is List
            ? [for (final p in json['projects']) CvProject.fromJson(Map<String, dynamic>.from(p))]
            : const [],
        education: json['education'] is List
            ? [for (final e in json['education']) CvEducation.fromJson(Map<String, dynamic>.from(e))]
            : const [],
        skillGroups: json['skillGroups'] is List
            ? [for (final s in json['skillGroups']) CvSkillGroup.fromJson(Map<String, dynamic>.from(s))]
            : const [],
        certifications: json['certifications'] is List
            ? [for (final c in json['certifications']) CvCertification.fromJson(Map<String, dynamic>.from(c))]
            : const [],
        achievements: json['achievements'] is List
            ? [for (final a in json['achievements']) CvAchievement.fromJson(Map<String, dynamic>.from(a))]
            : const [],
        languages: json['languages'] is List
            ? [for (final l in json['languages']) CvLanguage.fromJson(Map<String, dynamic>.from(l))]
            : const [],
        sourceLabel: json['sourceLabel'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        header,
        summary,
        experience,
        projects,
        education,
        skillGroups,
        certifications,
        achievements,
        languages,
        sourceLabel,
      ];
}

class CvHeader extends Equatable {
  const CvHeader({
    this.name = '',
    this.title = '',
    this.subtitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.links = const [],
  });

  final String name;
  final String title;
  final String subtitle;
  final String email;
  final String phone;
  final String location;
  final List<String> links;

  Map<String, Object?> toJson() => {
        'name': name,
        'title': title,
        'subtitle': subtitle,
        'email': email,
        'phone': phone,
        'location': location,
        'links': links,
      };

  factory CvHeader.fromJson(Map<String, dynamic> json) => CvHeader(
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        links: [for (final l in json['links'] as List? ?? const []) l as String],
      );

  CvHeader copyWith({
    String? name,
    String? title,
    String? subtitle,
    String? email,
    String? phone,
    String? location,
    List<String>? links,
  }) =>
      CvHeader(
        name: name ?? this.name,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        links: links ?? this.links,
      );

  @override
  List<Object?> get props => [name, title, subtitle, email, phone, location, links];
}

class CvExperience extends Equatable {
  const CvExperience({
    required this.role,
    this.company = '',
    this.years,
    this.startDate = '',
    this.endDate = '',
    this.description = '',
    this.bullets = const [],
    this.location = '',
    this.source = CvSource.ai,
  });

  final String role;
  final String company;
  final int? years;
  final String startDate;
  final String endDate;
  final String description;
  final List<String> bullets;
  final String location;
  final CvSource source;

  /// Effective bullets: explicit bullets list, or [description] wrapped as a
  /// single-element list when non-empty. Used by templates and export.
  List<String> get effectiveBullets {
    if (bullets.isNotEmpty) return bullets;
    if (description.trim().isNotEmpty) return [description.trim()];
    return const [];
  }

  Map<String, Object?> toJson() => {
        'role': role,
        'company': company,
        'years': years,
        'startDate': startDate,
        'endDate': endDate,
        'description': description,
        'bullets': bullets,
        'location': location,
        'source': source.name,
      };

  factory CvExperience.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: old versions have only `description`, no `bullets`.
    final bulletsRaw = json['bullets'];
    final List<String> parsedBullets;
    if (bulletsRaw is List && bulletsRaw.isNotEmpty) {
      parsedBullets = [for (final b in bulletsRaw) b.toString()];
    } else {
      // Fall back: if description exists, treat it as a single bullet.
      final desc = json['description'] as String? ?? '';
      parsedBullets = desc.trim().isNotEmpty ? [desc.trim()] : const [];
    }
    return CvExperience(
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      years: json['years'] as int?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bullets: parsedBullets,
      location: json['location'] as String? ?? '',
      source: CvSource.values.firstWhere(
        (s) => s.name == (json['source'] as String?),
        orElse: () => CvSource.ai,
      ),
    );
  }

  @override
  List<Object?> get props => [role, company, years, startDate, endDate, description, bullets, location, source];

  CvExperience copyWith({
    String? role,
    String? company,
    int? years,
    String? startDate,
    String? endDate,
    String? description,
    List<String>? bullets,
    String? location,
    CvSource? source,
  }) =>
      CvExperience(
        role: role ?? this.role,
        company: company ?? this.company,
        years: years ?? this.years,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        description: description ?? this.description,
        bullets: bullets ?? this.bullets,
        location: location ?? this.location,
        source: source ?? this.source,
      );

  String get yearsLabel => years == null ? '' : '${years}y';
}

class CvProject extends Equatable {
  const CvProject({
    required this.name,
    this.description = '',
    this.tech = const [],
    this.link = '',
    this.links = const [],
    this.bullets = const [],
    this.role = '',
    this.date = '',
    this.source = CvSource.ai,
  });

  final String name;
  final String description;
  final List<String> tech;
  final String link;
  final List<String> links;
  final List<String> bullets;
  final String role;
  final String date;
  final CvSource source;

  /// Effective bullets: explicit bullets list, or [description] wrapped as a
  /// single-element list when non-empty.
  List<String> get effectiveBullets {
    if (bullets.isNotEmpty) return bullets;
    if (description.trim().isNotEmpty) return [description.trim()];
    return const [];
  }

  /// Effective links: explicit links list, or [link] wrapped as a list.
  List<String> get effectiveLinks {
    if (links.isNotEmpty) return links;
    if (link.trim().isNotEmpty) return [link.trim()];
    return const [];
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'description': description,
        'tech': tech,
        'link': link,
        'links': links,
        'bullets': bullets,
        'role': role,
        'date': date,
        'source': source.name,
      };

  factory CvProject.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: old versions have only `description`, no `bullets`.
    final bulletsRaw = json['bullets'];
    final List<String> parsedBullets;
    if (bulletsRaw is List && bulletsRaw.isNotEmpty) {
      parsedBullets = [for (final b in bulletsRaw) b.toString()];
    } else {
      final desc = json['description'] as String? ?? '';
      parsedBullets = desc.trim().isNotEmpty ? [desc.trim()] : const [];
    }
    return CvProject(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tech: [for (final t in json['tech'] as List? ?? const []) t as String],
      link: json['link'] as String? ?? '',
      links: [for (final l in json['links'] as List? ?? const []) l as String],
      bullets: parsedBullets,
      role: json['role'] as String? ?? '',
      date: json['date'] as String? ?? '',
      source: CvSource.values.firstWhere(
        (s) => s.name == (json['source'] as String?),
        orElse: () => CvSource.ai,
      ),
    );
  }

  @override
  List<Object?> get props => [name, description, tech, link, links, bullets, role, date, source];

  CvProject copyWith({
    String? name,
    String? description,
    List<String>? tech,
    String? link,
    List<String>? links,
    List<String>? bullets,
    String? role,
    String? date,
    CvSource? source,
  }) =>
      CvProject(
        name: name ?? this.name,
        description: description ?? this.description,
        tech: tech ?? this.tech,
        link: link ?? this.link,
        links: links ?? this.links,
        bullets: bullets ?? this.bullets,
        role: role ?? this.role,
        date: date ?? this.date,
        source: source ?? this.source,
      );
}

class CvEducation extends Equatable {
  const CvEducation({
    required this.degree,
    this.field = '',
    this.institution = '',
    this.year = '',
    this.source = CvSource.ai,
  });

  final String degree;
  final String field;
  final String institution;
  final String year;
  final CvSource source;

  Map<String, Object?> toJson() => {
        'degree': degree,
        'field': field,
        'institution': institution,
        'year': year,
        'source': source.name,
      };

  factory CvEducation.fromJson(Map<String, dynamic> json) => CvEducation(
        degree: json['degree'] as String? ?? '',
        field: json['field'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        year: json['year'] as String? ?? '',
        source: CvSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => CvSource.ai,
        ),
      );

  @override
  List<Object?> get props => [degree, field, institution, year, source];

  CvEducation copyWith({
    String? degree,
    String? field,
    String? institution,
    String? year,
    CvSource? source,
  }) =>
      CvEducation(
        degree: degree ?? this.degree,
        field: field ?? this.field,
        institution: institution ?? this.institution,
        year: year ?? this.year,
        source: source ?? this.source,
      );
}

class CvCertification extends Equatable {
  const CvCertification({
    required this.name,
    this.issuer = '',
    this.year = '',
    this.source = CvSource.ai,
  });

  final String name;
  final String issuer;
  final String year;
  final CvSource source;

  Map<String, Object?> toJson() => {
        'name': name,
        'issuer': issuer,
        'year': year,
        'source': source.name,
      };

  factory CvCertification.fromJson(Map<String, dynamic> json) => CvCertification(
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        year: json['year'] as String? ?? '',
        source: CvSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => CvSource.ai,
        ),
      );

  @override
  List<Object?> get props => [name, issuer, year, source];

  CvCertification copyWith({
    String? name,
    String? issuer,
    String? year,
    CvSource? source,
  }) =>
      CvCertification(
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        year: year ?? this.year,
        source: source ?? this.source,
      );

  String get display =>
      [name, if (issuer.isNotEmpty) issuer, if (year.isNotEmpty) year]
          .join(' · ');
}

class CvAchievement extends Equatable {
  const CvAchievement({required this.text, this.source = CvSource.ai});

  final String text;
  final CvSource source;

  Map<String, Object?> toJson() => {'text': text, 'source': source.name};

  factory CvAchievement.fromJson(Map<String, dynamic> json) => CvAchievement(
        text: json['text'] as String? ?? '',
        source: CvSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => CvSource.ai,
        ),
      );

  @override
  List<Object?> get props => [text, source];

  CvAchievement copyWith({String? text, CvSource? source}) =>
      CvAchievement(
        text: text ?? this.text,
        source: source ?? this.source,
      );
}

class CvLanguage extends Equatable {
  const CvLanguage({required this.name, this.level = '', this.source = CvSource.ai});

  final String name;
  final String level;
  final CvSource source;

  Map<String, Object?> toJson() => {'name': name, 'level': level, 'source': source.name};

  factory CvLanguage.fromJson(Map<String, dynamic> json) => CvLanguage(
        name: json['name'] as String? ?? '',
        level: json['level'] as String? ?? '',
        source: CvSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => CvSource.ai,
        ),
      );

  @override
  List<Object?> get props => [name, level, source];

  CvLanguage copyWith({String? name, String? level, CvSource? source}) =>
      CvLanguage(
        name: name ?? this.name,
        level: level ?? this.level,
        source: source ?? this.source,
      );

  String get display => level.isNotEmpty ? '$name — $level' : name;
}

class CvSkillGroup extends Equatable {
  const CvSkillGroup({required this.title, required this.skills, this.source = CvSource.ai});

  final String title;
  final List<String> skills;
  final CvSource source;

  Map<String, Object?> toJson() => {
        'title': title,
        'skills': skills,
        'source': source.name,
      };

  factory CvSkillGroup.fromJson(Map<String, dynamic> json) => CvSkillGroup(
        title: json['title'] as String? ?? '',
        skills: [for (final s in json['skills'] as List? ?? const []) s as String],
        source: CvSource.values.firstWhere(
          (s) => s.name == (json['source'] as String?),
          orElse: () => CvSource.ai,
        ),
      );

  @override
  List<Object?> get props => [title, skills, source];

  CvSkillGroup copyWith({
    String? title,
    List<String>? skills,
    CvSource? source,
  }) =>
      CvSkillGroup(
        title: title ?? this.title,
        skills: skills ?? this.skills,
        source: source ?? this.source,
      );
}
