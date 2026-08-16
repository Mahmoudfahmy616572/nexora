import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../features/main/presentation/main_tab.dart';
import '../onboarding/cubit/onboarding_choices_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../data/data_sources/auth_remote_data_source.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/sign_in_cubit.dart';
import 'cubit/sign_in_state.dart';

enum AuthMode { signIn, signUp }

/// Pre-auth sign-in / create-account card backed by Supabase Auth.
///
/// Emits either a successful sign-in (→ main shell) or a request to verify the
/// email via OTP (→ verify screen).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInCubit(repository: AuthRepositoryImpl(AuthRemoteDataSource())),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  late AuthMode _mode = AuthMode.signIn;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(SignInCubit cubit) {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    if (_mode == AuthMode.signIn) {
      cubit.signIn(email: email, password: password);
    } else {
      cubit.signUp(
        fullName: _name.text,
        email: email,
        password: password,
      );
    }
  }

  Future<void> _showResetDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _email.text.trim());
    var loading = false;
    var sent = false;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.border),
          ),
          title: Text(l10n.resetPasswordTitle, style: AppTextStyles.cardTitle),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.resetPasswordBody,
                  style: AppTextStyles.bodySub.copyWith(height: 1.5),
                ),
                const SizedBox(height: 14),
                _AuthField(
                  controller: controller,
                  hint: l10n.emailHint,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                if (sent) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.resetPasswordSent,
                    style: const TextStyle(fontSize: 12, color: AppColors.teal, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.backLabel, style: const TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await AuthRepositoryImpl(AuthRemoteDataSource())
                            .resetPassword(email: controller.text.trim());
                      } on Object {
                        // Always show the neutral confirmation to avoid leaking
                        // which emails exist.
                      }
                      setState(() => loading = false);
                      setState(() => sent = true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.resetPasswordSend),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signIn = _mode == AuthMode.signIn;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: BlocListener<SignInCubit, SignInState>(
            listener: (context, state) {
              switch (state.outcome) {
                case SignInOutcome.signedIn:
                  // If the user went through the pre-auth choices, continue into
                  // the adaptive intake; otherwise land on the main shell.
                  final hasChoices =
                      context.read<OnboardingChoicesCubit>().state.hasAny;
                  if (hasChoices) {
                    context.go(Routes.intake);
                  } else {
                    context.go(
                      Routes.main,
                      extra: _mode == AuthMode.signUp
                          ? MainTab.dna
                          : MainTab.home,
                    );
                  }
                case SignInOutcome.verificationRequired:
                  context.go(Routes.verify, extra: _email.text.trim());
                case SignInOutcome.none:
                  break;
              }
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _BackButton(onPressed: () => context.go(Routes.welcome)),
                          const Spacer(),
                          const BrandLockup(compact: true, narrow: true),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _ModeToggle(
                        mode: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        signIn ? l10n.welcomeBack : l10n.createAccountTitle,
                        style: AppTextStyles.display(30),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        signIn ? l10n.signInBody : l10n.signUpBody,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 26),
                      _SocialPill(
                        label: l10n.continueGoogle,
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            fontFamily: AppTextStyles.fontFamily,
                          ),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 10),
                      _SocialPill(
                        label: l10n.continueApple,
                        icon: const Icon(Icons.apple, size: 16, color: AppColors.text),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),
                      const _OrDivider(),
                      const SizedBox(height: 20),
                      if (!signIn) ...[
                        _FieldLabel(text: l10n.fieldFullName),
                        _AuthField(
                          controller: _name,
                          hint: l10n.nameHint,
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _FieldLabel(text: l10n.fieldEmail),
                      _AuthField(
                        controller: _email,
                        hint: l10n.emailHint,
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _FieldLabel(text: l10n.fieldPassword),
                          const Spacer(),
                          if (signIn)
                            _ForgotLink(onTap: _showResetDialog),
                        ],
                      ),
                      _AuthField(
                        controller: _password,
                        hint: signIn ? l10n.passwordHint : l10n.passwordHintSignUp,
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                      ),
                      const SizedBox(height: 22),
                      BlocBuilder<SignInCubit, SignInState>(
                        builder: (context, state) {
                          return Column(
                            children: [
                              if (state.error != null) ...[
                                _ErrorBanner(message: state.error!),
                                const SizedBox(height: 14),
                              ],
                              NexoraPrimaryButton(
                                label: signIn ? l10n.signIn : l10n.createAccountShort,
                                onPressed: state.loading
                                    ? null
                                    : () => _submit(context.read<SignInCubit>()),
                                compact: true,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      NexoraSecondaryButton(
                        label: signIn ? l10n.newToNexora : l10n.alreadyHaveAccount,
                        onPressed: () => setState(
                          () => _mode = signIn ? AuthMode.signUp : AuthMode.signIn,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.termsNote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.redBdr),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.red),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Segment(
            label: l10n.signIn,
            active: mode == AuthMode.signIn,
            onTap: () => onChanged(AuthMode.signIn),
          ),
          _Segment(
            label: l10n.createAccountShort,
            active: mode == AuthMode.signUp,
            onTap: () => onChanged(AuthMode.signUp),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.tealBg : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: active ? AppColors.teal.withValues(alpha: 0.45) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppTextStyles.monoFont,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.teal : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialPill extends StatefulWidget {
  const _SocialPill({required this.label, required this.icon, required this.onPressed});

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  State<_SocialPill> createState() => _SocialPillState();
}

class _SocialPillState extends State<_SocialPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.cardHi : AppColors.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _hovered ? AppColors.borderMed : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(child: ColoredBox(color: AppColors.border, child: SizedBox(height: 1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.orContinueEmail,
            style: const TextStyle(
              fontFamily: AppTextStyles.monoFont,
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Expanded(child: ColoredBox(color: AppColors.border, child: SizedBox(height: 1))),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppTextStyles.monoFont,
          fontSize: 11,
          letterSpacing: 1,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _ForgotLink extends StatelessWidget {
  const _ForgotLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          l10n.forgotPassword,
          style: const TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 11,
            letterSpacing: 1,
            color: AppColors.teal,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final FocusNode _focus = FocusNode();
  late bool _obscure = widget.obscure;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.teal.withValues(alpha: 0.6) : AppColors.border,
        ),
        boxShadow: focused
            ? [BoxShadow(color: AppColors.tealBg, blurRadius: 20)]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            widget.icon,
            size: 18,
            color: focused ? AppColors.teal : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: _obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              cursorColor: AppColors.teal,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodySub,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          if (widget.obscure)
            GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}
