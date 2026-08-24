import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/data_sources/auth_remote_data_source.dart';
import '../../../../data/data_sources/career_local_data_source.dart';
import '../../../../data/data_sources/career_remote_data_source.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../data/repositories/career_dna_repository_impl.dart';
import '../../../../data/repositories/career_repository_impl.dart';
import '../../../../domain/entities/interview_practice_session.dart';
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../domain/repositories/career_target_repository.dart';
import '../../../../domain/repositories/interview_practice_repository.dart';
import '../../../../domain/repositories/job_analysis_repository.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'interview_practice_cubit.dart';

/// Interview Practice Coach (Phase 5).
///
/// Runs a short, role-specific mock interview derived from the candidate's
/// Interview Readiness plan. Every score is computed deterministically on the
/// device; AI contributes coaching only. Sessions are persisted additively.
class InterviewPracticeScreen extends StatelessWidget {
  const InterviewPracticeScreen({
    super.key,
    this.extra,
    this.dnaRepository,
    this.targetRepository,
    this.analysisRepository,
    this.practiceRepository,
    this.userId,
  });

  /// Expected shape: {'role': String, 'company': String, 'applicationId': String?}
  final Map<String, dynamic>? extra;

  final CareerDnaRepository? dnaRepository;
  final CareerTargetRepository? targetRepository;
  final JobAnalysisRepository? analysisRepository;
  final InterviewPracticeRepository? practiceRepository;

  /// Overrides the resolved auth user id (used for persistence + tests).
  final String? userId;

  static String _resolveUserId() {
    try {
      return AuthRepositoryImpl(AuthRemoteDataSource()).currentUser?.id ??
          'local';
    } on Object {
      return 'local';
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = '${extra?['role'] ?? ''}';
    final company = '${extra?['company'] ?? ''}';
    final applicationId = extra?['applicationId'] as String?;
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final local = CareerLocalDataSource(snap.data!);
        final remote = CareerRemoteDataSource();
        return BlocProvider<InterviewPracticeCubit>(
          create: (_) => InterviewPracticeCubit(
            dnaRepository:
                dnaRepository ?? CareerDnaRepositoryImpl(remote: remote, local: local),
            targetRepository:
                targetRepository ?? CareerTargetRepositoryImpl(remote, local),
            analysisRepository:
                analysisRepository ?? JobAnalysisRepositoryImpl(remote, local),
            practiceRepository:
                practiceRepository ?? InterviewPracticeRepositoryImpl(remote, local),
            userId: userId ?? _resolveUserId(),
            role: role,
            company: company,
            applicationId: applicationId,
            language:
                WidgetsBinding.instance.platformDispatcher.locale.languageCode,
          ),
          child: _InterviewPracticeView(role: role, company: company),
        );
      },
    );
  }
}

class _InterviewPracticeView extends StatefulWidget {
  const _InterviewPracticeView({required this.role, required this.company});

  final String role;
  final String company;

  @override
  State<_InterviewPracticeView> createState() => _InterviewPracticeViewState();
}

class _InterviewPracticeViewState extends State<_InterviewPracticeView> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InterviewPracticeCubit>().start();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(l10n.practiceTitle, style: AppTextStyles.cardTitle),
      ),
      body: SafeArea(
        child: BlocBuilder<InterviewPracticeCubit, InterviewPracticeState>(
        builder: (context, state) {
          if (state.status == InterviewPracticeStatus.loading ||
              state.status == InterviewPracticeStatus.initial) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.teal),
                  const SizedBox(height: 14),
                  Text(l10n.practiceDesc, style: AppTextStyles.bodyMuted),
                ],
              ),
            );
          }
          if (state.status == InterviewPracticeStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.practiceError,
                  style: AppTextStyles.bodySub,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state.status == InterviewPracticeStatus.completed &&
              state.session != null) {
            return _SummaryView(session: state.session!);
          }
          if (state.status == InterviewPracticeStatus.feedback &&
              state.lastTurn != null) {
            return _FeedbackView(turn: state.lastTurn!);
          }
          final question = state.currentQuestion;
          if (question == null) {
            return Center(
              child: Text(l10n.practiceEmpty, style: AppTextStyles.bodySub),
            );
          }
          return _AnswerView(
            controller: _answerController,
            question: question.questionText,
            focusArea: question.requirement,
            index: state.index,
            total: state.queue.length,
            submitting: state.status == InterviewPracticeStatus.submitting,
            onSubmitted: (text) {
              _answerController.clear();
              context.read<InterviewPracticeCubit>().submitAnswer(text);
            },
          );
        },
      ),
      ),
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({
    required this.controller,
    required this.question,
    required this.focusArea,
    required this.index,
    required this.total,
    required this.submitting,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String question;
  final String focusArea;
  final int index;
  final int total;
  final bool submitting;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          l10n.practiceProgress(index + 1, total),
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 8),
        if (focusArea.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.tealBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              focusArea,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.teal),
            ),
          ),
        const SizedBox(height: 14),
        Text(question, style: AppTextStyles.cardTitle),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          minLines: 6,
          maxLines: 12,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: l10n.practiceAnswerHint,
            hintStyle: AppTextStyles.bodyMuted,
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: submitting
                ? null
                : () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    onSubmitted(text);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.background,
            ),
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(l10n.practiceSubmit),
          ),
        ),
      ],
    );
  }
}

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.turn});

  final InterviewPracticeTurn turn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _verdictColor(turn.verdict);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _ScoreRing(score: turn.compositeScore, color: color),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _verdictLabel(l10n, turn.verdict),
            style: AppTextStyles.cardTitle.copyWith(color: color),
          ),
        ),
        const SizedBox(height: 16),
        _ScoreBar(
          label: l10n.practiceRelevance,
          value: turn.relevanceScore,
          color: AppColors.teal,
        ),
        _ScoreBar(
          label: l10n.practiceSpecificity,
          value: turn.specificityScore,
          color: AppColors.purple,
        ),
        _ScoreBar(
          label: l10n.practiceStructure,
          value: turn.structureScore,
          color: AppColors.amber,
        ),
        _ScoreBar(
          label: l10n.practiceConsistency,
          value: turn.profileConsistencyScore,
          color: AppColors.green,
        ),
        const SizedBox(height: 16),
        _BulletList(title: l10n.practiceStrengths, items: turn.feedbackStrengths, color: AppColors.green),
        if (turn.feedbackImprove.isNotEmpty)
          _BulletList(
            title: l10n.practiceImprove,
            items: turn.feedbackImprove,
            color: AppColors.amber,
          ),
        if (turn.unverifiedClaims.isNotEmpty)
          _UnverifiedNote(claims: turn.unverifiedClaims),
        if (turn.coachingSketch.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.practiceCoaching, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardHi.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(turn.coachingSketch, style: AppTextStyles.bodySub),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => context.read<InterviewPracticeCubit>().next(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.background,
            ),
            child: Text(
              context.read<InterviewPracticeCubit>().state.isLastQuestion
                  ? l10n.practiceFinish
                  : l10n.practiceNext,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.session});

  final InterviewPracticeSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _verdictColor(
      session.overallScore >= 75
          ? PracticeVerdict.strong
          : session.overallScore >= 50
              ? PracticeVerdict.good
              : PracticeVerdict.needsImprovement,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: Text(l10n.practiceSummaryTitle, style: AppTextStyles.screenTitle),
        ),
        const SizedBox(height: 16),
        _ScoreRing(score: session.overallScore, color: color),
        const SizedBox(height: 8),
        Center(
          child: Text(
            l10n.practiceSummaryScore(session.turns.length),
            style: AppTextStyles.bodySub,
          ),
        ),
        const SizedBox(height: 16),
        _ScoreBar(
          label: l10n.practiceRelevance,
          value: session.relevanceScore,
          color: AppColors.teal,
        ),
        _ScoreBar(
          label: l10n.practiceSpecificity,
          value: session.specificityScore,
          color: AppColors.purple,
        ),
        _ScoreBar(
          label: l10n.practiceStructure,
          value: session.structureScore,
          color: AppColors.amber,
        ),
        _ScoreBar(
          label: l10n.practiceConsistency,
          value: session.profileConsistencyScore,
          color: AppColors.green,
        ),
        const SizedBox(height: 18),
        if (session.recommendedNextArea != null &&
            session.recommendedNextArea!.isNotEmpty) ...[
          Text(l10n.practiceRecommended, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.purpleBdr),
            ),
            child: Text(
              session.recommendedNextArea!,
              style: AppTextStyles.bodySub,
            ),
          ),
          const SizedBox(height: 18),
        ],
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.read<InterviewPracticeCubit>().start(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.practiceAgain),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => context.pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.background,
            ),
            child: Text(l10n.practiceDone),
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              color: color,
              backgroundColor: AppColors.cardHi,
            ),
            Text('$score', style: AppTextStyles.metric.copyWith(fontSize: 32)),
          ],
        ),
      );
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text('$value', style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.cardHi,
            ),
          ],
        ),
      );
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      );
}

class _UnverifiedNote extends StatelessWidget {
  const _UnverifiedNote({required this.claims});

  final List<String> claims;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amberBdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(l10n.practiceUnverified, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            claims.take(5).join(', '),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

Color _verdictColor(PracticeVerdict verdict) => switch (verdict) {
      PracticeVerdict.strong => AppColors.green,
      PracticeVerdict.good => AppColors.teal,
      PracticeVerdict.needsImprovement => AppColors.amber,
    };

String _verdictLabel(AppLocalizations l10n, PracticeVerdict verdict) =>
    switch (verdict) {
      PracticeVerdict.strong => l10n.practiceStrong,
      PracticeVerdict.good => l10n.practiceGood,
      PracticeVerdict.needsImprovement => l10n.practiceNeedsImprovement,
    };
