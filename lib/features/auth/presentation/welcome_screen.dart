import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.5, 1],
          colors: [
            AppColors.background,
            AppColors.backgroundGradientMid,
            AppColors.background,
          ],
        ).createShader(rect),
    );

    void radial(Offset center, double radius, List<Color> colors, List<double> stops) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: colors,
            stops: stops,
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    radial(
      Offset(size.width * 0.72, size.height * 0.32),
      size.width * 0.28,
      const [Color(0x215D2BAA), Colors.transparent],
      const [0, 1],
    );
    radial(
      Offset(size.width * 0.90, size.height * 0.50),
      size.width * 0.30,
      const [Color(0x1A2563EB), Colors.transparent],
      const [0, 1],
    );
    radial(
      Offset(size.width * 0.85, size.height * 0.10),
      math.min(size.width, size.height) * 0.30,
      const [Color(0x407C3AED), Color(0x147C3AED), Colors.transparent],
      const [0, 0.5, 1],
    );
    radial(
      Offset(size.width * 0.95, size.height * 0.80),
      math.min(size.width, size.height) * 0.24,
      const [Color(0x402563EB), Color(0x142563EB), Colors.transparent],
      const [0, 0.5, 1],
    );
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
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BrandLockup(compact: mobile, narrow: narrow),
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
    final mobile = Breakpoints.isMobile(context);
    final width = MediaQuery.sizeOf(context).width;
    final displaySize = mobile ? 46.0 : (width * 0.05).clamp(52.0, 76.0);
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const EyebrowLabel(text: 'Welcome to Nexora'),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: AppTextStyles.display(
              displaySize,
              letterSpacing: mobile ? -2 : -3,
            ),
            children: [
              const TextSpan(text: 'Your Career\n'),
              const TextSpan(text: 'Understood.\n'),
              TextSpan(
                text: 'Elevated.',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: AppColors.headlineGradient,
                    ).createShader(const Rect.fromLTWH(0, 0, 500, 300)),
                ),
              ),
            ],
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'AI-powered career intelligence that understands '
            'who you are, what you want, and how to get you there.',
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
    const items = [
      TrustItem(
        icon: Icons.diamond_outlined,
        color: AppColors.iconPurple,
        title: '100% Private',
        subtitle: 'Your data is secure\nand encrypted',
      ),
      TrustItem(
        icon: Icons.bolt_rounded,
        color: AppColors.iconBlue,
        title: 'AI-Powered',
        subtitle: 'Smart insights that\nsave you time',
      ),
      TrustItem(
        icon: Icons.gps_fixed_rounded,
        color: AppColors.iconCyan,
        title: 'Results-Driven',
        subtitle: 'Get more interviews\nand opportunities',
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
          child: SizedBox(width: 1, height: 38, child: ColoredBox(color: Color(0x2694A0B8))),
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
    final center = Breakpoints.isMobile(context) ? false : true;
    return [
      FeatureTile(
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: const Color(0x4DA855F7),
        title: 'Smart Matching',
        subtitle: 'Find opportunities that\ntruly fit you.',
        center: center,
      ),
      FeatureTile(
        icon: Icons.diamond_outlined,
        iconColor: AppColors.iconBlue,
        borderColor: const Color(0x4D3B82F6),
        title: 'ATS Optimization',
        subtitle: 'Beat the system with\nAI-powered insights.',
        center: center,
      ),
      FeatureTile(
        icon: Icons.developer_board_rounded,
        iconColor: AppColors.iconPurple,
        borderColor: const Color(0x4DA855F7),
        title: 'Interview Ready',
        subtitle: 'Practice with AI and\nbuild your confidence.',
        center: center,
      ),
      FeatureTile(
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.iconCyan,
        borderColor: const Color(0x4D22D3EE),
        title: 'Career Growth',
        subtitle: 'Track progress and\nachieve your goals.',
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
          child: ColoredBox(color: Color(0x2494A0B8)),
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
            gradient: const LinearGradient(
              begin: Alignment(-0.4, -1),
              end: Alignment(1, 1),
              colors: [Color(0xD10E142B), Color(0xC2090F23)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: AppColors.panelShadow, blurRadius: 70, offset: const Offset(0, 20)),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NexoraPrimaryButton(
              label: 'Get Started',
              onPressed: onGetStarted,
              compact: Breakpoints.isMobile(context),
            ),
            const SizedBox(height: 12),
            NexoraSecondaryButton(label: 'I already have an account', onPressed: onSignIn),
            const SizedBox(height: 15),
            const Center(child: PrivacyNote()),
          ],
        ),
      ),
    );
  }
}
