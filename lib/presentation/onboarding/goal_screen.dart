import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/option_card.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/onboarding_choices_cubit.dart';
import 'choice_options.dart';
import 'widgets/choice_layout.dart';

/// Step 1/3 — pick the goal that brought the user to Nexora.
class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = context.watch<OnboardingChoicesCubit>().state.goal;
    return ChoiceLayout(
      title: l10n.goalTitle,
      subtitle: l10n.goalSubtitle,
      progress: 1 / 3,
      continueEnabled: selected != null,
      onContinue: () => context.go(Routes.stage),
      footerNote: Text(
        l10n.changeLater,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
      children: [
        for (final goal in allGoals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OptionCard(
              title: goalLabel(l10n, goal),
              description: goalDesc(l10n, goal),
              icon: goalIcon(goal),
              selected: selected == goal,
              onTap: () => context.read<OnboardingChoicesCubit>().setGoal(goal),
            ),
          ),
      ],
    );
  }
}
