import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_chip.dart';
import 'widgets/progress_bar.dart';
import 'widgets/section_label.dart';

/// CV Studio — mirrors the design's Studio screen.
class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StudioHeader(),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('My CVs (3)'),
                for (final cv in _CvModel.all) _CvCard(cv: cv),
                const SizedBox(height: 6),
                const _CvBattleHint(),
                const SizedBox(height: 14),
                const SectionLabel('Templates'),
                const _TemplateStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CvModel {
  const _CvModel({
    required this.title,
    required this.ats,
    required this.purpose,
    required this.updated,
    required this.match,
    this.best = false,
  });

  final String title;
  final int ats;
  final String purpose;
  final String updated;
  final int match;
  final bool best;

  Color get atsColor => ats >= 90 ? AppColors.teal : ats >= 80 ? AppColors.amber : AppColors.red;

  static const List<_CvModel> all = [
    _CvModel(title: 'Flutter Engineer', ats: 89, purpose: 'Job', updated: 'Aug 8', match: 82),
    _CvModel(title: 'Software Engineer', ats: 91, purpose: 'Job', updated: 'Aug 7', match: 88, best: true),
    _CvModel(title: "Master's Application", ats: 76, purpose: 'Academic', updated: 'Aug 5', match: 74),
  ];
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('CV Studio', style: AppTextStyles.screenTitle),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 13, color: AppColors.background),
                SizedBox(width: 6),
                Text(
                  'New CV',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({required this.cv});

  final _CvModel cv;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cv.best ? AppColors.tealBdr : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cv.best)
            Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.signatureGradient))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cv.title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        if (cv.best) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppChip(label: cv.purpose, color: AppColors.purple, size: 9),
                        const SizedBox(width: 6),
                        Text('Updated ${cv.updated}', style: AppTextStyles.mono.copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${cv.ats}',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: AppTextStyles.monoFont,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: cv.atsColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('ATS SCORE', style: TextStyle(fontSize: 8, fontFamily: AppTextStyles.monoFont, letterSpacing: 0.8, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(label: 'ATS Compatibility', value: cv.ats.toDouble(), color: cv.atsColor),
          const Row(
            children: [
              Expanded(child: _ActionButton(icon: Icons.visibility_outlined, label: 'Preview', color: AppColors.textSub, bg: AppColors.cardHi, border: AppColors.border)),
              SizedBox(width: 8),
              Expanded(child: _ActionButton(icon: Icons.bolt_rounded, label: 'Optimize', color: AppColors.teal, bg: AppColors.tealBg, border: AppColors.tealBdr)),
              SizedBox(width: 8),
              Expanded(child: _ActionButton(icon: Icons.edit_outlined, label: 'Edit', color: AppColors.purple, bg: AppColors.purpleBg, border: AppColors.purpleBdr)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.color, required this.bg, required this.border});

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _CvBattleHint extends StatelessWidget {
  const _CvBattleHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purpleBdr),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚔ CV Battle',
                style: TextStyle(fontSize: 12, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w600, color: AppColors.purple),
              ),
              SizedBox(height: 2),
              Text('Compare versions against a target role', style: AppTextStyles.bodySmall),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.purple),
        ],
      ),
    );
  }
}

class _TemplateStrip extends StatelessWidget {
  const _TemplateStrip();

  static const _templates = [
    ('ATS Minimal', AppColors.teal),
    ('Modern Pro', AppColors.purple),
    ('Academic', AppColors.amber),
    ('Tech', AppColors.green),
    ('Executive', Color(0xFFE879F9)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (name, color) = _templates[i];
          return Column(
            children: [
              Container(
                width: 88,
                height: 110,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 3, color: color),
                    const SizedBox(height: 5),
                    Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _line(0.9),
                    _line(0.6),
                    _line(0.75),
                    const SizedBox(height: 5),
                    Container(height: 1, color: color.withValues(alpha: 0.2)),
                    const SizedBox(height: 5),
                    _line(0.8),
                    _line(0.5),
                    _line(0.7),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(name, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, height: 1.3)),
            ],
          );
        },
      ),
    );
  }

  Widget _line(double width) => Container(
        height: 2,
        width: 74 * width,
        margin: const EdgeInsets.only(bottom: 3),
        color: AppColors.border,
      );
}
