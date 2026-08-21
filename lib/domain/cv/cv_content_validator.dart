import '../entities/career_dna.dart';
import '../entities/cv_content.dart';

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

  // Numbers tied to units, money, or scale claims. Factual CVs must not invent
  // these; any occurrence in generated free text is treated as unsupported.
  static final RegExp _metricUnit = RegExp(
    r'\d+(\.\d+)?\s?(%|percent|k|m|million|thousand|\$|usd|eur|gb|mb)',
    caseSensitive: false,
  );
  static final RegExp _metricPhrase = RegExp(
    r'(team of|led a team|managed|supervised|increased by|reduced by|improved by|grew by|boosted|'
    r'\d+\s?(developers|engineers|users|clients|customers|people|members|countries|markets))',
    caseSensitive: false,
  );

  static CvValidationResult validate(CvContent content, CareerDna dna) {
    final issues = <CvValidationIssue>[];
    final profile = dna.profile;

    final knownExperience = {
      for (final e in profile.experience) _norm('${e.role} ${e.company}'),
    };
    final knownProjects = {
      for (final p in profile.projects) _norm(p.name),
    };
    final knownTech = <String>{
      for (final p in profile.projects) ...p.tech.map(_norm),
      for (final s in dna.skills) _norm(s),
    };
    final knownDegrees = {for (final e in profile.education) _norm(e.degree)};
    final knownCerts = {for (final c in profile.certifications) _norm(c)};
    final knownLanguages = {for (final l in profile.languages) _norm(l)};

    for (final exp in content.experience) {
      final key = _norm('${exp.role} ${exp.company}');
      final exists = knownExperience.any((k) => k.isNotEmpty && (k == key || k.contains(key) || key.contains(k)));
      if (!exists && key.isNotEmpty) {
        issues.add(CvValidationIssue(
          code: 'unknown_experience',
          message: 'Experience "${exp.role} at ${exp.company}" is not in your Career DNA.',
          section: 'experience',
        ));
      }
      _checkMetric(exp.description, 'experience', issues);
    }

    for (final proj in content.projects) {
      final name = _norm(proj.name);
      final exists = knownProjects.any((n) => n.isNotEmpty && (n == name || n.contains(name)));
      if (!exists && name.isNotEmpty) {
        issues.add(CvValidationIssue(
          code: 'unknown_project',
          message: 'Project "${proj.name}" is not in your Career DNA.',
          section: 'projects',
        ));
      }
      for (final tech in proj.tech) {
        final t = _norm(tech);
        if (t.isNotEmpty && !knownTech.contains(t)) {
          issues.add(CvValidationIssue(
            code: 'unknown_technology',
            message: 'Technology "$tech" is not in your Career DNA.',
            section: 'projects',
          ));
        }
      }
      _checkMetric(proj.description, 'projects', issues);
    }

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

    for (final cert in content.certifications) {
      final c = _norm(cert.name);
      if (c.isNotEmpty && !knownCerts.contains(c)) {
        issues.add(CvValidationIssue(
          code: 'unknown_certification',
          message: 'Certification "${cert.name}" is not in your Career DNA.',
          section: 'certifications',
        ));
      }
    }

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

    _checkMetric(content.summary, 'summary', issues);
    for (final ach in content.achievements) {
      _checkMetric(ach.text, 'achievements', issues);
    }

    return CvValidationResult(valid: issues.isEmpty, issues: issues);
  }

  static void _checkMetric(String text, String section, List<CvValidationIssue> issues) {
    if (text.isEmpty) return;
    if (_metricUnit.hasMatch(text) || _metricPhrase.hasMatch(text)) {
      issues.add(CvValidationIssue(
        code: 'unsupported_metric',
        message: 'Generated text contains a metric or scale claim that is not in your Career DNA.',
        section: section,
      ));
    }
  }
}
