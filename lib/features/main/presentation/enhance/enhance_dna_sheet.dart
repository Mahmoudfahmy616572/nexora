import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'enhance_dna_cubit.dart';
import 'enhance_suggestion.dart';

/// Bottom sheet that shows AI enhancement suggestions for CareerDNA gaps.
/// Each suggestion shows before → after with accept/reject buttons.
Future<bool> showEnhanceDnaSheet(BuildContext context, EnhanceDnaCubit cubit) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _EnhanceDnaSheet(),
    ),
  );
  return result ?? false;
}

class _EnhanceDnaSheet extends StatefulWidget {
  const _EnhanceDnaSheet();

  @override
  State<_EnhanceDnaSheet> createState() => _EnhanceDnaSheetState();
}

class _EnhanceDnaSheetState extends State<_EnhanceDnaSheet> {
  @override
  void initState() {
    super.initState();
    context.read<EnhanceDnaCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocConsumer<EnhanceDnaCubit, EnhanceDnaState>(
          listener: (context, state) {
            if (state.status == EnhanceStatus.done) {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.enhanceApplied),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHandle(),
                  _buildHeader(state, l10n),
                  if (state.status == EnhanceStatus.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (state.status == EnhanceStatus.error)
                    Expanded(child: _buildError(state, l10n))
                  else ...[
                    _buildCountBar(state, l10n),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.suggestions.length,
                        itemBuilder: (context, i) => _SuggestionCard(
                          index: i,
                          suggestion: state.suggestions[i],
                          isAccepted: state.accepted.contains(i),
                          isRejected: state.rejected.contains(i),
                          onAccept: () => context.read<EnhanceDnaCubit>().accept(i),
                          onReject: () => context.read<EnhanceDnaCubit>().reject(i),
                        ),
                      ),
                    ),
                    _buildBottomBar(state, l10n),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildHeader(EnhanceDnaState state, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Row(
      children: [
        const Icon(Icons.auto_fix_high_rounded, size: 22, color: AppColors.brand),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.enhanceTitle,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
          ),
        ),
        if (state.status == EnhanceStatus.loaded)
          TextButton(
            onPressed: () => context.read<EnhanceDnaCubit>().acceptAll(),
            child: Text(l10n.enhanceAcceptAll),
          ),
      ],
    ),
  );

  Widget _buildCountBar(EnhanceDnaState state, AppLocalizations l10n) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(
          '${state.pendingCount} ${l10n.enhanceSuggestionsLeft}',
          style: AppTextStyles.bodySub.copyWith(fontSize: 13),
        ),
        const Spacer(),
        if (state.accepted.isNotEmpty)
          _MiniBadge(count: state.accepted.length, color: Colors.green, label: l10n.enhanceAccepted),
        if (state.rejected.isNotEmpty) ...[
          const SizedBox(width: 6),
          _MiniBadge(count: state.rejected.length, color: Colors.red.shade300, label: l10n.enhanceRejected),
        ],
      ],
    ),
  );

  Widget _buildError(EnhanceDnaState state, AppLocalizations l10n) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            state.message?.isNotEmpty == true ? state.message! : l10n.enhanceError,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<EnhanceDnaCubit>().load(),
            child: Text(l10n.enhanceRetry),
          ),
        ],
      ),
    ),
  );

  Widget _buildBottomBar(EnhanceDnaState state, AppLocalizations l10n) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: state.status == EnhanceStatus.applying || state.accepted.isEmpty
              ? null
              : () => context.read<EnhanceDnaCubit>().apply(),
          child: state.status == EnhanceStatus.applying
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.enhanceApply),
        ),
      ),
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.index,
    required this.suggestion,
    required this.isAccepted,
    required this.isRejected,
    required this.onAccept,
    required this.onReject,
  });

  final int index;
  final EnhanceSuggestion suggestion;
  final bool isAccepted;
  final bool isRejected;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  Color get _sectionColor {
    switch (suggestion.section) {
      case 'skills':
        return Colors.blue;
      case 'experience':
        return Colors.orange;
      case 'projects':
        return Colors.purple;
      case 'summary':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData get _sectionIcon {
    switch (suggestion.section) {
      case 'skills':
        return Icons.build_rounded;
      case 'experience':
        return Icons.work_outline_rounded;
      case 'projects':
        return Icons.rocket_launch_rounded;
      case 'summary':
        return Icons.description_outlined;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = isRejected ? 0.4 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAccepted
                ? Colors.green.withValues(alpha: 0.5)
                : isRejected
                    ? Colors.red.withValues(alpha: 0.3)
                    : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Icon(_sectionIcon, size: 16, color: _sectionColor),
                  const SizedBox(width: 6),
                  Text(
                    suggestion.section.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _sectionColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _sectionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      suggestion.action,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ),
                  const Spacer(),
                  if (isAccepted)
                    const Icon(Icons.check_circle, size: 18, color: Colors.green)
                  else if (isRejected)
                    Icon(Icons.cancel, size: 18, color: Colors.red.shade300),
                ],
              ),
            ),
            // Reason
            if (suggestion.reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  suggestion.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Before → After
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (suggestion.current.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.enhanceBefore,
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.red.shade300),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        suggestion.current,
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    AppLocalizations.of(context)!.enhanceAfter,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      suggestion.suggested,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            if (!isAccepted && !isRejected)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(AppLocalizations.of(context)!.enhanceReject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade300,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(AppLocalizations.of(context)!.enhanceAccept),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.count, required this.color, required this.label});
  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
