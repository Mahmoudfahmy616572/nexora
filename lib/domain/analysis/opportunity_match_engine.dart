import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/job_extraction.dart';
import '../entities/opportunity_analysis.dart';
import '../entities/profile_data.dart';
import 'job_analyzer.dart';

/// Deterministic Opportunity Intelligence engine.
///
/// Receives a [JobExtraction] (from AI or offline) plus the candidate's
/// [CareerDna] and optional [CareerTarget], and produces an explainable
/// [OpportunityAnalysis]. This code is PURE DART: it never touches Supabase,
/// HTTP, an Edge Function, or an LLM. The score is therefore always
/// reproducible for the same inputs.
class OpportunityMatchEngine {
  const OpportunityMatchEngine();

  // ---- Canonicalization helpers (reuse JobAnalyzer's alias tables) ----

  String _canon(String s) =>
      JobAnalyzer.aliasToCanonical[s.trim().toLowerCase()] ??
      s.trim().toLowerCase();

  List<String> _tokens(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+#./ -]'), ' ').split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  /// True when every meaningful token of [target] appears in [container].
  bool _covers(String container, String target) {
    final ct = _tokens(container);
    final tt = _tokens(target);
    if (tt.isEmpty) return false;
    return tt.every((t) => ct.any((c) => c == t || c.contains(t) || t.contains(c)));
  }

  int _highestRank(List<ProfileEducation> education) {
    var highest = 0;
    for (final e in education) {
      final r = JobAnalyzer.educationRank[e.degree.toLowerCase()] ?? 0;
      if (r > highest) highest = r;
    }
    return highest;
  }

  static const Map<int, String> _rankLabels = {
    0: 'none',
    1: 'High School',
    2: 'Associate',
    3: 'Bachelor',
    4: 'Master',
    5: 'PhD',
  };

  String _rankLabel(int rank) => _rankLabels[rank] ?? 'unknown';

  /// Skill families used for partial/adjacent matching.
  static const Map<String, List<String>> _families = {
    'frontend': ['Flutter', 'React', 'Vue', 'Angular', 'JavaScript', 'TypeScript', 'HTML', 'CSS'],
    'backend': ['Node.js', 'Python', 'Django', 'Spring', 'Ruby', 'PHP', 'Go', 'Java', 'Express'],
    'mobile': ['Flutter', 'React Native', 'Swift', 'Kotlin', 'Android', 'iOS'],
    'devops': ['Docker', 'Kubernetes', 'CI/CD', 'AWS', 'Azure', 'GCP', 'Terraform'],
    'data': ['SQL', 'Python', 'Pandas', 'Machine Learning', 'TensorFlow', 'Spark'],
    'design': ['UI/UX', 'Figma', 'Sketch', 'Photoshop'],
  };

  String? _familyOf(String reqCanon) {
    for (final entry in _families.entries) {
      if (entry.value.any((m) => _canon(m) == reqCanon)) return entry.key;
    }
    return null;
  }

  // ---- Offline extraction (rule-based, less rich than AI) ----

  JobExtraction extract(String description) {
    final lower = description.toLowerCase();
    final required = <String>{};
    for (final entry in JobAnalyzer.skillAliases.entries) {
      final patterns = [entry.key.toLowerCase(), ...entry.value];
      for (final p in patterns) {
        if (RegExp('\\b${RegExp.escape(p)}\\b').hasMatch(lower)) {
          required.add(entry.key);
          break;
        }
      }
    }
    final years = _extractYears(description);
    final edu = _extractEducation(description);
    final keywords = <String>{...required};
    return JobExtraction(
      role: _firstLine(description),
      company: '',
      requiredSkills: required.toList(),
      preferredSkills: const [],
      responsibilities: const [],
      technologies: required.toList(),
      experienceYearsRequired: years,
      educationRequired: edu,
      certifications: const [],
      languages: const [],
      softSkills: const [],
      domainKnowledge: const [],
      keywords: keywords.toList(),
      seniority: '',
      locationRemote: _extractRemote(description),
      rawText: description,
    );
  }

  String _firstLine(String text) {
    final line = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).firstOrNull ?? '';
    return line.length > 60 ? '${line.substring(0, 60)}…' : line;
  }

  int? _extractYears(String text) {
    final m = RegExp(r'(\d{1,2})\s*\+?\s*(?:-|to|–|and)?\s*\d*\s*years?', caseSensitive: false).firstMatch(text);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  String? _extractEducation(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\bph\.?d\b|doctorate|postdoc').hasMatch(lower)) return 'phd';
    if (RegExp(r'\bmaster|\bm\.?sc\b|\bmba\b').hasMatch(lower)) return 'master';
    if (RegExp(r'\bbachelor|\bb\.?sc\b|\bb\.?eng\b|undergraduate').hasMatch(lower)) return 'bachelor';
    if (RegExp(r'\bassociate|diploma').hasMatch(lower)) return 'associate';
    if (RegExp(r'\bhigh school').hasMatch(lower)) return 'high school';
    return null;
  }

  String _extractRemote(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('remote') || lower.contains('work from home')) return 'remote';
    if (lower.contains('on-site') || lower.contains('onsite')) return 'on-site';
    return '';
  }

  // ---- Evidence resolution ----

  ({EvidenceSource source, String text})? _bestEvidence(
    String reqCanon,
    CareerDna dna,
    Set<String> projectTech,
    Map<String, String> projectEvidence,
  ) {
    for (final e in dna.profile.experience) {
      final roleCanon = _canon(e.role);
      if (_covers(roleCanon, reqCanon) ||
          (e.company.isNotEmpty && _covers(_canon(e.company), reqCanon))) {
        if (e.years > 0) {
          return (
            source: EvidenceSource.professionalExperience,
            text: '${e.years} yr${e.years == 1 ? '' : 's'} as ${e.role}${e.company.isNotEmpty ? ' at ${e.company}' : ''}'
          );
        }
      }
    }
    if (projectTech.contains(reqCanon)) {
      return (source: EvidenceSource.project, text: 'Project ${projectEvidence[reqCanon]}');
    }
    final certs = <String>{for (final c in dna.profile.certifications) _canon(c)};
    if (certs.contains(reqCanon)) {
      return (source: EvidenceSource.certification, text: 'Certification: $reqCanon');
    }
    final declared = <String>{for (final s in dna.skills) _canon(s)};
    if (declared.contains(reqCanon)) {
      return (source: EvidenceSource.declaredSkill, text: 'Declared skill: $reqCanon');
    }
    return null;
  }

  ({EvidenceSource source, String text})? _partialEvidence(
    String reqCanon,
    CareerDna dna,
    Set<String> candidateCanon,
  ) {
    if (dna.stage == CareerStage.careerChanger) {
      final transferable = <String>{
        for (final t in (dna.extra<List>('transferableSkills') ?? [])) _canon(t as String),
      };
      if (transferable.contains(reqCanon)) {
        final prev = dna.extra<String>('previousCareer') ?? 'your previous career';
        return (
          source: EvidenceSource.declaredSkill,
          text: 'Transferable evidence from $prev (no direct experience yet).'
        );
      }
    }
    final family = _familyOf(reqCanon);
    if (family != null) {
      for (final m in _families[family]!) {
        final mc = _canon(m);
        if (mc != reqCanon && candidateCanon.contains(mc)) {
          return (source: EvidenceSource.declaredSkill, text: 'Related skill: $m (adjacent to $reqCanon).');
        }
      }
    }
    return null;
  }

  JobRequirement _resolveSkill(String label, bool required, CareerDna dna,
      Set<String> projectTech, Map<String, String> projectEvidence, bool candidateHasData) {
    final reqCanon = _canon(label);
    final best = _bestEvidence(reqCanon, dna, projectTech, projectEvidence);
    if (best != null) {
      return JobRequirement(
        label: label,
        required: required,
        status: RequirementStatus.strongMatch,
        evidenceSource: best.source,
        evidenceText: best.text,
      );
    }
    final partial = _partialEvidence(reqCanon, dna, {
      ...{for (final s in dna.skills) _canon(s)},
      ...projectTech,
      ...{for (final c in dna.profile.certifications) _canon(c)},
      ...{for (final e in dna.profile.experience) _canon(e.role)},
    });
    if (partial != null) {
      return JobRequirement(
        label: label,
        required: required,
        status: RequirementStatus.partialMatch,
        evidenceSource: partial.source,
        evidenceText: partial.text,
      );
    }
    final noData = !candidateHasData;
    return JobRequirement(
      label: label,
      required: required,
      status: noData ? RequirementStatus.unknown : RequirementStatus.notEvidenced,
      evidenceSource: EvidenceSource.none,
      evidenceText: noData
          ? 'Not enough data in your Career DNA to evaluate this.'
          : 'No evidence found in your Career DNA.',
    );
  }

  JobRequirement _resolveExperience(
      int? required, CareerDna dna, int yearsTotal, bool hasExpData, bool candidateHasData) {
    if (required == null) {
      return const JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.unknown,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'Experience requirement not specified.',
      );
    }
    final isJuniorStage =
        dna.stage == CareerStage.student || dna.stage == CareerStage.freshGraduate;
    final text = '$yearsTotal of $required+ years required';
    if (isJuniorStage && required > 2) {
      final stageName = dna.stage == CareerStage.freshGraduate ? 'a fresh graduate' : 'a student';
      return JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.requirementMismatch,
        evidenceSource: EvidenceSource.none,
        evidenceText:
            'This role asks for $required+ years; as $stageName this is a significant gap — target junior/entry versions.',
      );
    }
    if (yearsTotal >= required) {
      return JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.professionalExperience,
        evidenceText: '$yearsTotal yrs professional experience',
      );
    }
    if (!hasExpData && !candidateHasData) {
      return const JobRequirement(
        label: 'Experience',
        required: true,
        status: RequirementStatus.unknown,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'No professional experience recorded.',
      );
    }
    final ratio = required == 0 ? 1.0 : yearsTotal / required;
    return JobRequirement(
      label: 'Experience',
      required: true,
      status: ratio >= 0.5 ? RequirementStatus.partialMatch : RequirementStatus.notEvidenced,
      evidenceSource: EvidenceSource.none,
      evidenceText: '$text.',
    );
  }

  JobRequirement _resolveEducation(
      String? required, CareerDna dna, int highestRank, bool hasEduData, bool candidateHasData) {
    if (required == null) {
      return const JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.unknown,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'Education requirement not specified.',
      );
    }
    final reqRank = JobAnalyzer.educationRank[required.toLowerCase()] ?? 0;
    if (reqRank == 0) {
      return const JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.unknown,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'Education requirement is unclear.',
      );
    }
    if (highestRank >= reqRank) {
      return JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.strongMatch,
        evidenceSource: EvidenceSource.education,
        evidenceText: 'Holds ${_rankLabel(highestRank)} (meets ${_rankLabel(reqRank)}).',
      );
    }
    if (!hasEduData && !candidateHasData) {
      return const JobRequirement(
        label: 'Education',
        required: true,
        status: RequirementStatus.unknown,
        evidenceSource: EvidenceSource.none,
        evidenceText: 'No education recorded to evaluate.',
      );
    }
    return JobRequirement(
      label: 'Education',
      required: true,
      status: RequirementStatus.requirementMismatch,
      evidenceSource: EvidenceSource.none,
      evidenceText: 'Requires ${_rankLabel(reqRank)}; you hold ${_rankLabel(highestRank)}.',
    );
  }

  // ---- Deterministic scoring ----

  double _coverage(List<JobRequirement> reqs) {
    if (reqs.isEmpty) return 0;
    var credit = 0.0;
    for (final r in reqs) {
      credit += r.status == RequirementStatus.strongMatch
          ? 1.0
          : r.status == RequirementStatus.partialMatch
              ? 0.5
              : 0.0;
    }
    return credit / reqs.length;
  }

  double _skillsScore(List<JobRequirement> required, List<JobRequirement> preferred) {
    if (required.isEmpty) {
      if (preferred.isEmpty) return 70.0;
      final pc = _coverage(preferred);
      return (70 + 15 * pc).clamp(0, 100);
    }
    return (100 * (0.8 * _coverage(required) + 0.2 * _coverage(preferred))).clamp(0, 100);
  }

  double _experienceScore(int? required, int yearsTotal, CareerStage? stage) {
    if (required == null) return yearsTotal > 0 ? 75.0 : 60.0;
    final isJuniorStage = stage == CareerStage.student || stage == CareerStage.freshGraduate;
    if (isJuniorStage && required <= 2) return 100.0;
    if (yearsTotal >= required) return 100.0;
    final ratio = required == 0 ? 1.0 : yearsTotal / required;
    if (isJuniorStage) return (ratio * 100).clamp(20, 100);
    return (ratio * 100).clamp(0, 100);
  }

  double _educationScore(String? required, int highestRank) {
    if (required == null) return highestRank > 0 ? 80.0 : 70.0;
    final reqRank = JobAnalyzer.educationRank[required.toLowerCase()] ?? 0;
    if (reqRank == 0) return 80.0;
    if (highestRank >= reqRank) return 100.0;
    final gap = (reqRank - highestRank).clamp(0, 3);
    const scaled = [70.0, 45.0, 20.0, 0.0];
    return scaled[gap];
  }

  double _keywordScore(JobExtraction extraction, Set<String> pool) {
    if (extraction.keywords.isEmpty) return 70.0;
    final matched = extraction.keywords.where((k) => pool.contains(_canon(k))).length;
    return (100 * matched / extraction.keywords.length).clamp(0, 100);
  }

  double _languageScore(JobExtraction extraction, Set<String> candidateLangs) {
    if (extraction.languages.isEmpty) return 100.0;
    final matched =
        extraction.languages.where((l) => candidateLangs.contains(l.trim().toLowerCase())).length;
    return (100 * matched / extraction.languages.length).clamp(0, 100);
  }

  MatchCategory _category(double overall, List<JobRequirement> required,
      List<JobRequirement> mismatches) {
    final reqGaps = required.where((r) => r.status != RequirementStatus.strongMatch).length;
    final mismatchCount = mismatches.length;
    if (overall >= 80 && mismatchCount == 0 && reqGaps == 0) return MatchCategory.strong;
    if (overall >= 65 && mismatchCount == 0) return MatchCategory.good;
    if (overall >= 45 || reqGaps <= 2) return MatchCategory.moderate;
    return MatchCategory.weak;
  }

  String _buildRecommendation({
    required MatchCategory category,
    required List<JobRequirement> requiredGaps,
    required List<JobRequirement> preferredGaps,
    required List<JobRequirement> strong,
    CareerTarget? target,
  }) {
    final parts = <String>[];
    final targetNote = target != null && target.role.isNotEmpty ? ' for ${target.role}' : '';
    switch (category) {
      case MatchCategory.strong:
        parts.add('Strong match$targetNote — apply with confidence.');
      case MatchCategory.good:
        parts.add('Good match$targetNote — apply after closing a few preferred gaps.');
      case MatchCategory.moderate:
        parts.add('Moderate match$targetNote — strengthen key areas before applying.');
      case MatchCategory.weak:
        parts.add('Weak match$targetNote — significant gaps remain; consider a closer-fit role first.');
    }
    final topGaps = [...requiredGaps, ...preferredGaps].where((r) => r.status != RequirementStatus.strongMatch).take(3);
    if (topGaps.isNotEmpty) {
      final labels = topGaps.map((r) => r.label).join(', ');
      parts.add('Focus on: $labels.');
    }
    if (strong.isNotEmpty) {
      final top = strong.take(3).map((r) => r.label).join(', ');
      parts.add('Your strengths: $top.');
    }
    return parts.join(' ');
  }

  // ---- Public compute ----

  OpportunityAnalysis compute({
    required CareerDna dna,
    required JobExtraction extraction,
    CareerTarget? target,
    String? aiRecommendation,
  }) {
    final projectTech = <String>{};
    final projectEvidence = <String, String>{};
    for (final p in dna.profile.projects) {
      for (final t in p.tech) {
        final c = _canon(t);
        projectTech.add(c);
        projectEvidence.putIfAbsent(c, () => p.name);
      }
    }
    final candidateHasData = dna.skills.isNotEmpty ||
        dna.profile.projects.isNotEmpty ||
        dna.profile.experience.isNotEmpty ||
        dna.profile.certifications.isNotEmpty ||
        dna.profile.education.isNotEmpty;

    final requiredSkillLabels = <String>{
      ...extraction.requiredSkills,
      ...extraction.technologies,
    };
    final skillRequirements = <JobRequirement>[
      for (final label in requiredSkillLabels)
        _resolveSkill(label, true, dna, projectTech, projectEvidence, candidateHasData),
      for (final label in extraction.preferredSkills)
        _resolveSkill(label, false, dna, projectTech, projectEvidence, candidateHasData),
    ];

    final yearsTotal = dna.profile.yearsTotal;
    final highestRank = _highestRank(dna.profile.education);
    final hasExpData = dna.profile.experience.isNotEmpty;
    final hasEduData = dna.profile.education.isNotEmpty;

    final experienceItem = _resolveExperience(
        extraction.experienceYearsRequired, dna, yearsTotal, hasExpData, candidateHasData);
    final educationItem = _resolveEducation(
        extraction.educationRequired, dna, highestRank, hasEduData, candidateHasData);

    final requiredReqs = skillRequirements.where((r) => r.required).toList();
    final preferredReqs = skillRequirements.where((r) => !r.required).toList();

    final double skillsScore = _skillsScore(requiredReqs, preferredReqs).toDouble();
    final double experienceScore =
        _experienceScore(extraction.experienceYearsRequired, yearsTotal, dna.stage).toDouble();
    final double educationScore =
        _educationScore(extraction.educationRequired, highestRank).toDouble();
    final keywordPool = <String>{
      ...{for (final s in dna.skills) _canon(s)},
      ...projectTech,
      ...{for (final c in dna.profile.certifications) _canon(c)},
      ...{for (final e in dna.profile.experience) _canon(e.role)},
    };
    final double keywordsScore = _keywordScore(extraction, keywordPool).toDouble();
    final candidateLangs = <String>{for (final l in dna.profile.languages) l.trim().toLowerCase()};
    final double languageScore = _languageScore(extraction, candidateLangs);

    final double overall = (skillsScore * 0.45 +
            experienceScore * 0.25 +
            educationScore * 0.15 +
            keywordsScore * 0.15)
        .clamp(0, 100)
        .toDouble();

    final mismatches = <JobRequirement>[
      ...skillRequirements.where((r) => r.status == RequirementStatus.requirementMismatch),
      if (experienceItem.status == RequirementStatus.requirementMismatch) experienceItem,
      if (educationItem.status == RequirementStatus.requirementMismatch) educationItem,
    ];

    final category = _category(overall, requiredReqs, mismatches);
    final recommendationText = (aiRecommendation != null && aiRecommendation.trim().isNotEmpty)
        ? aiRecommendation.trim()
        : _buildRecommendation(
            category: category,
            requiredGaps: requiredReqs.where((r) => r.status != RequirementStatus.strongMatch).toList(),
            preferredGaps: preferredReqs.where((r) => r.status != RequirementStatus.strongMatch).toList(),
            strong: skillRequirements.where((r) => r.status == RequirementStatus.strongMatch).toList(),
            target: target,
          );

    return OpportunityAnalysis(
      targetId: target?.id,
      jobDescription: extraction.rawText,
      role: extraction.role.isNotEmpty ? extraction.role : (target?.role ?? ''),
      company: extraction.company,
      seniority: extraction.seniority,
      requirements: skillRequirements,
      responsibilities: extraction.responsibilities,
      technologies: extraction.technologies,
      experienceItem: experienceItem,
      educationItem: educationItem,
      experienceRequirement: extraction.experienceYearsRequired == null
          ? null
          : '${extraction.experienceYearsRequired}+ years',
      educationRequirement:
          extraction.educationRequired == null ? null : _rankLabel(JobAnalyzer.educationRank[extraction.educationRequired!.toLowerCase()] ?? 0),
      certifications: extraction.certifications,
      languages: extraction.languages,
      softSkills: extraction.softSkills,
      domainKnowledge: extraction.domainKnowledge,
      keywords: extraction.keywords,
      skillsScore: skillsScore,
      experienceScore: experienceScore,
      educationScore: educationScore,
      keywordsScore: keywordsScore,
      languageScore: languageScore,
      overall: overall,
      recommendationCategory: category,
      recommendationText: recommendationText,
    );
  }
}
