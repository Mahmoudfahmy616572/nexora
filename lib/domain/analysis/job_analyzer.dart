import '../entities/job_analysis.dart';
import '../entities/profile_data.dart';

/// Offline, domain-aware analyzer for a pasted opportunity description.
///
/// This is the engine that runs whenever the hosted AI edge function is
/// unavailable (signed out, offline, or unconfigured). It extracts the
/// opportunity's real requirements from free text, scores them against the
/// candidate's actual profile with weighted sub-scores, and produces tailored,
/// candidate-specific advice.
class JobAnalyzer {
  const JobAnalyzer();

  /// Canonical skill -> synonyms/phrases that imply it in a job description.
  static const Map<String, List<String>> _skillAliases = {
    'Flutter': ['flutter'],
    'Dart': ['dart'],
    'REST APIs': ['rest', 'restful', 'rest api', 'restful api', 'apis', 'web api', 'http api'],
    'Supabase': ['supabase'],
    'Git': ['git', 'github', 'gitlab', 'bitbucket', 'version control'],
    'Google Maps': ['google maps', 'maps sdk', 'map sdk', 'maps api'],
    'Docker': ['docker', 'container', 'containerization', 'containers'],
    'CI/CD': ['ci/cd', 'cicd', 'continuous integration', 'continuous delivery', 'continuous deployment', 'build pipeline'],
    'Unit Testing': ['unit test', 'unit testing', 'tdd', 'test-driven', 'test driven', 'automated testing'],
    'Firebase': ['firebase'],
    'State Management': ['state management', 'provider', 'bloc', 'riverpod', 'getx', 'mobx'],
    'GraphQL': ['graphql'],
    'SQL': ['sql', 'postgres', 'postgresql', 'mysql', 'sqlite', 'relational database'],
    'Kubernetes': ['kubernetes', 'k8s', 'orchestration'],
    'Python': ['python'],
    'JavaScript': ['javascript', 'ecmascript'],
    'TypeScript': ['typescript'],
    'React': ['react', 'react native', 'reactjs'],
    'Node.js': ['node', 'nodejs', 'node.js', 'express'],
    'AWS': ['aws', 'amazon web services', 'ec2', 's3', 'lambda'],
    'Agile': ['agile', 'scrum', 'kanban', 'sprint'],
    'UI/UX': ['ui/ux', 'ui ux', 'user experience', 'user interface', 'figma', 'wireframe', 'prototyping'],
    'Leadership': ['leadership', 'team lead', 'tech lead', 'mentoring', 'mentor'],
    'Communication': ['communication', 'collaboration', 'stakeholder', 'presentation'],
  };

  static const Map<String, int> _educationRank = {
    'phd': 5,
    'master': 4,
    'bachelor': 3,
    'associate': 2,
    'high school': 1,
  };

  /// Reverse lookup: a lowercased skill phrase -> its canonical name.
  static final Map<String, String> _aliasToCanonical = () {
    final map = <String, String>{};
    for (final entry in _skillAliases.entries) {
      map[entry.key.toLowerCase()] = entry.key;
      for (final alias in entry.value) {
        map[alias.toLowerCase()] = entry.key;
      }
    }
    return map;
  }();

  /// Public accessors so the Opportunity Match Engine can reuse the same
  /// canonical skill aliases and education ranking without duplicating them.
  static Map<String, List<String>> get skillAliases => _skillAliases;
  static Map<String, String> get aliasToCanonical => _aliasToCanonical;
  static Map<String, int> get educationRank => _educationRank;

  /// Runs the analysis and returns a fully populated [JobAnalysis].
  JobAnalysis analyze({
    required String description,
    required List<String> candidateSkills,
    required int yearsOfExperience,
    required String education,
    ProfileData? profile,
    String id = '',
    String title = '',
    String company = '',
    String timeAgo = 'Just now',
  }) {
    final required = _extractRequiredSkills(description);
    final candidateSet = _candidateSkillSet(candidateSkills);

    final strong = <String>[];
    final missing = <String>[];
    for (final requirement in required) {
      if (candidateSet.contains(requirement)) {
        strong.add(requirement);
      } else {
        missing.add(requirement);
      }
    }

    final skillsScore = required.isEmpty
        ? 65.0
        : (strong.length / required.length) * 100;

    final requiredYears = _extractRequiredYears(description);
    final experienceScore = requiredYears == null
        ? (yearsOfExperience > 0 ? 75.0 : 60.0)
        : (yearsOfExperience >= requiredYears
            ? 100.0
            : (yearsOfExperience / requiredYears) * 100);

    final requiredEdu = _extractRequiredEducation(description);
    final candidateRank = _educationRank[education.toLowerCase()] ?? 0;
    final educationScore = requiredEdu == null
        ? 80.0
        : _educationScore(candidateRank, _educationRank[requiredEdu] ?? 0);

    final signals = <String, bool>{};
    if (requiredYears != null) {
      signals['experience'] = yearsOfExperience >= requiredYears;
    }
    if (requiredEdu != null) {
      signals['education'] = candidateRank >= (_educationRank[requiredEdu] ?? 0);
    }
    signals['agile'] = _hasKeyword(description, ['agile', 'scrum', 'kanban']);
    signals['communication'] = _hasKeyword(description, ['communication', 'collaboration', 'stakeholder']);
    signals['leadership'] = _hasKeyword(description, ['lead', 'leadership', 'mentor', 'tech lead']);
    signals['remote'] = _hasKeyword(description, ['remote', 'work from home', 'distributed']);

    final matchedSignals = signals.values.where((matched) => matched).length;
    final keywordsScore = signals.isEmpty ? 70.0 : (matchedSignals / signals.length) * 100;

    const weightSkills = 0.45;
    const weightExperience = 0.25;
    const weightEducation = 0.15;
    const weightKeywords = 0.15;
    final overall = (skillsScore * weightSkills +
            experienceScore.clamp(0, 100) * weightExperience +
            educationScore.clamp(0, 100) * weightEducation +
            keywordsScore * weightKeywords)
        .clamp(0, 100);

    final recommendation = _buildRecommendation(
      description: description,
      strong: strong,
      missing: missing,
      requiredYears: requiredYears,
      yearsOfExperience: yearsOfExperience,
      requiredEdu: requiredEdu,
      education: education,
      profile: profile,
    );

    return JobAnalysis(
      id: id.isEmpty ? '${DateTime.now().microsecondsSinceEpoch}' : id,
      title: title,
      company: company,
      timeAgo: timeAgo,
      overall: overall.roundToDouble(),
      skills: skillsScore.roundToDouble(),
      experience: experienceScore.clamp(0, 100).roundToDouble(),
      education: educationScore.clamp(0, 100).roundToDouble(),
      keywords: keywordsScore.roundToDouble(),
      strong: strong,
      missing: missing,
      aiRecommendation: recommendation,
    );
  }

  List<String> _extractRequiredSkills(String text) {
    final lower = text.toLowerCase();
    final found = <String>{};
    for (final entry in _skillAliases.entries) {
      final canonical = entry.key;
      final patterns = [canonical.toLowerCase(), ...entry.value];
      for (final pattern in patterns) {
        if (RegExp('\\b${RegExp.escape(pattern)}\\b', caseSensitive: false).hasMatch(lower)) {
          found.add(canonical);
          break;
        }
      }
    }
    return found.toList();
  }

  Set<String> _candidateSkillSet(List<String> skills) {
    final set = <String>{};
    for (final skill in skills) {
      final key = skill.trim().toLowerCase();
      if (key.isEmpty) continue;
      set.add(_aliasToCanonical[key] ?? key);
    }
    return set;
  }

  int? _extractRequiredYears(String text) {
    final match = RegExp(
      r'(\d{1,2})\s*\+?\s*(?:-|to|–|and)?\s*\d*\s*years?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String? _extractRequiredEducation(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\bph\.?d\b|doctorate|postdoc').hasMatch(lower)) return 'phd';
    if (RegExp(r'\bmaster|\bm\.?sc\b|\bmba\b').hasMatch(lower)) return 'master';
    if (RegExp(r'\bbachelor|\bb\.?sc\b|\bb\.?eng\b|undergraduate').hasMatch(lower)) return 'bachelor';
    if (RegExp(r'\bassociate|diploma').hasMatch(lower)) return 'associate';
    if (RegExp(r'\bhigh school').hasMatch(lower)) return 'high school';
    return null;
  }

  bool _hasKeyword(String text, List<String> words) {
    final lower = text.toLowerCase();
    return words.any((word) => RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false).hasMatch(lower));
  }

  double _educationScore(int candidate, int required) {
    if (candidate >= required) return 100;
    final gap = (required - candidate).clamp(0, 3);
    const scaled = [70.0, 45.0, 20.0, 0.0];
    return scaled[gap];
  }

  String _buildRecommendation({
    required String description,
    required List<String> strong,
    required List<String> missing,
    required int? requiredYears,
    required int yearsOfExperience,
    required String? requiredEdu,
    required String education,
    ProfileData? profile,
  }) {
    final parts = <String>[];

    if (missing.isNotEmpty) {
      parts.add(
        "You're missing ${_listPhrases(missing)} — these show up as requirements, so add them (or evidence of them) to your CV.",
      );
    }
    if (requiredYears != null && yearsOfExperience < requiredYears) {
      parts.add(
        "The role asks for $requiredYears+ years; you have $yearsOfExperience. Lean on shipped projects to close the gap.",
      );
    }
    if (requiredEdu != null && (_educationRank[education.toLowerCase()] ?? 0) < (_educationRank[requiredEdu] ?? 0)) {
      parts.add(
        "A ${_titleCase(requiredEdu)} is preferred — note equivalent practical experience if you don't hold one.",
      );
    }
    if (strong.isNotEmpty) {
      final top = strong.length > 3 ? strong.sublist(0, 3) : strong;
      parts.add("Strong match on ${_listPhrases(top)}; lead your CV summary with these.");
    }

    if (profile != null && profile.projects.isNotEmpty) {
      for (final project in profile.projects) {
        final haystack = '${project.name} ${project.description} ${project.tech.join(' ')}'.toLowerCase();
        final hit = [...strong, ...missing].where((skill) => haystack.contains(skill.toLowerCase())).firstOrNull;
        if (hit != null) {
          parts.add("Highlight '$hit' through your ${project.name} project.");
          break;
        }
      }
    }

    if (parts.isEmpty) {
      parts.add(
        'No clear skill requirements detected — paste the full job description for a precise match.',
      );
    }

    return parts.join(' ');
  }

  String _listPhrases(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.single;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }

  String _titleCase(String value) => value.replaceFirstMapped(RegExp(r'^.'), (match) => match[0]!.toUpperCase());
}
