import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/shared_prefs.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_dna_repository_impl.dart';
import '../../../domain/entities/career_dna.dart';
import '../../../l10n/app_localizations.dart';
import '../career_dna/cubit/career_dna_cubit.dart';
import 'interview_cubit.dart';

/// Contextual AI career interview. The AI asks one focused question at a time,
/// adapts to the user's answers, and finalizes a structured profile when it has
/// enough — or when the user finishes early. Answers are never lost.
class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dna = context.read<CareerDnaCubit>().state.dna;
    if (dna == null) {
      // Should not happen in the flow, but guard against a deep link.
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(Routes.intake));
    }
    return BlocProvider(
      create: (_) => InterviewCubit(
        repository: CareerDnaRepositoryImpl(
          remote: CareerRemoteDataSource(),
          local: CareerLocalDataSource(kPrefs),
        ),
      ),
      child: _InterviewView(initialDna: dna),
    );
  }
}

class _InterviewView extends StatefulWidget {
  const _InterviewView({this.initialDna});

  final CareerDna? initialDna;

  @override
  State<_InterviewView> createState() => _InterviewViewState();
}

class _InterviewViewState extends State<_InterviewView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final dna = widget.initialDna ?? context.read<CareerDnaCubit>().state.dna;
    if (dna != null) {
      final language = Localizations.localeOf(context).languageCode;
      context.read<InterviewCubit>().start(dna, language);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDone(InterviewState state) {
    final merged = state.merged;
    if (merged == null) return;
    context.read<CareerDnaCubit>().updateDraft(merged);
    context.go(Routes.dna);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 720 ? 720.0 : 560.0;
            return BlocConsumer<InterviewCubit, InterviewState>(
              listener: (context, state) {
                if (state.status == InterviewStatus.done) _onDone(state);
              },
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => context.go(Routes.intake),
                            ),
                          ),
                          Text(l10n.interviewTitle, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(l10n.interviewSubtitle, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
                          const SizedBox(height: 18),
                          if (state.usedFallback) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
                              ),
                              child: Text(l10n.interviewFallback, style: AppTextStyles.bodySub),
                            ),
                          ],
                          // Conversation history
                          for (final turn in state.turns) ...[
                            _Bubble(text: turn.question, isUser: false),
                            const SizedBox(height: 8),
                            if (turn.answer.trim().isNotEmpty) ...[
                              _Bubble(text: turn.answer, isUser: true),
                              const SizedBox(height: 12),
                            ],
                          ],
                          if (state.status == InterviewStatus.generating) ...[
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 8),
                            Center(child: Text(l10n.interviewThinking, style: AppTextStyles.bodySub)),
                          ] else if (state.status == InterviewStatus.asking && state.question != null) ...[
                            const SizedBox(height: 12),
                            _Bubble(text: state.question!, isUser: false),
                            const SizedBox(height: 14),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
                              ),
                              child: TextField(
                                controller: _controller,
                                maxLines: 4,
                                cursorColor: AppColors.violet,
                                style: const TextStyle(fontSize: 14, color: AppColors.text),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: l10n.intakeAboutYouHint,
                                  hintStyle: AppTextStyles.bodySub,
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final text = _controller.text.trim();
                                      if (text.isEmpty) return;
                                      _controller.clear();
                                      context.read<InterviewCubit>().answer(text);
                                    },
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: AppColors.primaryButtonGradient,
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(l10n.interviewContinue, style: AppTextStyles.primaryButton),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: state.turns.isEmpty
                                      ? null
                                      : () => context.read<InterviewCubit>().back(),
                                  child: Text(l10n.intakeBack, style: const TextStyle(color: AppColors.textSub)),
                                ),
                                TextButton(
                                  onPressed: () => context.read<InterviewCubit>().skip(),
                                  child: Text(l10n.intakeSkip, style: const TextStyle(color: AppColors.textSub)),
                                ),
                                TextButton(
                                  onPressed: () => context.read<InterviewCubit>().finish(),
                                  child: Text(l10n.intakeFinish, style: const TextStyle(color: AppColors.violet)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.violet.withValues(alpha: 0.16) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: isUser
              ? Border.all(color: AppColors.violet.withValues(alpha: 0.4))
              : Border.all(color: AppColors.borderViolet.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.4),
        ),
      ),
    );
  }
}
