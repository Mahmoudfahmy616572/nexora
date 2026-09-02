import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../domain/entities/profile_data.dart';
import '../../../domain/profile_generator.dart';
import '../../../features/main/presentation/main_tab.dart';
import '../../../l10n/app_localizations.dart';

/// A guided, tap-first way to build a Career DNA profile without a CV or any
/// prior writing — Nexora drafts the whole profile from a few choices.
class SmartBuilderScreen extends StatefulWidget {
  const SmartBuilderScreen({super.key, required this.onSave});

  final Future<void> Function(ProfileData profile, List<String> skills) onSave;

  @override
  State<SmartBuilderScreen> createState() => _SmartBuilderScreenState();
}

class _SmartBuilderScreenState extends State<SmartBuilderScreen> {

  int _step = 0;
  final Set<Interest> _interests = {};
  final List<String> _customInterests = [];
  final Set<Goal> _goals = {};
  final _sentence = TextEditingController();
  final _customController = TextEditingController();

  List<String> _skills = [];
  List<ProfileExperience> _experience = [];
  List<ProfileProject> _projects = [];
  List<ProfileEducation> _education = [];
  List<String> _certifications = [];
  List<String> _achievements = [];
  List<String> _languages = [];
  final TextEditingController _summary = TextEditingController();

  bool _saving = false;
  bool _generating = false;
  bool _saved = false;

  static const Duration _minGenDelay = Duration(milliseconds: 650);

  /// Example "about me" prompts tailored to the chosen domains, goals, and any
  /// custom domain — so the suggestions always relate to the user's pick.
  List<String> get _prompts => buildSuggestionPrompts(
        interests: _interests,
        customInterests: _customInterests,
        goals: _goals,
      );

  static final Map<Interest, ({IconData icon, Color color, String Function(AppLocalizations) label})> _interestsUi = {
    Interest.programming: (icon: Icons.code_rounded, color: AppColors.teal, label: (l) => l.sbIntProgramming),
    Interest.design: (icon: Icons.brush_rounded, color: AppColors.purple, label: (l) => l.sbIntDesign),
    Interest.writing: (icon: Icons.edit_note_rounded, color: AppColors.amber, label: (l) => l.sbIntWriting),
    Interest.data: (icon: Icons.bar_chart_rounded, color: AppColors.green, label: (l) => l.sbIntData),
    Interest.marketing: (icon: Icons.campaign_rounded, color: AppColors.purple, label: (l) => l.sbIntMarketing),
    Interest.teaching: (icon: Icons.school_rounded, color: AppColors.teal, label: (l) => l.sbIntTeaching),
    Interest.business: (icon: Icons.business_center_rounded, color: AppColors.amber, label: (l) => l.sbIntBusiness),
    Interest.engineering: (icon: Icons.engineering_rounded, color: AppColors.teal, label: (l) => l.sbIntEngineering),
    Interest.medicine: (icon: Icons.medical_services_rounded, color: AppColors.red, label: (l) => l.sbIntMedicine),
    Interest.law: (icon: Icons.gavel_rounded, color: AppColors.purple, label: (l) => l.sbIntLaw),
    Interest.finance: (icon: Icons.account_balance_rounded, color: AppColors.green, label: (l) => l.sbIntFinance),
    Interest.psychology: (icon: Icons.psychology_rounded, color: AppColors.amber, label: (l) => l.sbIntPsychology),
    Interest.photography: (icon: Icons.photo_camera_rounded, color: AppColors.teal, label: (l) => l.sbIntPhotography),
    Interest.music: (icon: Icons.music_note_rounded, color: AppColors.purple, label: (l) => l.sbIntMusic),
    Interest.sports: (icon: Icons.fitness_center_rounded, color: AppColors.green, label: (l) => l.sbIntSports),
    Interest.hospitality: (icon: Icons.room_service_rounded, color: AppColors.amber, label: (l) => l.sbIntHospitality),
    Interest.agriculture: (icon: Icons.eco_rounded, color: AppColors.green, label: (l) => l.sbIntAgriculture),
    Interest.science: (icon: Icons.science_rounded, color: AppColors.teal, label: (l) => l.sbIntScience),
    Interest.sales: (icon: Icons.trending_up_rounded, color: AppColors.green, label: (l) => l.sbIntSales),
  };

  static final Map<Goal, ({IconData icon, Color color, String Function(AppLocalizations) label})> _goalsUi = {
    Goal.internship: (icon: Icons.work_rounded, color: AppColors.teal, label: (l) => l.sbGoalInternship),
    Goal.scholarship: (icon: Icons.school_rounded, color: AppColors.purple, label: (l) => l.sbGoalScholarship),
    Goal.job: (icon: Icons.badge_rounded, color: AppColors.green, label: (l) => l.sbGoalJob),
    Goal.freelance: (icon: Icons.laptop_mac_rounded, color: AppColors.amber, label: (l) => l.sbGoalFreelance),
  };

  @override
  void dispose() {
    _sentence.dispose();
    _customController.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _toggleInterest(Interest i) => setState(
        () => _interests.contains(i) ? _interests.remove(i) : _interests.add(i),
      );

  void _toggleGoal(Goal g) => setState(
        () => _goals.contains(g) ? _goals.remove(g) : _goals.add(g),
      );

  void _addCustom() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    if (_customInterests.any((c) => c.toLowerCase() == value.toLowerCase())) {
      _customController.clear();
      return;
    }
    setState(() => _customInterests.add(value));
    _customController.clear();
  }

  void _removeCustom(int index) => setState(() => _customInterests.removeAt(index));

  void _back() => setState(() => _step -= 1);

  void _next() => setState(() => _step += 1);

  Future<void> _generate() async {
    setState(() => _generating = true);
    final stopwatch = Stopwatch()..start();
    final sentence = _sentence.text.trim().isEmpty ? null : _sentence.text.trim();
    GeneratedProfile result;

    // Prefer the hosted AI builder when Supabase is configured; on any failure
    // (unconfigured, function missing, offline) fall back to the local draft so
    // the flow never blocks the user.
    if (SupabaseConfig.isConfigured) {
      try {
        final remote = CareerRemoteDataSource();
        final data = await remote.runAiProfileBuild({
          'interests': [for (final i in _interests) i.name],
          'customInterests': _customInterests,
          'goals': [for (final g in _goals) g.name],
          'sentence': sentence,
        });
        result = parseAiProfile(data);
      } catch (_) {
        result = _localGenerate(sentence);
      }
    } else {
      result = _localGenerate(sentence);
    }

    // Keep the drafting moment on screen briefly so the transition reads as
    // intentional rather than a jarring instant jump.
    final remaining = _minGenDelay - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    _skills = [...result.skills];
    _experience = [...result.data.experience];
    _projects = [...result.data.projects];
    _education = [...result.data.education];
    _certifications = [...result.data.certifications.map((c) => c.name)];
    _achievements = [...result.data.achievements];
    _languages = [...result.data.languages];
    _summary.text = result.data.summary;
    setState(() {
      _generating = false;
      _step = 3;
    });
  }

  GeneratedProfile _localGenerate(String? sentence) => generateProfile(
        interests: _interests,
        customInterests: _customInterests,
        goals: _goals,
        sentence: sentence,
      );

  ProfileData _currentProfile() => ProfileData(
        summary: _summary.text.trim(),
        experience: _experience,
        projects: _projects,
        education: _education,
        certifications: _certifications.map((s) => ProfileCertification.fromString(s)).toList(),
        achievements: _achievements,
        languages: _languages,
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_currentProfile(), _skills);
    if (!mounted) return;
    // Hand off to the "what's next" view instead of popping — it guides the
    // user to the feature that makes the fresh DNA useful.
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.sbStepEnjoy,
      l10n.sbStepAim,
      l10n.sbStepAbout,
      l10n.sbStepDna,
    ];
    final subtitles = [
      l10n.sbSubEnjoy,
      l10n.sbSubAim,
      l10n.sbSubAbout,
      l10n.sbSubDna,
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _saved
                      ? _Header(
                          step: 3,
                          title: l10n.sbReady,
                          subtitle: l10n.sbReadySub,
                          onBack: null,
                        )
                      : _Header(
                          step: _step,
                          title: titles[_step],
                          subtitle: subtitles[_step],
                          onBack: _step > 0 && _step < 3 ? _back : null,
                        ),
                  Expanded(
                    child: _saved
                        ? _SuccessView(
                            onAnalyze: () => context.go(Routes.main, extra: MainTab.analyze),
                            onStudio: () => context.go(Routes.main, extra: MainTab.studio),
                            onDone: () => Navigator.of(context).pop(),
                          )
                        : _buildStep(),
                  ),
                  _saved
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            ),
                            child: Text(l10n.sbDone, style: AppTextStyles.primaryButton),
                          ),
                        )
                      : _Footer(
                          step: _step,
                          canContinue: _step == 0
                              ? _interests.isNotEmpty || _customInterests.isNotEmpty
                              : _step == 1
                                  ? _goals.isNotEmpty
                                  : true,
                          saving: _saving,
                          generating: _generating,
                          onContinue: _next,
                          onGenerate: _generate,
                          onSave: _save,
                        ),
                ],
              ),
              if (_generating) const _DraftingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: switch (_step) {
        0 => _InterestStep(
              selected: _interests,
              customInterests: _customInterests,
              controller: _customController,
              onToggle: _toggleInterest,
              onAddCustom: _addCustom,
              onRemoveCustom: _removeCustom,
            ),
        1 => _GoalStep(selected: _goals, onToggle: _toggleGoal),
        2 => _SentenceStep(controller: _sentence, examples: _prompts, onExample: (e) => _sentence.text = e),
        _ => _ReviewStep(
            summary: _summary,
            skills: _skills,
            experience: _experience,
            projects: _projects,
            education: _education,
            certifications: _certifications,
            achievements: _achievements,
            languages: _languages,
            onRemoveSkill: (i) => setState(() => _skills.removeAt(i)),
            onRemoveExperience: (i) => setState(() => _experience.removeAt(i)),
            onRemoveProject: (i) => setState(() => _projects.removeAt(i)),
            onRemoveEducation: (i) => setState(() => _education.removeAt(i)),
            onRemoveCert: (i) => setState(() => _certifications.removeAt(i)),
            onRemoveAchievement: (i) => setState(() => _achievements.removeAt(i)),
            onRemoveLanguage: (i) => setState(() => _languages.removeAt(i)),
            onAddString: (list, value) => setState(() => list.add(value)),
          ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.title, required this.subtitle, this.onBack});

  final int step;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSub),
                  visualDensity: VisualDensity.compact,
                )
              else
                const SizedBox(width: 8),
              const Spacer(),
              ...List.generate(4, (i) {
                final active = i <= step;
                return Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: i == step ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active ? AppColors.teal : AppColors.border,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.screenTitle),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.canContinue,
    required this.saving,
    required this.generating,
    required this.onContinue,
    required this.onGenerate,
    required this.onSave,
  });

  final int step;
  final bool canContinue;
  final bool saving;
  final bool generating;
  final VoidCallback onContinue;
  final VoidCallback onGenerate;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (step < 3) {
      final busy = generating;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: FilledButton(
          onPressed: busy ? null : (canContinue ? (step == 2 ? onGenerate : onContinue) : null),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          child: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                )
              : Text(step == 0 ? l10n.sbContinue : step == 1 ? l10n.sbContinue : l10n.sbDraft,
                  style: AppTextStyles.primaryButton),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: FilledButton(
        onPressed: saving ? null : () => onSave(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        child: saving
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 17),
                  const SizedBox(width: 8),
                  Text(l10n.sbSaveDna, style: AppTextStyles.primaryButton),
                ],
              ),
      ),
    );
  }
}

/// Covers the screen with a calm "drafting" moment while Nexora generates the
/// profile — a small delight instead of a bare spinner.
class _DraftingOverlay extends StatefulWidget {
  const _DraftingOverlay();

  @override
  State<_DraftingOverlay> createState() => _DraftingOverlayState();
}

class _DraftingOverlayState extends State<_DraftingOverlay> {
  late final Timer _timer;
  int _dots = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: AppColors.background.withValues(alpha: 0.86),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderMed),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 26, color: AppColors.background),
                ),
                const SizedBox(height: 16),
                Text(
                  '${l10n.sbDrafting}${'.' * _dots}',
                  style: AppTextStyles.primaryButton.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sbDraftingSub,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSub, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after a successful save — guides the user to the feature that makes
/// the fresh DNA useful, so they get value without a dead end.
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.onAnalyze,
    required this.onStudio,
    required this.onDone,
  });

  final VoidCallback onAnalyze;
  final VoidCallback onStudio;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 40, color: AppColors.background),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.sbReady, style: AppTextStyles.display(24), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l10n.sbReadySub,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSub, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 26),
          _NextStepTile(
            icon: Icons.track_changes_rounded,
            title: l10n.sbNextAnalyze,
            subtitle: l10n.sbNextAnalyzeSub,
            onTap: onAnalyze,
          ),
          const SizedBox(height: 12),
          _NextStepTile(
            icon: Icons.description_rounded,
            title: l10n.sbNextCv,
            subtitle: l10n.sbNextCvSub,
            onTap: onStudio,
          ),
          const SizedBox(height: 12),
          _NextStepTile(
            icon: Icons.fingerprint_rounded,
            title: l10n.sbNextExplore,
            subtitle: l10n.sbNextExploreSub,
            onTap: onDone,
          ),
        ],
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMed),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSub)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textSub),
            ],
          ),
        ),
      );
}

class _InterestStep extends StatelessWidget {
  const _InterestStep({
    required this.selected,
    required this.customInterests,
    required this.controller,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  final Set<Interest> selected;
  final List<String> customInterests;
  final TextEditingController controller;
  final void Function(Interest) onToggle;
  final VoidCallback onAddCustom;
  final void Function(int) onRemoveCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in _SmartBuilderScreenState._interestsUi.entries)
              _SelectTile(
                label: entry.value.label(l10n),
                icon: entry.value.icon,
                color: entry.value.color,
                selected: selected.contains(entry.key),
                onTap: () => onToggle(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l10n.sbAddOwn, style: AppTextStyles.bodyMuted),
        const SizedBox(height: 10),
        if (customInterests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < customInterests.length; i++)
                  _DeletableChip(
                    label: customInterests[i],
                    color: AppColors.teal,
                    onDeleted: () => onRemoveCustom(i),
                  ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAddCustom(),
                  style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: l10n.sbCustomHint,
                    hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                onPressed: onAddCustom,
                icon: const Icon(Icons.add_rounded, color: AppColors.teal, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.selected, required this.onToggle});

  final Set<Goal> selected;
  final void Function(Goal) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in _SmartBuilderScreenState._goalsUi.entries)
          _SelectTile(
            label: entry.value.label(l10n),
            icon: entry.value.icon,
            color: entry.value.color,
            selected: selected.contains(entry.key),
            onTap: () => onToggle(entry.key),
          ),
      ],
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppColors.textSub),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentenceStep extends StatelessWidget {
  const _SentenceStep({
    required this.controller,
    required this.examples,
    required this.onExample,
  });

  final TextEditingController controller;
  final List<String> examples;
  final void Function(String) onExample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(fontSize: 14, fontFamily: AppTextStyles.fontFamily, color: AppColors.text, height: 1.5),
            decoration: InputDecoration(
              hintText: l10n.sbSentenceHint,
              hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(l10n.sbInspiration, style: AppTextStyles.bodyMuted),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in examples)
              GestureDetector(
                onTap: () => onExample(example),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.cardHi,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(example, style: AppTextStyles.bodySmall),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.summary,
    required this.skills,
    required this.experience,
    required this.projects,
    required this.education,
    required this.certifications,
    required this.achievements,
    required this.languages,
    required this.onRemoveSkill,
    required this.onRemoveExperience,
    required this.onRemoveProject,
    required this.onRemoveEducation,
    required this.onRemoveCert,
    required this.onRemoveAchievement,
    required this.onRemoveLanguage,
    required this.onAddString,
  });

  final TextEditingController summary;
  final List<String> skills;
  final List<ProfileExperience> experience;
  final List<ProfileProject> projects;
  final List<ProfileEducation> education;
  final List<String> certifications;
  final List<String> achievements;
  final List<String> languages;
  final void Function(int) onRemoveSkill;
  final void Function(int) onRemoveExperience;
  final void Function(int) onRemoveProject;
  final void Function(int) onRemoveEducation;
  final void Function(int) onRemoveCert;
  final void Function(int) onRemoveAchievement;
  final void Function(int) onRemoveLanguage;
  final void Function(List<String>, String) onAddString;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.background, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.sbDraftedBy,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.background),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          label: l10n.sbSummary,
          child: TextField(
            controller: summary,
            maxLines: null,
            style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.text, height: 1.6),
            decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
          ),
        ),
        const SizedBox(height: 12),
        _StringListCard(
          label: l10n.sbSkills,
          items: skills,
          color: AppColors.teal,
          onRemove: onRemoveSkill,
          onAdd: (v) => onAddString(skills, v),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(items: experience, onRemove: onRemoveExperience),
        const SizedBox(height: 12),
        _ProjectCard(items: projects, onRemove: onRemoveProject),
        const SizedBox(height: 12),
        _EducationCard(items: education, onRemove: onRemoveEducation),
        const SizedBox(height: 12),
        _StringListCard(
          label: l10n.sbCertifications,
          items: certifications,
          color: AppColors.purple,
          onRemove: onRemoveCert,
          onAdd: (v) => onAddString(certifications, v),
        ),
        const SizedBox(height: 12),
        _StringListCard(
          label: l10n.sbAchievements,
          items: achievements,
          color: AppColors.amber,
          onRemove: onRemoveAchievement,
          onAdd: (v) => onAddString(achievements, v),
        ),
        const SizedBox(height: 12),
        _StringListCard(
          label: l10n.sbLanguages,
          items: languages,
          color: AppColors.green,
          onRemove: onRemoveLanguage,
          onAdd: (v) => onAddString(languages, v),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StringListCard extends StatelessWidget {
  const _StringListCard({required this.label, required this.items, required this.color, required this.onRemove, required this.onAdd});

  final String label;
  final List<String> items;
  final Color color;
  final void Function(int) onRemove;
  final void Function(String) onAdd;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return _SectionCard(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < items.length; i++)
                _DeletableChip(label: items[i], color: color, onDeleted: () => onRemove(i)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Add $label',
                    hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isNotEmpty) onAdd(v);
                  controller.clear();
                },
                icon: Icon(Icons.add_rounded, color: color, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeletableChip extends StatelessWidget {
  const _DeletableChip({required this.label, required this.color, required this.onDeleted});

  final String label;
  final Color color;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDeleted,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.19)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontFamily: AppTextStyles.monoFont, fontWeight: FontWeight.w500, color: color)),
            const SizedBox(width: 5),
            Icon(Icons.close_rounded, size: 13, color: color),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.items, required this.onRemove});

  final List<ProfileExperience> items;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      label: l10n.sbExperience,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].role.isEmpty ? l10n.sbPlaceholderRole : items[i].role, style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(
                          '${items[i].company}${items[i].durationLabel.isNotEmpty ? ' · ${items[i].durationLabel}' : ''}',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => onRemove(i), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.items, required this.onRemove});

  final List<ProfileProject> items;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      label: l10n.sbProjects,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].name.isEmpty ? l10n.sbPlaceholderProject : items[i].name, style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(items[i].description, style: AppTextStyles.bodyMuted.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => onRemove(i), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.items, required this.onRemove});

  final List<ProfileEducation> items;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      label: l10n.sbEducation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].degree.isEmpty ? l10n.sbPlaceholderDegree : items[i].degree, style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(items[i].field, style: AppTextStyles.bodyMuted),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => onRemove(i), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
