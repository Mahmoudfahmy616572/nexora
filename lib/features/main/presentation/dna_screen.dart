import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_chip.dart';
import 'widgets/section_row.dart';

/// Career DNA screen — mirrors the design's DNA screen.
class DnaScreen extends StatelessWidget {
  const DnaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DnaHeader(),
          SizedBox(height: 4),
          _CompletenessCard(),
          SizedBox(height: 14),
          _EvidenceNote(),
          SizedBox(height: 14),
          _ProfileSections(),
        ],
      ),
    );
  }
}

class _DnaHeader extends StatelessWidget {
  const _DnaHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Career DNA', style: AppTextStyles.screenTitle),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tealBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.tealBdr),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: AppColors.teal),
                SizedBox(width: 6),
                Text(
                  'AI Interview',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
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

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DNA COMPLETENESS', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 6),
                  Text('82%', style: AppTextStyles.metric.copyWith(fontSize: 32, height: 1)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AppChip(label: '2 Sections Need Work', color: AppColors.amber),
                  const SizedBox(height: 6),
                  Text(
                    'Achievements · 62%\nExperience · 80%',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySub.copyWith(fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(color: AppColors.border),
                  FractionallySizedBox(
                    widthFactor: 0.82,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.signatureGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: AppTextStyles.mono),
              Text('82% · Target 95%', style: TextStyle(fontSize: 10, fontFamily: AppTextStyles.monoFont, color: AppColors.teal)),
              Text('100%', style: AppTextStyles.mono),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceNote extends StatelessWidget {
  const _EvidenceNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purpleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purpleBdr),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodySub.copyWith(fontSize: 11, height: 1.45),
                children: [
                  TextSpan(text: 'Your profile is '),
                  TextSpan(
                    text: 'evidence-based',
                    style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                      text: ' — the AI will never fabricate experience or skills. Only verified claims are used.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSections extends StatelessWidget {
  const _ProfileSections();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('PROFILE SECTIONS', style: AppTextStyles.sectionLabel),
          ),
          const SectionRow(icon: Icons.person_rounded, label: 'Personal Profile', pct: 100),
          const SectionRow(icon: Icons.school_rounded, label: 'Education', pct: 95),
          const SectionRow(icon: Icons.work_rounded, label: 'Experience', pct: 80, color: AppColors.purple),
          const SectionRow(icon: Icons.code_rounded, label: 'Projects', pct: 90),
          const SectionRow(icon: Icons.bolt_rounded, label: 'Skills · 42 entries', pct: 88, color: AppColors.purple),
          const SectionRow(icon: Icons.menu_book_rounded, label: 'Certifications', pct: 100),
          const SectionRow(icon: Icons.emoji_events_rounded, label: 'Achievements', pct: 62, color: AppColors.amber),
          const SectionRow(icon: Icons.language_rounded, label: 'Languages', pct: 100),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 13, color: AppColors.textMuted),
                  SizedBox(width: 7),
                  Text(
                    'Add Volunteering · Publications · Courses',
                    style: TextStyle(fontSize: 12, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
