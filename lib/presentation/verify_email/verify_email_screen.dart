import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../features/main/presentation/main_tab.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../data/data_sources/auth_remote_data_source.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../l10n/app_localizations.dart';
import '../onboarding/cubit/onboarding_choices_cubit.dart';
import 'cubit/verify_email_cubit.dart';
import 'cubit/verify_email_state.dart';

/// Post-sign-up email verification — 6-digit OTP entry with auto-advance,
/// paste support, resend countdown, and an animated success state.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyEmailCubit(repository: AuthRepositoryImpl(AuthRemoteDataSource())),
      child: _VerifyEmailView(email: email),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  const _VerifyEmailView({this.email});

  final String? email;

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  static const int _length = 6;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focus =
      List.generate(_length, (_) => FocusNode());

  Timer? _timer;
  int _seconds = 30;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < _length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= _length) {
        _focus[_length - 1].unfocus();
      } else if (digits.isNotEmpty) {
        FocusScope.of(context)
            .requestFocus(_focus[digits.length.clamp(0, _length - 1)]);
      }
    } else if (digits.isNotEmpty) {
      if (index < _length - 1) {
        FocusScope.of(context).requestFocus(_focus[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      _controllers[index - 1].clear();
      FocusScope.of(context).requestFocus(_focus[index - 1]);
    }
    setState(() => _ready = _code.length == _length);
  }

  void _verify(VerifyEmailCubit cubit) {
    FocusScope.of(context).unfocus();
    cubit.verify(email: widget.email ?? '', code: _code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: BlocListener<VerifyEmailCubit, VerifyEmailState>(
            listener: (context, state) {
              if (state.verified) {
                _timer?.cancel();
                Timer(const Duration(milliseconds: 1600), () {
                  if (mounted) {
                    // Fresh sign-up with pre-auth choices continues into the
                    // adaptive intake; otherwise land on the DNA tab.
                    final hasChoices =
                        context.read<OnboardingChoicesCubit>().state.hasAny;
                    context.go(
                      hasChoices ? Routes.intake : Routes.main,
                      extra: hasChoices ? null : MainTab.dna,
                    );
                  }
                });
              }
            },
            child: BlocBuilder<VerifyEmailCubit, VerifyEmailState>(
              builder: (context, state) {
                return state.verified
                    ? const _VerifiedSplash()
                    : _buildForm(context, state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, VerifyEmailState state) {
    final l10n = AppLocalizations.of(context)!;
    final email = widget.email ?? '';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BackButton(onPressed: () => context.go(Routes.login)),
                  const Spacer(),
                  const BrandLockup(compact: true, narrow: true),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.tealBdr),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 30,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.verifyEmailTitle,
                style: AppTextStyles.display(30),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.verifySentCode(email),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  for (var i = 0; i < _length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focus[i],
                        onChanged: (v) => _onChanged(i, v),
                        autofocus: i == 0,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _seconds > 0
                      ? null
                      : () {
                          context.read<VerifyEmailCubit>().resend(email: email);
                          _startCountdown();
                        },
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                      children: [
                        TextSpan(text: l10n.verifyDidntGet),
                        if (_seconds > 0)
                          TextSpan(
                            text: l10n.verifyResendIn(_seconds),
                            style: const TextStyle(color: AppColors.textMuted),
                          )
                        else
                          TextSpan(
                            text: l10n.verifyResend,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: state.error!),
              ],
              const SizedBox(height: 26),
              Opacity(
                opacity: _ready && !state.loading ? 1 : 0.45,
                child: NexoraPrimaryButton(
                  label: l10n.verifyCta,
                  onPressed: _ready && !state.loading
                      ? () => _verify(context.read<VerifyEmailCubit>())
                      : null,
                  compact: true,
                ),
              ),
              const SizedBox(height: 10),
              NexoraSecondaryButton(
                label: l10n.changeEmail,
                onPressed: () => context.go(Routes.login),
              ),
            ],
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

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.autofocus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 64,
      decoration: BoxDecoration(
        color: focused ? AppColors.cardHi : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.teal.withValues(alpha: 0.6) : AppColors.border,
        ),
        boxShadow: focused
            ? [BoxShadow(color: AppColors.tealBg, blurRadius: 16)]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: _VerifyEmailViewState._length,
        cursorColor: AppColors.teal,
        style: const TextStyle(
          fontSize: 24,
          fontFamily: AppTextStyles.monoFont,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _VerifiedSplash extends StatelessWidget {
  const _VerifiedSplash();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: const Icon(Icons.check_rounded, size: 46, color: AppColors.background),
          ),
          const SizedBox(height: 24),
          Text(l10n.emailVerified, style: AppTextStyles.display(30)),
          const SizedBox(height: 12),
          Text(
            l10n.settingUpDna,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySub,
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.teal,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
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
