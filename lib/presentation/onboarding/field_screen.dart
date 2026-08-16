import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/option_card.dart';
import '../../../l10n/app_localizations.dart';
import 'cubit/onboarding_choices_cubit.dart';
import 'choice_options.dart';
import 'widgets/choice_layout.dart';

/// Step 3/3 — pick the target field, then hand off to authentication.
class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = context.watch<OnboardingChoicesCubit>().state.targetField;
    return ChoiceLayout(
      title: l10n.fieldTitle,
      subtitle: l10n.fieldSubtitle,
      progress: 1.0,
      onBack: () => context.go(Routes.stage),
      continueEnabled: selected != null,
      continueLabel: l10n.continueLabel,
      onContinue: () => context.go(Routes.login),
      children: [
        for (final field in allFields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionCard(
              title: fieldLabel(l10n, field),
              icon: fieldIcon(field),
              selected: selected == field,
              onTap: () =>
                  context.read<OnboardingChoicesCubit>().setField(field),
            ),
          ),
      ],
    );
  }
}
