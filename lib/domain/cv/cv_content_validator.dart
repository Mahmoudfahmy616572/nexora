import '../entities/career_dna.dart';
import '../entities/cv_content.dart';
import '../entities/user_identity.dart';

/// A single factual problem found while validating AI-generated CV content.
class CvValidationIssue {
  const CvValidationIssue({
    required this.code,
    required this.message,
    this.section,
  });

  final String code;
  final String message;
  final String? section;

  @override
  String toString() => '[$code] ${section ?? ''}: $message';
}

/// The result of validating generated [CvContent] against verified [CareerDna].
class CvValidationResult {
  const CvValidationResult({required this.valid, this.issues = const []});

  final bool valid;
  final List<CvValidationIssue> issues;

  CvValidationResult copyWithAdded(CvValidationIssue issue) => CvValidationResult(
        valid: false,
        issues: [...issues, issue],
      );
}

/// Deterministic validation layer.
///
/// The LLM is a wording/tailoring engine, never a source of truth. After
/// generation we MUST verify every factual claim against the user's [CareerDna]
/// before the content can be used. Unknown experience, companies, projects,
/// technologies, degrees, certifications, or fabricated metrics are rejected.
///
/// See [CvFactualBuilder] for the always-valid deterministic fallback.
class CvContentValidator {
  const CvContentValidator._();

  static String _norm(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+#. ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static final RegExp _metricUnit = RegExp(
    r'\d+(\.\d+)?\s?(%|percent|k|m|million|thousand|\$|usd|eur|gb|mb)',
    caseSensitive: false,
  );
  static final RegExp _metricPhrase = RegExp(
    r'(team of|led a team|managed|supervised|increased by|reduced by|improved by|grew by|boosted|'
    r'\d+\s?(developers|engineers|users|clients|customers|people|members|countries|markets))',
    caseSensitive: false,
  );

  static CvValidationResult validate(CvContent content, CareerDna dna, {UserIdentity? identity}) {
    final issues = <CvValidationIssue>[];
    final profile = dna.profile;

    // Corpus of the user's OWN authored facts. Metrics / technologies that
    // merely echo something the user already provided are NOT fabrication, so
    // we allow them even if they don't exactly match a structured field.
    final knownSource = _buildCorpus(dna);

    final knownExperience = {
      for (final e in profile.experience) _norm('${e.role} ${e.company}'),
    };
    final knownExperienceAchievements = <String>{
      for (final e in profile.experience) ...e.achievements.map(_norm),
    };
    final knownProjects = {
      for (final p in profile.projects) _norm(p.name),
    };
    final knownTech = <String>{
      for (final p in profile.projects) ...p.tech.map(_norm),
      for (final s in dna.skills) _norm(s),
    };
    final knownDegrees = {for (final e in profile.education) _norm(e.degree)};
    final knownCerts = {for (final c in profile.certifications) _norm(c.name)};
    final knownLanguages = {for (final l in profile.languages) _norm(l)};
    final knownProjectUrls = <String>{
      for (final p in profile.projects)
        for (final l in p.links)
          if (l.url.trim().isNotEmpty) l.url.trim().toLowerCase(),
    };
    final knownIdentityUrls = <String>{
      if (identity?.linkedinUrl.isNotEmpty == true) identity!.linkedinUrl.trim().toLowerCase(),
      if (identity?.githubUrl.isNotEmpty == true) identity!.githubUrl.trim().toLowerCase(),
      if (identity?.portfolioUrl.isNotEmpty == true) identity!.portfolioUrl.trim().toLowerCase(),
    };

    // --- Experience validation ---
    for (final exp in content.experience) {
      final key = _norm('${exp.role} ${exp.company}');
      final exists = knownExperience.any((k) => k.isNotEmpty && _nameOverlap(key, k));
      if (!exists && key.isNotEmpty) {
        issues.add(CvValidationIssue(
          code: 'unknown_experience',
          message: 'Experience "${exp.role} at ${exp.company}" is not in your Career DNA.',
          section: 'experience',
        ));
      }
      // Validate description (backward compat).
      _checkMetric(exp.description, 'experience', issues, knownSource);
      // Validate each bullet for fabricated metrics.
      for (final bullet in exp.bullets) {
        _checkMetric(bullet, 'experience', issues, knownSource);
      }
      // Validate per-experience achievements against CareerDNA.
      for (final ach in exp.achievements) {
        final normAch = _norm(ach);
        if (normAch.isNotEmpty &&
            !knownExperienceAchievements.contains(normAch) &&
            !knownSource.contains(normAch)) {
          issues.add(CvValidationIssue(
            code: 'unknown_experience_achievement',
            message: 'Experience achievement "$ach" for "${exp.role} at ${exp.company}" is not in your Career DNA.',
            section: 'experience',
          ));
        }
      }
    }

    // --- Project validation ---
    for (final proj in content.projects) {
      final name = _norm(proj.name);
      final exists = knownProjects.any((n) => n.isNotEmpty && _nameOverlap(name, n));
      if (!exists && name.isNotEmpty) {
        issues.add(CvValidationIssue(
          code: 'unknown_project',
          message: 'Project "${proj.name}" is not in your Career DNA.',
          section: 'projects',
        ));
      }
      for (final tech in proj.tech) {
        final t = _norm(tech);
        if (t.isNotEmpty && !knownTech.contains(t) && !knownSource.contains(t)) {
          issues.add(CvValidationIssue(
            code: 'unknown_technology',
            message: 'Technology "$tech" is not in your Career DNA.',
            section: 'projects',
          ));
        }
      }
      // Validate description (backward compat).
      _checkMetric(proj.description, 'projects', issues, knownSource);
      for (final bullet in proj.bullets) {
        _checkMetric(bullet, 'projects', issues, knownSource);
      }
      // Validate project links come from CareerDNA.
      for (final link in proj.links) {
        if (link.url.trim().isEmpty) continue;
        final url = link.url.trim().toLowerCase();
        if (!knownProjectUrls.contains(url)) {
          issues.add(CvValidationIssue(
            code: 'unknown_project_url',
            message: 'Project link "${link.url}" for "${proj.name}" is not in your Career DNA.',
            section: 'projects',
          ));
        }
      }
    }

    // --- Education validation ---
    for (final edu in content.education) {
      final d = _norm(edu.degree);
      if (d.isNotEmpty && !knownDegrees.contains(d)) {
        issues.add(CvValidationIssue(
          code: 'unknown_education',
          message: 'Education "${edu.degree}" is not in your Career DNA.',
          section: 'education',
        ));
      }
    }

    // --- Certification validation ---
    final knownCertUrls = <String>{
      for (final c in profile.certifications)
        if (c.link.trim().isNotEmpty) c.link.trim().toLowerCase(),
    };
    for (final cert in content.certifications) {
      final c = _norm(cert.name);
      if (c.isNotEmpty && !knownCerts.contains(c)) {
        issues.add(CvValidationIssue(
          code: 'unknown_certification',
          message: 'Certification "${cert.name}" is not in your Career DNA.',
          section: 'certifications',
        ));
      }
      if (cert.link.trim().isNotEmpty &&
          !knownCertUrls.contains(cert.link.trim().toLowerCase())) {
        issues.add(CvValidationIssue(
          code: 'unknown_certification_link',
          message: 'Certification link for "${cert.name}" is not in your Career DNA.',
          section: 'certifications',
        ));
      }
    }

    // --- Language validation ---
    for (final lang in content.languages) {
      final l = _norm(lang.name);
      if (l.isNotEmpty && !knownLanguages.contains(l)) {
        issues.add(CvValidationIssue(
          code: 'unknown_language',
          message: 'Language "${lang.name}" is not in your Career DNA.',
          section: 'languages',
        ));
      }
    }

    // --- Summary + achievements metric check ---
    _checkMetric(content.summary, 'summary', issues, knownSource);
    for (final ach in content.achievements) {
      _checkMetric(ach.text, 'achievements', issues, knownSource);
    }

    // --- Header name match (when identity is provided) ---
    if (identity != null && identity.fullName.isNotEmpty) {
      final headerName = _norm(content.header.name);
      final expectedName = _norm(identity.fullName);
      final matches = headerName.isNotEmpty &&
          expectedName.isNotEmpty &&
          (headerName == expectedName ||
              headerName.contains(expectedName) ||
              expectedName.contains(headerName) ||
              _nameOverlap(headerName, expectedName));
      if (headerName.isNotEmpty && expectedName.isNotEmpty && !matches) {
        issues.add(CvValidationIssue(
          code: 'header_name_mismatch',
          message: 'Header name "${content.header.name}" does not match your identity "${identity.fullName}".',
          section: 'header',
        ));
      }
    }

    // --- Header link validation (when identity is provided) ---
    if (identity != null) {
      for (final link in content.header.links) {
        if (link.url.trim().isEmpty) continue;
        final url = link.url.trim().toLowerCase();
        if (!knownIdentityUrls.contains(url)) {
          issues.add(CvValidationIssue(
            code: 'unknown_header_url',
            message: 'Header link "${link.url}" is not in your identity data.',
            section: 'header',
          ));
        }
      }
    }

    return CvValidationResult(valid: issues.isEmpty, issues: issues);
  }

  /// A normalized corpus of everything the user actually authored in their DNA.
  /// Metrics / technologies that merely echo this text are legitimate.
  static String _buildCorpus(CareerDna dna) {
    final parts = <String>[
      dna.profile.summary,
      for (final e in dna.profile.experience) ...[
        e.role,
        e.company,
        e.description,
        ...e.bullets,
      ],
      for (final p in dna.profile.projects) ...[
        p.name,
        p.description,
        p.role,
        p.outcome,
        p.keyFeatures,
        p.challenges,
        ...p.tech,
      ],
      for (final e in dna.profile.education) '${e.degree} ${e.field}',
      ...dna.skills,
      ...dna.profile.certifications.map((c) => c.name),
      ...dna.profile.achievements,
      ...dna.profile.languages,
    ];
    return _norm(parts.join(' '));
  }

  /// True when [a] and [b] are the same name or share a strong (>=50%) token
  /// overlap. Allows benign rewording (e.g. "SoundOra Mobile App" vs
  /// "SoundOra App") while still rejecting clearly fabricated names.
  static bool _nameOverlap(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || a.contains(b) || b.contains(a)) return true;
    final ta = _tokens(a);
    final tb = _tokens(b);
    if (ta.isEmpty || tb.isEmpty) return false;
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    return union > 0 && inter / union >= 0.5;
  }

  static Set<String> _tokens(String s) =>
      _norm(s).split(' ').where((t) => t.length > 2).toSet();

  static void _checkMetric(
    String text,
    String section,
    List<CvValidationIssue> issues,
    String knownSource,
  ) {
    if (text.isEmpty) return;
    if (_metricUnit.hasMatch(text) || _metricPhrase.hasMatch(text)) {
      // Allow metrics that originate from the user's own DNA facts.
      final matched = _metricUnit.firstMatch(text)?.group(0) ??
          _metricPhrase.firstMatch(text)?.group(0) ??
          text;
      if (_norm(matched).isNotEmpty && knownSource.contains(_norm(matched))) {
        return;
      }
      issues.add(CvValidationIssue(
        code: 'unsupported_metric',
        message: 'Generated text contains a metric or scale claim that is not in your Career DNA.',
        section: section,
      ));
    }
  }
}
