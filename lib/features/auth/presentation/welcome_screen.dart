import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/dna_visualization.dart';
import '../../../core/widgets/eyebrow_label.dart';
import '../../../core/widgets/feature_tile.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../core/widgets/privacy_note.dart';
import '../../../core/widgets/trust_item.dart';

/// Welcome / landing — pre-auth gate (Screen 1 of the approved design).
///
/// Fully responsive: two-column hero on desktop, stacked on tablet/mobile.
/// The whole page scrolls so content can never overflow.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _WelcomeBackgroundPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: AppBreakpointValues.of<EdgeInsets>(
                    context,
                    mobile: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                    desktop: const EdgeInsets.fromLTRB(46, 34, 46, 30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 24),
                      const _Hero(),
                      const SizedBox(height: 24),
                      const _FeaturePanel(),
                      const SizedBox(height: 22),
                      _Actions(
                        onGetStarted: () => context.go(Routes.onboarding),
                        onSignIn: () => context.go(Routes.login),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _WelcomeBackgroundPainter extends CustomPainter {
  const _WelcomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(covariant _WelcomeBackgroundPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: BrandLockup(compact: mobile, narrow: narrow)),
        LanguageSelector(compact: mobile),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Hero
// -----------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

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
              TextSpan(text: l10n.welcomeCareer),
              TextSpan(text: l10n.welcomeUnderstood),
              TextSpan(
                text: l10n.welcomeElevated,
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
        title: l10n.welcomePrivateTitle,
        subtitle: l10n.welcomePrivateSub,
      ),
      TrustItem(
        icon: Icons.bolt_rounded,
        color: AppColors.iconBlue,
        title: l10n.welcomeAiTitle,
        subtitle: l10n.welcomeAiSub,
      ),
      TrustItem(
        icon: Icons.gps_fixed_rounded,
        color: AppColors.iconCyan,
        title: l10n.welcomeResultsTitle,
        subtitle: l10n.welcomeResultsSub,
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

// -----------------------------------------------------------------------------
// Feature panel
// -----------------------------------------------------------------------------

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel();

  List<Widget> _tiles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final center = Breakpoints.isMobile(context) ? false : true;
    return [
      FeatureTile(
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: AppColors.iconPurple.withValues(alpha: 0.35),
        title: l10n.welcomeMatchingTitle,
        subtitle: l10n.welcomeMatchingSub,
        center: center,
      ),
      FeatureTile(
        icon: Icons.diamond_outlined,
        iconColor: AppColors.iconBlue,
        borderColor: AppColors.iconBlue.withValues(alpha: 0.35),
        title: l10n.welcomeAtsTitle,
        subtitle: l10n.welcomeAtsSub,
        center: center,
      ),
      FeatureTile(
        icon: Icons.developer_board_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: AppColors.iconPurple.withValues(alpha: 0.35),
        title: l10n.welcomeInterviewTitle,
        subtitle: l10n.welcomeInterviewSub,
        center: center,
      ),
      FeatureTile(
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.iconCyan,
        borderColor: AppColors.iconCyan.withValues(alpha: 0.35),
        title: l10n.welcomeGrowthTitle,
        subtitle: l10n.welcomeGrowthSub,
        center: center,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles(context);
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

// -----------------------------------------------------------------------------
// Actions
// -----------------------------------------------------------------------------

class _Actions extends StatelessWidget {
  const _Actions({required this.onGetStarted, required this.onSignIn});

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
              label: l10n.welcomeGetStarted,
              onPressed: onGetStarted,
              compact: Breakpoints.isMobile(context),
            ),
            const SizedBox(height: 12),
            NexoraSecondaryButton(label: l10n.welcomeAlreadyAccount, onPressed: onSignIn),
            const SizedBox(height: 15),
            const Center(child: PrivacyNote()),
          ],
        ),
      ),
    );
  }
}
