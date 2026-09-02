import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/analysis/career_intelligence_engine.dart';
import '../../domain/entities/career_dna.dart';
import '../../domain/entities/career_intelligence.dart';
import '../../domain/entities/profile_data.dart';
import '../../l10n/app_localizations.dart';

String experienceLabel(AppLocalizations l10n, ExperienceStrength value) => switch (value) {
      ExperienceStrength.none => l10n.strengthNone,
      ExperienceStrength.limited => l10n.strengthLimited,
      ExperienceStrength.moderate => l10n.strengthModerate,
      ExperienceStrength.strong => l10n.strengthStrong,
    };

String educationLabel(AppLocalizations l10n, EducationStrength value) => switch (value) {
      EducationStrength.none => l10n.strengthNone,
      EducationStrength.basic => l10n.eduBasic,
      EducationStrength.standard => l10n.eduStandard,
      EducationStrength.strong => l10n.eduStrong,
    };

String readinessLabel(AppLocalizations l10n, ReadinessLevel value) => switch (value) {
      ReadinessLevel.starter => l10n.readinessStarter,
      ReadinessLevel.building => l10n.readinessBuilding,
      ReadinessLevel.strong => l10n.readinessStrong,
      ReadinessLevel.interviewReady => l10n.readinessInterviewReady,
    };

String gapLabel(AppLocalizations l10n, ProfileGap gap) => switch (gap) {
      ProfileGap.targetRole => l10n.gapTargetRole,
      ProfileGap.summary => l10n.gapSummary,
      ProfileGap.skills => l10n.gapSkills,
      ProfileGap.experience => l10n.gapExperience,
      ProfileGap.projects => l10n.gapProjects,
      ProfileGap.education => l10n.gapEducation,
      ProfileGap.certifications => l10n.gapCertifications,
      ProfileGap.achievements => l10n.gapAchievements,
      ProfileGap.languages => l10n.gapLanguages,
      ProfileGap.skillEvidence => l10n.gapSkillEvidence,
    };

/// Deterministic, AI-free readout of the user's Career Intelligence, derived
/// live from their real Career DNA. Acts as the hero of the Career Intelligence
/// surface and complements (never replaces) the evidence-based DNA tab.
class CareerIntelligencePanel extends StatelessWidget {
  const CareerIntelligencePanel({
    super.key,
    required this.dna,
    required this.profile,
    required this.skills,
  });

  final CareerDna dna;
  final ProfileData profile;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intel = computeCareerIntelligence(dna: dna, profile: profile, skills: skills);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderMed),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.purpleBg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.purpleBdr),
                  ),
                  child: const Icon(Icons.insights_rounded, size: 19, color: AppColors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.ciTitle, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        readinessLabel(l10n, intel.readiness),
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
                _Pill(label: '${intel.completeness}%', color: AppColors.teal),
              ],
            ),
            const SizedBox(height: 14),
            _Meter(value: intel.completeness / 100),
            const SizedBox(height: 14),
            _FacetGrid(
              experience: experienceLabel(l10n, intel.experience),
              education: educationLabel(l10n, intel.education),
              direction: intel.hasClearDirection ? l10n.ciClearDirection : l10n.ciNoDirection,
            ),
            if (intel.strongestSkills.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ChipsSection(title: l10n.ciStrongestSkills, items: intel.strongestSkills, color: AppColors.teal),
            ],
            if (intel.supportingSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ChipsSection(title: l10n.ciSupportingSkills, items: intel.supportingSkills, color: AppColors.purple),
            ],
            if (intel.missingInformation.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ChipsSection(
                title: l10n.ciMissingInfo,
                items: [for (final g in intel.missingInformation) gapLabel(l10n, g)],
                color: AppColors.amber,
              ),
            ],
            if (intel.weaknesses.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ChipsSection(
                title: l10n.ciWeaknesses,
                items: [for (final g in intel.weaknesses) gapLabel(l10n, g)],
                color: AppColors.amber,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => context.push('/targets/form'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.ciAddTargetCta, style: AppTextStyles.primaryButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(color: AppColors.border),
              FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.brand),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FacetGrid extends StatelessWidget {
  const _FacetGrid({
    required this.experience,
    required this.education,
    required this.direction,
  });

  final String experience;
  final String education;
  final String direction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _Facet(label: 'Experience', value: experience)),
          const SizedBox(width: 10),
          Expanded(child: _Facet(label: 'Education', value: education)),
          const SizedBox(width: 10),
          Expanded(child: _Facet(label: 'Direction', value: direction)),
        ],
      );
}

class _Facet extends StatelessWidget {
  const _Facet({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontFamily: AppTextStyles.monoFont,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ],
        ),
      );
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.items, required this.color});

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
}
