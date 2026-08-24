import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/action_center/action_center.dart';
import '../../../../l10n/app_localizations.dart';
import '../main_tab.dart';
import 'action_center_cubit.dart';
import 'action_center_state.dart';

/// Presentational card for the single primary action. Kept free of Bloc so it
/// can be unit-tested directly with a plain [ActionCenterState].
class ActionCenterCard extends StatelessWidget {
  const ActionCenterCard({
    required this.decision,
    required this.onAction,
    super.key,
  });
  final ActionCenterState decision;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = _resolve(l10n, decision);

    final chips = <Widget>[];
    final role = decision.metadata?['targetRole'] as String?;
    if (role != null && role.isNotEmpty) {
      chips.add(_chip(context, '${l10n.acTarget}: $role'));
    }
    final score = decision.metadata?['score'];
    if (score is int) {
      chips.add(_chip(context, '${l10n.acScore}: $score'));
    }
    final pending = decision.metadata?['pendingCount'];
    if (pending is int && pending > 0) {
      chips.add(_chip(context, l10n.acPending(pending)));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(copy.icon, color: AppColors.brand, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.acLabel,
                  style: AppTextStyles.sectionEyebrow,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            copy.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              fontFamily: AppTextStyles.displayFont,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            copy.description,
            style: AppTextStyles.bodySub.copyWith(height: 1.4),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('acPrimaryCta'),
            onPressed: onAction,
            icon: Icon(copy.icon),
            label: Text(copy.cta),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.tealBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
      );
}

/// Bloc-driven hero that loads the canonical state and shows the next action.
class ActionCenterHero extends StatelessWidget {
  const ActionCenterHero({required this.onOpenTab, super.key});
  final ValueChanged<MainTab> onOpenTab;

  void _handleAction(BuildContext context, ActionCenterState d) {
    switch (d.actionType) {
      case ActionType.completeDna:
        GoRouter.of(context).push(Routes.dna);
      case ActionType.defineTarget:
        GoRouter.of(context).push('/targets');
      case ActionType.analyzeOpportunity:
        onOpenTab(MainTab.analyze);
      case ActionType.createCv:
        onOpenTab(MainTab.studio);
      case ActionType.evaluateCv:
      case ActionType.improveCv:
        if (d.documentId != null) {
          GoRouter.of(context).push('/cv/${d.documentId}/evaluate');
        }
      case ActionType.trackApplications:
        onOpenTab(MainTab.track);
      case ActionType.prepareInterview:
        final role = d.metadata?['targetRole'] as String? ?? '';
        final company = d.metadata?['company'] as String? ?? '';
        final applicationId = d.metadata?['applicationId'] as String?;
        GoRouter.of(context).push(
          Routes.interviewPrep,
          extra: {
            'role': role,
            'company': company,
            'applicationId': applicationId,
          },
        );
      case ActionType.practiceInterview:
        final role = d.metadata?['targetRole'] as String? ?? '';
        final company = d.metadata?['company'] as String? ?? '';
        final applicationId = d.metadata?['applicationId'] as String?;
        GoRouter.of(context).push(
          Routes.interviewPractice,
          extra: {
            'role': role,
            'company': company,
            'applicationId': applicationId,
          },
        );
      case ActionType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ActionCenterCubit, ActionCenterCubitState>(
      builder: (context, state) {
        if (state.status == ActionCenterStatus.loading ||
            state.decision == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.acLoading, style: AppTextStyles.bodySub),
                ),
              ],
            ),
          );
        }
        return ActionCenterCard(
          decision: state.decision!,
          onAction: () => _handleAction(context, state.decision!),
        );
      },
    );
  }
}

class _Copy {
  const _Copy(this.title, this.description, this.cta, this.icon);
  final String title;
  final String description;
  final String cta;
  final IconData icon;
}

/// Resolves localized copy for an action type from metadata.
_Copy _resolve(AppLocalizations l10n, ActionCenterState d) {
  final role = d.metadata?['targetRole'] as String? ?? '';
  switch (d.actionType) {
    case ActionType.completeDna:
      return _Copy(l10n.acTitleCompleteDna, l10n.acDescCompleteDna,
          l10n.acCtaCompleteDna, Icons.account_circle);
    case ActionType.defineTarget:
      return _Copy(l10n.acTitleDefineTarget, l10n.acDescDefineTarget,
          l10n.acCtaDefineTarget, Icons.flag);
    case ActionType.analyzeOpportunity:
      return _Copy(
        l10n.acTitleAnalyzeOpportunity,
        l10n.acDescAnalyzeOpportunity,
        l10n.acCtaAnalyzeOpportunity,
        Icons.track_changes,
      );
    case ActionType.createCv:
      return _Copy(
        l10n.acTitleCreateCv(role),
        l10n.acDescCreateCv(role),
        l10n.acCtaCreateCv,
        Icons.description,
      );
    case ActionType.evaluateCv:
      return _Copy(l10n.acTitleEvaluateCv, l10n.acDescEvaluateCv,
          l10n.acCtaEvaluateCv, Icons.analytics);
    case ActionType.improveCv:
      return _Copy(l10n.acTitleImproveCv, l10n.acDescImproveCv,
          l10n.acCtaImproveCv, Icons.auto_fix_high);
    case ActionType.trackApplications:
      return _Copy(
        l10n.acTitleTrackApplications,
        l10n.acDescTrackApplications,
        l10n.acCtaTrackApplications,
        Icons.send,
      );
    case ActionType.prepareInterview:
      return _Copy(
        l10n.acTitlePrepareInterview,
        l10n.acDescPrepareInterview,
        l10n.acCtaPrepareInterview,
        Icons.record_voice_over,
      );
    case ActionType.practiceInterview:
      return _Copy(
        l10n.acTitlePracticeInterview,
        l10n.acDescPracticeInterview,
        l10n.acCtaPracticeInterview,
        Icons.record_voice_over,
      );
    case ActionType.none:
      return _Copy(l10n.acTitleCompleteDna, l10n.acDescCompleteDna,
          l10n.acCtaCompleteDna, Icons.account_circle);
  }
}
