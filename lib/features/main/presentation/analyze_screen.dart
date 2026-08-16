import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../domain/analysis/job_analyzer.dart';
import '../../../domain/entities/job_analysis.dart';
import '../../../domain/entities/profile_data.dart';
import '../../../domain/repositories/job_analysis_repository.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../../domain/repositories/profile_skills_repository.dart';
import 'widgets/app_chip.dart';
import 'widgets/info_note.dart';
import 'widgets/progress_bar.dart';
import 'widgets/section_label.dart';

/// Opportunity Analyzer — mirrors the design's Analyze screen.
///
/// Analyses are data-driven and persist across restarts (Supabase when signed
/// in, SharedPreferences offline): running a new analysis extracts the
/// opportunity's requirements from the pasted text, appends a result card,
/// and analyses can be removed.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  static const List<String> _types = ['Full-time Job', 'Internship', "Master's", 'Scholarship'];

  static const List<(String, String)> _educationOptions = [
    ('high school', 'High School'),
    ('bachelor', 'Bachelor'),
    ('master', 'Master'),
    ('phd', 'PhD'),
  ];

  static const List<String> _seedSkills = [
    'Flutter',
    'Dart',
    'REST APIs',
    'Supabase',
    'Git',
    'Google Maps',
  ];

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  List<String> _skills = [..._seedSkills];
  ProfileData _profile = const ProfileData();
  String _selectedType = 'Full-time Job';
  String _education = 'bachelor';
  bool _showResults = true;
  bool _analyzing = false;
  List<JobAnalysis> _analyses = [_seedAnalysis()];
  JobAnalysisRepository? _repository;
  ProfileSkillsRepository? _skillsRepository;
  ProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  static JobAnalysis _seedAnalysis() => const JobAnalysis(
        id: 'seed',
        title: 'Flutter Engineer',
        company: 'Careem · Dubai 🇦🇪',
        timeAgo: '2h ago',
        overall: 82,
        skills: 91,
        experience: 76,
        education: 100,
        keywords: 73,
        strong: ['Flutter', 'Dart', 'REST APIs', 'Supabase', 'Git', 'Google Maps'],
        missing: ['Docker', 'CI/CD', 'Unit Testing'],
        aiRecommendation:
            'Strong Flutter and Dart foundation — lead with your shipping record, and add Docker/CI-CD evidence to cover the gaps.',
      );

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final local = CareerLocalDataSource(prefs);
    final remote = CareerRemoteDataSource();
    _repository = JobAnalysisRepositoryImpl(remote, local);
    _skillsRepository = ProfileSkillsRepositoryImpl(remote, local);
    _profileRepository = ProfileRepositoryImpl(remote, local);

    final skills = await _skillsRepository!.load();
    final profile = await _profileRepository!.load();
    final analyses = await _repository!.load();
    if (!mounted) return;
    if (skills != null) _skills = skills;
    if (profile != null) {
      _profile = profile;
      if (profile.education.isNotEmpty) {
        _education = _highestEducation(profile.education.map((e) => e.degree).toList());
      }
    }
    if (analyses == null) {
      await _repository!.saveAll(_analyses);
      return;
    }
    setState(() => _analyses = analyses);
  }

  /// Maps the user's highest real degree to the dropdown's education code.
  static String _highestEducation(List<String> degrees) {
    const rank = {
      'phd': 5,
      'doctor': 5,
      'master': 4,
      'mba': 4,
      'bachelor': 3,
      'b.sc': 3,
      'b.s': 3,
      'b.eng': 3,
      'associate': 2,
      'diploma': 2,
      'high school': 1,
    };
    var highest = 0;
    for (final degree in degrees) {
      final lowered = degree.toLowerCase();
      for (final entry in rank.entries) {
        if (lowered.contains(entry.key) && entry.value > highest) {
          highest = entry.value;
        }
      }
    }
    return switch (highest) {
      >= 5 => 'phd',
      >= 4 => 'master',
      >= 3 => 'bachelor',
      >= 2 => 'associate',
      _ => 'high school',
    };
  }

  Future<void> _persistAnalyses() async {
    await _repository?.saveAll(_analyses);
  }

  Future<void> _analyze() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _snack(l10n.analyzePasteFirst);
      return;
    }
    setState(() => _analyzing = true);

    final started = DateTime.now();
    JobAnalysis? aiResult;
    final repository = _repository;
    if (repository != null) {
      try {
        final yearsText = _yearsController.text.trim();
        aiResult = await repository.analyze(
          description: text,
          skills: _skills,
          yearsOfExperience:
              yearsText.isNotEmpty ? int.tryParse(yearsText) ?? 0 : _profile.yearsTotal,
          education: _education,
          profile: _profile,
        );
      } catch (_) {
        // AI unavailable: fall back to the local extractor below.
      }
    }
    final analysis = aiResult ?? _buildAnalysis(text);

    // Keep the extracting state visible for a stable minimum duration, whether
    // the AI returned fast or the local fallback ran instantly.
    final remaining = const Duration(milliseconds: 1500) - DateTime.now().difference(started);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    setState(() {
      _analyses = [analysis, ..._analyses];
      _analyzing = false;
      _showResults = true;
    });
    await _persistAnalyses();
    if (!mounted) return;
    _snack(l10n.analyzeReady(analysis.overall.round()));
  }

  JobAnalysis _buildAnalysis(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final rawTitle = lines.isNotEmpty ? lines.first : _selectedType;
    final title = rawTitle.length > 34 ? '${rawTitle.substring(0, 34)}…' : rawTitle;
    final company = lines.length > 1 ? lines[1] : '—';

    final yearsText = _yearsController.text.trim();
    final years = yearsText.isNotEmpty ? int.tryParse(yearsText) ?? _profile.yearsTotal : _profile.yearsTotal;

    return const JobAnalyzer().analyze(
      description: text,
      candidateSkills: _skills,
      yearsOfExperience: years,
      education: _education,
      profile: _profile,
      title: title,
      company: company,
    );
  }

  Future<void> _deleteAnalysis(JobAnalysis analysis) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _analyses = [for (final a in _analyses) if (a.id != analysis.id) a];
    });
    await _persistAnalyses();
    if (!mounted) return;
    _snack(l10n.analyzeRemoved);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  String _typeLabel(AppLocalizations l10n, String code) => switch (code) {
        'Full-time Job' => l10n.analyzeTypeFullTime,
        'Internship' => l10n.analyzeTypeInternship,
        "Master's" => l10n.analyzeTypeMasters,
        _ => l10n.analyzeTypeScholarship,
      };

  String _eduLabel(AppLocalizations l10n, String code) => switch (code) {
        'high school' => l10n.analyzeEduHighSchool,
        'bachelor' => l10n.analyzeEduBachelor,
        'master' => l10n.analyzeEduMaster,
        _ => l10n.analyzeEduPhd,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeEntries = [for (final c in _types) (c, _typeLabel(l10n, c))];
    final educationEntries = [for (final e in _educationOptions) (e.$1, _eduLabel(l10n, e.$1))];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.analyzeTitle, style: AppTextStyles.screenTitle),
                const SizedBox(height: 14),
                _SegmentSwitch(value: _showResults, onChanged: (v) => setState(() => _showResults = v)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_showResults)
            _AnalysisResults(analyses: _analyses, onDelete: _deleteAnalysis)
          else
            _NewAnalysis(
              controller: _textController,
              yearsController: _yearsController,
              typeEntries: typeEntries,
              educationEntries: educationEntries,
              selectedType: _selectedType,
              education: _education,
              analyzing: _analyzing,
              onSelectType: (t) => setState(() => _selectedType = t),
              onSelectEducation: (e) => setState(() => _education = e),
              onAnalyze: _analyze,
            ),
        ],
      ),
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildSegment(l10n.analyzeMyAnalyses, true, () => onChanged(true)),
          _buildSegment(l10n.analyzeNewAnalysis, false, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool isResults, VoidCallback onTap) {
    final selected = value == isResults;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.background : AppColors.textSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisResults extends StatelessWidget {
  const _AnalysisResults({required this.analyses, required this.onDelete});

  final List<JobAnalysis> analyses;
  final ValueChanged<JobAnalysis> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (analyses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(l10n.analyzeEmptyTitle, style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(l10n.analyzeEmptySub, style: AppTextStyles.bodySub),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < analyses.length; i++) ...[
            _AnimatedCard(
              delay: Duration(milliseconds: i * 70),
              child: _AnalysisCard(analysis: analyses[i], onDelete: onDelete),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

/// Fades and slides a card in, staggered by [delay], for a livelier list.
class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurveTween(curve: Curves.easeOutCubic).animate(_controller));
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _offset, child: widget.child),
      );
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis, required this.onDelete});

  final JobAnalysis analysis;
  final ValueChanged<JobAnalysis> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final missing = analysis.missing;
    final weakNote = missing.isEmpty
        ? l10n.analyzeAllBacked
        : '${missing.join(', ')} ${l10n.analyzeMissingEvidence}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.signatureGradient))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(analysis.company, style: AppTextStyles.bodySub),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppChip(label: analysis.timeAgo),
                  IconButton(
                    tooltip: l10n.analyzeRemoveTooltip,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.textMuted),
                    onPressed: () => onDelete(analysis),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ProgressBar(label: l10n.analyzeOverallMatch, value: analysis.overall),
          ProgressBar(label: l10n.analyzeSkills, value: analysis.skills),
          ProgressBar(label: l10n.analyzeExperience, value: analysis.experience, color: AppColors.purple),
          ProgressBar(label: l10n.analyzeEducation, value: analysis.education, color: AppColors.green),
          ProgressBar(label: l10n.analyzeKeywords, value: analysis.keywords, color: AppColors.amber),
          const SizedBox(height: 4),
          SectionLabel(l10n.analyzeStrongMatches),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final skill in analysis.strong) AppChip(label: skill)],
          ),
          const SizedBox(height: 14),
          SectionLabel(l10n.analyzeMissingSkills),
          if (missing.isEmpty)
            Text(l10n.analyzeAllCovered, style: AppTextStyles.bodySmall)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final skill in missing) AppChip(label: skill, color: AppColors.red)],
            ),
          const SizedBox(height: 14),
          InfoNote(
            icon: Icons.warning_amber_rounded,
            color: AppColors.amber,
            title: l10n.analyzeWeakEvidence,
            body: weakNote,
          ),
          const SizedBox(height: 12),
          InfoNote(
            icon: Icons.lightbulb_outline_rounded,
            color: AppColors.purple,
            title: l10n.analyzeAiRecommendation,
            body: analysis.aiRecommendation.isEmpty
                ? 'Your ShipLink project strongly supports the real-time systems requirement. Prioritize this in your CV summary.'
                : analysis.aiRecommendation,
          ),
        ],
      ),
    );
  }
}

class _NewAnalysis extends StatelessWidget {
  const _NewAnalysis({
    required this.controller,
    required this.yearsController,
    required this.typeEntries,
    required this.educationEntries,
    required this.selectedType,
    required this.education,
    required this.analyzing,
    required this.onSelectType,
    required this.onSelectEducation,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final TextEditingController yearsController;
  final List<(String, String)> typeEntries;
  final List<(String, String)> educationEntries;
  final String selectedType;
  final String education;
  final bool analyzing;
  final ValueChanged<String> onSelectType;
  final ValueChanged<String> onSelectEducation;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var pressed = false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.analyzeIntro,
            style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 6,
              style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.6, color: AppColors.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: l10n.analyzeHint,
                hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (code, label) in typeEntries)
                GestureDetector(
                  onTap: analyzing ? null : () => onSelectType(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedType == code ? AppColors.teal.withValues(alpha: 0.12) : AppColors.cardHi,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selectedType == code ? AppColors.teal : AppColors.border),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selectedType == code ? AppColors.teal : AppColors.textSub,
                        fontWeight: selectedType == code ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.analyzeYourExperience,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: yearsController,
                        enabled: !analyzing,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, fontFamily: AppTextStyles.fontFamily, color: AppColors.text),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          hintText: l10n.analyzeYearsHint,
                          hintStyle: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.textMuted),
                        ),
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
                    Text(
                      l10n.analyzeHighestEducation,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: education,
                          isExpanded: true,
                          dropdownColor: AppColors.cardHi,
                          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
                          style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.fontFamily, color: AppColors.text),
                          items: [
                            for (final (code, label) in educationEntries)
                              DropdownMenuItem(value: code, child: Text(label)),
                          ],
                          onChanged: analyzing ? null : (v) => onSelectEducation(v ?? 'bachelor'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setPressed) {
              return GestureDetector(
                onTapDown: analyzing ? null : (_) => setPressed(() => pressed = true),
                onTapUp: analyzing ? null : (_) => setPressed(() => pressed = false),
                onTapCancel: () => setPressed(() => pressed = false),
                onTap: analyzing ? null : onAnalyze,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  scale: pressed && !analyzing ? 0.97 : 1.0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: analyzing ? AppColors.border : AppColors.teal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: analyzing
                          ? [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSub),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.analyzeAnalyzing,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSub,
                                ),
                              ),
                            ]
                          : [
                              Icon(Icons.bolt_rounded, size: 17, color: AppColors.background),
                              SizedBox(width: 8),
                              Text(
                                l10n.analyzeWithAi,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.background,
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (analyzing) ...[
            const SizedBox(height: 14),
            const NexoraShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShimmerBlock(height: 130, radius: 20),
                  SizedBox(height: 14),
                  ShimmerBlock(height: 80, radius: 16),
                  SizedBox(height: 14),
                  ShimmerBlock(height: 60, radius: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
