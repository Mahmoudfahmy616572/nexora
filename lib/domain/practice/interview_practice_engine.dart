/// Pure-Dart, deterministic logic for the Interview Practice Coach.
///
/// Every numeric score is produced HERE. The AI (mock_feedback Edge Function)
/// is only ever asked for qualitative coaching; it never sets scores and never
/// invents user facts. See the Phase 5 specification for boundaries.
library;

import '../entities/interview_practice_session.dart';

/// A single question in the session queue.
class PracticeQuestion {
  const PracticeQuestion({
    required this.requirement,
    required this.questionText,
  });
  final String requirement;
  final String questionText;

  PracticeQuestion copyWith({String? requirement, String? questionText}) =>
      PracticeQuestion(
        requirement: requirement ?? this.requirement,
        questionText: questionText ?? this.questionText,
      );
}

/// Deterministic scoring result for one answer.
class PracticeAssessment {
  const PracticeAssessment({
    required this.relevanceScore,
    required this.specificityScore,
    required this.structureScore,
    required this.profileConsistencyScore,
    required this.compositeScore,
    required this.verdict,
    required this.strengths,
    required this.improve,
    required this.unverifiedClaims,
    this.coachingSketch = '',
  });

  final int relevanceScore;
  final int specificityScore;
  final int structureScore;
  final int profileConsistencyScore;
  final int compositeScore;
  final PracticeVerdict verdict;
  final List<String> strengths;
  final List<String> improve;

  /// Terms in the answer not found in the known profile — surfaced as
  /// "New / Unverified" so the user can verify them. Never a truth judgement.
  final List<String> unverifiedClaims;

  /// Optional AI-authored response pattern. Empty when AI is unavailable.
  final String coachingSketch;
}

class InterviewPracticeEngine {
  InterviewPracticeEngine._();

  // --- Scoring weights (single source of truth) ----------------------------
  static const double _wRelevance = 0.35;
  static const double _wSpecificity = 0.25;
  static const double _wStructure = 0.20;
  static const double _wConsistency = 0.20;

  static const int _verdictStrong = 75;
  static const int _verdictGood = 50;

  static const int _maxQuestions = 5;
  static const int _minQuestions = 3;

  /// Deterministic fallback coaching shown when AI is unavailable.
  static const String deterministicCoachingHint =
      'Use Situation → Action → Result: set the scene, say what YOU did, '
      'and close with a measurable outcome.';

  static List<String> _tokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9.+#/ ]"), ' ')
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList();

  /// Builds a capped, de-duplicated question queue.
  ///
  /// [primary] are the requirement-grounded questions (from the prep plan),
  /// [overflow] are extra likely-questions used only to reach the minimum.
  static List<PracticeQuestion> buildQueue(
    List<PracticeQuestion> primary, {
    List<String> overflow = const [],
    int maxQuestions = _maxQuestions,
    int minQuestions = _minQuestions,
  }) {
    final out = <PracticeQuestion>[];
    final seen = <String>{};
    void add(PracticeQuestion q) {
      final key = q.questionText.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      out.add(q);
    }

    for (final q in primary) {
      add(q);
    }
    for (final q in overflow) {
      if (out.length >= maxQuestions) break;
      add(PracticeQuestion(requirement: '', questionText: q));
    }
    while (out.length < minQuestions && overflow.isNotEmpty) {
      final q = overflow[out.length % overflow.length];
      add(PracticeQuestion(requirement: '', questionText: '$q (variation)'));
    }
    return out.take(maxQuestions).toList();
  }

  /// Deterministic question text for a focus area when no AI question exists.
  static PracticeQuestion questionForRequirement(String requirement) =>
      PracticeQuestion(
        requirement: requirement,
        questionText:
            'How would you handle "$requirement" in this role? Walk through a '
            'concrete example.',
      );

  /// Core deterministic assessment. [knownTerms] are the user's verified
  /// profile vocabulary (CareerDna skills, focus-area labels, etc.) used to
  /// flag unverified claims. [requiredConcepts] are the focus-area requirement
  /// terms used for relevance.
  static PracticeAssessment assess({
    required String answer,
    required String question,
    required String focusArea,
    List<String> requiredConcepts = const [],
    Set<String> knownTerms = const {},
  }) {
    final trimmed = answer.trim();
    final answerTokens = _tokens(trimmed);

    // 1) Relevance — coverage of required concepts by the answer.
    final conceptSource = [
      ...requiredConcepts,
      if (focusArea.isNotEmpty) focusArea,
    ];
    final conceptTokens = _tokens(conceptSource.join(' '))
        .where((t) => t.length > 2)
        .toSet();
    int relevance;
    if (trimmed.isEmpty) {
      relevance = 0;
    } else if (conceptTokens.isEmpty) {
      relevance = 100;
    } else {
      final covered =
          conceptTokens.where((c) => answerTokens.contains(c)).length;
      relevance = ((covered / conceptTokens.length) * 100).round().clamp(0, 100);
    }

    // 2) Specificity — presence of metrics / timeframes.
    final metricHits = _metricRegex.allMatches(trimmed).length;
    final specificity =
        metricHits == 0 ? 0 : (metricHits > 3 ? 100 : (metricHits * 33).clamp(0, 100));

    // 3) Structure — STAR cue categories present.
    int categories = 0;
    if (_situationRegex.hasMatch(trimmed)) {
      categories++;
    }
    if (_actionRegex.hasMatch(trimmed)) {
      categories++;
    }
    if (_resultRegex.hasMatch(trimmed)) {
      categories++;
    }
    final structure = ((categories / 3) * 100).round();

    // 4) Profile consistency — flag unverified claims, never judge truth.
    final unverified = _unverifiedClaims(trimmed, knownTerms);
    final consistency = (100 - (unverified.length * 20).clamp(0, 100)).clamp(0, 100);

    final composite = (_clamp01(relevance) * _wRelevance +
            _clamp01(specificity) * _wSpecificity +
            _clamp01(structure) * _wStructure +
            _clamp01(consistency) * _wConsistency) *
        100;

    final verdict = composite >= _verdictStrong
        ? PracticeVerdict.strong
        : composite >= _verdictGood
            ? PracticeVerdict.good
            : PracticeVerdict.needsImprovement;

    final strengths = <String>[];
    final improve = <String>[];
    if (relevance >= 70) {
      strengths.add('You addressed the question directly.');
    } else {
      improve.add('Tie your answer more closely to the question and focus area.');
    }
    if (specificity >= 60) {
      strengths.add('You included concrete details or measurable results.');
    } else {
      improve.add('Add a concrete example, metric, or timeframe.');
    }
    if (structure >= 60) {
      strengths.add('Your answer was clearly structured.');
    } else {
      improve.add('Use Situation → Action → Result to organize the answer.');
    }
    if (unverified.isNotEmpty) {
      improve.add(
        'Some claims are new or unverified (${unverified.take(3).join(', ')}). '
        'Confirm they match your profile, or update Career DNA — do not present '
        'unverified details as facts.',
      );
    }

    return PracticeAssessment(
      relevanceScore: relevance,
      specificityScore: specificity,
      structureScore: structure,
      profileConsistencyScore: consistency,
      compositeScore: composite.round(),
      verdict: verdict,
      strengths: strengths,
      improve: improve,
      unverifiedClaims: unverified,
    );
  }

  /// Aggregates a completed session into summary scores + next recommendation.
  static InterviewPracticeSession summarize(InterviewPracticeSession session) {
    final turns = session.turns;
    if (turns.isEmpty) return session;
    int rel = 0, spec = 0, struct = 0, cons = 0, comp = 0;
    final areaScores = <String, List<int>>{};
    for (final t in turns) {
      rel += t.relevanceScore;
      spec += t.specificityScore;
      struct += t.structureScore;
      cons += t.profileConsistencyScore;
      comp += t.compositeScore;
      if (t.focusArea.isNotEmpty) {
        areaScores.putIfAbsent(t.focusArea, () => []).add(t.compositeScore);
      }
    }
    final n = turns.length;
    String? weakest;
    var weakestAvg = 101.0;
    areaScores.forEach((area, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < weakestAvg) {
        weakestAvg = avg;
        weakest = area;
      }
    });
    final overall = (comp / n).round();
    return session.copyWith(
      status: PracticeStatus.completed,
      completedAt: DateTime.now(),
      answeredCount: n,
      completedCount: n,
      relevanceScore: (rel / n).round(),
      specificityScore: (spec / n).round(),
      structureScore: (struct / n).round(),
      profileConsistencyScore: (cons / n).round(),
      overallScore: overall,
      recommendedNextArea: weakest,
    );
  }

  /// Recommends the next drill, weakest area first.
  static List<PracticeQuestion> recommendNext({
    required List<String> focusAreas,
    required InterviewPracticeSession lastSession,
  }) {
    final weakest = lastSession.recommendedNextArea;
    final ordered = [...focusAreas];
    if (weakest != null && ordered.contains(weakest)) {
      ordered.remove(weakest);
      ordered.insert(0, weakest);
    }
    return [
      for (final f in ordered) questionForRequirement(f),
    ];
  }

  // --- internals ------------------------------------------------------------

  static double _clamp01(num v) => (v.clamp(0, 100) / 100);

  static final RegExp _metricRegex = RegExp(
    r'(\d+(\.\d+)?\s?%|\b\d+\s?(years?|months?|weeks?|days?|hours?)\b|'
    r'\b(increased|decreased|improved|reduced|grew|cut)\s+by\b|\$\s?\d)',
    caseSensitive: false,
  );

  static final RegExp _situationRegex = RegExp(
    r'\b(when|while|during|at|on the|my last|previously|in my role|as a)\b',
    caseSensitive: false,
  );
  static final RegExp _actionRegex = RegExp(
    r'\b(i (led|built|developed|created|designed|implemented|drove|shipped|launched|owned|migrated|optimized))\b',
    caseSensitive: false,
  );
  static final RegExp _resultRegex = RegExp(
    r'\b(resulted|which (improved|increased|reduced|saved|boosted)|'
    r'(improved|increased|reduced|saved|boosted|achieved|delivered) (by|to|from))\b',
    caseSensitive: false,
  );

  static final Set<String> _stopWords = {
    'the', 'this', 'that', 'they', 'them', 'then', 'there', 'these', 'those',
    'when', 'while', 'during', 'after', 'before', 'because', 'but', 'and', 'or',
    'you', 'your', 'our', 'we', 'he', 'she', 'it', 'my', 'me', 'i', 'so', 'if',
    'for', 'with', 'from', 'into', 'than', 'about', 'over', 'here', 'what',
    'have', 'has', 'had', 'were', 'was', 'are', 'did', 'does',
  };

  static List<String> _unverifiedClaims(String answer, Set<String> knownTerms) {
    if (knownTerms.isEmpty) return const [];
    final known = knownTerms.map((t) => t.toLowerCase()).toSet();
    final claims = <String>[];
    for (final raw in answer.split(RegExp(r"[\s,.;:!?()""'']+"))) {
      final token = raw.trim();
      if (token.length < 3) continue;
      final lower = token.toLowerCase();
      if (_stopWords.contains(lower)) continue;
      // Only consider "tech-like" tokens (capitalized or symbol-bearing).
      final techLike = RegExp(r'[A-Z]').hasMatch(token) ||
          RegExp(r'[.+#/]').hasMatch(token) ||
          RegExp(r'^\d').hasMatch(token);
      if (!techLike) continue;
      if (!known.contains(lower)) claims.add(token);
    }
    // De-duplicate preserving order.
    final seen = <String>{};
    final out = <String>[];
    for (final c in claims) {
      if (seen.add(c.toLowerCase())) out.add(c);
    }
    return out;
  }
}
