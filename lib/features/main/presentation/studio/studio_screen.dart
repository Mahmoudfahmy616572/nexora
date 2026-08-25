import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/data_sources/career_local_data_source.dart';
import '../../../../data/data_sources/career_remote_data_source.dart';
import '../../../../data/repositories/career_dna_repository_impl.dart';
import '../../../../data/repositories/career_repository_impl.dart';
import '../../../../domain/cv/cv_template_registry.dart';
import '../../../../domain/entities/career_dna.dart' show CareerStage;
import '../../../../domain/entities/career_target.dart';
import '../../../../domain/entities/cv_content.dart';
import '../../../../domain/entities/cv_document.dart';
import '../../../../l10n/app_localizations.dart';
import 'cubit/cv_cubit.dart';
import 'cubit/cv_state.dart';
import 'cv_create_sheet.dart';
import 'cv_edit_sheet.dart';
import 'cv_export_sheet.dart';
import 'cv_preview.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({this.analysisId, this.targetId, super.key});
  final String? analysisId;
  final String? targetId;

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _StudioBody(
            prefs: snap.data!,
            analysisId: analysisId,
            targetId: targetId,
          );
        },
      );
}

class _StudioBody extends StatefulWidget {
  const _StudioBody({
    required this.prefs,
    this.analysisId,
    this.targetId,
  });
  final SharedPreferences prefs;
  final String? analysisId;
  final String? targetId;

  @override
  State<_StudioBody> createState() => _StudioBodyState();
}

class _StudioBodyState extends State<_StudioBody> {
  late final CvCubit _cubit;

  @override
  void initState() {
    super.initState();
    final local = CareerLocalDataSource(widget.prefs);
    final remote = CareerRemoteDataSource();
    _cubit = CvCubit(
      CvDocumentRepositoryImpl(remote, local),
      CvGenerationRepositoryImpl(remote),
      CareerDnaRepositoryImpl(remote: remote, local: local),
      CareerTargetRepositoryImpl(remote, local),
      JobAnalysisRepositoryImpl(remote, local),
    );
    if (widget.targetId != null) _cubit.selectTarget(widget.targetId);
    if (widget.analysisId != null) _cubit.setAnalysisId(widget.analysisId);
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<CvCubit>.value(
        value: _cubit,
        child: const _StudioView(),
      );
}

class _StudioView extends StatelessWidget {
  const _StudioView();

  void _showCreate(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: context.read<CvCubit>(),
          child: const CvCreateSheet(),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.studioTitle)),
      body: SafeArea(
        child: BlocBuilder<CvCubit, CvState>(
        builder: (context, state) {
          if (state.status == CvStatus.generating) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(key: Key('cvLoading')),
                  const SizedBox(height: 12),
                  Text(l10n.cvGenerating),
                ],
              ),
            );
          }
          if (state.content != null) return _Editor(state: state);
          if (state.status == CvStatus.failure) {
            return _GenerationFailed(state: state);
          }
          if (state.documents.isEmpty) {
            return _Empty(onCreate: () => _showCreate(context));
          }
          return _MyCvs(state: state, onCreate: () => _showCreate(context));
        },
      ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final state = context.watch<CvCubit>().state;
          if (state.content != null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            key: const Key('cvCreate'),
            onPressed: () => _showCreate(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.cvCreate),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.cvNoCvs, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('cvCreateEmpty'),
            onPressed: onCreate,
            child: Text(l10n.cvCreate),
          ),
        ],
      ),
    );
  }
}

class _MyCvs extends StatelessWidget {
  const _MyCvs({required this.state, required this.onCreate});
  final CvState state;
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.studioMyCvs, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final doc in state.documents)
          Card(
            key: Key('cvDoc_${doc.id}'),
            child: ListTile(
              title: Text(doc.title),
              subtitle: Text(l10n.studioUpdated(_fmt(doc.updatedAt))),
              trailing: FilledButton(
                key: Key('cvOpen_${doc.id}'),
                onPressed: () => context.read<CvCubit>().openDocument(doc.id),
                child: Text(l10n.cvOpen),
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('cvCreateList'),
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: Text(l10n.cvCreate),
        ),
      ],
    );
  }
}

class _GenerationFailed extends StatelessWidget {
  const _GenerationFailed({required this.state});
  final CvState state;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CvCubit>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.cvGenerationFailed,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (state.message != null) Text(state.message!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('cvFactual'),
              onPressed: cubit.useFactual,
              child: Text(l10n.cvUseFactual),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('cvRetry'),
              onPressed: cubit.retry,
              child: Text(l10n.cvRetry),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('backToCvList'),
              onPressed: cubit.backToList,
              child: Text(l10n.cvBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.state});
  final CvState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CvCubit>();
    final content = state.content!;
    final resolvedTarget =
        _targetById(state, state.targetId) ??
        _targetById(state, state.selectedDocument?.targetId);
    final stage = state.dna?.stage;
    final targetType = resolvedTarget?.type;

    final controls = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(state.isAiGenerated
                    ? l10n.cvAiTailored
                    : l10n.cvFactualLabel),
                backgroundColor: state.isAiGenerated
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
              ),
              if (state.selectedDocument != null)
                TextButton.icon(
                  key: const Key('cvBack'),
                  onPressed: cubit.backToList,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.cvBack),
                ),
            ],
          ),
          if (state.status == CvStatus.failure && state.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(state.message!,
                    style: TextStyle(color: Colors.red.shade800)),
              ),
            ),
          if (state.status == CvStatus.failure) ...[
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('cvFactual'),
              onPressed: cubit.useFactual,
              child: Text(l10n.cvUseFactual),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('cvRetry'),
              onPressed: cubit.retry,
              child: Text(l10n.cvRetry),
            ),
          ] else ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('cvTemplate'),
              decoration: InputDecoration(labelText: l10n.cvTemplate),
              // ignore: deprecated_member_use
              value: state.templateId,
              items: [
                for (final t in CvTemplateRegistry.all)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) {
                if (v != null) cubit.switchTemplate(v);
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('cvSave'),
              onPressed: cubit.save,
              icon: const Icon(Icons.save),
              label: Text(l10n.studioSave),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('cvEdit'),
                    onPressed: () => _showEdit(context, content),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.studioEdit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('cvExport'),
                    onPressed: () =>
                        _showExport(context, content, state.templateId, stage, targetType),
                    icon: const Icon(Icons.share),
                    label: Text(l10n.cvExport),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.selectedDocument != null)
              FilledButton.icon(
                key: const Key('cvEvaluate'),
                onPressed: () => context.push(
                  '/cv/${state.selectedDocument!.id}/evaluate',
                ),
                icon: const Icon(Icons.analytics),
                label: Text(l10n.cvEvaluateTitle),
              ),
            const SizedBox(height: 16),
            if (state.versions.isNotEmpty) ...[
              Text(l10n.cvVersions,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final v in state.versions)
                ListTile(
                  key: Key('cvVersion_${v.id}'),
                  title: Text(l10n.cvVersion('${v.version}')),
                  onTap: () => cubit.openVersion(v.id),
                ),
            ],
            const SizedBox(height: 8),
            if (state.selectedDocument != null)
              OutlinedButton.icon(
                key: const Key('cvDelete'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmDelete(context, state.selectedDocument!),
                icon: const Icon(Icons.delete),
                label: Text(l10n.delete),
              ),
          ],
        ],
      ),
    );

    final preview = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CvPreview(
        key: const Key('cvPreview'),
        content: content,
        templateId: state.templateId,
        stage: stage,
        targetType: targetType,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 650) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 380, child: controls),
              Expanded(child: preview),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [controls, const Divider(), preview],
          ),
        );
      },
    );
  }
}

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void _showEdit(BuildContext context, CvContent content) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CvEditSheet(
        initial: content,
        onSave: (c) => context.read<CvCubit>().editContent(c),
      ),
    );

void _showExport(
  BuildContext context,
  CvContent content,
  String templateId,
  CareerStage? stage,
  TargetType? targetType,
) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CvExportSheet(
        content: content,
        templateId: templateId,
        stage: stage,
        targetType: targetType,
      ),
    );

CareerTarget? _targetById(CvState state, String? id) {
  if (id == null) return null;
  for (final t in state.targets) {
    if (t.id == id) return t;
  }
  return null;
}

Future<void> _confirmDelete(BuildContext context, CvDocument doc) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(l10n.delete),
      content: Text(l10n.cvConfirmDelete),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(l10n.studioCancel),
        ),
        FilledButton(
          key: const Key('cvDeleteConfirm'),
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<CvCubit>().deleteDocument(doc.id);
  }
}
