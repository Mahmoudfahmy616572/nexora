import '../entities/career_dna.dart';
import '../entities/career_target.dart';
import '../entities/cv_content.dart';
import 'cv_section_ordering.dart';
import '../entities/profile_data.dart';
import '../entities/user_identity.dart';

/// Builds a [CvContent] directly from verified [CareerDna] facts.
///
/// This is the deterministic fallback used when AI generation is unavailable
/// or fails validation. It contains ONLY known facts and is clearly labelled
/// as a "Factual CV". It never invents experience, employers, metrics, dates,
/// or any other information, and the [CareerTarget] influences ordering,
/// emphasis, and prioritization — never the facts themselves.
class CvFactualBuilder {
  const CvFactualBuilder._();

  static const String factualLabel = 'Factual CV';

  // ---------------------------------------------------------------------------
  // Skill categorization
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _skillCategories = {
    'Programming & Languages': [
      'dart', 'kotlin', 'swift', 'java', 'python', 'javascript',
      'typescript', 'c++', 'c#', 'php', 'ruby', 'go', 'rust', 'scala',
      'r', 'sql', 'html', 'css', 'sass', 'less', 'groovy', 'objective-c',
    ],
    'Frameworks & Architecture': [
      'flutter', 'react', 'react native', 'angular', 'vue', 'vue.js',
      'next.js', 'nuxt', 'svelte', 'django', 'flask', 'express',
      'spring', 'laravel', 'rails', '.net', 'xamarin', 'ionic',
      'tailwind', 'bootstrap', 'material', 'swiftui', 'jetpack compose',
      'oop', 'solid', 'clean architecture', 'mvvm', 'mvc', 'mvp',
      'bloc', 'bloc/cubit', 'cubit', 'provider', 'riverpod', 'getx',
      'hooks', 'redux', 'mobx', 'get_it', 'injectable', 'bloc/cubit',
    ],
    'Backend & Databases': [
      'firebase', 'firestore', 'realtime db', 'firebase auth',
      'cloud functions', 'cloud firestore', 'supabase', 'postgres',
      'postgresql', 'mysql', 'mongodb', 'redis', 'sqlite', 'hive',
      'local storage', 'appwrite', 'aws', 'gcp', 'azure',
      'node', 'node.js', 'deno',
    ],
    'APIs & Integrations': [
      'rest', 'rest apis', 'restful', 'graphql', 'websockets', 'socket.io',
      'google maps', 'maps', 'stripe', 'paymob', 'razorpay',
      'in-app purchase', 'push notifications', 'fcm', 'firebase cloud messaging',
      'deep linking', 'oauth', 'jwt', 'webhooks',
      'google sign-in', 'apple sign-in', 'facebook login',
    ],
    'Mobile & Cross-Platform': [
      'ios', 'android', 'flutter', 'react native', 'xamarin', 'ionic',
      'swiftui', 'jetpack compose', 'material design', 'cupertino',
      'adaptive layouts', 'responsive design', 'pwa',
    ],
    'DevOps & Tools': [
      'git', 'github', 'gitlab', 'bitbucket', 'ci/cd', 'jenkins',
      'github actions', 'docker', 'kubernetes', 'fastlane', 'codemagic',
      'postman', 'android studio', 'vs code', 'xcode', 'intellij',
      'jira', 'trello', 'notion', 'confluence', 'slack',
    ],
    'Design & Prototyping': [
      'figma', 'sketch', 'adobe xd', 'zeplin', 'canva',
      'photoshop', 'illustrator', 'after effects', 'premiere pro',
      'ui/ux', 'user research', 'wireframing', 'prototyping',
      'design systems', 'user testing',
    ],
    'Networking & Security': [
      'tcp/ip', 'osi model', 'routing', 'switching', 'network security',
      'vpn', 'firewall', 'ssl', 'tls', 'https', 'ci/cd',
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

    const categoryOrder = [
      'Programming & Languages',
      'Frameworks & Architecture',
      'Mobile & Cross-Platform',
      'Backend & Databases',
      'APIs & Integrations',
      'Design & Prototyping',
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

  static CvContent build(CareerDna dna, {CareerTarget? target, UserIdentity? identity}) {
    final profile = dna.profile;

    // --- Experience ---
    var experience = [
      for (final e in profile.experience)
        if (e.role.isNotEmpty || e.company.isNotEmpty || e.description.isNotEmpty)
          CvExperience(
            role: e.role,
            company: e.company,
            years: e.years,
            durationMonths: e.durationMonths,
            startDate: e.startDate,
            endDate: e.endDate,
            location: e.location,
            description: e.description,
            bullets: _experienceBullets(e),
            technologies: e.technologies,
            achievements: e.achievements,
            source: CvSource.careerDna,
          ),
    ];

    // --- Projects ---
    var projects = [
      for (final p in profile.projects)
        if (p.name.isNotEmpty)
          CvProject(
            name: p.name,
            description: p.description,
            tech: p.tech,
            role: p.role,
            outcome: p.outcome,
            bullets: _projectBullets(p),
            links: [
              for (final l in p.links.where((l) => l.url.trim().isNotEmpty))
                CvContactLink(
                  label: l.label.trim().isNotEmpty
                      ? l.label.trim()
                      : ProjectLink.autoLabel(l.url, p.name),
                  url: l.url.trim(),
                ),
            ],
            source: CvSource.careerDna,
          ),
    ];

    // --- Education ---
    final education = [
      for (final e in profile.education)
        if (e.degree.isNotEmpty)
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
        if (c.name.trim().isNotEmpty)
          CvCertification(name: c.name, link: c.link.trim(), source: CvSource.careerDna),
    ];

    // --- Achievements ---
    final achievements = [
      for (final a in profile.achievements)
        if (a.trim().isNotEmpty)
          CvAchievement(text: a, source: CvSource.careerDna),
    ];

    // --- Languages ---
    final languages = [
      for (final l in profile.languages)
        if (l.trim().isNotEmpty)
          CvLanguage(name: l, source: CvSource.careerDna),
    ];

    // --- Header (from identity when available) ---
    final effectiveTitle = identity?.professionalTitle.isNotEmpty == true
        ? identity!.professionalTitle
        : target?.role.isNotEmpty == true
            ? target!.role
            : dna.targetRole;

    final header = CvHeader(
      name: identity?.fullName ?? '',
      title: effectiveTitle,
      subtitle: _emphasisFor(dna, target),
      email: identity?.email ?? '',
      phone: identity?.phone ?? '',
      location: identity?.location ?? '',
      links: [
        if (identity?.linkedinUrl.isNotEmpty == true)
          const CvContactLink(label: 'LinkedIn', url: '').copyWith(url: identity!.linkedinUrl),
        if (identity?.githubUrl.isNotEmpty == true)
          const CvContactLink(label: 'GitHub', url: '').copyWith(url: identity!.githubUrl),
        if (identity?.portfolioUrl.isNotEmpty == true)
          const CvContactLink(label: 'Portfolio', url: '').copyWith(url: identity!.portfolioUrl),
      ],
    );

    var content = CvContent(
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

    // Apply target-aware prioritization.
    if (target != null) {
      content = content.copyWith(
        experience: CvSectionOrdering.prioritizeExperience(
          experience: content.experience,
          target: target,
        ),
        projects: CvSectionOrdering.prioritizeProjects(
          projects: content.projects,
          target: target,
        ),
        skillGroups: CvSectionOrdering.prioritizeSkills(
          groups: content.skillGroups,
          target: target,
        ),
      );
    }

    return content;
  }

  /// Generates factual bullets from a [ProfileExperience].
  ///
  /// Uses explicit bullets if provided, falls back to decomposing the
  /// description, or returns empty if nothing is available.
  static List<String> _experienceBullets(ProfileExperience e) {
    if (e.bullets.isNotEmpty) return e.bullets;
    return _decomposeBullets(e.description);
  }

  /// Generates factual bullets from a [ProfileProject].
  static List<String> _projectBullets(ProfileProject p) {
    final parts = <String>[
      ..._decomposeBullets(p.description),
      ..._decomposeBullets(p.keyFeatures),
      ..._decomposeBullets(p.challenges),
      ..._decomposeBullets(p.outcome),
    ];
    return parts;
  }

  /// Target may influence which factual sections are emphasized, never invented.
  static String _emphasisFor(CareerDna dna, CareerTarget? target) {
    if (target?.role.isNotEmpty == true) return target!.role;
    if (dna.targetRole.isNotEmpty) return dna.targetRole;
    if (dna.stage != null) return dna.stage!.name;
    return '';
  }
}
