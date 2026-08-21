import 'package:equatable/equatable.dart';

/// The confidence/provenance of a single matched requirement.
enum EvidenceSource {
  professionalExperience,
  project,
  certification,
  education,
  declaredSkill,
  none,
}

/// Classification of a single job requirement against the candidate's DNA.
enum RequirementStatus {
  /// Directly covered by real evidence.
  strongMatch,

  /// Related/adjacent or transferable evidence exists, but not a direct match.
  partialMatch,

  /// The DNA was searched and no signal was found.
  notEvidenced,

  /// The DNA contradicts the requirement (e.g. fresh grad vs 5-yr role).
  requirementMismatch,

  /// Not enough data in the DNA to judge this requirement at all.
  unknown,
}

/// The overall, deterministic recommendation bucket.
enum MatchCategory {
  strong,
  good,
  moderate,
  weak,
}

String _enumName(Object e) => e.toString().split('.').last;

RequirementStatus _parseStatus(String? s) =>
    RequirementStatus.values.firstWhere((e) => _enumName(e) == s,
        orElse: () => RequirementStatus.unknown);

EvidenceSource _parseSource(String? s) =>
    EvidenceSource.values.firstWhere((e) => _enumName(e) == s,
        orElse: () => EvidenceSource.none);

MatchCategory _parseCategory(String? s) =>
    MatchCategory.values.firstWhere((e) => _enumName(e) == s,
        orElse: () => MatchCategory.moderate);

/// One job requirement and how it was resolved against the candidate's DNA.
class JobRequirement extends Equatable {
  const JobRequirement({
    required this.label,
    required this.required,
    required this.status,
    required this.evidenceSource,
    this.evidenceText = '',
  });

  /// Canonical requirement name (e.g. "Flutter").
  final String label;

  /// True when the job lists this as mandatory, false when preferred/nice-to-have.
  final bool required;

  final RequirementStatus status;
  final EvidenceSource evidenceSource;

  /// Human-readable explanation of the match or gap.
  final String evidenceText;

  @override
  List<Object?> get props =>
      [label, required, status, evidenceSource, evidenceText];

  Map<String, Object?> toJson() => {
        'label': label,
        'required': required,
        'status': _enumName(status),
        'evidenceSource': _enumName(evidenceSource),
        'evidenceText': evidenceText,
      };

  factory JobRequirement.fromJson(Map<String, dynamic> json) => JobRequirement(
        label: json['label'] as String? ?? '',
        required: json['required'] as bool? ?? true,
        status: _parseStatus(json['status'] as String?),
        evidenceSource: _parseSource(json['evidenceSource'] as String?),
        evidenceText: json['evidenceText'] as String? ?? '',
      );
}

/// The complete, explainable result of matching a job/opportunity extraction
/// against the user's Career DNA and (optionally) a Career Target.
class OpportunityAnalysis extends Equatable {
  const OpportunityAnalysis({
    this.targetId,
    this.jobDescription = '',
    this.role = '',
    this.company = '',
    this.seniority = '',
    this.requirements = const [],
    this.responsibilities = const [],
    this.technologies = const [],
    this.experienceItem,
    this.educationItem,
    this.experienceRequirement,
    this.educationRequirement,
    this.certifications = const [],
    this.languages = const [],
    this.softSkills = const [],
    this.domainKnowledge = const [],
    this.keywords = const [],
    this.skillsScore = 0,
    this.experienceScore = 0,
    this.educationScore = 0,
    this.keywordsScore = 0,
    this.languageScore = 0,
    this.overall = 0,
    this.recommendationCategory = MatchCategory.moderate,
    this.recommendationText = '',
  });

  final String? targetId;
  final String jobDescription;
  final String role;
  final String company;
  final String seniority;

  /// Skill requirements (required + preferred). Experience/education are held
  /// separately so they are not double-counted in the skills sub-score.
  final List<JobRequirement> requirements;

  final List<String> responsibilities;
  final List<String> technologies;

  /// The resolved experience requirement as a [JobRequirement] for display.
  final JobRequirement? experienceItem;

  /// The resolved education requirement as a [JobRequirement] for display.
  final JobRequirement? educationItem;

  final String? experienceRequirement;
  final String? educationRequirement;

  final List<String> certifications;
  final List<String> languages;
  final List<String> softSkills;
  final List<String> domainKnowledge;
  final List<String> keywords;

  final double skillsScore;
  final double experienceScore;
  final double educationScore;
  final double keywordsScore;
  final double languageScore;
  final double overall;

  final MatchCategory recommendationCategory;
  final String recommendationText;

  // ---- Derived sections (single source of truth: [requirements]) ----

  List<JobRequirement> get strongMatches =>
      requirements.where((r) => r.status == RequirementStatus.strongMatch).toList();

  List<JobRequirement> get partialMatches =>
      requirements.where((r) => r.status == RequirementStatus.partialMatch).toList();

  List<JobRequirement> get notEvidenced =>
      requirements.where((r) => r.status == RequirementStatus.notEvidenced).toList();

  List<JobRequirement> get requirementMismatches => requirements
      .where((r) => r.status == RequirementStatus.requirementMismatch)
      .toList();

  List<JobRequirement> get unknowns =>
      requirements.where((r) => r.status == RequirementStatus.unknown).toList();

  /// Required requirements that are not strongly matched (gaps to close).
  List<JobRequirement> get requiredGaps => requirements
      .where((r) => r.required && r.status != RequirementStatus.strongMatch)
      .toList();

  /// Preferred requirements that are not strongly matched.
  List<JobRequirement> get preferredGaps => requirements
      .where((r) => !r.required && r.status != RequirementStatus.strongMatch)
      .toList();

  Map<String, JobRequirement> get evidenceMap =>
      {for (final r in requirements) r.label: r};

  @override
  List<Object?> get props => [
        targetId,
        jobDescription,
        role,
        company,
        seniority,
        requirements,
        responsibilities,
        technologies,
        experienceItem,
        educationItem,
        experienceRequirement,
        educationRequirement,
        certifications,
        languages,
        softSkills,
        domainKnowledge,
        keywords,
        skillsScore,
        experienceScore,
        educationScore,
        keywordsScore,
        languageScore,
        overall,
        recommendationCategory,
        recommendationText,
      ];

  Map<String, Object?> toJson() => {
        'targetId': targetId,
        'jobDescription': jobDescription,
        'role': role,
        'company': company,
        'seniority': seniority,
        'requirements': [for (final r in requirements) r.toJson()],
        'responsibilities': responsibilities,
        'technologies': technologies,
        'experienceItem': experienceItem?.toJson(),
        'educationItem': educationItem?.toJson(),
        'experienceRequirement': experienceRequirement,
        'educationRequirement': educationRequirement,
        'certifications': certifications,
        'languages': languages,
        'softSkills': softSkills,
        'domainKnowledge': domainKnowledge,
        'keywords': keywords,
        'skillsScore': skillsScore,
        'experienceScore': experienceScore,
        'educationScore': educationScore,
        'keywordsScore': keywordsScore,
        'languageScore': languageScore,
        'overall': overall,
        'recommendationCategory': _enumName(recommendationCategory),
        'recommendationText': recommendationText,
      };

  factory OpportunityAnalysis.fromJson(Map<String, dynamic> json) {
    final reqs = json['requirements'];
    final exp = json['experienceItem'];
    final edu = json['educationItem'];
    return OpportunityAnalysis(
      targetId: json['targetId'] as String?,
      jobDescription: json['jobDescription'] as String? ?? '',
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      seniority: json['seniority'] as String? ?? '',
      requirements: reqs is List
          ? [for (final r in reqs) JobRequirement.fromJson(Map<String, dynamic>.from(r))]
          : const [],
      responsibilities: [for (final s in json['responsibilities'] as List? ?? const []) s as String],
      technologies: [for (final s in json['technologies'] as List? ?? const []) s as String],
      experienceItem: exp is Map
          ? JobRequirement.fromJson(Map<String, dynamic>.from(exp))
          : null,
      educationItem: edu is Map
          ? JobRequirement.fromJson(Map<String, dynamic>.from(edu))
          : null,
      experienceRequirement: json['experienceRequirement'] as String?,
      educationRequirement: json['educationRequirement'] as String?,
      certifications: [for (final s in json['certifications'] as List? ?? const []) s as String],
      languages: [for (final s in json['languages'] as List? ?? const []) s as String],
      softSkills: [for (final s in json['softSkills'] as List? ?? const []) s as String],
      domainKnowledge: [for (final s in json['domainKnowledge'] as List? ?? const []) s as String],
      keywords: [for (final s in json['keywords'] as List? ?? const []) s as String],
      skillsScore: (json['skillsScore'] as num? ?? 0).toDouble(),
      experienceScore: (json['experienceScore'] as num? ?? 0).toDouble(),
      educationScore: (json['educationScore'] as num? ?? 0).toDouble(),
      keywordsScore: (json['keywordsScore'] as num? ?? 0).toDouble(),
      languageScore: (json['languageScore'] as num? ?? 0).toDouble(),
      overall: (json['overall'] as num? ?? 0).toDouble(),
      recommendationCategory: _parseCategory(json['recommendationCategory'] as String?),
      recommendationText: json['recommendationText'] as String? ?? '',
    );
  }
}
