import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/eyebrow_label.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../main/presentation/widgets/app_chip.dart';
import '../../main/presentation/widgets/progress_ring.dart';

/// Pre-auth onboarding carousel — three product-benefit slides with phone
/// mock shots built from the app's own primitives.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

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
    final slides = _OnboardingSlide.slidesFor(l10n);
    final isLast = _page == slides.length - 1;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                showSkip: !isLast,
                onSkip: () => context.go(Routes.login),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => slides[i],
                ),
              ),
              _Dots(count: slides.length, current: _page),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NexoraPrimaryButton(
                      label: isLast ? l10n.onbCreateDna : l10n.onbNext,
                      onPressed: isLast ? () => context.go(Routes.login) : _next,
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    NexoraSecondaryButton(
                      label: l10n.onbAlreadyAccount,
                      onPressed: () => context.go(Routes.login),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showSkip, required this.onSkip});

  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          const BrandLockup(compact: true),
          const Spacer(),
          if (showSkip)
            GestureDetector(
              onTap: onSkip,
              child: Text(
                l10n.onbSkip,
                style: const TextStyle(
                  fontFamily: AppTextStyles.monoFont,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: AppColors.textSub,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: i == current ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current ? AppColors.teal : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.titleLead,
    required this.titleAccent,
    required this.body,
    required this.scene,
  });

  final String eyebrow;
  final String titleLead;
  final String titleAccent;
  final String body;
  final Widget scene;

  static List<_OnboardingSlide> slidesFor(AppLocalizations l10n) => [
        _OnboardingSlide(
          eyebrow: l10n.onbSlide1Eyebrow,
          titleLead: l10n.onbSlide1Lead,
          titleAccent: l10n.onbSlide1Accent,
          body: l10n.onbSlide1Body,
          scene: const _MatchScene(),
        ),
        _OnboardingSlide(
          eyebrow: l10n.onbSlide2Eyebrow,
          titleLead: l10n.onbSlide2Lead,
          titleAccent: l10n.onbSlide2Accent,
          body: l10n.onbSlide2Body,
          scene: const _CvScene(),
        ),
        _OnboardingSlide(
          eyebrow: l10n.onbSlide3Eyebrow,
          titleLead: l10n.onbSlide3Lead,
          titleAccent: l10n.onbSlide3Accent,
          body: l10n.onbSlide3Body,
          scene: const _PipelineScene(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    final titleSize = mobile ? 30.0 : 42.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: mobile ? 10 : 26),
          Center(
            child: SizedBox(
              width: 240,
              height: 340,
              child: scene,
            ),
          ),
          SizedBox(height: mobile ? 24 : 34),
          Center(child: EyebrowLabel(text: eyebrow)),
          Center(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.display(titleSize),
                children: [
                  TextSpan(text: titleLead),
                  TextSpan(
                    text: titleAccent,
                    style: TextStyle(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: AppColors.headlineGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(const Rect.fromLTWH(0, 0, 420, 300)),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: mobile
                    ? AppTextStyles.descriptionCompact
                    : AppTextStyles.description,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.phone, required this.badge, required this.glow});

  final Widget phone;
  final Widget badge;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -40,
            right: -40,
            bottom: -30,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                gradient: RadialGradient(
                  colors: [glow.withValues(alpha: 0.18), glow.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 5,
            top: 14,
            right: 5,
            child: phone,
          ),
          Positioned(top: -8, right: -2, child: badge),
        ],
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 350,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.cardHi],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderMed),
        boxShadow: [
          BoxShadow(
            color: AppColors.panelShadow,
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MockHeader extends StatelessWidget {
  const _MockHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.signatureGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: const Icon(Icons.bolt_rounded, size: 11, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.monoFont,
              fontSize: 8,
              letterSpacing: 1.2,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.mono.copyWith(fontSize: 8)),
              Text(
                '${value.round()}%',
                style: AppTextStyles.mono.copyWith(fontSize: 8, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              color: color,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.monoFont,
          fontSize: 9,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MatchScene extends StatelessWidget {
  const _MatchScene();

  @override
  Widget build(BuildContext context) {
    return _Scene(
      glow: AppColors.teal,
      badge: const _FloatingBadge(label: '91% MATCH', color: AppColors.teal),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'OPPORTUNITY MATCH'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressRing(
                  value: 91,
                  size: 84,
                  stroke: 7,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('91%', style: AppTextStyles.metric.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      const Text(
                        'MATCH',
                        style: TextStyle(
                          fontFamily: AppTextStyles.monoFont,
                          fontSize: 6,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Flutter Engineer', style: AppTextStyles.cardTitleSmall),
                      const SizedBox(height: 3),
                      const Text('Careem · Dubai 🇦🇪', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 10),
                      const AppChip(label: 'Strong ✓', color: AppColors.teal, size: 8),
                      const SizedBox(height: 6),
                      const AppChip(label: 'Missing ✗', color: AppColors.red, size: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _MiniBar(label: 'SKILLS', value: 91, color: AppColors.teal),
            const _MiniBar(label: 'EXPERIENCE', value: 76, color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}

class _CvScene extends StatelessWidget {
  const _CvScene();

  @override
  Widget build(BuildContext context) {
    return _Scene(
      glow: AppColors.purple,
      badge: const _FloatingBadge(label: '+3 ATS', color: AppColors.purple),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'CV STUDIO'),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purpleBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.purpleBdr),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'ATS SCORE',
                        style: TextStyle(
                          fontFamily: AppTextStyles.monoFont,
                          fontSize: 7,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('92', style: AppTextStyles.metric),
                      SizedBox(height: 4),
                      Text(
                        'TOP 10%',
                        style: TextStyle(
                          fontFamily: AppTextStyles.monoFont,
                          fontSize: 7,
                          letterSpacing: 0.8,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flutter Engineer', style: AppTextStyles.cardTitleSmall),
                      SizedBox(height: 3),
                      Text('Updated today', style: AppTextStyles.bodySmall),
                      SizedBox(height: 10),
                      AppChip(label: 'AI REWRITE ✓', color: AppColors.purple, size: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DocLine(widthFactor: 1),
                  SizedBox(height: 6),
                  _DocLine(widthFactor: 0.72),
                  SizedBox(height: 6),
                  _DocLine(widthFactor: 0.88),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const AppChip(label: 'OPTIMIZE', color: AppColors.teal, size: 8),
                const Spacer(),
                _TemplateDot(color: AppColors.teal),
                const SizedBox(width: 6),
                _TemplateDot(color: AppColors.purple),
                const SizedBox(width: 6),
                _TemplateDot(color: AppColors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocLine extends StatelessWidget {
  const _DocLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderMed,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _TemplateDot extends StatelessWidget {
  const _TemplateDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, width: 12, color: color),
          const SizedBox(height: 3),
          Container(height: 2, width: 16, color: AppColors.borderMed),
          const SizedBox(height: 2),
          Container(height: 2, width: 10, color: AppColors.borderMed),
        ],
      ),
    );
  }
}

class _PipelineScene extends StatelessWidget {
  const _PipelineScene();

  @override
  Widget build(BuildContext context) {
    return _Scene(
      glow: AppColors.green,
      badge: const _FloatingBadge(label: 'ON TRACK', color: AppColors.green),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MockHeader(title: 'APPLICATIONS'),
            const SizedBox(height: 16),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: Row(
                children: [
                  Expanded(flex: 3, child: SizedBox(height: 8, child: ColoredBox(color: AppColors.teal))),
                  Expanded(flex: 2, child: SizedBox(height: 8, child: ColoredBox(color: AppColors.purple))),
                  Expanded(flex: 1, child: SizedBox(height: 8, child: ColoredBox(color: AppColors.green))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MockAppRow(
              company: 'Google',
              date: 'Aug 17 · Interview',
              status: 'HR ROUND',
              icon: Icons.work_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(height: 8),
            _MockAppRow(
              company: 'Noon',
              date: 'Aug 1 · Offer',
              status: 'OFFER 🎉',
              icon: Icons.emoji_events_rounded,
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            _MockAppRow(
              company: 'Meta',
              date: 'Aug 24 · Applied',
              status: '91% MATCH',
              icon: Icons.track_changes_rounded,
              color: AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _MockAppRow extends StatelessWidget {
  const _MockAppRow({
    required this.company,
    required this.date,
    required this.status,
    required this.icon,
    required this.color,
  });

  final String company;
  final String date;
  final String status;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(date, style: AppTextStyles.mono.copyWith(fontSize: 7)),
              ],
            ),
          ),
          AppChip(label: status, color: color, size: 7),
        ],
      ),
    );
  }
}
