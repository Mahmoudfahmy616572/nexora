import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/eyebrow_label.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../l10n/app_localizations.dart';

/// One onboarding slide: eyebrow + display title + body above a mock scene.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
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
                    style: const TextStyle(color: AppColors.brand),
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

/// Convenience: builds the three slides from the active localization.
List<OnboardingSlide> buildOnboardingSlides(AppLocalizations l10n) => [
      OnboardingSlide(
        eyebrow: l10n.onboardingSlide1Eyebrow,
        titleLead: l10n.onboardingSlide1TitleLead,
        titleAccent: l10n.onboardingSlide1TitleAccent,
        body: l10n.onboardingSlide1Body,
        scene: const MatchScene(),
      ),
      OnboardingSlide(
        eyebrow: l10n.onboardingSlide2Eyebrow,
        titleLead: l10n.onboardingSlide2TitleLead,
        titleAccent: l10n.onboardingSlide2TitleAccent,
        body: l10n.onboardingSlide2Body,
        scene: const CvScene(),
      ),
      OnboardingSlide(
        eyebrow: l10n.onboardingSlide3Eyebrow,
        titleLead: l10n.onboardingSlide3TitleLead,
        titleAccent: l10n.onboardingSlide3TitleAccent,
        body: l10n.onboardingSlide3Body,
        scene: const PipelineScene(),
      ),
    ];

// -----------------------------------------------------------------------------
// Scene scaffolding
// -----------------------------------------------------------------------------

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
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -40,
            right: -40,
            bottom: -30,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(90),
                color: glow.withValues(alpha: 0.12),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderMed),
        boxShadow: [
          BoxShadow(
            color: AppColors.panelShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
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
          decoration: BoxDecoration(
            color: AppColors.brand,
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

// -----------------------------------------------------------------------------
// Slide 1 — Opportunity match
// -----------------------------------------------------------------------------

class MatchScene extends StatelessWidget {
  const MatchScene({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Scene(
      glow: AppColors.teal,
      badge: _FloatingBadge(label: l10n.mockMatchBadge, color: AppColors.teal),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockHeader(title: l10n.mockOpportunityMatch),
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
                      Text(
                        l10n.mockMatch,
                        style: const TextStyle(
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
                      AppChip(label: l10n.mockStrong, color: AppColors.teal, size: 8),
                      const SizedBox(height: 6),
                      AppChip(label: l10n.mockMissing, color: AppColors.red, size: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MiniBar(label: l10n.mockSkills, value: 91, color: AppColors.teal),
            _MiniBar(label: l10n.mockExperience, value: 76, color: AppColors.purple),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Slide 2 — CV Studio
// -----------------------------------------------------------------------------

class CvScene extends StatelessWidget {
  const CvScene({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Scene(
      glow: AppColors.purple,
      badge: const _FloatingBadge(label: '+3 ATS', color: AppColors.purple),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockHeader(title: l10n.studioTitle.toUpperCase()),
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
                  child: Column(
                    children: [
                      Text(
                        l10n.mockAtsScore,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.monoFont,
                          fontSize: 7,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('92', style: AppTextStyles.metric),
                      const SizedBox(height: 4),
                      Text(
                        l10n.mockTop10,
                        style: const TextStyle(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Flutter Engineer', style: AppTextStyles.cardTitleSmall),
                      const SizedBox(height: 3),
                      Text(l10n.mockUpdatedToday, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 10),
                      AppChip(label: l10n.mockAiRewrite, color: AppColors.purple, size: 8),
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
                AppChip(label: l10n.mockOptimize, color: AppColors.teal, size: 8),
                const Spacer(),
                const _TemplateDot(color: AppColors.teal),
                const SizedBox(width: 6),
                const _TemplateDot(color: AppColors.purple),
                const SizedBox(width: 6),
                const _TemplateDot(color: AppColors.amber),
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

// -----------------------------------------------------------------------------
// Slide 3 — Pipeline
// -----------------------------------------------------------------------------

class PipelineScene extends StatelessWidget {
  const PipelineScene({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Scene(
      glow: AppColors.green,
      badge: _FloatingBadge(label: l10n.mockOnTrack, color: AppColors.green),
      phone: _PhoneFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockHeader(title: l10n.mockApplications),
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
              date: 'Aug 17',
              status: l10n.mockHrRound,
              icon: Icons.work_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(height: 8),
            _MockAppRow(
              company: 'Noon',
              date: 'Aug 1',
              status: l10n.mockStatusOffer,
              icon: Icons.emoji_events_rounded,
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            _MockAppRow(
              company: 'Meta',
              date: 'Aug 24',
              status: l10n.mockStatusApplied,
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
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  '$date · ${l10n.mockStatusInterview}',
                  style: AppTextStyles.mono.copyWith(fontSize: 7),
                ),
              ],
            ),
          ),
          AppChip(label: status, color: color, size: 7),
        ],
      ),
    );
  }
}
