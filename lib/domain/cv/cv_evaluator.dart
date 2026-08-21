import '../entities/career_target.dart';
import '../entities/cv_content.dart';
import '../entities/cv_evaluation.dart';
import '../entities/job_analysis.dart';
import '../entities/opportunity_analysis.dart';

/// The result of a deterministic evaluation pass.
class CvEvaluationResult {
  const CvEvaluationResult(this.evaluation, this.suggestions);

  final CvEvaluation evaluation;
  final List<CvSuggestion> suggestions;
}

/// Deterministic, reproducible CV evaluation.
///
/// Every numeric score is a pure function of the CV content and (optional)
/// target/opportunity context. The AI layer may later enrich the qualitative
/// [CvEvaluation.explanations] and propose [CvSuggestion]s, but it can NEVER
/// change the numeric scores — those are always produced here.
class CvEvaluator {
  CvEvaluator._();

  static String _norm(String s) => s.toLowerCase().trim();

  static String _allText(CvContent c) => [
        c.header.name,
        c.header.title,
        c.header.subtitle,
        c.header.email,
        c.header.phone,
        c.header.location,
        c.summary,
        for (final e in c.experience) '${e.role} ${e.company} ${e.description}',
        for (final p in c.projects) '${p.name} ${p.description} ${p.tech.join(' ')}',
        for (final e in c.education) '${e.degree} ${e.field} ${e.institution}',
        for (final g in c.skillGroups) '${g.title} ${g.skills.join(' ')}',
        for (final cert in c.certifications) cert.name,
        for (final a in c.achievements) a.text,
        for (final l in c.languages) l.name,
      ].join(' \n ');

  static int _clamp(num v) =>
      (v < 0 ? 0 : (v > 100 ? 100 : v)).round();

  static int _sectionCompleteness(CvContent c) {
    int s = 0;
    final hasName = c.header.name.isNotEmpty;
    final hasEmail = c.header.email.isNotEmpty;
    if (hasName && hasEmail) {
      s += 20;
    } else if (hasName || hasEmail) {
      s += 10;
    }
    if (c.summary.trim().length >= 40) {
      s += 20;
    } else if (c.summary.trim().isNotEmpty) {
      s += 10;
    }
    if (c.experience.isNotEmpty || c.projects.isNotEmpty) s += 25;
    if (c.education.isNotEmpty) s += 15;
    if (c.skillGroups.isNotEmpty) s += 15;
    if (c.certifications.isNotEmpty ||
        c.achievements.isNotEmpty ||
        c.languages.isNotEmpty) {
      s += 5;
    }
    return s;
  }

  static int _structure(CvContent c) {
    int s = 0;
    if (c.summary.trim().length >= 40) s += 20;
    if (c.experience.isNotEmpty || c.projects.isNotEmpty) s += 25;
    if (c.education.isNotEmpty) s += 15;
    if (c.skillGroups.isNotEmpty) s += 20;
    final described = [
      ...c.experience.map((e) => e.description.trim().isNotEmpty),
      ...c.projects.map((p) => p.description.trim().isNotEmpty),
    ];
    if (described.isNotEmpty) {
      final ratio = described.where((b) => b).length / described.length;
      s += (ratio * 20).round();
    }
    return s;
  }

  static int _contentStrength(CvContent c) {
    final itemCount = c.experience.length +
        c.projects.length +
        c.education.length +
        c.skillGroups.fold(0, (sum, g) => sum + g.skills.length) +
        c.certifications.length +
        c.achievements.length;
    final describedCount = c.experience
            .where((e) => e.description.trim().isNotEmpty)
            .length +
        c.projects.where((p) => p.description.trim().isNotEmpty).length;
    return _clamp(itemCount * 4 + describedCount * 6);
  }

  static int _evidenceStrength(CvContent c) {
    final descriptions = <String>[
      for (final e in c.experience) e.description,
      for (final p in c.projects) p.description,
    ];
    if (descriptions.isEmpty) return 0;
    final described =
        descriptions.where((d) => d.trim().isNotEmpty).length;
    final withMetric = descriptions.where(_hasMetric).length;
    final ratio = (described / descriptions.length * 70) +
        (withMetric / descriptions.length * 30);
    return _clamp(ratio.round());
  }

  static bool _hasMetric(String s) {
    // Any digit / percentage / measurement token counts as an evidence signal.
    return RegExp(r'\d').hasMatch(s) ||
        RegExp(r'%|\$|k\b|users?|downloads?|requests?/s|ms\b').hasMatch(s.toLowerCase());
  }

  static int _readability(CvContent c) {
    final texts = [
      c.summary,
      for (final e in c.experience) e.description,
      for (final p in c.projects) p.description,
    ].where((t) => t.trim().isNotEmpty).toList();
    if (texts.isEmpty) return 0;
    int penalties = 0;
    for (final t in texts) {
      final sentences = t.split(RegExp(r'[.!?\n]'));
      for (final s in sentences) {
        final words = s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        if (words.length > 28) {
          penalties += 6; // run-on sentence
        } else if (words.length >= 12) {
          penalties += 2;
        }
      }
    }
    final textsWithDesc = texts.where((t) => t.trim().length >= 20).length;
    final base = (textsWithDesc / texts.length * 70).round();
    return _clamp(base + 30 - penalties);
  }

  static int _clarity(CvContent c) {
    final texts = [
      c.summary,
      for (final e in c.experience) e.description,
      for (final p in c.projects) p.description,
    ].join(' ');
    if (texts.trim().isEmpty) return 0;
    final vague = RegExp(r'\b(etc|various|some|things|stuff|several|many|'
        r'a number of|and more|et cetera)\b', caseSensitive: false);
    final matches = vague.allMatches(texts).length;
    final words = texts.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words == 0) return 0;
    final ratio = matches / words;
    return _clamp((100 - ratio * 400).round());
  }

  static int _ats(CvContent c) {
    int s = 0;
    if (c.header.name.isNotEmpty) s += 15;
    if (c.header.email.isNotEmpty) s += 10;
    if (c.header.phone.isNotEmpty) s += 5;
    if (c.summary.trim().isNotEmpty) s += 15;
    if (c.experience.isNotEmpty || c.projects.isNotEmpty) s += 15;
    if (c.education.isNotEmpty) s += 15;
    if (c.skillGroups.isNotEmpty) s += 15;
    final text = _allText(c);
    if (!RegExp(r'[\u0000-\u001F]').hasMatch(text)) s += 10; // no control chars
    return s;
  }

  static int _keywordAlignment(CvContent c, List<String> keywords) {
    if (keywords.isEmpty) return 100; // neutral when no target keywords
    final text = _norm(_allText(c));
    final matched =
        keywords.where((k) => k.isNotEmpty && text.contains(_norm(k))).length;
    return _clamp(((matched / keywords.length) * 100).round());
  }

  static int _skillAlignment(CvContent c, List<String> targetSkills) {
    if (targetSkills.isEmpty) return 100;
    final text = _norm(_allText(c));
    final matched = targetSkills
        .where((s) => s.isNotEmpty && text.contains(_norm(s)))
        .length;
    return _clamp(((matched / targetSkills.length) * 100).round());
  }

  static int _targetAlignment(
    CvContent content,
    List<String> keywords,
    List<String> targetSkills,
    OpportunityAnalysis? opportunity,
  ) {
    if (opportunity == null && keywords.isEmpty && targetSkills.isEmpty) {
      return 100; // neutral: general evaluation
    }
    final kw = _keywordAlignment(content, keywords);
    final sk = _skillAlignment(content, targetSkills);
    double coverage = 1.0;
    if (opportunity != null && opportunity.requirements.isNotEmpty) {
      final covered = opportunity.requirements
          .where((r) =>
              r.status == RequirementStatus.strongMatch ||
              r.status == RequirementStatus.partialMatch)
          .length;
      coverage = covered / opportunity.requirements.length;
    }
    return _clamp(((kw * 0.4 + sk * 0.4 + coverage * 20)).round());
  }

  static List<String> _contextKeywords(
    JobAnalysis? analysis,
    OpportunityAnalysis? opportunity,
  ) {
    final keywords = <String>[];
    if (analysis != null) {
      keywords.addAll(analysis.strong);
      keywords.addAll(analysis.missing);
    }
    if (opportunity != null) {
      keywords.addAll(opportunity.keywords);
      keywords.addAll(opportunity.technologies);
      for (final r in opportunity.requirements) {
        keywords.add(r.label);
      }
    }
    return keywords.where((s) => s.trim().isNotEmpty).toList();
  }

  static List<String> _contextSkills(
    JobAnalysis? analysis,
    OpportunityAnalysis? opportunity,
  ) {
    final skills = <String>[];
    if (analysis != null) {
      skills.addAll(analysis.strong);
      skills.addAll(analysis.missing);
    }
    if (opportunity != null) {
      for (final r in opportunity.requirements) {
        skills.add(r.label);
      }
    }
    return skills.where((s) => s.trim().isNotEmpty).toList();
  }

  /// Evaluates [content] deterministically. Optional [target], [analysis], and
  /// [opportunity] provide target context; when absent, target-specific scores
  /// are neutral (100) so a general CV is not unfairly penalised.
  static CvEvaluationResult evaluate({
    required CvContent content,
    CareerTarget? target,
    JobAnalysis? analysis,
    OpportunityAnalysis? opportunity,
    String userId = '',
    String versionId = '',
    String targetId = '',
  }) {
    final keywords = _contextKeywords(analysis, opportunity);
    final skills = _contextSkills(analysis, opportunity);

    final sectionCompleteness = _sectionCompleteness(content);
    final structure = _structure(content);
    final contentStrength = _contentStrength(content);
    final evidenceStrength = _evidenceStrength(content);
    final readability = _readability(content);
    final clarity = _clarity(content);
    final ats = _ats(content);
    final keywordAlignment = _keywordAlignment(content, keywords);
    final skillAlignment = _skillAlignment(content, skills);
    final targetAlignment =
        _targetAlignment(content, keywords, skills, opportunity);

    const wSection = 0.15;
    const wStructure = 0.10;
    const wContent = 0.15;
    const wEvidence = 0.15;
    const wRead = 0.10;
    const wClarity = 0.10;
    const wAts = 0.10;
    const wKw = 0.05;
    const wSkill = 0.05;
    const wTarget = 0.05;
    final overall = _clamp((
        sectionCompleteness * wSection +
        structure * wStructure +
        contentStrength * wContent +
        evidenceStrength * wEvidence +
        readability * wRead +
        clarity * wClarity +
        ats * wAts +
        keywordAlignment * wKw +
        skillAlignment * wSkill +
        targetAlignment * wTarget)
        .round());

    final explanations = <String, String>{
      'overall': overall >= 75
          ? 'Strong, well-rounded CV.'
          : overall >= 50
              ? 'Decent CV with clear areas to improve.'
              : 'Needs substantial work before it is competitive.',
      'sectionCompleteness': sectionCompleteness >= 80
          ? 'All key sections are present.'
          : 'Some key sections are missing or incomplete.',
      'structure': structure >= 70
          ? 'Clear, well-organised sections.'
          : 'Structure could be more consistent across sections.',
      'contentStrength': contentStrength >= 60
          ? 'Good amount of concrete content.'
          : 'Content is thin — add more concrete detail.',
      'evidenceStrength': evidenceStrength >= 60
          ? 'Experience is backed by concrete detail.'
          : 'Add measurable outcomes and specifics to strengthen evidence.',
      'readability': readability >= 70
          ? 'Easy to read with concise phrasing.'
          : 'Some sentences are long or hard to scan.',
      'clarity': clarity >= 70
          ? 'Clear, specific language.'
          : 'Reduce vague wording for sharper clarity.',
      'ats': ats >= 80
          ? 'ATS-friendly formatting and contact details.'
          : 'Improve ATS compatibility (contact info, standard sections).',
      'keywordAlignment': keywordAlignment >= 80
          ? 'Good keyword coverage for the target.'
          : keywords.isEmpty
              ? 'No target keywords provided for comparison.'
              : 'Mirror more of the target keywords in your CV.',
      'skillAlignment': skillAlignment >= 80
          ? 'Your skills align well with the target.'
          : skills.isEmpty
              ? 'No target skills provided for comparison.'
              : 'Surface more of the target skills you actually have.',
      'targetAlignment': targetAlignment >= 80
          ? 'Closely aligned with the target role.'
          : (opportunity == null && keywords.isEmpty && skills.isEmpty)
              ? 'General evaluation — add a target for role-specific scoring.'
              : 'Close the gaps between your CV and the target role.',
    };

    return CvEvaluationResult(
      CvEvaluation(
        id: CareerTarget.newId(),
        userId: userId,
        versionId: versionId,
        targetId: targetId,
        overall: overall,
        ats: ats,
        targetAlignment: targetAlignment,
        contentStrength: contentStrength,
        evidenceStrength: evidenceStrength,
        readability: readability,
        clarity: clarity,
        structure: structure,
        keywordAlignment: keywordAlignment,
        skillAlignment: skillAlignment,
        sectionCompleteness: sectionCompleteness,
        explanations: explanations,
        deterministicOnly: false,
        createdAt: DateTime.now(),
      ),
      _deterministicSuggestions(content, userId, versionId, opportunity),
    );
  }

  /// Safe, fallback suggestions derived from the deterministic checks.
  ///
  /// Only rephrases EXISTING non-empty content (never invents new facts). When
  /// the AI explanation step is available, these are replaced by richer AI
  /// suggestions.
  static List<CvSuggestion> _deterministicSuggestions(
    CvContent content,
    String userId,
    String versionId,
    OpportunityAnalysis? opportunity,
  ) {
    final out = <CvSuggestion>[];
    void add(String section, String current, String suggested, String problem,
        String why, String req) {
      out.add(CvSuggestion(
        id: CareerTarget.newId(),
        userId: userId,
        evaluationId: '',
        versionId: versionId,
        section: section,
        problem: problem,
        current: current,
        suggested: suggested,
        why: why,
        targetRequirement: req,
        createdAt: DateTime.now(),
      ));
    }

    if (content.summary.trim().isNotEmpty &&
        content.summary.trim().length < 40) {
      add(
        'summary',
        content.summary.trim(),
        '${content.summary.trim()} Focus on measurable outcomes and the value you delivered.',
        'The professional summary is too brief to differentiate you.',
        'A 2–3 sentence summary helps recruiters grasp your value quickly.',
        '',
      );
    }
    for (final e in content.experience) {
      if (e.description.trim().isNotEmpty && e.description.trim().length < 25) {
        add(
          'experience',
          e.description.trim(),
          '${e.description.trim()} Describe a concrete responsibility or outcome.',
          'An experience bullet is too short to show impact.',
          'Longer, specific bullets demonstrate real contribution.',
          '',
        );
      }
    }
    for (final p in content.projects) {
      if (p.description.trim().isNotEmpty && p.description.trim().length < 25) {
        add(
          'projects',
          p.description.trim(),
          '${p.description.trim()} Note the problem solved and your specific role.',
          'A project description is too short to show impact.',
          'Specific project context helps reviewers assess fit.',
          '',
        );
      }
    }
    return out;
  }

  /// Applies an accepted/edited suggestion to [content] by replacing the exact
  /// [CvSuggestion.current] text within its [CvSuggestion.section].
  ///
  /// Factuality guard: if [CvSuggestion.current] is empty or not actually
  /// present in the content, the content is returned unchanged (no-op). This
  /// prevents any invented or injected text from entering the CV.
  static CvContent applySuggestion(CvContent content, CvSuggestion s) {
    final replacement = (s.editedText?.isNotEmpty == true ? s.editedText! : s.suggested);
    if (s.current.isEmpty || replacement.isEmpty) return content;
    final current = s.current;

    switch (s.section) {
      case 'summary':
        if (content.summary.contains(current)) {
          return content.copyWith(
              summary: content.summary.replaceFirst(current, replacement));
        }
      case 'experience':
        final items = content.experience.map((e) {
          if (e.description.contains(current)) {
            return e.copyWith(description: e.description.replaceFirst(current, replacement));
          }
          return e;
        }).toList();
        return content.copyWith(experience: items);
      case 'projects':
        final items = content.projects.map((p) {
          if (p.description.contains(current)) {
            return p.copyWith(description: p.description.replaceFirst(current, replacement));
          }
          return p;
        }).toList();
        return content.copyWith(projects: items);
      case 'education':
        final items = content.education.map((e) {
          if (e.degree.contains(current)) {
            return e.copyWith(degree: e.degree.replaceFirst(current, replacement));
          }
          if (e.field.contains(current)) {
            return e.copyWith(field: e.field.replaceFirst(current, replacement));
          }
          return e;
        }).toList();
        return content.copyWith(education: items);
      case 'skills':
        final groups = content.skillGroups.map((g) {
          final skills = g.skills.map((sk) {
            return sk == current ? replacement : sk;
          }).toList();
          return g.copyWith(skills: skills);
        }).toList();
        return content.copyWith(skillGroups: groups);
      case 'certifications':
        final items = content.certifications.map((c) {
          if (c.name.contains(current)) {
            return c.copyWith(name: c.name.replaceFirst(current, replacement));
          }
          return c;
        }).toList();
        return content.copyWith(certifications: items);
      case 'achievements':
        final items = content.achievements.map((a) {
          if (a.text.contains(current)) {
            return a.copyWith(text: a.text.replaceFirst(current, replacement));
          }
          return a;
        }).toList();
        return content.copyWith(achievements: items);
      case 'languages':
        final items = content.languages.map((l) {
          if (l.name.contains(current)) {
            return l.copyWith(name: l.name.replaceFirst(current, replacement));
          }
          return l;
        }).toList();
        return content.copyWith(languages: items);
      case 'header':
        final h = content.header;
        if (h.name.contains(current)) {
          return content.copyWith(header: h.copyWith(name: h.name.replaceFirst(current, replacement)));
        }
        if (h.title.contains(current)) {
          return content.copyWith(header: h.copyWith(title: h.title.replaceFirst(current, replacement)));
        }
        if (h.subtitle.contains(current)) {
          return content.copyWith(header: h.copyWith(subtitle: h.subtitle.replaceFirst(current, replacement)));
        }
    }
    return content;
  }
}
