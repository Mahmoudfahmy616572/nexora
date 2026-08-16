import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_cubit.dart';
import '../../../domain/entities/app_language.dart';
import '../../../domain/entities/career_dna.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../domain/entities/profile_data.dart';
import '../../../domain/entities/profile_section.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/profile_section_repository.dart';
import '../../../domain/repositories/profile_skills_repository.dart';
import '../../../presentation/career_dna/cubit/career_dna_cubit.dart';
import '../../../presentation/onboarding/choice_options.dart';
import 'smart_builder_screen.dart';
import 'widgets/app_chip.dart';
import 'widgets/section_row.dart';

/// Which real profile dataset a base section edits (null = user-added).
enum _SectionKind {
  summary,
  education,
  experience,
  projects,
  certifications,
  achievements,
  languages,
  skills,
}

/// Career DNA screen — mirrors the design's DNA screen.
///
/// Every base section is backed by the user's real profile data: tapping one
/// opens a live editor (summary, experience, projects, certifications,
/// achievements, languages, skills) whose content feeds the AI match scoring
/// on the Analyze tab. User-added sections persist too (Supabase online,
/// SharedPreferences offline).
class DnaScreen extends StatefulWidget {
  const DnaScreen({super.key});

  @override
  State<DnaScreen> createState() => _DnaScreenState();
}

class _DnaSection {
  const _DnaSection({
    required this.icon,
    required this.label,
    required this.pct,
    this.color = AppColors.teal,
    this.categoryCode = '',
    this.id = '',
    this.kind,
  });

  final IconData icon;
  final String label;
  final double pct;
  final Color color;

  /// Persistence code for user-added sections ('v' | 'p' | 'c'); '' for base.
  final String categoryCode;

  /// Stable identity for persisted sections.
  final String id;

  /// Which profile dataset this section edits; null for user-added sections.
  final _SectionKind? kind;

  _DnaSection copyWith({double? pct}) => _DnaSection(
        icon: icon,
        label: label,
        pct: pct ?? this.pct,
        color: color,
        categoryCode: categoryCode,
        id: id,
        kind: kind,
      );
}

class _DnaScreenState extends State<DnaScreen> {
  /// Sections that still need evidence (below the 90% "on track" line).
  static const double _onTrackThreshold = 90;

  List<String> _skills = const [];
  List<_DnaSection> _custom = [];
  ProfileData _profile = const ProfileData();
  late List<_DnaSection> _sections = _compose(_profile, _skills, const []);
  bool _ready = false;
  ProfileSectionRepository? _repository;
  ProfileSkillsRepository? _skillsRepository;
  ProfileRepository? _profileRepository;

  /// Completeness derived from how much real evidence exists.
  static double _pctFor(int count) => count == 0 ? 0 : (count >= 2 ? 100 : 60);

  static _DnaSection _skillsRowFor(List<String> skills) => _DnaSection(
        icon: Icons.bolt_rounded,
        label: 'Skills · ${skills.length} entries',
        pct: (skills.length * 10).clamp(0, 100).toDouble(),
        color: AppColors.purple,
        kind: _SectionKind.skills,
      );

  static List<_DnaSection> _profileSections(ProfileData profile, List<String> skills) => [
        _DnaSection(
          icon: Icons.person_rounded,
          label: 'Personal Profile',
          pct: profile.summary.isEmpty ? 0 : 100,
          kind: _SectionKind.summary,
        ),
        _DnaSection(
          icon: Icons.school_rounded,
          label: 'Education',
          pct: _pctFor(profile.education.length),
          kind: _SectionKind.education,
        ),
        _DnaSection(
          icon: Icons.work_rounded,
          label: 'Experience',
          pct: _pctFor(profile.experience.length),
          color: AppColors.purple,
          kind: _SectionKind.experience,
        ),
        _DnaSection(
          icon: Icons.code_rounded,
          label: 'Projects',
          pct: _pctFor(profile.projects.length),
          kind: _SectionKind.projects,
        ),
        _skillsRowFor(skills),
        _DnaSection(
          icon: Icons.menu_book_rounded,
          label: 'Certifications',
          pct: _pctFor(profile.certifications.length),
          kind: _SectionKind.certifications,
        ),
        _DnaSection(
          icon: Icons.emoji_events_rounded,
          label: 'Achievements',
          pct: _pctFor(profile.achievements.length),
          color: AppColors.amber,
          kind: _SectionKind.achievements,
        ),
        _DnaSection(
          icon: Icons.language_rounded,
          label: 'Languages',
          pct: _pctFor(profile.languages.length),
          kind: _SectionKind.languages,
        ),
      ];

  static List<_DnaSection> _compose(
    ProfileData profile,
    List<String> skills,
    List<_DnaSection> custom,
  ) =>
      [..._profileSections(profile, skills), ...custom];

  void _rebuild() {
    _sections = _compose(_profile, _skills, _custom);
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final dnaCubit = context.read<CareerDnaCubit>();
    final prefs = await SharedPreferences.getInstance();
    final local = CareerLocalDataSource(prefs);
    final remote = CareerRemoteDataSource();
    _repository = ProfileSectionRepositoryImpl(remote, local);
    _skillsRepository = ProfileSkillsRepositoryImpl(remote, local);
    _profileRepository = ProfileRepositoryImpl(remote, local);

    // Load the structured Career DNA identity so the Command Center can show the
    // user's declared goal / stage / target alongside their evidence.
    try {
      await dnaCubit.load();
    } on Object {
      // Non-fatal: the identity banner simply stays hidden if this fails.
    }

    final skills = await _skillsRepository!.load();
    final profile = await _profileRepository!.load();
    final custom = await _repository!.load();
    if (!mounted) return;
    if (skills != null) _skills = skills;
    if (profile != null) _profile = profile;
    if (custom != null) _custom = [for (final section in custom) _toUiSection(section)];
    _rebuild();
    setState(() => _ready = true);
  }

  Future<void> _persistCustomSections() async {
    final custom = <ProfileSection>[
      for (final s in _custom)
        ProfileSection(id: s.id, label: s.label, pct: s.pct, category: s.categoryCode),
    ];
    await _repository?.saveAll(custom);
  }

  static _DnaSection _toUiSection(ProfileSection section) {
    final (icon, color) = switch (section.category) {
      'p' => (Icons.article_rounded, AppColors.purple),
      'c' => (Icons.school_rounded, AppColors.teal),
      _ => (Icons.volunteer_activism_rounded, AppColors.green),
    };
    return _DnaSection(
      icon: icon,
      label: section.label,
      pct: section.pct,
      color: color,
      categoryCode: section.category,
      id: section.id,
    );
  }

  /// Overall DNA completeness — weighted by section percentage, derived live
  /// from the current section list (base + any added sections).
  double get _overall {
    if (_sections.isEmpty) return 0;
    final sum = _sections.fold<double>(0, (acc, s) => acc + s.pct);
    return sum / _sections.length;
  }

  List<_DnaSection> get _needsWork {
    final list = _sections.where((s) => s.pct < _onTrackThreshold).toList();
    list.sort((a, b) => a.pct.compareTo(b.pct));
    return list;
  }

  Future<void> _openFullProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileEditorScreen(
          profile: _profile,
          skills: _skills,
          onSave: _saveFullProfile,
        ),
      ),
    );
  }

  Future<void> _openSmartBuilder() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SmartBuilderScreen(onSave: _saveFullProfile),
      ),
    );
  }

  Future<void> _saveFullProfile(ProfileData profile, List<String> skills) async {
    setState(() {
      _profile = profile;
      _skills = skills;
      _rebuild();
    });
    await _profileRepository?.save(profile);
    await _skillsRepository?.save(skills);
  }

  Future<void> _showAddSectionSheet() async {
    final result = await showModalBottomSheet<_AddResult>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _AddSectionSheet(),
    );
    if (result == null || !mounted) return;

    setState(() {
      _custom = [
        ..._custom,
        _DnaSection(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          icon: result.icon,
          label: result.label,
          pct: 0,
          color: result.color,
          categoryCode: result.category,
        ),
      ];
      _rebuild();
    });
    await _persistCustomSections();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${result.label} added — DNA completeness updated'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _showSectionDetail(_DnaSection section) async {
    final markComplete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      builder: (_) => _SectionDetailSheet(section: section),
    );
    if (markComplete != true || !mounted) return;

    setState(() {
      _sections = [
        for (final s in _sections) s.label == section.label ? s.copyWith(pct: 100) : s,
      ];
      final customIndex = _custom.indexWhere((s) => s.label == section.label);
      if (customIndex >= 0) {
        _custom = [..._custom]..[customIndex] =
            _custom[customIndex].copyWith(pct: 100);
      }
    });
    if (section.categoryCode.isNotEmpty) {
      await _persistCustomSections();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${section.label} marked complete'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _openSection(_DnaSection section) async {
    final kind = section.kind;
    if (kind == null) {
      await _showSectionDetail(section);
      return;
    }
    if (kind == _SectionKind.skills) {
      await _openSkillsEditor();
      return;
    }
    await _editSection(kind);
  }

  /// Field layout for a section's real-data editor.
  static _SectionEditor _editorFor(_SectionKind kind) => switch (kind) {
        _SectionKind.summary => const _SectionEditor(
            title: 'Personal Profile',
            subtitle: 'A short summary hiring teams read first — the AI uses it when advising you.',
            fields: [
              _FieldSpec(
                label: 'Summary',
                hint: 'e.g. Flutter engineer with 4+ years shipping real-time products used by thousands of riders.',
                lines: 4,
              ),
            ],
          ),
        _SectionKind.experience => const _SectionEditor(
            title: 'Experience',
            subtitle: 'Real roles you have held — these back your experience match score.',
            fields: [
              _FieldSpec(label: 'Role', hint: 'e.g. Senior Flutter Engineer'),
              _FieldSpec(label: 'Company', hint: 'e.g. Careem'),
              _FieldSpec(label: 'Years', hint: 'e.g. 2.5'),
            ],
          ),
        _SectionKind.projects => const _SectionEditor(
            title: 'Projects',
            subtitle: 'Projects you shipped — the AI reads these to verify skills and give tailored advice.',
            fields: [
              _FieldSpec(label: 'Name', hint: 'e.g. ShipLink'),
              _FieldSpec(label: 'Description', hint: 'What it does and your part in it…', lines: 3),
              _FieldSpec(label: 'Tech (comma separated)', hint: 'Flutter, Dart, Supabase, Google Maps'),
            ],
          ),
        _SectionKind.education => const _SectionEditor(
            title: 'Education',
            subtitle: 'Degrees you hold.',
            fields: [
              _FieldSpec(label: 'Degree', hint: 'e.g. B.Sc. Computer Engineering'),
              _FieldSpec(label: 'Field', hint: 'e.g. Software Engineering'),
            ],
          ),
        _SectionKind.certifications => const _SectionEditor(
            title: 'Certifications',
            subtitle: 'Certificates that verify your skills.',
            fields: [_FieldSpec(label: 'Certification', hint: 'e.g. AWS Certified Developer')],
          ),
        _SectionKind.achievements => const _SectionEditor(
            title: 'Achievements',
            subtitle: 'Wins and recognitions worth proving.',
            fields: [_FieldSpec(label: 'Achievement', hint: 'e.g. 1st place, University Hackathon 2025')],
          ),
        _SectionKind.languages => const _SectionEditor(
            title: 'Languages',
            subtitle: 'Spoken languages you can prove.',
            fields: [_FieldSpec(label: 'Language', hint: 'e.g. Arabic (Native)')],
          ),
        _SectionKind.skills => throw UnimplementedError(),
      };

  /// Current values for a section, as editable row-fields.
  static List<List<String>> _entriesFor(_SectionKind kind, ProfileData p) =>
      switch (kind) {
        _SectionKind.summary => p.summary.isEmpty ? [] : [
            [p.summary]
          ],
        _SectionKind.experience => [
            for (final e in p.experience) [e.role, e.company, e.years == 0 ? '' : e.years.toString()],
          ],
        _SectionKind.projects => [
            for (final e in p.projects) [e.name, e.description, e.tech.join(', ')],
          ],
        _SectionKind.education => [
            for (final e in p.education) [e.degree, e.field],
          ],
        _SectionKind.certifications => [for (final c in p.certifications) [c]],
        _SectionKind.achievements => [for (final a in p.achievements) [a]],
        _SectionKind.languages => [for (final l in p.languages) [l]],
        _SectionKind.skills => throw UnimplementedError(),
      };

  static String _at(List<String> row, int i) => i < row.length ? row[i].trim() : '';

  static List<String> _column(List<List<String>> rows) => [for (final row in rows) _at(row, 0)];

  static List<String> _csv(String value) =>
      value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static ProfileData _applyEntries(
    ProfileData p,
    _SectionKind kind,
    List<List<String>> entries,
  ) =>
      switch (kind) {
        _SectionKind.summary => p.copyWith(summary: entries.isEmpty ? '' : _at(entries.first, 0)),
        _SectionKind.experience => p.copyWith(
            experience: [
              for (final e in entries)
                ProfileExperience(
                  role: _at(e, 0),
                  company: _at(e, 1),
                  years: int.tryParse(_at(e, 2)) ?? 0,
                ),
            ],
          ),
        _SectionKind.projects => p.copyWith(
            projects: [
              for (final e in entries)
                ProfileProject(name: _at(e, 0), description: _at(e, 1), tech: _csv(_at(e, 2))),
            ],
          ),
        _SectionKind.education => p.copyWith(
            education: [
              for (final e in entries) ProfileEducation(degree: _at(e, 0), field: _at(e, 1)),
            ],
          ),
        _SectionKind.certifications => p.copyWith(certifications: _column(entries)),
        _SectionKind.achievements => p.copyWith(achievements: _column(entries)),
        _SectionKind.languages => p.copyWith(languages: _column(entries)),
        _SectionKind.skills => p,
      };

  Future<void> _editSection(_SectionKind kind) async {
    final editor = _editorFor(kind);
    final result = await showModalBottomSheet<List<List<String>>>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SectionEditorSheet(
        title: editor.title,
        subtitle: editor.subtitle,
        fields: editor.fields,
        initial: _entriesFor(kind, _profile),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _profile = _applyEntries(_profile, kind, result);
      _rebuild();
    });
    await _profileRepository?.save(_profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${editor.title} saved — match scores updated'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _openSkillsEditor() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SkillsSheet(initial: _skills),
    );
    if (result == null || !mounted) return;
    setState(() {
      _skills = result;
      _rebuild();
    });
    await _skillsRepository?.save(result);
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overall;
    final needsWork = _needsWork;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DnaHeader(onEditProfile: _openFullProfile),
          BlocBuilder<CareerDnaCubit, CareerDnaState>(
            builder: (context, dnaState) {
              final dna = dnaState.dna;
              if (dna == null) return const SizedBox.shrink();
              return _CareerIdentityBanner(dna: dna);
            },
          ),
          _ready && _profile.isEmpty
              ? _DnaEmptyState(onBuild: _openSmartBuilder)
              : _BuildNexoraBanner(onBuild: _openSmartBuilder, isEmpty: _profile.isEmpty),
          const SizedBox(height: 4),
          _CompletenessCard(overall: overall, needsWork: needsWork),
          const SizedBox(height: 14),
          const _EvidenceNote(),
          const SizedBox(height: 14),
          _ProfileSections(
            sections: _sections,
            onSectionTap: _openSection,
            onAddTap: _showAddSectionSheet,
          ),
        ],
      ),
    );
  }
}

class _DnaHeader extends StatelessWidget {
  const _DnaHeader({required this.onEditProfile});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.watch<LocaleCubit>();
    final isEnglish = localeCubit.state.language == AppLanguage.english;
    final targetLabel = isEnglish ? l10n.langArabic : l10n.langEnglish;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              l10n.dnaTitle,
              style: AppTextStyles.screenTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: localeCubit.toggleLanguage,
                icon: const Icon(Icons.language_rounded, color: AppColors.textSub),
                tooltip: targetLabel,
                visualDensity: VisualDensity.compact,
              ),
              GestureDetector(
                onTap: onEditProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.tealBg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.tealBdr),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, size: 14, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(
                        l10n.dnaEditProfile,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareerIdentityBanner extends StatelessWidget {
  const _CareerIdentityBanner({required this.dna});

  final CareerDna dna;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chips = <String>[
      if (dna.goal != null) goalLabel(l10n, dna.goal!),
      if (dna.stage != null) stageLabel(l10n, dna.stage!),
      if (dna.targetField != null) fieldLabel(l10n, dna.targetField!),
    ];
    final target = [
      if (dna.targetRole.trim().isNotEmpty) dna.targetRole.trim(),
      if (dna.targetIndustry.trim().isNotEmpty) dna.targetIndustry.trim(),
    ].join(' · ');
    if (chips.isEmpty && target.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderViolet.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dnaIdentityTitle.toUpperCase(), style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            if (chips.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
                      ),
                      child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                    ),
                ],
              ),
            if (target.isNotEmpty) ...[
              if (chips.isNotEmpty) const SizedBox(height: 8),
              Text(
                target,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuildNexoraBanner extends StatelessWidget {
  const _BuildNexoraBanner({required this.onBuild, this.isEmpty = false});

  final VoidCallback onBuild;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dna = context.watch<CareerDnaCubit>().state.dna;

    // Personalized next action derived from the Career DNA (Phase 1 data only).
    final completeness = dna?.completeness ?? 0.0;
    String title;
    String subtitle;
    if (dna == null || completeness < 0.3) {
      title = l10n.nextActionCompleteDna;
      subtitle = l10n.nextActionCompleteDnaSub;
    } else if (dna.targetRole.trim().isEmpty) {
      title = l10n.nextActionTargetRole;
      subtitle = l10n.nextActionTargetRoleSub;
    } else if (dna.stage == CareerStage.careerChanger &&
        (dna.extra<List<dynamic>>('transferableSkills') ?? const []).isEmpty) {
      title = l10n.nextActionTransferable;
      subtitle = l10n.nextActionTransferableSub;
    } else if (completeness < 0.8) {
      title = l10n.nextActionRefine;
      subtitle = l10n.nextActionRefineSub;
    } else {
      title = l10n.dnaRefineNexora;
      subtitle = l10n.dnaRefineSub;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: onBuild,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.signatureGradient),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.background),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                        fontFamily: AppTextStyles.displayFont,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.background, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.background),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the thin banner when the profile is completely empty — a
/// hero nudge that sends a brand-new user straight into the Smart Builder.
class _DnaEmptyState extends StatelessWidget {
  const _DnaEmptyState({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.signatureGradient),
          borderRadius: BorderRadius.circular(18),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 22, color: AppColors.background),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.dnaEmptyTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.background,
                    fontFamily: AppTextStyles.displayFont,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dnaEmptySub,
            style: const TextStyle(fontSize: 13, color: AppColors.background, height: 1.45),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onBuild,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, size: 17),
                const SizedBox(width: 8),
                Text(l10n.dnaBuildNexora, style: AppTextStyles.primaryButton),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.overall, required this.needsWork});

  final double overall;
  final List<_DnaSection> needsWork;

  @override
  Widget build(BuildContext context) {
    final weak = needsWork;
    final note = weak.isEmpty
        ? 'All sections on track'
        : [for (final s in weak.take(2)) '${s.label} · ${s.pct.round()}%'].join('\n');
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DNA COMPLETENESS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 6),
                    Text('${overall.round()}%', style: AppTextStyles.metric.copyWith(fontSize: 32, height: 1)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppChip(
                      label: weak.isEmpty ? 'All on Track' : '${weak.length} Section${weak.length == 1 ? '' : 's'} Need Work',
                      color: weak.isEmpty ? AppColors.green : AppColors.amber,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodySub.copyWith(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
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
                    widthFactor: overall.clamp(0, 1),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%', style: AppTextStyles.mono),
              Text(
                '${overall.round()}% · Target 95%',
                style: const TextStyle(fontSize: 11, fontFamily: AppTextStyles.monoFont, color: AppColors.teal),
              ),
              const Text('100%', style: AppTextStyles.mono),
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
          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodySub.copyWith(fontSize: 12, height: 1.45),
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
  const _ProfileSections({
    required this.sections,
    required this.onSectionTap,
    required this.onAddTap,
  });

  final List<_DnaSection> sections;
  final ValueChanged<_DnaSection> onSectionTap;
  final VoidCallback onAddTap;

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
          for (final section in sections)
            SectionRow(
              icon: section.icon,
              label: section.label,
              pct: section.pct,
              color: section.color,
              onTap: () => onSectionTap(section),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: AppColors.textMuted),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Add Volunteering · Publications · Courses',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddResult {
  const _AddResult({
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String category;
}

class _AddSectionSheet extends StatefulWidget {
  const _AddSectionSheet();

  @override
  State<_AddSectionSheet> createState() => _AddSectionSheetState();
}

class _AddSectionSheetState extends State<_AddSectionSheet> {
  static const _categories = [
    (code: 'v', label: 'Volunteering', icon: Icons.volunteer_activism_rounded, color: AppColors.green),
    (code: 'p', label: 'Publications', icon: Icons.article_rounded, color: AppColors.purple),
    (code: 'c', label: 'Courses', icon: Icons.school_rounded, color: AppColors.teal),
  ];

  final _controller = TextEditingController(text: 'Volunteering');
  String _category = 'v';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(String code, String label) {
    setState(() {
      _category = code;
      _controller.text = label;
    });
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    final category = _categories.firstWhere((c) => c.code == _category);
    Navigator.of(context).pop(
      _AddResult(label: label, icon: category.icon, color: category.color, category: category.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a section', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          const Text('Sections are evidence-based — you can attach proof later.', style: AppTextStyles.bodySub),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c.code,
                  onSelected: (_) => _select(c.code, c.label),
                  selectedColor: c.color.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: _category == c.code ? c.color : AppColors.textSub,
                  ),
                  side: BorderSide(color: _category == c.code ? c.color : AppColors.border),
                  backgroundColor: AppColors.card,
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Section name',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(color: AppColors.text),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Section', style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDetailSheet extends StatelessWidget {
  const _SectionDetailSheet({required this.section});

  final _DnaSection section;

  @override
  Widget build(BuildContext context) {
    final done = section.pct >= 100;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: section.color.withValues(alpha: 0.2)),
                ),
                child: Icon(section.icon, size: 20, color: section.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${section.pct.round()}% complete', style: AppTextStyles.bodySub),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: section.pct / 100,
              minHeight: 6,
              color: done ? AppColors.teal : section.color,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            done
                ? 'Everything in this section is verified. Nice work!'
                : 'Add evidence — upload a document, link, or certificate to bring this section up to 100%.',
            style: AppTextStyles.bodySub.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: done ? null : () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                done ? 'Already Complete' : 'Mark as Complete',
                style: AppTextStyles.primaryButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsSheet extends StatefulWidget {
  const _SkillsSheet({required this.initial});

  final List<String> initial;

  @override
  State<_SkillsSheet> createState() => _SkillsSheetState();
}

class _SkillsSheetState extends State<_SkillsSheet> {
  final TextEditingController _controller = TextEditingController();
  late final List<String> _skills = [...widget.initial];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final skill = _controller.text.trim();
    if (skill.isEmpty) return;
    final existing = _skills.map((s) => s.toLowerCase()).toSet();
    if (existing.contains(skill.toLowerCase())) {
      setState(() {});
      _controller.clear();
      return;
    }
    setState(() => _skills.add(skill));
    _controller.clear();
  }

  void _remove(String skill) {
    setState(() => _skills.remove(skill));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your skills', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          const Text(
            'These drive your real match scores when you analyze opportunities.',
            style: AppTextStyles.bodySub,
          ),
          const SizedBox(height: 16),
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in _skills)
                  InputChip(
                    label: Text(skill),
                    onDeleted: () => _remove(skill),
                    deleteIcon: const Icon(Icons.close_rounded, size: 15),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: AppColors.purple,
                    ),
                    backgroundColor: AppColors.purpleBg,
                    side: const BorderSide(color: AppColors.purpleBdr),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Flutter, Figma, SQL…',
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _add,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18, color: AppColors.background),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_skills),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save skills', style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// One input in a section editor (label + hint + optional multi-line).
class _FieldSpec {
  const _FieldSpec({required this.label, required this.hint, this.lines = 1});

  final String label;
  final String hint;
  final int lines;
}

/// Static configuration describing how a section's real data is edited.
class _SectionEditor {
  const _SectionEditor({
    required this.title,
    required this.subtitle,
    required this.fields,
  });

  final String title;
  final String subtitle;
  final List<_FieldSpec> fields;
}

/// Generic editor for one real profile section: existing entries are listed
/// and editable, new ones can be added, and everything is returned on save.
class _SectionEditorSheet extends StatefulWidget {
  const _SectionEditorSheet({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.initial,
  });

  final String title;
  final String subtitle;
  final List<_FieldSpec> fields;
  final List<List<String>> initial;

  @override
  State<_SectionEditorSheet> createState() => _SectionEditorSheetState();
}

class _SectionEditorSheetState extends State<_SectionEditorSheet> {
  late final List<List<String>> _entries = [
    for (final entry in widget.initial) [...entry],
  ];
  late final List<TextEditingController> _controllers = [
    for (final _ in widget.fields) TextEditingController(),
  ];
  int? _editingIndex;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startEdit([int? index]) {
    setState(() {
      _editingIndex = index;
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = index == null ? '' : _entries[index][i];
      }
    });
  }

  void _saveEntry() {
    final values = [for (final controller in _controllers) controller.text.trim()];
    if (values.every((value) => value.isEmpty)) return;
    setState(() {
      final index = _editingIndex;
      if (index == null) {
        _entries.add(values);
      } else {
        _entries[index] = values;
      }
      _editingIndex = null;
      for (final controller in _controllers) {
        controller.clear();
      }
    });
  }

  void _remove(int index) {
    setState(() {
      _entries.removeAt(index);
      if (_editingIndex == index) _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: AppTextStyles.bodySub),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('Nothing added yet.', style: AppTextStyles.bodySub),
                    )
                  else
                    for (var i = 0; i < _entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EntryCard(
                          title: _entries[i].first,
                          subtitle: _entries[i].length > 1
                              ? _entries[i].sublist(1).where((v) => v.isNotEmpty).join(' · ')
                              : '',
                          onEdit: () => _startEdit(i),
                          onDelete: () => _remove(i),
                        ),
                      ),
                  const SizedBox(height: 10),
                  Text(
                    _editingIndex == null ? 'Add entry' : 'Edit entry',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < widget.fields.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _controllers[i],
                        maxLines: widget.fields[i].lines,
                        style: const TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          labelText: widget.fields[i].label,
                          hintText: widget.fields[i].hint,
                          labelStyle: AppTextStyles.bodySub,
                          hintStyle: AppTextStyles.bodySub,
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveEntry,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _editingIndex == null ? 'Add' : 'Update',
                            style: AppTextStyles.primaryButton,
                          ),
                        ),
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _startEdit(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_entries),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save changes', style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: AppTextStyles.bodySub),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Full-screen editor for the whole real profile: every section visible at
/// once, filled from scratch or one at a time. Saving persists everything.
class _ProfileEditorScreen extends StatefulWidget {
  const _ProfileEditorScreen({
    required this.profile,
    required this.skills,
    required this.onSave,
  });

  final ProfileData profile;
  final List<String> skills;
  final Future<void> Function(ProfileData profile, List<String> skills) onSave;

  @override
  State<_ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<_ProfileEditorScreen> {
  static const List<_SectionKind> _kinds = [
    _SectionKind.summary,
    _SectionKind.experience,
    _SectionKind.projects,
    _SectionKind.education,
    _SectionKind.certifications,
    _SectionKind.achievements,
    _SectionKind.languages,
    _SectionKind.skills,
  ];

  static const Map<_SectionKind, String> _titles = {
    _SectionKind.summary: 'Personal Profile',
    _SectionKind.experience: 'Experience',
    _SectionKind.projects: 'Projects',
    _SectionKind.education: 'Education',
    _SectionKind.certifications: 'Certifications',
    _SectionKind.achievements: 'Achievements',
    _SectionKind.languages: 'Languages',
    _SectionKind.skills: 'Skills',
  };

  static const Map<_SectionKind, IconData> _icons = {
    _SectionKind.summary: Icons.person_rounded,
    _SectionKind.experience: Icons.work_rounded,
    _SectionKind.projects: Icons.code_rounded,
    _SectionKind.education: Icons.school_rounded,
    _SectionKind.certifications: Icons.menu_book_rounded,
    _SectionKind.achievements: Icons.emoji_events_rounded,
    _SectionKind.languages: Icons.language_rounded,
    _SectionKind.skills: Icons.bolt_rounded,
  };

  late ProfileData _profile = widget.profile;
  late List<String> _skills = [...widget.skills];
  bool _saving = false;

  double get _overall {
    final p = _profile;
    final pcts = <double>[
      p.summary.isEmpty ? 0 : 100,
      _DnaScreenState._pctFor(p.experience.length),
      _DnaScreenState._pctFor(p.projects.length),
      _DnaScreenState._pctFor(p.education.length),
      _DnaScreenState._pctFor(p.certifications.length),
      _DnaScreenState._pctFor(p.achievements.length),
      _DnaScreenState._pctFor(p.languages.length),
      (_skills.length * 10).clamp(0, 100).toDouble(),
    ];
    return pcts.reduce((a, b) => a + b) / pcts.length;
  }

  String _summaryFor(_SectionKind kind) {
    final p = _profile;
    return switch (kind) {
      _SectionKind.summary => p.summary.isEmpty ? 'Tap to add your summary' : p.summary,
      _SectionKind.experience => p.experience.isEmpty
          ? 'No roles yet'
          : p.experience.map((e) => [e.role, e.company].where((v) => v.isNotEmpty).join(' · ')).join(', '),
      _SectionKind.projects => p.projects.isEmpty
          ? 'No projects yet'
          : p.projects.map((e) => e.name).join(', '),
      _SectionKind.education => p.education.isEmpty
          ? 'No degrees yet'
          : p.education.map((e) => e.degree).join(', '),
      _SectionKind.certifications => p.certifications.isEmpty ? 'No certifications yet' : p.certifications.join(', '),
      _SectionKind.achievements => p.achievements.isEmpty ? 'No achievements yet' : p.achievements.join(', '),
      _SectionKind.languages => p.languages.isEmpty ? 'No languages yet' : p.languages.join(', '),
      _SectionKind.skills => _skills.isEmpty ? 'No skills yet' : _skills.join(', '),
    };
  }

  Future<void> _edit(_SectionKind kind) async {
    if (kind == _SectionKind.skills) {
      final result = await showModalBottomSheet<List<String>>(
        context: context,
        backgroundColor: AppColors.cardHi,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _SkillsSheet(initial: _skills),
      );
      if (result == null || !mounted) return;
      setState(() => _skills = result);
      return;
    }

    final editor = _DnaScreenState._editorFor(kind);
    final result = await showModalBottomSheet<List<List<String>>>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SectionEditorSheet(
        title: editor.title,
        subtitle: editor.subtitle,
        fields: editor.fields,
        initial: _DnaScreenState._entriesFor(kind, _profile),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _profile = _DnaScreenState._applyEntries(_profile, kind, result));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_profile, _skills);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overall = _overall;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(l10n.dnaEditProfile, style: AppTextStyles.screenTitle)),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      l10n.dnaSave,
                      style: const TextStyle(fontSize: 15, fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.w700, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                'Fill what you have — the AI matches you on this real data.',
                style: AppTextStyles.bodySub.copyWith(fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EditorProgress(overall: overall),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  for (final kind in _kinds)
                    _ProfileSectionTile(
                      icon: _icons[kind]!,
                      label: _titles[kind]!,
                      subtitle: _summaryFor(kind),
                      onTap: () => _edit(kind),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorProgress extends StatelessWidget {
  const _EditorProgress({required this.overall});

  final double overall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Row(
        children: [
          Text(
            '${overall.round()}%',
            style: AppTextStyles.metric.copyWith(fontSize: 24, height: 1, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor: overall.clamp(0, 1) / 100,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.signatureGradient)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMed),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySub.copyWith(fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
