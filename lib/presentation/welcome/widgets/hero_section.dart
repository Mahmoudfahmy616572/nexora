import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/dna_visualization.dart';
import '../../../core/widgets/eyebrow_label.dart';
import '../../../core/widgets/trust_item.dart';
import '../../../l10n/app_localizations.dart';

/// Welcome hero: headline + description + trust row (with the DNA visual on
/// desktop, below on tablet/mobile).
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 580),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Expanded(flex: 9, child: _HeroContent()),
            Expanded(flex: 11, child: DnaVisualization()),
          ],
        ),
      );
    }
    return const Column(
      children: [
        _HeroContent(centered: true),
        SizedBox(height: 20),
        DnaVisualization(),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mobile = Breakpoints.isMobile(context);
    final width = MediaQuery.sizeOf(context).width;
    final displaySize = mobile ? 46.0 : (width * 0.05).clamp(52.0, 76.0);
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        EyebrowLabel(text: l10n.welcomeEyebrow),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: AppTextStyles.display(
              displaySize,
              letterSpacing: mobile ? -2 : -3,
            ),
            children: [
              TextSpan(text: '${l10n.welcomeTitleCareer}\n'),
              TextSpan(text: '${l10n.welcomeTitleUnderstood}\n'),
              TextSpan(
                text: l10n.welcomeTitleElevated,
                style: const TextStyle(color: AppColors.brand),
              ),
            ],
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            l10n.welcomeBody,
            style: mobile ? AppTextStyles.descriptionCompact : AppTextStyles.description,
            textAlign: textAlign,
          ),
        ),
        const SizedBox(height: 38),
        _TrustRow(centered: centered),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      TrustItem(
        icon: Icons.diamond_outlined,
        color: AppColors.iconPurple,
        title: l10n.trustPrivateTitle,
        subtitle: l10n.trustPrivateSubtitle,
      ),
      TrustItem(
        icon: Icons.bolt_rounded,
        color: AppColors.iconBlue,
        title: l10n.trustAiTitle,
        subtitle: l10n.trustAiSubtitle,
      ),
      TrustItem(
        icon: Icons.gps_fixed_rounded,
        color: AppColors.iconCyan,
        title: l10n.trustResultsTitle,
        subtitle: l10n.trustResultsSubtitle,
      ),
    ];

    if (Breakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          items[0],
          const SizedBox(height: 16),
          items[1],
          const SizedBox(height: 16),
          items[2],
        ],
      );
    }

    Widget divider() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: SizedBox(width: 1, height: 38, child: ColoredBox(color: AppColors.borderMed)),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final canFitRow = constraints.maxWidth >= 520;
        if (!canFitRow) {
          return Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: items,
          );
        }
        return Row(
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            items[0],
            divider(),
            items[1],
            divider(),
            items[2],
          ],
        );
      },
    );
  }
}
