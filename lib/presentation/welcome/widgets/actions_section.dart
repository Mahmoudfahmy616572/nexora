import 'package:flutter/material.dart';

import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../core/widgets/privacy_note.dart';
import '../../../l10n/app_localizations.dart';

/// Welcome CTAs: Get Started + sign-in link + privacy note.
class WelcomeActions extends StatelessWidget {
  const WelcomeActions({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NexoraPrimaryButton(
              label: l10n.getStarted,
              onPressed: onGetStarted,
              compact: Breakpoints.isMobile(context),
            ),
            const SizedBox(height: 12),
            NexoraSecondaryButton(label: l10n.haveAccount, onPressed: onSignIn),
            const SizedBox(height: 15),
            const Center(child: PrivacyNote()),
          ],
        ),
      ),
    );
  }
}
