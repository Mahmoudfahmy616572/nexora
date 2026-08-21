import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/breakpoints.dart';
import '../../l10n/app_localizations.dart';
import '../../data/data_sources/career_local_data_source.dart';
import '../../data/data_sources/career_remote_data_source.dart';
import '../../data/repositories/career_repository_impl.dart';
import '../../domain/entities/career_target.dart';
import 'cubit/target_cubit.dart';
import 'cubit/target_state.dart';
import 'target_labels.dart';

class TargetListScreen extends StatefulWidget {
  const TargetListScreen({super.key});

  @override
  State<TargetListScreen> createState() => _TargetListScreenState();
}

class _TargetListScreenState extends State<TargetListScreen> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<SharedPreferences>(
      future: _prefs,
      builder: (context, snap) {
        if (!snap.hasData) return _shell(l10n, const Center(child: CircularProgressIndicator()));
        final repo = CareerTargetRepositoryImpl(
          CareerRemoteDataSource(),
          CareerLocalDataSource(snap.data!),
        );
        return BlocProvider<TargetCubit>(
          create: (_) => TargetCubit(repo)..loadTargets(),
          child: _TargetListView(l10n: l10n),
        );
      },
    );
  }

  Widget _shell(AppLocalizations l10n, Widget body) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(title: l10n.targetTitle, onBack: () => context.pop()),
              Expanded(child: body),
            ],
          ),
        ),
      );
}

class _TargetListView extends StatelessWidget {
  const _TargetListView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TargetCubit, TargetState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.cardHi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
        }
      },
      builder: (context, state) {
        if (state.status == TargetStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildCta(context, state)),
            if (state.status == TargetStatus.empty || state.targets.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(l10n: l10n, onAdd: () => _openForm(context, null)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Breakpoints.isTablet(context) || Breakpoints.isDesktop(context) ? 2 : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TargetCard(
                      l10n: l10n,
                      target: state.targets[index],
                      onOpen: () => _openForm(context, state.targets[index]),
                      onDelete: () => _confirmDelete(context, state.targets[index]),
                    ),
                    childCount: state.targets.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCta(BuildContext context, TargetState state) {
    final hasTargets = state.targets.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: FilledButton.icon(
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(hasTargets ? l10n.targetAdd : l10n.targetAdd),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, CareerTarget? target) async {
    await context.push<void>('/targets/form', extra: target);
    if (context.mounted) context.read<TargetCubit>().loadTargets();
  }

  Future<void> _confirmDelete(BuildContext context, CareerTarget target) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.targetDelete, style: AppTextStyles.cardTitle),
        content: Text(l10n.targetDeleteConfirm, style: AppTextStyles.bodySub),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.targetDelete, style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<TargetCubit>().deleteTarget(target.id);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 8),
      child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.screenTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.onAdd});

  final AppLocalizations l10n;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tealBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tealBdr),
              ),
              child: const Icon(Icons.track_changes_rounded, size: 30, color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            Text(l10n.targetListEmpty, style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(
              l10n.targetListEmptySub,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySub,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.targetAdd),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.l10n,
    required this.target,
    required this.onOpen,
    required this.onDelete,
  });

  final AppLocalizations l10n;
  final CareerTarget target;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (target.industry != null && target.industry!.isNotEmpty) target.industry!,
      if (target.company != null && target.company!.isNotEmpty) target.company!,
    ].join(' · ');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tealBdr),
                  ),
                  child: const Icon(Icons.flag_rounded, size: 20, color: AppColors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        target.role,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetTypeLabel(l10n, target.type),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
