import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../data/data_sources/career_local_data_source.dart';
import '../../../../../data/data_sources/career_remote_data_source.dart';
import '../../../../../data/repositories/cv_evaluation_repository_impl.dart';
import '../../../../../data/repositories/cv_suggestion_repository_impl.dart';
import '../../../../../data/repositories/career_repository_impl.dart';
import '../../../../../l10n/app_localizations.dart';
import 'cv_evaluation_cubit.dart';
import 'cv_evaluation_state.dart';
import 'cv_score_breakdown.dart';
import 'cv_suggestion_card.dart';

class CvEvaluationScreen extends StatelessWidget {
  const CvEvaluationScreen({required this.documentId, super.key});
  final String documentId;

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _EvaluationBody(prefs: snap.data!, documentId: documentId);
        },
      );
}

class _EvaluationBody extends StatefulWidget {
  const _EvaluationBody({
    required this.prefs,
    required this.documentId,
  });
  final SharedPreferences prefs;
  final String documentId;

  @override
  State<_EvaluationBody> createState() => _EvaluationBodyState();
}

class _EvaluationBodyState extends State<_EvaluationBody> {
  late final CvEvaluationCubit _cubit;

  @override
  void initState() {
    super.initState();
    final local = CareerLocalDataSource(widget.prefs);
    final remote = CareerRemoteDataSource();
    final suggestionRepo = CvSuggestionRepositoryImpl(local);
    final docRepo = CvDocumentRepositoryImpl(remote, local);
    final evalRepo = CvEvaluationRepositoryImpl(remote, local, suggestionRepo);
    final targetRepo = CareerTargetRepositoryImpl(remote, local);
    final analysisRepo = JobAnalysisRepositoryImpl(remote, local);
    _cubit = CvEvaluationCubit(
      evalRepo: evalRepo,
      suggestionRepo: suggestionRepo,
      docRepo: docRepo,
      targetRepo: targetRepo,
      analysisRepo: analysisRepo,
      documentId: widget.documentId,
      userId: '',
    );
    _cubit.evaluate();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<CvEvaluationCubit>.value(
        value: _cubit,
        child: const _EvaluationView(),
      );
}

class _EvaluationView extends StatelessWidget {
  const _EvaluationView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cvEvaluateTitle)),
      body: SafeArea(
        child: BlocBuilder<CvEvaluationCubit, CvEvaluationState>(
        builder: (context, state) {
          if (state.status == CvEvaluationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CvEvaluationStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? l10n.cvEvaluateFailed,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('cvReEvaluate'),
                      onPressed: () =>
                          context.read<CvEvaluationCubit>().reEvaluate(),
                      child: Text(l10n.cvReEvaluate),
                    ),
                  ],
                ),
              ),
            );
          }
          final evaluation = state.evaluation;
          if (evaluation == null) {
            return const SizedBox.shrink();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.deterministicOnly)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.cvDeterministicOnly,
                      style: TextStyle(color: Colors.amber.shade900)),
                ),
              const SizedBox(height: 12),
              CvScoreBreakdown(evaluation: evaluation),
              const SizedBox(height: 16),
              if (evaluation.explanations.isNotEmpty) ...[
                Text(l10n.cvScoreOverall,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final entry in evaluation.explanations.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(entry.value),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.cvApplySuggestion,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  OutlinedButton.icon(
                    key: const Key('cvReEvaluateBtn'),
                    onPressed: () =>
                        context.read<CvEvaluationCubit>().reEvaluate(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.cvReEvaluate),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.cvNoSuggestions),
                )
              else
                for (final s in state.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CvSuggestionCard(
                      suggestion: s,
                      onAccept: (sug) => context
                          .read<CvEvaluationCubit>()
                          .acceptSuggestion(sug),
                      onAcceptEdit: (sug, edited) => context
                          .read<CvEvaluationCubit>()
                          .acceptSuggestionWithEdit(sug, edited),
                      onReject: (sug) => context
                          .read<CvEvaluationCubit>()
                          .rejectSuggestion(sug),
                    ),
                  ),
            ],
          );
        },
      ),
      ),
    );
  }
}
