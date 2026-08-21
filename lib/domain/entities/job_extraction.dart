import 'package:equatable/equatable.dart';

/// Structured facts extracted from a job/opportunity description.
///
/// Produced either by the hosted AI Edge Function (rich, semantic) or by the
/// offline [OpportunityMatchEngine] extractor (rule-based). Both feed the same
/// deterministic [OpportunityMatchEngine.compute], so the final score is always
/// reproducible regardless of which extraction path was used.
class JobExtraction extends Equatable {
  const JobExtraction({
    this.role = '',
    this.company = '',
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.responsibilities = const [],
    this.technologies = const [],
    this.experienceYearsRequired,
    this.educationRequired,
    this.certifications = const [],
    this.languages = const [],
    this.softSkills = const [],
    this.domainKnowledge = const [],
    this.keywords = const [],
    this.seniority = '',
    this.locationRemote = '',
    this.rawText = '',
  });

  final String role;
  final String company;

  /// Mandatory skills/tools/technologies explicitly demanded.
  final List<String> requiredSkills;

  /// Preferred / nice-to-have skills. Weighted far lower than required.
  final List<String> preferredSkills;

  final List<String> responsibilities;
  final List<String> technologies;
  final int? experienceYearsRequired;
  final String? educationRequired;

  final List<String> certifications;
  final List<String> languages;
  final List<String> softSkills;
  final List<String> domainKnowledge;
  final List<String> keywords;

  final String seniority;
  final String locationRemote;
  final String rawText;

  @override
  List<Object?> get props => [
        role,
        company,
        requiredSkills,
        preferredSkills,
        responsibilities,
        technologies,
        experienceYearsRequired,
        educationRequired,
        certifications,
        languages,
        softSkills,
        domainKnowledge,
        keywords,
        seniority,
        locationRemote,
        rawText,
      ];

  Map<String, Object?> toJson() => {
        'role': role,
        'company': company,
        'required_skills': requiredSkills,
        'preferred_skills': preferredSkills,
        'responsibilities': responsibilities,
        'technologies': technologies,
        'experience_years': experienceYearsRequired,
        'education': educationRequired,
        'certifications': certifications,
        'languages': languages,
        'soft_skills': softSkills,
        'domain_knowledge': domainKnowledge,
        'keywords': keywords,
        'seniority': seniority,
        'location_remote': locationRemote,
        'raw_text': rawText,
      };

  /// Parses the `detail` object returned by the analyze Edge Function.
  factory JobExtraction.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) =>
        [for (final s in json[key] as List? ?? const []) s as String];
    return JobExtraction(
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      requiredSkills: list('required_skills'),
      preferredSkills: list('preferred_skills'),
      responsibilities: list('responsibilities'),
      technologies: list('technologies'),
      experienceYearsRequired: json['experience_years'] as int?,
      educationRequired: json['education'] as String?,
      certifications: list('certifications'),
      languages: list('languages'),
      softSkills: list('soft_skills'),
      domainKnowledge: list('domain_knowledge'),
      keywords: list('keywords'),
      seniority: json['seniority'] as String? ?? '',
      locationRemote: json['location_remote'] as String? ?? '',
      rawText: json['raw_text'] as String? ?? '',
    );
  }
}
