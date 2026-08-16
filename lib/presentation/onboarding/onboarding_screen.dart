import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/nexora_buttons.dart';
import '../../l10n/app_localizations.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';
import 'widgets/onboarding_progress.dart';
import 'widgets/slides.dart';
import 'widgets/top_bar.dart';

/// Pre-auth onboarding carousel — three product-benefit slides with phone
/// mock shots built from the app's own primitives.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = buildOnboardingSlides(l10n);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              final isLast = state.isLast;
              return Column(
                children: [
                  OnboardingTopBar(
                    showSkip: !isLast,
                    onSkip: () => context.go(Routes.login),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: slides.length,
                      onPageChanged: context.read<OnboardingCubit>().onPageChanged,
                      itemBuilder: (context, i) => slides[i],
                    ),
                  ),
                  OnboardingProgress(count: slides.length, current: state.page),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NexoraPrimaryButton(
                          label: isLast ? l10n.onboardingCreateDna : l10n.onboardingNext,
                          onPressed: isLast
                              ? () => context.go(Routes.login)
                              : _next,
                          compact: true,
                        ),
                        const SizedBox(height: 10),
                        NexoraSecondaryButton(
                          label: l10n.haveAccount,
                          onPressed: () => context.go(Routes.login),
                        ),
                      ],
                    ),
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
