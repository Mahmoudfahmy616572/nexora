import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../l10n/app_localizations.dart';

/// Onboarding top bar with the brand lockup and a skip action.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key, required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          const BrandLockup(compact: true),
          const Spacer(),
          if (showSkip)
            GestureDetector(
              onTap: onSkip,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  AppLocalizations.of(context)!.onboardingSkip,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.monoFont,
                    fontSize: 12,
                    letterSpacing: 1.4,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
