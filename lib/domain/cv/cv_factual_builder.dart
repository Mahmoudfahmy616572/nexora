import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/cv_content.dart';
import '../entities/profile_data.dart';

/// Builds a [CvContent] directly from verified [CareerDna] facts.
///
/// This is the deterministic fallback used when AI generation is unavailable
/// or fails validation. It contains ONLY known facts and is clearly labelled
/// as a "Factual CV". It never invents experience, employers, metrics, dates,
/// or any other information, and the [CareerTarget] only influences ordering
/// and emphasis — never the facts themselves.
class CvFactualBuilder {
  const CvFactualBuilder._();

  static const String factualLabel = 'Factual CV';

  // ---------------------------------------------------------------------------
  // Skill categorization
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _skillCategories = {
    'Programming & Architecture': [
      'dart', 'flutter', 'kotlin', 'swift', 'java', 'python', 'javascript',
      'typescript', 'c++', 'c#', 'php', 'ruby', 'go', 'rust', 'scala',
      'r', 'sql', 'html', 'css', 'sass', 'less',
      'oop', 'solid', 'clean architecture', 'mvvm', 'mvc', 'mvp',
      'bloc', 'bloc/cubit', 'cubit', 'provider', 'riverpod', 'getx',
      'hooks', 'redux', 'mobx', 'get_it', 'injectable',
    ],
    'Backend & Databases': [
      'firebase', 'firestore', 'realtime db', 'firebase auth',
      'cloud functions', 'cloud firestore', 'supabase', 'postgres',
      'postgresql', 'mysql', 'mongodb', 'redis', 'sqlite', 'hive',
      'local storage', 'rest', 'graphql', 'firebase realtime database',
      'appwrite', 'aws', 'gcp', 'azure', 'django', 'flask', 'express',
      'node', 'node.js', 'spring', 'laravel',
    ],
    'APIs & Integrations': [
      'rest apis', 'restful', 'graphql', 'websockets', 'socket.io',
      'google maps', 'maps', 'stripe', 'paymob', 'razorpay',
      'in-app purchase', 'push notifications', 'fcm', 'firebase cloud messaging',
      'deep linking', 'oauth', 'jwt', 'webhooks',
      'google sign-in', 'apple sign-in', 'facebook login',
    ],
    'DevOps & Tools': [
      'git', 'github', 'gitlab', 'bitbucket', 'ci/cd', 'jenkins',
      'github actions', 'docker', 'kubernetes', 'fastlane', 'codemagic',
      'postman', 'android studio', 'vs code', 'xcode', 'intellij',
      'figma', 'sketch', 'adobe xd', 'zeplin', 'jira', 'trello',
      'notion', 'confluence', 'slack',
    ],
    'Networking & Security': [
      'tcp/ip', 'osi model', 'routing', 'switching', 'network security',
      'vpn', 'firewall', 'ssl', 'tls', 'https',
    ],
  };

  /// Categorizes a flat list of skills into meaningful groups. Skills that
  /// don't match any known category are placed under "Other".
  static List<CvSkillGroup> categorizeSkills(
    List<String> skills, {
    CvSource source = CvSource.careerDna,
  }) {
    if (skills.isEmpty) return const [];

    final buckets = <String, List<String>>{};
    for (final skill in skills) {
      final lower = skill.toLowerCase().trim();
      if (lower.isEmpty) continue;

      String placedCategory = 'Other';
      for (final entry in _skillCategories.entries) {
        if (entry.value.any((k) =>
            lower == k ||
            (lower.length >= 4 && k.length >= 4 && lower.contains(k)) ||
            (lower.length >= 4 && k.length >= 4 && k.contains(lower)))) {
          placedCategory = entry.key;
          break;
        }
      }
      buckets.putIfAbsent(placedCategory, () => []).add(skill);
    }

    // Preferred ordering: Programming first, then Backend, APIs, DevOps, Networking, Other.
    const categoryOrder = [
      'Programming & Architecture',
      'Backend & Databases',
      'APIs & Integrations',
      'DevOps & Tools',
      'Networking & Security',
      'Other',
    ];

    return [
      for (final cat in categoryOrder)
        if (buckets.containsKey(cat))
          CvSkillGroup(title: cat, skills: buckets[cat]!, source: source),
    ];
  }

  // ---------------------------------------------------------------------------
  // Bullet decomposition
  // ---------------------------------------------------------------------------

  /// Decomposes a single description string into factual bullets by splitting
  /// on sentence boundaries. Each sentence that is substantive (>15 chars)
  /// becomes a separate bullet. Never invents content.
  static List<String> _decomposeBullets(String description) {
    if (description.trim().isEmpty) return const [];
    final sentences = description
        .split(RegExp(r'(?<=[.!?\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();
    return sentences.isEmpty ? [description.trim()] : sentences;
  }

  // ---------------------------------------------------------------------------
  // Main builder
  // ---------------------------------------------------------------------------

  static CvContent build(CareerDna dna, {CareerTarget? target}) {
    final profile = dna.profile;

    // --- Experience ---
    final experience = [
      for (final e in profile.experience)
        CvExperience(
          role: e.role,
          company: e.company,
          years: e.years,
          bullets: _experienceBullets(e),
          source: CvSource.careerDna,
        ),
    ];

    // --- Projects ---
    final projects = [
      for (final p in profile.projects)
        CvProject(
          name: p.name,
          description: p.description,
          tech: p.tech,
          bullets: _decomposeBullets(p.description),
          source: CvSource.careerDna,
        ),
    ];

    // --- Education ---
    final education = [
      for (final e in profile.education)
        CvEducation(
          degree: e.degree,
          field: e.field,
          source: CvSource.careerDna,
        ),
    ];

    // --- Skills (categorized) ---
    final skillGroups = categorizeSkills(dna.skills);

    // --- Certifications ---
    final certifications = [
      for (final c in profile.certifications)
        CvCertification(name: c, source: CvSource.careerDna),
    ];

    // --- Achievements ---
    final achievements = [
      for (final a in profile.achievements)
        CvAchievement(text: a, source: CvSource.careerDna),
    ];

    // --- Languages ---
    final languages = [
      for (final l in profile.languages)
        CvLanguage(name: l, source: CvSource.careerDna),
    ];

    // --- Header ---
    final header = CvHeader(
      title: target?.role ?? dna.targetRole,
      subtitle: _emphasisFor(dna, target),
    );

    return CvContent(
      header: header,
      summary: profile.summary,
      experience: experience,
      projects: projects,
      education: education,
      skillGroups: skillGroups,
      certifications: certifications,
      achievements: achievements,
      languages: languages,
      sourceLabel: factualLabel,
    );
  }

  /// Generates factual bullets from a [ProfileExperience]. Since the source
  /// data only contains role/company/years (no description), bullets are
  /// necessarily minimal — the AI layer enriches these later.
  static List<String> _experienceBullets(ProfileExperience e) {
    // ProfileExperience has no description field, so we cannot invent bullets.
    // Return empty — the template will fall back to role/company header only.
    // AI generation is responsible for creating meaningful experience bullets
    // from the CareerDna context.
    return const [];
  }

  /// Target may influence which factual sections are emphasized, never invented.
  static String _emphasisFor(CareerDna dna, CareerTarget? target) {
    if (target?.role.isNotEmpty == true) return target!.role;
    if (dna.targetRole.isNotEmpty) return dna.targetRole;
    if (dna.stage != null) return dna.stage!.name;
    return '';
  }
}
