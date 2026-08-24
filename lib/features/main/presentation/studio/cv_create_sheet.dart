import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/cv/cv_template_registry.dart';
import '../../../../l10n/app_localizations.dart';
import 'cubit/cv_cubit.dart';
import 'cubit/cv_state.dart';

class CvCreateSheet extends StatefulWidget {
  const CvCreateSheet({super.key});

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
    // Refresh the cubit so the new target shows up in the dropdown.
    await context.read<CvCubit>().load();
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
                  FilledButton(
                    key: const Key('cvCreateConfirm'),
                    onPressed: targets.isEmpty
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
