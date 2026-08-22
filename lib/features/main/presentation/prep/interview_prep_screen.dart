import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/data_sources/career_local_data_source.dart';
import '../../../../data/data_sources/career_remote_data_source.dart';
import '../../../../data/repositories/career_dna_repository_impl.dart';
import '../../../../data/repositories/career_repository_impl.dart';
import '../../../../domain/entities/interview_prep.dart';
import '../../../../domain/repositories/career_dna_repository.dart';
import '../../../../domain/repositories/career_target_repository.dart';
import '../../../../domain/repositories/job_analysis_repository.dart';
import '../../../../l10n/app_localizations.dart';
import 'interview_prep_cubit.dart';

/// Interview prep screen (Phase 4).
///
/// Shows a coaching plan focused on the gaps that matter for one role. The
/// plan is grounded in the stored opportunity analysis when one exists, and in
/// Career DNA skills otherwise. When AI is unavailable a deterministic,
/// explainable plan is shown instead — nothing is fabricated.
class InterviewPrepScreen extends StatelessWidget {
  const InterviewPrepScreen({
    super.key,
    this.extra,
    this.dnaRepository,
    this.targetRepository,
    this.analysisRepository,
  });

  /// Expected shape: {'role': String, 'company': String, 'applicationId': String?}
  final Map<String, dynamic>? extra;

  /// Optional repository overrides (tests inject fakes here).
  final CareerDnaRepository? dnaRepository;
  final CareerTargetRepository? targetRepository;
  final JobAnalysisRepository? analysisRepository;

  @override
  Widget build(BuildContext context) {
    final role = '${extra?['role'] ?? ''}';
    final company = '${extra?['company'] ?? ''}';
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
        return BlocProvider<InterviewPrepCubit>(
          create: (_) => InterviewPrepCubit(
            dnaRepository: dnaRepository ??
                CareerDnaRepositoryImpl(remote: remote, local: local),
            targetRepository:
                targetRepository ?? CareerTargetRepositoryImpl(remote, local),
            analysisRepository:
                analysisRepository ?? JobAnalysisRepositoryImpl(remote, local),
          ),
          child: _InterviewPrepView(role: role, company: company),
        );
      },
    );
  }
}

class _InterviewPrepView extends StatefulWidget {
  const _InterviewPrepView({required this.role, required this.company});

  final String role;
  final String company;

  @override
  State<_InterviewPrepView> createState() => _InterviewPrepViewState();
}

class _InterviewPrepViewState extends State<_InterviewPrepView> {
  @override
  void initState() {
    super.initState();
    // Safe in initState: does not depend on inherited widgets.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  void _prepare() {
    if (!mounted) return;
    context.read<InterviewPrepCubit>().prepare(
          role: widget.role,
          company: widget.company,
          language:
              WidgetsBinding.instance.platformDispatcher.locale.languageCode,
        );
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
        title: Text(l10n.prepTitle, style: AppTextStyles.cardTitle),
      ),
      body: BlocBuilder<InterviewPrepCubit, InterviewPrepState>(
        builder: (context, state) {
          if (state.status == InterviewPrepStatus.loading ||
              state.status == InterviewPrepStatus.initial ||
              state.plan == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.teal),
                  const SizedBox(height: 14),
                  Text(l10n.prepDesc, style: AppTextStyles.bodyMuted),
                ],
              ),
            );
          }
          final plan = state.plan!;
          final subtitle = [
            l10n.prepForRole(widget.role),
            if (widget.company.isNotEmpty) widget.company,
          ].join(' · ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(subtitle, style: AppTextStyles.bodySub),
              const SizedBox(height: 12),
              if (plan.deterministicOnly)
                _Banner(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.amber,
                  text: l10n.prepAiUnavailable,
                )
              else if (!state.analysisAvailable)
                _Banner(
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.teal,
                  text: l10n.prepNoAnalysis,
                ),
              const SizedBox(height: 16),
              if (plan.focusAreas.isEmpty)
                _Banner(
                  icon: Icons.hourglass_empty_rounded,
                  color: AppColors.purple,
                  text: l10n.prepEmptyNoInterview,
                )
              else ...[
                Text(l10n.prepFocusTitle, style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                for (final area in plan.focusAreas)
                  _FocusAreaCard(area: area),
              ],
              if (plan.likelyQuestions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(l10n.prepLikelyQuestions, style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                for (var i = 0; i < plan.likelyQuestions.length; i++)
                  _NumberedLine(index: i + 1, text: plan.likelyQuestions[i]),
              ],
              if (plan.tips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(l10n.prepTips, style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardHi.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(plan.tips, style: AppTextStyles.bodySub),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _prepare,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.prepRegenerate),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _FocusAreaCard extends StatelessWidget {
  const _FocusAreaCard({required this.area});

  final PrepFocusArea area;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  area.requirement,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (area.why.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${l10n.prepWhyLabel}: ${area.why}', style: AppTextStyles.bodySmall),
          ],
          if (area.question.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.prepQuestionLabel, style: AppTextStyles.bodyMuted.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(area.question, style: AppTextStyles.bodySmall),
          ],
          if (area.coaching.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.prepCoachingLabel, style: AppTextStyles.bodyMuted.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(area.coaching, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index.', style: AppTextStyles.mono),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
