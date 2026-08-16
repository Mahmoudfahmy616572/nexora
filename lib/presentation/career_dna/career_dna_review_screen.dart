import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../domain/entities/career_dna.dart';
import '../../../domain/entities/intake_question.dart';
import '../../../domain/entities/profile_data.dart';
import '../../../features/main/presentation/main_tab.dart';
import '../../../l10n/app_localizations.dart';
import '../career_dna/cubit/career_dna_cubit.dart';
import 'edit_widgets.dart';

/// Final step of onboarding — review, edit every part of the compiled Career DNA,
/// then save it (version 1) before entering the app. Manual edits are authoritative
/// and are written straight into the draft; the AI never silently overwrites them.
class CareerDnaReviewScreen extends StatefulWidget {
  const CareerDnaReviewScreen({super.key});

  @override
  State<CareerDnaReviewScreen> createState() => _CareerDnaReviewScreenState();
}

class _CareerDnaReviewScreenState extends State<CareerDnaReviewScreen> {
  final _role = TextEditingController();
  final _industry = TextEditingController();
  final _summary = TextEditingController();
  var _saving = false;
  CareerDna? _draft;

  // Structured-list schemas reused by the edit sheets.
  static final List<ListField> _educationSchema = [
    ListField(name: 'degree', inputType: IntakeInputType.shortText, label: (l) => l.intakeDegree),
    ListField(name: 'field', inputType: IntakeInputType.shortText, label: (l) => l.intakeFieldStudy),
  ];
  static final List<ListField> _experienceSchema = [
    ListField(name: 'role', inputType: IntakeInputType.shortText, label: (l) => l.intakePlaceholderRole),
    ListField(name: 'company', inputType: IntakeInputType.shortText, label: (l) => l.intakeCompany),
    ListField(name: 'years', inputType: IntakeInputType.shortText, label: (l) => l.intakeYears),
  ];
  static final List<ListField> _projectSchema = [
    ListField(name: 'name', inputType: IntakeInputType.shortText, label: (l) => l.intakeProjectName),
    ListField(name: 'description', inputType: IntakeInputType.longText, label: (l) => l.intakeProjectDesc),
    ListField(name: 'tech', inputType: IntakeInputType.tags, label: (l) => l.intakeProjectTech),
  ];

  @override
  void initState() {
    super.initState();
    final dna = context.read<CareerDnaCubit>().state.dna;
    if (dna != null) {
      _draft = dna;
      _role.text = dna.targetRole;
      _industry.text = dna.targetIndustry;
      _summary.text = dna.profile.summary;
    }
  }

  @override
  void dispose() {
    _role.dispose();
    _industry.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _editSkills() async {
    final result = await showStringListSheet(
      context,
      title: AppLocalizations.of(context)!.dnaSkills,
      items: _draft!.skills,
      hint: AppLocalizations.of(context)!.intakeSkillsHint,
    );
    if (result != null) setState(() => _draft = _draft!.copyWith(skills: result));
  }

  Future<void> _editEducation() async {
    final result = await showStructListSheet(
      context,
      title: AppLocalizations.of(context)!.dnaEducation,
      schema: _educationSchema,
      items: [
        for (final e in _draft!.profile.education) {'degree': e.degree, 'field': e.field},
      ],
    );
    if (result != null) {
      setState(() => _draft = _draft!.copyWith(
            profile: _draft!.profile.copyWith(
              education: [
                for (final m in result)
                  ProfileEducation(degree: m['degree']?.trim() ?? '', field: m['field']?.trim() ?? ''),
              ].where((e) => e.degree.isNotEmpty || e.field.isNotEmpty).toList(),
            ),
          ));
    }
  }

  Future<void> _editExperience() async {
    final result = await showStructListSheet(
      context,
      title: AppLocalizations.of(context)!.dnaExperience,
      schema: _experienceSchema,
      items: [
        for (final e in _draft!.profile.experience)
          {'role': e.role, 'company': e.company, 'years': e.years.toString()},
      ],
    );
    if (result != null) {
      setState(() => _draft = _draft!.copyWith(
            profile: _draft!.profile.copyWith(
              experience: [
                for (final m in result)
                  ProfileExperience(
                    role: m['role']?.trim() ?? '',
                    company: m['company']?.trim() ?? '',
                    years: int.tryParse((m['years'] ?? '').trim()) ?? 0,
                  ),
              ].where((e) => e.role.isNotEmpty).toList(),
            ),
          ));
    }
  }

  Future<void> _editProjects() async {
    final result = await showStructListSheet(
      context,
      title: AppLocalizations.of(context)!.dnaProjects,
      schema: _projectSchema,
      items: [
        for (final p in _draft!.profile.projects)
          {'name': p.name, 'description': p.description, 'tech': p.tech.join(', ')},
      ],
    );
    if (result != null) {
      setState(() => _draft = _draft!.copyWith(
            profile: _draft!.profile.copyWith(
              projects: [
                for (final m in result)
                  ProfileProject(
                    name: m['name']?.trim() ?? '',
                    description: m['description']?.trim() ?? '',
                    tech: (m['tech'] ?? '')
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                  ),
              ].where((e) => e.name.isNotEmpty).toList(),
            ),
          ));
    }
  }

  Future<void> _editStringList(String title, List<String> items, ValueChanged<List<String>> onSaved) async {
    final result = await showStringListSheet(context, title: title, items: items);
    if (result != null) onSaved(result);
  }

  void _syncText() {
    if (_draft == null) return;
    _draft = _draft!.copyWith(
      targetRole: _role.text.trim(),
      targetIndustry: _industry.text.trim(),
      profile: _draft!.profile.copyWith(summary: _summary.text.trim()),
    );
  }

  Future<void> _save() async {
    if (_saving || _draft == null) return;
    _syncText();
    setState(() => _saving = true);
    context.read<CareerDnaCubit>().updateDraft(_draft!);
    try {
      await context.read<CareerDnaCubit>().save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.dnaSaved)),
      );
      context.go(Routes.main, extra: MainTab.home);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.genericError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_draft == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dnaEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              NexoraPrimaryButton(label: l10n.continueLabel, onPressed: () => context.go(Routes.intake)),
            ],
          ),
        ),
      );
    }

    final dna = _draft!;
    final percent = (dna.completeness * 100).round();
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 720 ? 760.0 : 560.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.go(Routes.interview),
                        ),
                      ),
                      Text(l10n.dnaReviewTitle, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(l10n.dnaReviewSubtitle, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
                      const SizedBox(height: 18),
                      _Completeness(percent: percent, label: l10n.dnaCompleteness),
                      const SizedBox(height: 16),
                      _EditField(label: l10n.dnaTarget, controller: _role, hint: l10n.intakeTargetRoleHint),
                      const SizedBox(height: 12),
                      _EditField(label: l10n.intakeTargetIndustry, controller: _industry, hint: l10n.intakeTargetIndustryHint),
                      const SizedBox(height: 12),
                      _EditField(label: l10n.dnaSummary, controller: _summary, hint: l10n.intakeAboutYouHint, maxLines: 3),
                      const SizedBox(height: 16),
                      _SectionTile(
                        title: l10n.dnaSkills,
                        items: dna.skills,
                        onTap: _editSkills,
                      ),
                      _SectionTile(
                        title: l10n.dnaEducation,
                        items: [for (final e in dna.profile.education) '${e.degree} — ${e.field}'],
                        onTap: _editEducation,
                      ),
                      _SectionTile(
                        title: l10n.dnaExperience,
                        items: [for (final e in dna.profile.experience) '${e.role} — ${e.company}'],
                        onTap: _editExperience,
                      ),
                      _SectionTile(
                        title: l10n.dnaProjects,
                        items: [for (final p in dna.profile.projects) p.name],
                        onTap: _editProjects,
                      ),
                      _SectionTile(
                        title: l10n.dnaCertifications,
                        items: dna.profile.certifications,
                        onTap: () => _editStringList(l10n.dnaCertifications, dna.profile.certifications, (v) {
                          setState(() => _draft = _draft!.copyWith(profile: _draft!.profile.copyWith(certifications: v)));
                        }),
                      ),
                      _SectionTile(
                        title: l10n.dnaAchievements,
                        items: dna.profile.achievements,
                        onTap: () => _editStringList(l10n.dnaAchievements, dna.profile.achievements, (v) {
                          setState(() => _draft = _draft!.copyWith(profile: _draft!.profile.copyWith(achievements: v)));
                        }),
                      ),
                      _SectionTile(
                        title: l10n.dnaLanguages,
                        items: dna.profile.languages,
                        onTap: () => _editStringList(l10n.dnaLanguages, dna.profile.languages, (v) {
                          setState(() => _draft = _draft!.copyWith(profile: _draft!.profile.copyWith(languages: v)));
                        }),
                      ),
                      const SizedBox(height: 22),
                      NexoraPrimaryButton(
                        label: l10n.dnaSaveEnter,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Completeness extends StatelessWidget {
  const _Completeness({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: AppColors.borderViolet,
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(8),
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Text(l10n.dnaScoreFormat(percent), style: AppTextStyles.metric),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.label, required this.controller, this.hint, this.maxLines = 1});

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(label.toUpperCase(),
              style: const TextStyle(fontFamily: AppTextStyles.monoFont, fontSize: 11, letterSpacing: 1, color: AppColors.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            cursorColor: AppColors.violet,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.bodySub,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.title, required this.items, required this.onTap});

  final String title;
  final List<String> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
                  const Icon(Icons.edit_rounded, size: 16, color: AppColors.textSub),
                ],
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Text(l10n.dnaNotAdded, style: AppTextStyles.bodySub)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
                        ),
                        child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
