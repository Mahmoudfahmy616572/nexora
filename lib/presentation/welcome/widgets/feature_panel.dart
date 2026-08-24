import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/feature_tile.dart';
import '../../../l10n/app_localizations.dart';

/// Feature strip panel (Smart Matching · ATS Optimization · Interview Ready ·
/// Career Growth) with responsive row / grid / column layouts.
class WelcomeFeaturePanel extends StatelessWidget {
  const WelcomeFeaturePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final center = Breakpoints.isMobile(context) ? false : true;
    final tiles = [
      FeatureTile(
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: AppColors.iconPurple.withValues(alpha: 0.35),
        title: l10n.featureMatchingTitle,
        subtitle: l10n.featureMatchingSubtitle,
        center: center,
      ),
      FeatureTile(
        icon: Icons.diamond_outlined,
        iconColor: AppColors.iconBlue,
        borderColor: AppColors.iconBlue.withValues(alpha: 0.35),
        title: l10n.featureAtsTitle,
        subtitle: l10n.featureAtsSubtitle,
        center: center,
      ),
      FeatureTile(
        icon: Icons.developer_board_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: AppColors.iconPurple.withValues(alpha: 0.35),
        title: l10n.featureInterviewTitle,
        subtitle: l10n.featureInterviewSubtitle,
        center: center,
      ),
      FeatureTile(
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.iconCyan,
        borderColor: AppColors.iconCyan.withValues(alpha: 0.35),
        title: l10n.featureGrowthTitle,
        subtitle: l10n.featureGrowthSubtitle,
        center: center,
      ),
    ];

    Widget separator() => const SizedBox(
          width: 1,
          height: 52,
          child: ColoredBox(color: AppColors.borderMed),
        );

    final child = Breakpoints.isDesktop(context)
        ? Row(
            children: [
              Expanded(child: tiles[0]),
              separator(),
              Expanded(child: tiles[1]),
              separator(),
              Expanded(child: tiles[2]),
              separator(),
              Expanded(child: tiles[3]),
            ],
          )
        : Breakpoints.isTablet(context)
            ? Column(
                children: [
                  Row(children: [Expanded(child: tiles[0]), Expanded(child: tiles[1])]),
                  const SizedBox(height: 25),
                  Row(children: [Expanded(child: tiles[2]), Expanded(child: tiles[3])]),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tiles[0],
                  const SizedBox(height: 18),
                  tiles[1],
                  const SizedBox(height: 18),
                  tiles[2],
                  const SizedBox(height: 18),
                  tiles[3],
                ],
              );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: AppColors.panelShadow, blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
