import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/cv/cv_readiness_engine.dart';
import '../../../../domain/cv/cv_template_registry.dart';
import '../../../../l10n/app_localizations.dart';
import 'cubit/cv_cubit.dart';
import 'cubit/cv_state.dart';

class CvCreateSheet extends StatefulWidget {
  const CvCreateSheet({super.key, this.onCompleteProfile, this.onFixMissing});

  final VoidCallback? onCompleteProfile;

  /// Called with a readiness item key (e.g. 'identity', 'experience') when the
  /// user taps a missing/weak item to fix it.
  final ValueChanged<String>? onFixMissing;

  @override
  State<CvCreateSheet> createState() => _CvCreateSheetState();
}

class _CvCreateSheetState extends State<CvCreateSheet> {
  final _title = TextEditingController();
  String? _targetId;
  String _templateId = 'nexoraMinimal';

  @override
  void initState() {
    super.initState();
    _targetId = context.read<CvCubit>().state.targetId;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _createTarget() async {
    await context.push('/targets/form');
    if (!mounted) return;
    await context.read<CvCubit>().load();
    if (!mounted) return;
    final targets = context.read<CvCubit>().state.targets;
    if (targets.isNotEmpty && _targetId == null) {
      setState(() => _targetId = targets.last.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CvCubit>();
    final templates = CvTemplateRegistry.all;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<CvCubit, CvState>(
            builder: (context, state) {
              final targets = state.targets;
              final targetValue =
                  targets.where((t) => t.id == _targetId).isNotEmpty
                      ? _targetId
                      : null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.cvCreate,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('cvTitleField'),
                    controller: _title,
                    decoration:
                        InputDecoration(labelText: l10n.studioCvTitleHint),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('cvTargetSelect'),
                    decoration: InputDecoration(labelText: l10n.cvTarget),
                    // ignore: deprecated_member_use
                    value: targetValue,
                    items: [
                      for (final t in targets)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(t.role.isNotEmpty ? t.role : t.id),
                        ),
                    ],
                    onChanged: (v) => setState(() => _targetId = v),
                  ),
                  if (targets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.cvSelectTargetFirst,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const Key('cvCreateTarget'),
                            onPressed: _createTarget,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.targetAdd),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('cvTemplateSelect'),
                    decoration: InputDecoration(labelText: l10n.cvTemplate),
                    // ignore: deprecated_member_use
                    value: _templateId,
                    items: [
                      for (final t in templates)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) =>
                        setState(() => _templateId = v ?? 'nexoraMinimal'),
                  ),
                  const SizedBox(height: 16),
                  _ReadinessBar(
                    cubit: cubit,
                    selectedTargetId: targetValue,
                    onCompleteProfile: widget.onCompleteProfile,
                    onFixMissing: widget.onFixMissing,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('cvCreateConfirm'),
                    onPressed: targetValue == null
                        ? null
                        : () {
                            final title = _title.text.trim();
                            Navigator.pop(context);
                            cubit.startCreation(
                              title: title.isNotEmpty ? title : l10n.cvCreate,
                              templateId: _templateId,
                              targetId: _targetId,
                            );
                          },
                    child: Text(l10n.cvGenerate),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadinessBar extends StatelessWidget {
  const _ReadinessBar({required this.cubit, this.selectedTargetId, this.onCompleteProfile, this.onFixMissing});
  final CvCubit cubit;
  final String? selectedTargetId;
  final VoidCallback? onCompleteProfile;
  final ValueChanged<String>? onFixMissing;

  @override
  Widget build(BuildContext context) {
    final engine = const CvReadinessEngine();
    final selectedTarget = selectedTargetId != null
        ? cubit.state.targets.where((t) => t.id == selectedTargetId).firstOrNull
        : null;
    final report = engine.evaluate(
      dna: cubit.state.dna,
      target: selectedTarget,
      identity: cubit.state.identity,
    );
    if (report.ready) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              report.summary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }
    final missing =
        report.items.where((i) => i.state == CvReadinessItemState.missing).toList();
    final weak =
        report.items.where((i) => i.state == CvReadinessItemState.weak).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.cvQualityCouldBeBetter,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Missing:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final item in missing)
                _FixChip(
                  label: item.label,
                  color: Colors.orange,
                  onTap: onFixMissing != null ? () => onFixMissing!(item.key) : null,
                ),
            ],
          ),
        ],
        if (weak.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Weak:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade300,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final item in weak)
                _FixChip(
                  label: item.label,
                  color: Colors.orange.shade300,
                  onTap: onFixMissing != null ? () => onFixMissing!(item.key) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FixChip extends StatelessWidget {
  const _FixChip({required this.label, required this.color, this.onTap});
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      avatar: onTap != null
          ? Icon(Icons.arrow_forward_rounded, size: 14, color: color)
          : null,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
