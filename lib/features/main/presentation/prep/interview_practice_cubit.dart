import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/data_sources/career_local_data_source.dart';
import '../../../../domain/analysis/interview_prep_engine.dart';
import '../../../../domain/entities/career_target.dart';
import '../../../../domain/entities/interview_practice_session.dart';
import '../../../../domain/entities/job_analysis.dart';
import '../../../../domain/entities/opportunity_analysis.dart';
import '../../../../domain/practice/interview_practice_engine.dart';
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../domain/repositories/career_target_repository.dart';
import '../../../../domain/repositories/job_analysis_repository.dart';
import '../../../../domain/repositories/interview_practice_repository.dart';

enum InterviewPracticeStatus {
  initial,
  loading,
  ready,
  submitting,
  feedback,
  completed,
  error,
}

/// Presentation state for the Interview Practice Coach (Phase 5).
class InterviewPracticeState {
  const InterviewPracticeState({
    this.status = InterviewPracticeStatus.initial,
    this.queue = const [],
    this.index = 0,
    this.session,
    this.lastTurn,
    this.aiUnavailable = false,
    this.error,
  });

  final InterviewPracticeStatus status;
  final List<PracticeQuestion> queue;
  final int index;
  final InterviewPracticeSession? session;
  final InterviewPracticeTurn? lastTurn;
  final bool aiUnavailable;

  /// True once the AI has been confirmed unavailable at least once, so the UI
  /// can show the deterministic-coaching notice for the whole session.
  final String? error;

  bool get isLastQuestion => index >= queue.length - 1;

  PracticeQuestion? get currentQuestion =>
      index < queue.length ? queue[index] : null;

  InterviewPracticeState copyWith({
    InterviewPracticeStatus? status,
    List<PracticeQuestion>? queue,
    int? index,
    InterviewPracticeSession? session,
    InterviewPracticeTurn? lastTurn,
    bool? aiUnavailable,
    String? error,
  }) =>
      InterviewPracticeState(
        status: status ?? this.status,
        queue: queue ?? this.queue,
        index: index ?? this.index,
        session: session ?? this.session,
        lastTurn: lastTurn ?? this.lastTurn,
        aiUnavailable: aiUnavailable ?? this.aiUnavailable,
        error: error ?? this.error,
      );
}

class InterviewPracticeCubit extends Cubit<InterviewPracticeState> {
  InterviewPracticeCubit({
    required this.dnaRepository,
    required this.targetRepository,
    required this.analysisRepository,
    required this.practiceRepository,
    required this.userId,
    required this.role,
    required this.company,
    this.applicationId,
    required this.language,
    this.localDataSource,
  }) : super(const InterviewPracticeState());

  final CareerDnaRepository dnaRepository;
  final CareerTargetRepository targetRepository;
  final JobAnalysisRepository analysisRepository;
  final InterviewPracticeRepository practiceRepository;
  final String userId;
  final String role;
  final String company;
  final String? applicationId;
  final String language;
  final CareerLocalDataSource? localDataSource;

  // Captured at [start] and reused for scoring/AI calls.
  Set<String> _knownTerms = const {};
  Map<String, dynamic> _context = const {};
  String? _analysisId;

  /// Loads canonical data, builds the question queue, and creates the session.
  Future<void> start() async {
    emit(const InterviewPracticeState(status: InterviewPracticeStatus.loading));
    try {
      final dna = await _safe(() => dnaRepository.load(), null);
      final targets =
          await _safe(() => targetRepository.loadAll(), const <CareerTarget>[]);
      final analyses =
          await _safe(() => analysisRepository.load(), null) ??
              const <JobAnalysis>[];

      final target = _matchTarget(targets, role, company);
      OpportunityAnalysis? analysis;
      if (target != null) {
        for (final a in analyses) {
          if (a.targetId == target.id && a.detail != null) {
            analysis = a.detail;
            _analysisId = a.id;
            break;
          }
        }
      }

      final focusAreas = analysis != null
          ? InterviewPrepEngine.selectFocusAreas(analysis)
          : InterviewPrepEngine.focusFromSkills(dna?.skills ?? const []);

      _knownTerms = {
        ...?dna?.skills.map((s) => s.toLowerCase()),
        ...focusAreas.map((f) => f.toLowerCase()),
      };
      _context = dna?.toContext() ?? <String, dynamic>{};

      List<PracticeQuestion> questions = [];
      final overflow = <String>[];
      var aiUnavailable = false;
      try {
        final plan = await dnaRepository.generateInterviewPlan(
          context: _context,
          focusAreas: focusAreas,
          language: language,
          targetRole: role,
          company: company.isEmpty ? null : company,
        );
        questions = [
          for (final area in plan.focusAreas)
            PracticeQuestion(
              requirement: area.requirement,
              questionText: area.question.isNotEmpty
                  ? area.question
                  : InterviewPracticeEngine.questionForRequirement(
                      area.requirement,
                    ).questionText,
            ),
        ];
        overflow.addAll(plan.likelyQuestions);
      } on Object {
        aiUnavailable = true;
        questions = [
          for (final f in focusAreas)
            InterviewPracticeEngine.questionForRequirement(f),
        ];
      }

      final queue = InterviewPracticeEngine.buildQueue(
        questions,
        overflow: overflow,
      );

      final session = InterviewPracticeSession(
        id: _newId(),
        userId: userId,
        targetId: target?.id,
        applicationId: applicationId,
        analysisId: _analysisId,
        role: role,
        company: company.isEmpty ? null : company,
        startedAt: DateTime.now(),
        status: PracticeStatus.inProgress,
        focusAreas: focusAreas,
        questionCount: queue.length,
      );
      await _safe(() => practiceRepository.save(session), null);

      emit(InterviewPracticeState(
        status: InterviewPracticeStatus.ready,
        queue: queue,
        index: 0,
        session: session,
        aiUnavailable: aiUnavailable,
      ));
    } on Object catch (e) {
      emit(InterviewPracticeState(
        status: InterviewPracticeStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Scores the answer deterministically and (best-effort) fetches AI coaching.
  Future<void> submitAnswer(String answer) async {
    final session = state.session;
    final q = state.currentQuestion;
    if (session == null || q == null) return;
    emit(state.copyWith(status: InterviewPracticeStatus.submitting));

    try {
      final assessment = InterviewPracticeEngine.assess(
        answer: answer,
        question: q.questionText,
        focusArea: q.requirement,
        requiredConcepts: [q.requirement],
        knownTerms: _knownTerms,
      );

      var coaching = InterviewPracticeEngine.deterministicCoachingHint;
      var aiOk = true;
      try {
        final fb = await dnaRepository.generateMockFeedback(
          context: _context,
          question: q.questionText,
          answer: answer,
          focusArea: q.requirement,
          targetRole: role,
          company: company.isEmpty ? null : company,
          language: language,
        );
        final c = (fb['coaching'] as String?) ?? '';
        final s = (fb['sketch'] as String?) ?? '';
        final combined = [
          if (c.isNotEmpty) c,
          if (s.isNotEmpty) 'Example skeleton: $s',
        ].join('\n').trim();
        if (combined.isNotEmpty) coaching = combined;
      } on Object {
        aiOk = false;
      }

      final turn = InterviewPracticeTurn(
        id: _newId(),
        question: q.questionText,
        answer: answer,
        focusArea: q.requirement,
        relevanceScore: assessment.relevanceScore,
        specificityScore: assessment.specificityScore,
        structureScore: assessment.structureScore,
        profileConsistencyScore: assessment.profileConsistencyScore,
        compositeScore: assessment.compositeScore,
        verdict: assessment.verdict,
        feedbackStrengths: assessment.strengths,
        feedbackImprove: assessment.improve,
        coachingSketch: coaching,
        unverifiedClaims: assessment.unverifiedClaims,
        createdAt: DateTime.now(),
      );

      final updated = session.copyWith(
        turns: [...session.turns, turn],
        answeredCount: session.answeredCount + 1,
      );
      await _safe(() => practiceRepository.save(updated), null);

      emit(state.copyWith(
        status: InterviewPracticeStatus.feedback,
        session: updated,
        lastTurn: turn,
        aiUnavailable: state.aiUnavailable || !aiOk,
      ));
    } on Object catch (e) {
      emit(state.copyWith(
        status: InterviewPracticeStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Advances to the next question, or finalizes the session on the last one.
  Future<void> next() async {
    final session = state.session;
    if (session == null) return;
    final nextIndex = state.index + 1;
    if (nextIndex < state.queue.length) {
      emit(state.copyWith(
        status: InterviewPracticeStatus.ready,
        index: nextIndex,
        lastTurn: null,
      ));
    } else {
      await finish();
    }
  }

  Future<void> finish() async {
    final session = state.session;
    if (session == null) return;
    final completed = InterviewPracticeEngine.summarize(session);
    await _safe(() => practiceRepository.save(completed), null);

    // Log activity for the home screen recent activity feed.
    final companyPart = (completed.company ?? '').isNotEmpty
        ? ' · ${completed.company}'
        : '';
    final rolePart = (completed.role ?? '').isNotEmpty
        ? completed.role
        : role;
    final text = 'Interview practice · $rolePart$companyPart'
        ' · Score ${completed.overallScore}%';
    await localDataSource?.logActivity({
      'type': 'interview',
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    emit(state.copyWith(
      status: InterviewPracticeStatus.completed,
      session: completed,
    ));
  }

  /// Best-effort matching of a tracked target to this role/company.
  CareerTarget? _matchTarget(
    List<CareerTarget> targets,
    String role,
    String company,
  ) {
    if (targets.isEmpty || role.trim().isEmpty) return null;
    final r = role.toLowerCase();
    final c = company.toLowerCase();
    CareerTarget? byBoth;
    CareerTarget? byRole;
    for (final t in targets) {
      final tr = t.role.toLowerCase();
      final tc = (t.company ?? '').toLowerCase();
      final roleMatch = r.isNotEmpty && (tr.contains(r) || r.contains(tr));
      final companyMatch = c.isNotEmpty && tc.isNotEmpty && tc.contains(c);
      if (roleMatch && companyMatch) return t;
      byBoth ??= roleMatch && (t.company ?? '').isNotEmpty ? t : null;
      byRole ??= roleMatch ? t : null;
    }
    if (byBoth != null) return byBoth;
    if (byRole != null) return byRole;
    if (c.isNotEmpty) {
      for (final t in targets) {
        if ((t.company ?? '').toLowerCase().contains(c)) return t;
      }
    }
    return null;
  }

  Future<T> _safe<T>(Future<T> Function() run, T fallback) async {
    try {
      return await run();
    } on Object {
      return fallback;
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${(DateTime.now().millisecond)}';
}
