import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/career_dna.dart';
import 'package:nexora/presentation/career_dna/cubit/career_dna_cubit.dart';
import 'package:nexora/presentation/onboarding/cubit/onboarding_choices_cubit.dart';

import '../../l10n/app_localizations.dart';
import 'ai_intake_cubit.dart';
class AiIntakeScreen extends StatelessWidget {
  const AiIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dna = context.read<CareerDnaCubit>().state.dna ?? CareerDna();
    return BlocProvider(
      create: (_) => AiIntakeCubit(initialDna: dna),
      child: const _AiIntakeView(),
    );
  }
}

class _AiIntakeView extends StatefulWidget {
  const _AiIntakeView();
  @override
  State<_AiIntakeView> createState() => _AiIntakeViewState();
}

class _AiIntakeViewState extends State<_AiIntakeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _otherCtrl = TextEditingController();
  bool _showOther = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  void _animateIn() {
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _onContinue() {
    final cubit = context.read<AiIntakeCubit>();
    if (_showOther) {
      final text = _otherCtrl.text.trim();
      if (text.isEmpty) return;
      _otherCtrl.clear();
      setState(() => _showOther = false);
      cubit.answerOther(text, 'en');
    } else {
      cubit.confirmSelection('en');
    }
    _animateIn();
  }

  void _importGitHub() {
    showDialog<void>(
      context: context,
      builder: (_) => _GitHubImportDialog(
        onImport: (username) {
          if (username.trim().isNotEmpty) {
            context.read<AiIntakeCubit>().importGitHub(username.trim(), 'en');
            _animateIn();
          }
        },
      ),
    );
  }

  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          Navigator.of(context).maybePop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exitConfirm),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.text),
          onPressed: () {
            final cubit = context.read<AiIntakeCubit>();
            if (cubit.state.turns.length > 1) {
              cubit.back();
              _animateIn();
            } else {
              context.go(Routes.main);
            }
          },
        ),
        title: const Text(
          'Build Your Profile',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () =>
                context.read<AiIntakeCubit>().finalize('en'),
            child: const Text('Skip',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
      ),
      body: BlocConsumer<AiIntakeCubit, AiIntakeState>(
        listener: (context, state) {
          if (state.status == AiIntakeStatus.done && state.merged != null) {
            context.read<CareerDnaCubit>().updateDraft(state.merged!);
            OnboardingChoicesCubit.markOnboardingCompleted();
            context.pushReplacement(Routes.dna);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // ── Progress bar ────────────────────────────────────────
              if (state.stepNumber > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: state.stepNumber / state.totalSteps,
                      backgroundColor: AppColors.card,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.violet),
                      minHeight: 4,
                    ),
                  ),
                ),

              // ── Main content ────────────────────────────────────────
              Expanded(
                child: state.status == AiIntakeStatus.importing
                    ? _buildImporting()
                    : state.status == AiIntakeStatus.error
                        ? _buildError(state)
                        : state.turns.isEmpty
                            ? _buildWelcome(state)
                            : _buildQuestionArea(state),
              ),
              // ── Bottom bar ──────────────────────────────────────────
              if (state.status != AiIntakeStatus.importing)
                _buildBottomBar(state, bottomPad),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildWelcome(AiIntakeState state) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // AI Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.violet, Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              "Hi! I'm Nexora AI",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's build your professional profile together.\nI'll ask a few quick questions — just tap to answer.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const Spacer(flex: 2),
            // Import buttons
            _ImportButton(
              icon: Icons.code,
              label: 'Import from GitHub',
              onTap: _importGitHub,
            ),
            const SizedBox(height: 12),
            _ImportButton(
              icon: Icons.link,
              label: 'Import from LinkedIn',
              onTap: null,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                context.read<AiIntakeCubit>().start('en');
                _animateIn();
              },
              child: const Text(
                'Start from scratch',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.violet,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ── Question area ───────────────────────────────────────────────────────

  Widget _buildQuestionArea(AiIntakeState state) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // AI bubble with question
          if (state.currentFeedback != null) ...[
            _AiFeedback(text: state.currentFeedback!),
            const SizedBox(height: 12),
          ],
          _AiBubble(text: state.currentQuestion),
          const SizedBox(height: 20),

          // Choice chips
          if (state.currentChoices.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: state.currentChoices.map((choice) {
                if (choice.type == ChoiceType.other) {
                  return _OtherChip(
                    onTap: () {
                      setState(() => _showOther = !_showOther);
                    },
                    active: _showOther,
                  );
                }
                final selected = state.selectedValues.contains(choice.value);
                return _ChoiceChip(
                  label: choice.label,
                  selected: selected,
                  multi: state.isMulti,
                  onTap: () {
                    context.read<AiIntakeCubit>().toggleChoice(choice.value);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Other text field
            if (_showOther) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: TextField(
                  controller: _otherCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Type your answer...',
                    hintStyle:
                        const TextStyle(color: AppColors.muted, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  onSubmitted: (_) => _onContinue(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Multi-select hint
            if (state.isMulti)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Select all that apply',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],

          // Loading indicator
          if (state.status == AiIntakeStatus.loading &&
              state.turns.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.violet,
                  ),
                ),
              ),
            ),

          // History (previous turns, compact)
          if (state.turns.length > 1) ...[
            const SizedBox(height: 8),
            ...state.turns.reversed.skip(1).take(3).map((turn) =>
                _CompactTurn(question: turn.question, answer: turn.answer)),
          ],
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────

  Widget _buildBottomBar(AiIntakeState state, double bottomPad) {
    final canAction = state.status == AiIntakeStatus.showing && state.canContinue;
    final canOther = _showOther && _otherCtrl.text.trim().isNotEmpty;
    final enabled = canAction || canOther;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.borderViolet.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (state.turns.length > 1)
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AiIntakeCubit>().back();
                  setState(() => _showOther = false);
                  _animateIn();
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  side: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (state.turns.length > 1) const SizedBox(width: 12),

          // Continue / Finish button
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: enabled ? _onContinue : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  disabledBackgroundColor: AppColors.violet.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: enabled ? 2 : 0,
                ),
                child: Text(
                  state.status == AiIntakeStatus.loading
                      ? 'Thinking...'
                      : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Importing state ─────────────────────────────────────────────────────

  Widget _buildImporting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.violet,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Importing from GitHub...',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'Building your profile from repositories',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────

  Widget _buildError(AiIntakeState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Something went wrong',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                context.read<AiIntakeCubit>().start('en');
                _animateIn();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.violet, Color(0xFF9C27B0)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        // Bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppColors.borderViolet.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiFeedback extends StatelessWidget {
  const _AiFeedback({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 46),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.violet,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.borderViolet.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (multi)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.violet : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected
                        ? AppColors.violet
                        : AppColors.muted.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.violet : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherChip extends StatelessWidget {
  const _OtherChip({required this.onTap, required this.active});
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.violet.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.violet
                : AppColors.borderViolet.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.keyboard_hide : Icons.edit,
              size: 16,
              color: active ? AppColors.violet : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              'Other',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.violet : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTurn extends StatelessWidget {
  const _CompactTurn({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderViolet.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.violet),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// GitHub-import dialog. Owns its [TextEditingController] in [initState] and
/// releases it in [dispose], which runs only after the dialog's exit animation
/// completes — avoiding the "used after being disposed" crash.
class _GitHubImportDialog extends StatefulWidget {
  const _GitHubImportDialog({required this.onImport});

  final ValueChanged<String> onImport;

  @override
  State<_GitHubImportDialog> createState() => _GitHubImportDialogState();
}

class _GitHubImportDialogState extends State<_GitHubImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) widget.onImport(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Import from GitHub',
          style: TextStyle(color: AppColors.text)),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'GitHub username',
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: const Icon(Icons.code, color: AppColors.violet),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: AppColors.text),
        autofocus: true,
        onSubmitted: (_) {
          Navigator.of(context).pop();
          _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.muted)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _submit();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
