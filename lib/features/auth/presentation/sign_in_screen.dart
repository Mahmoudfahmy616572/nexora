import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/nexora_buttons.dart';

enum AuthMode { signIn, signUp }

/// Pre-auth sign-in / create-account card — centered form on the ambient
/// background with social options, glass inputs and a mode toggle.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.mode = AuthMode.signIn});

  final AuthMode mode;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late AuthMode _mode;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signIn = _mode == AuthMode.signIn;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
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
                        const BrandLockup(compact: true),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ModeToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      signIn ? 'Welcome back' : 'Create your account',
                      style: AppTextStyles.display(30),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      signIn
                          ? 'Sign in to continue building your Career DNA.'
                          : 'Start with your basics — we will never publish anything.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 26),
                    _SocialPill(
                      label: 'Continue with Google',
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
                      label: 'Continue with Apple',
                      icon: const Icon(Icons.apple, size: 16, color: AppColors.text),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 20),
                    const _OrDivider(),
                    const SizedBox(height: 20),
                    if (!signIn) ...[
                      const _FieldLabel('Full name'),
                      _AuthField(
                        controller: _name,
                        hint: 'Ahmed Al-Rashidi',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                    ],
                    const _FieldLabel('Email'),
                    _AuthField(
                      controller: _email,
                      hint: 'you@example.com',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const _FieldLabel('Password'),
                        const Spacer(),
                        if (signIn)
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'FORGOT?',
                              style: TextStyle(
                                fontFamily: AppTextStyles.monoFont,
                                fontSize: 9,
                                letterSpacing: 1,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _AuthField(
                      controller: _password,
                      hint: signIn ? 'Your password' : 'Min. 8 characters',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 22),
                    NexoraPrimaryButton(
                      label: signIn ? 'Sign in' : 'Create account',
                      onPressed: () =>
                          context.go(signIn ? Routes.main : Routes.verify),
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    NexoraSecondaryButton(
                      label: signIn
                          ? 'New to Nexora? Create an account'
                          : 'Already have an account? Sign in',
                      onPressed: () => setState(
                        () => _mode = signIn ? AuthMode.signUp : AuthMode.signIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'By continuing you agree to the Terms of Service '
                      'and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
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
            label: 'Sign in',
            active: mode == AuthMode.signIn,
            onTap: () => onChanged(AuthMode.signIn),
          ),
          _Segment(
            label: 'Create account',
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 10,
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
    return Row(
      children: [
        const Expanded(child: ColoredBox(color: AppColors.border, child: SizedBox(height: 1))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH EMAIL',
            style: TextStyle(
              fontFamily: AppTextStyles.monoFont,
              fontSize: 8,
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
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppTextStyles.monoFont,
          fontSize: 9,
          letterSpacing: 1,
          color: AppColors.textMuted,
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
            size: 16,
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
              style: const TextStyle(fontSize: 13, color: AppColors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodySub,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (widget.obscure)
            GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 15,
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
