import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/option_card.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/onboarding_choices_cubit.dart';
import 'choice_options.dart';
import 'widgets/choice_layout.dart';

/// Step 2/3 — pick the current career stage, which drives the adaptive intake.
class StageScreen extends StatelessWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = context.watch<OnboardingChoicesCubit>().state.stage;
    return ChoiceLayout(
      title: l10n.stageTitle,
      subtitle: l10n.stageSubtitle,
      progress: 2 / 3,
      onBack: () => context.go(Routes.goal),
      continueEnabled: selected != null,
      onContinue: () => context.go(Routes.field),
      children: [
        for (final stage in allStages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OptionCard(
              title: stageLabel(l10n, stage),
              description: stageDesc(l10n, stage),
              icon: stageIcon(stage),
              selected: selected == stage,
              onTap: () => context.read<OnboardingChoicesCubit>().setStage(stage),
            ),
          ),
      ],
    );
  }
}
