import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_dna_repository_impl.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../domain/entities/career_target.dart';
import '../../../domain/entities/job_analysis.dart';
import '../../../domain/entities/opportunity_analysis.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/career_dna/cubit/career_dna_cubit.dart';
import 'analyze/cubit/analyze_cubit.dart';
import 'analyze/cubit/analyze_state.dart';
import 'analyze/opportunity_analysis_view.dart';
import 'enhance/enhance_dna_cubit.dart';
import 'enhance/enhance_dna_sheet.dart';

/// Opportunity Intelligence (Analyze tab).
///
/// Runs a deterministic, explainable analysis of a pasted opportunity against
/// the user's Career DNA — optionally focused by a Career Target — and renders
/// the full result (scores + per-requirement evidence). The single source of
/// truth for scoring is the offline [OpportunityMatchEngine] invoked by the
/// repository; the hosted AI (when reachable) only enriches extraction and the
/// recommendation text.
class AnalyzeScreen extends StatelessWidget {
  const AnalyzeScreen({super.key, required this.onOpenStudio});

  /// Lets the host shell open the Studio tab with the analysed target/analysis
  /// context (used by the "Create CV for this Target" call-to-action).
  final void Function(String? targetId, String? analysisId) onOpenStudio;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final local = CareerLocalDataSource(snap.data!);
        final remote = CareerRemoteDataSource();
        final jobRepo = JobAnalysisRepositoryImpl(remote, local);
        final targetRepo = CareerTargetRepositoryImpl(remote, local);
        final dnaRepo = CareerDnaRepositoryImpl(remote: remote, local: local);
        return BlocProvider<AnalyzeCubit>(
          create: (_) => AnalyzeCubit(jobRepo, targetRepo, dnaRepo, local)..load(),
          child: _AnalyzeView(onOpenStudio: onOpenStudio),
        );
      },
    );
  }
}

class _AnalyzeView extends StatefulWidget {
  const _AnalyzeView({required this.onOpenStudio});

  final void Function(String?, String?) onOpenStudio;

  @override
  State<_AnalyzeView> createState() => _AnalyzeViewState();
}

class _AnalyzeViewState extends State<_AnalyzeView> {
  bool _modeIsNew = false;
  bool _analyzing = false;
  DateTime _analyzeStart = DateTime.now();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAnalyze() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _analyzing = true);
    _analyzeStart = DateTime.now();
    context.read<AnalyzeCubit>().analyze(description: text);
  }

  /// Keep the "Analyzing…" state visible for a short, stable minimum so the
  /// (often instantaneous) offline analysis still reads as processing and the
  /// result doesn't flash in before the user taps.
  void _finishAnalyzing(AnalyzeStatus status) {
    if (!_analyzing) return;
    final elapsed = DateTime.now().difference(_analyzeStart);
    final wait = const Duration(milliseconds: 800) - elapsed;
    void clear() {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        if (status == AnalyzeStatus.success && _modeIsNew) _modeIsNew = false;
      });
    }

    if (wait > Duration.zero) {
      Future.delayed(wait, clear);
    } else {
      clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<AnalyzeCubit, AnalyzeState>(
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
        if (state.status == AnalyzeStatus.success ||
            state.status == AnalyzeStatus.failure) {
          _finishAnalyzing(state.status);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.analyzeTitle, style: AppTextStyles.screenTitle),
                    const SizedBox(height: 6),
                    Text(
                      l10n.analyzeSubtitle,
                      style: AppTextStyles.bodySub.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    _Segment(
                      isNew: _modeIsNew,
                      onChanged: (v) => setState(() => _modeIsNew = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_modeIsNew)
                _NewAnalysisForm(
                  controller: _controller,
                  analyzing: _analyzing,
                  selectedTargetId: state.selectedTargetId,
                  targets: state.targets,
                  onSelectTarget: (id) {
                    context.read<AnalyzeCubit>().selectTarget(id);
                    if (id != null) {
                      final target = state.targets
                          .where((t) => t.id == id)
                          .firstOrNull;
                      if (target != null && (target.jobDescription?.trim().isNotEmpty ?? false)) {
                        _controller.text = target.jobDescription!;
                      }
                    }
                  },
                  onNewTarget: () async {
                    final cubit = context.read<AnalyzeCubit>();
                    await context.push('/targets/form');
                    if (mounted) cubit.load();
                  },
                  onAnalyze: _onAnalyze,
                )
              else
                _ResultsList(
                  analyses: state.analyses,
                  onDelete: (id) => context.read<AnalyzeCubit>().deleteAnalysis(id),
                  onOpenStudio: widget.onOpenStudio,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.isNew, required this.onChanged});

  final bool isNew;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildSegment(l10n.analyzeMyAnalyses, isNew, !isNew, () => onChanged(false)),
          _buildSegment(l10n.analyzeNewAnalysis, isNew, isNew, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool isNew, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.background : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewAnalysisForm extends StatelessWidget {
  const _NewAnalysisForm({
    required this.controller,
    required this.analyzing,
    required this.selectedTargetId,
    required this.targets,
    required this.onSelectTarget,
    required this.onNewTarget,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final bool analyzing;
  final String? selectedTargetId;
  final List<CareerTarget> targets;
  final ValueChanged<String?> onSelectTarget;
  final VoidCallback onNewTarget;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.analyzeNewTarget, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TargetChip(
                label: l10n.analyzeJustAnalyze,
                selected: selectedTargetId == null,
                onTap: () => onSelectTarget(null),
              ),
              for (final target in targets)
                _TargetChip(
                  label: target.role.isNotEmpty ? target.role : l10n.analyzeNewTarget,
                  selected: selectedTargetId == target.id,
                  onTap: () => onSelectTarget(target.id),
                ),
              OutlinedButton.icon(
                onPressed: analyzing ? null : onNewTarget,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.analyzeNewTarget),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: BorderSide(color: AppColors.tealBdr),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 6,
              enabled: !analyzing,
              style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6, color: AppColors.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: l10n.analyzeDescriptionHint,
                hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: analyzing ? null : onAnalyze,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 50,
              decoration: BoxDecoration(
                color: analyzing ? AppColors.border : AppColors.teal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: analyzing
                    ? [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSub),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.analyzeAnalyzing,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSub,
                          ),
                        ),
                      ]
                    : [
                        Icon(Icons.bolt_rounded, size: 17, color: AppColors.background),
                        const SizedBox(width: 8),
                        Text(
                          l10n.analyzeWithAi,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal.withValues(alpha: 0.12) : AppColors.cardHi,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.teal : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.teal : AppColors.textSub,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.analyses,
    required this.onDelete,
    required this.onOpenStudio,
  });

  final List<JobAnalysis> analyses;
  final ValueChanged<String> onDelete;
  final void Function(String?, String?) onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (analyses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(l10n.analyzeEmpty, style: AppTextStyles.bodySub, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < analyses.length; i++) ...[
            _AnalysisCard(analysis: analyses[i], onDelete: onDelete, onOpenStudio: onOpenStudio),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.onDelete,
    required this.onOpenStudio,
  });

  final JobAnalysis analysis;
  final ValueChanged<String> onDelete;
  final void Function(String?, String?) onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = analysis.detail;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    if (analysis.company.isNotEmpty)
                      Text(analysis.company, style: AppTextStyles.bodySub),
                  ],
                ),
              ),
              Row(
                children: [
                  if (analysis.timeAgo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cardHi,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(analysis.timeAgo, style: AppTextStyles.bodySmall),
                    ),
                  IconButton(
                    tooltip: l10n.analyzeRemoveTooltip,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted),
                    onPressed: () => onDelete(analysis.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (detail != null) ...[
            OpportunityAnalysisView(analysis: detail),
            const SizedBox(height: 12),
            _EnhanceButton(
              analysis: detail,
              jobDescription: analysis.jobDescription,
              onEnhanced: () => context.read<AnalyzeCubit>().analyze(
                description: analysis.jobDescription,
              ),
            ),
          ] else ...[
            // Legacy analyses (no stored detail): render the simple scores.
            _LegacyScore(label: l10n.analyzeSkills, value: analysis.skills),
            _LegacyScore(label: l10n.analyzeExperience, value: analysis.experience),
            _LegacyScore(label: l10n.analyzeEducation, value: analysis.education),
            _LegacyScore(label: l10n.analyzeKeywords, value: analysis.keywords),
            const SizedBox(height: 10),
            Text(l10n.analyzeStrongMatches, style: AppTextStyles.bodySmall),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in analysis.strong)
                  Chip(label: Text(skill), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 10),
            if (analysis.aiRecommendation.isNotEmpty)
              Text(analysis.aiRecommendation, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
          ],
          if (analysis.targetId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onOpenStudio(analysis.targetId, analysis.id),
                icon: const Icon(Icons.description_rounded, size: 16),
                label: Text(l10n.analyzeCreateCv),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: BorderSide(color: AppColors.tealBdr),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnhanceButton extends StatelessWidget {
  const _EnhanceButton({
    required this.analysis,
    required this.jobDescription,
    this.onEnhanced,
  });

  final OpportunityAnalysis analysis;
  final String jobDescription;
  final VoidCallback? onEnhanced;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Collect gaps: not evidenced + weak requirements
    final gaps = [
      ...analysis.notEvidenced.map((r) => r.label),
      ...analysis.requiredGaps.map((r) => r.label),
    ];
    if (gaps.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final dnaCubit = context.read<CareerDnaCubit>();
          final remote = CareerRemoteDataSource();
          final dnaRepo = CareerDnaRepositoryImpl(remote: remote, local: CareerLocalDataSource(await SharedPreferences.getInstance()));
          final dna = dnaCubit.state.dna ?? await dnaRepo.load();
          if (dna == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.enhanceError), behavior: SnackBarBehavior.floating),
            );
            return;
          }
          if (!context.mounted) return;
          final enhanceCubit = EnhanceDnaCubit(
            dnaRepo,
            remote,
            dna: dna,
            gaps: gaps,
            targetRole: analysis.role.isNotEmpty ? analysis.role : null,
          );
          final applied = await showEnhanceDnaSheet(context, enhanceCubit);
          if (applied && context.mounted) {
            final updatedDna = await dnaRepo.load();
            if (updatedDna != null) dnaCubit.updateDraft(updatedDna);
            // Re-run analysis with updated DNA
            if (jobDescription.isNotEmpty) {
              onEnhanced?.call();
            }
          }
        },
        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
        label: Text(l10n.enhanceBtn),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber,
          side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _LegacyScore extends StatelessWidget {
  const _LegacyScore({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Text(
                label,
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 5,
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: AppColors.teal,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(value.toStringAsFixed(0), textAlign: TextAlign.end, style: AppTextStyles.bodySmall),
            ),
          ],
        ),
      );
}
