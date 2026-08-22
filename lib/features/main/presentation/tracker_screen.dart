import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../domain/entities/job_application.dart';
import '../../../domain/repositories/job_application_repository.dart';
import 'widgets/app_chip.dart';
import 'widgets/section_label.dart';

/// Application Tracker — mirrors the design's Track screen.
///
/// Applications are data-driven and persist across restarts (Supabase when
/// signed in, SharedPreferences offline): stats and the pipeline are derived
/// from the current list, new applications are added via a form, and tapping
/// a card lets you advance its status or remove it.
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

String _statusLabel(AppLocalizations l10n, String code) => switch (code) {
      'Applied' => l10n.trackerStatusApplied,
      'Under Review' => l10n.trackerStatusUnderReview,
      'Assessment' => l10n.trackerStatusAssessment,
      'Interview' => l10n.trackerStatusInterview,
      'Offer 🎉' => l10n.trackerStatusOffer,
      'Rejected' => l10n.trackerStatusRejected,
      _ => code,
    };

String _stageLabel(AppLocalizations l10n, String stage) => switch (stage) {
      'Applied' => l10n.trackerApplied,
      'Review' => l10n.trackerReview,
      'Interview' => l10n.trackerInterview,
      'Offer' => l10n.trackerOffer,
      _ => stage,
    };

class _TrackerScreenState extends State<TrackerScreen> {
  static const List<String> _statuses = [
    'Applied',
    'Under Review',
    'Assessment',
    'Interview',
    'Offer 🎉',
    'Rejected',
  ];

  static const List<JobApplication> _seedApps = [
    JobApplication(id: 'app1', company: 'Google', role: 'Flutter Engineer', status: 'Interview', date: 'Aug 17', match: 91, ats: 92),
    JobApplication(id: 'app2', company: 'Careem', role: 'Mobile Developer', status: 'Under Review', date: 'Applied Aug 10', match: 82, ats: 87),
    JobApplication(id: 'app3', company: 'Noon', role: 'Frontend Engineer', status: 'Assessment', date: 'Due Aug 14', match: 78, ats: 81),
    JobApplication(id: 'app4', company: 'Noon Commerce', role: 'Frontend Engineer', status: 'Offer 🎉', date: 'Aug 1', match: 88, ats: 89),
    JobApplication(id: 'app5', company: 'Jumia', role: 'Mobile Developer', status: 'Rejected', date: 'Jul 28', match: 71, ats: 75),
  ];

  late List<JobApplication> _apps = [..._seedApps];
  JobApplicationRepository? _repository;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final repository = JobApplicationRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    _repository = repository;
    final apps = await repository.load();
    if (!mounted) return;
    if (apps == null) {
      await repository.saveAll(_apps);
      return;
    }
    setState(() => _apps = apps);
  }

  Future<void> _persistApps() async {
    await _repository?.saveAll(_apps);
  }

  static String _stageOf(String status) {
    if (status.startsWith('Offer')) return 'Offer';
    if (status == 'Rejected') return 'Rejected';
    if (status == 'Interview') return 'Interview';
    if (status == 'Assessment' || status == 'Under Review') return 'Review';
    return 'Applied';
  }

  static Color _colorOf(String status) {
    if (status.startsWith('Offer')) return AppColors.green;
    if (status == 'Rejected') return AppColors.red;
    if (status == 'Interview') return AppColors.teal;
    if (status == 'Assessment') return AppColors.amber;
    return AppColors.purple;
  }

  int get _total => _apps.length;
  int get _active => _apps.where((a) => a.active).length;
  int get _interviews => _apps.where((a) => _stageOf(a.status) == 'Interview').length;
  int get _offers => _apps.where((a) => _stageOf(a.status) == 'Offer').length;
  int _inStage(String stage) => _apps.where((a) => _stageOf(a.status) == stage).length;

  Future<void> _showAddAppSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_AddAppResult>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddAppSheet(statuses: _statuses),
    );
    if (result == null || !mounted) return;

    final seed = result.company.length + result.role.length;
    final match = 70 + (seed % 21);
    setState(() {
      _apps = [
        JobApplication(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          company: result.company,
          role: result.role,
          status: result.status,
          date: 'Applied Just now',
          match: match,
          ats: (match + 4).clamp(0, 100),
        ),
        ..._apps,
      ];
    });
    await _persistApps();
    if (!mounted) return;
    _snack(l10n.trackerCompanyAdded(result.company));
  }

  Future<void> _openAppDetail(JobApplication app) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_AppEditResult>(
      context: context,
      backgroundColor: AppColors.cardHi,
      showDragHandle: true,
      builder: (_) => _AppDetailSheet(app: app, statuses: _statuses),
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      setState(() {
        _apps = [for (final a in _apps) if (a.id != app.id) a];
      });
      await _persistApps();
      if (!mounted) return;
      _snack(l10n.trackerRemoved);
      return;
    }
    final newStatus = result.status;
    if (result.prepare) {
      if (!mounted) return;
      context.push(
        Routes.interviewPrep,
        extra: {'role': app.role, 'company': app.company, 'applicationId': app.id},
      );
      return;
    }
    if (newStatus == null || newStatus == app.status) return;
    setState(() {
      _apps = [
        for (final a in _apps)
          a.id == app.id ? a.copyWith(status: newStatus) : a,
      ];
    });
    await _persistApps();
    if (!mounted) return;
    _snack('${l10n.trackerMovedTo} ${_statusLabel(l10n, newStatus)}');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeApps = [for (final a in _apps) if (a.active) a];
    final doneApps = [for (final a in _apps) if (!a.active) a];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackerHeader(onAdd: _showAddAppSheet),
          const SizedBox(height: 4),
          _StatsRow(
            total: _total,
            active: _active,
            interviews: _interviews,
            offers: _offers,
          ),
          _Pipeline(countFor: _inStage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.trackerActiveSection),
                for (final app in activeApps) _AppCard(app: app, onTap: () => _openAppDetail(app)),
                const SizedBox(height: 6),
                SectionLabel(l10n.trackerCompletedSection),
                for (final app in doneApps) _AppCard(app: app, completed: true, onTap: () => _openAppDetail(app)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerHeader extends StatelessWidget {
  const _TrackerHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(l10n.trackerTitle, style: AppTextStyles.screenTitle, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: AppColors.background),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.total, required this.active, required this.interviews, required this.offers});

  final int total;
  final int active;
  final int interviews;
  final int offers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = [
      (key: 'total', label: l10n.trackerTotal, value: total, color: AppColors.textSub),
      (key: 'active', label: l10n.trackerActive, value: active, color: AppColors.teal),
      (key: 'interviews', label: l10n.trackerInterviews, value: interviews, color: AppColors.purple),
      (key: 'offers', label: l10n.trackerOffers, value: offers, color: AppColors.green),
    ];
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = stats[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${s.value}',
                  key: ValueKey('stat_${s.key}'),
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: AppTextStyles.monoFont,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: s.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.label, style: AppTextStyles.bodyMuted),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.countFor});

  final int Function(String stage) countFor;

  static const _stages = [
    ('Applied', 'applied', AppColors.textSub),
    ('Review', 'review', AppColors.purple),
    ('Interview', 'interview', AppColors.teal),
    ('Offer', 'offer', AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.trackerPipeline),
          Row(
            children: [
              for (var i = 0; i < _stages.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _stages[i].$3.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: _stages[i].$3.withValues(alpha: 0.19)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${countFor(_stages[i].$1)}',
                          key: ValueKey('pipe_${_stages[i].$2}'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTextStyles.monoFont,
                            color: _stages[i].$3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(_stageLabel(l10n, _stages[i].$1), textAlign: TextAlign.center, style: AppTextStyles.bodyMuted.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                if (i < _stages.length - 1)
                  Container(width: 18, height: 1, color: AppColors.border),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onTap, this.completed = false});

  final JobApplication app;
  final VoidCallback onTap;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _TrackerScreenState._colorOf(app.status);
    final icon = completed && app.status.startsWith('Offer') ? Icons.emoji_events_rounded : Icons.work_rounded;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: completed ? 0.72 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: completed ? 0.06 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: completed ? null : Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.company, style: AppTextStyles.body),
                        const SizedBox(height: 2),
                        Text(app.role, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (!completed) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppChip(label: _statusLabel(l10n, app.status), color: color, size: 10),
                        const SizedBox(height: 4),
                        Text(l10n.trackerMatchPct(app.match), style: AppTextStyles.mono),
                      ],
                    ),
                    ] else
                      AppChip(label: _statusLabel(l10n, app.status), color: color, size: 10),
                ],
              ),
              if (!completed) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _MetaPill(icon: Icons.schedule_rounded, text: app.date)),
                    const SizedBox(width: 6),
                    Expanded(child: _MetaPill(icon: Icons.verified_user_outlined, text: l10n.trackerAts(app.ats))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardHi,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mono,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAppResult {
  const _AddAppResult({required this.company, required this.role, required this.status});

  final String company;
  final String role;
  final String status;
}

class _AddAppSheet extends StatefulWidget {
  const _AddAppSheet({required this.statuses});

  final List<String> statuses;

  @override
  State<_AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends State<_AddAppSheet> {
  final TextEditingController _company = TextEditingController();
  final TextEditingController _role = TextEditingController();
  String _status = 'Applied';

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    super.dispose();
  }

  void _submit() {
    final company = _company.text.trim();
    final role = _role.text.trim();
    if (company.isEmpty || role.isEmpty) return;
    Navigator.of(context).pop(_AddAppResult(company: company, role: role, status: _status));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(l10n.trackerAddApp, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(l10n.trackerAddAppSub, style: AppTextStyles.bodySub),
          const SizedBox(height: 16),
          TextField(
            controller: _company,
            decoration: InputDecoration(
              hintText: l10n.trackerCompany,
              filled: true,
              fillColor: AppColors.card,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _role,
            decoration: InputDecoration(
              hintText: l10n.trackerRole,
              filled: true,
              fillColor: AppColors.card,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(color: AppColors.text),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Text(l10n.trackerStatus, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in widget.statuses)
                ChoiceChip(
                  label: Text(_statusLabel(l10n, s)),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: _TrackerScreenState._colorOf(s).withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: _status == s ? _TrackerScreenState._colorOf(s) : AppColors.textSub,
                  ),
                  side: BorderSide(color: _status == s ? _TrackerScreenState._colorOf(s) : AppColors.border),
                  backgroundColor: AppColors.card,
                ),
            ],
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
              child: Text(l10n.trackerAddAppBtn, style: AppTextStyles.primaryButton),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isInterviewStage(String status) =>
    status == 'Interview' || status == 'Assessment';

class _AppEditResult {
  const _AppEditResult.status(this.status) : delete = false, prepare = false;
  const _AppEditResult.delete() : status = null, delete = true, prepare = false;
  const _AppEditResult.prepare() : status = null, delete = false, prepare = true;

  final String? status;
  final bool delete;
  final bool prepare;
}

class _AppDetailSheet extends StatelessWidget {
  const _AppDetailSheet({required this.app, required this.statuses});

  final JobApplication app;
  final List<String> statuses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _TrackerScreenState._colorOf(app.status);
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.work_rounded, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.company, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(app.role, style: AppTextStyles.bodySub),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(l10n.trackerCurrentStatus, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          AppChip(label: _statusLabel(l10n, app.status), color: color),
          const SizedBox(height: 14),
          Text(l10n.trackerMoveTo, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in statuses)
                if (s != app.status)
                  ChoiceChip(
                    label: Text(_statusLabel(l10n, s)),
                    selected: false,
                    onSelected: (_) => Navigator.of(context).pop(_AppEditResult.status(s)),
                    selectedColor: _TrackerScreenState._colorOf(s).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                      color: _TrackerScreenState._colorOf(s),
                    ),
                    side: BorderSide(color: _TrackerScreenState._colorOf(s)),
                    backgroundColor: AppColors.card,
                  ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isInterviewStage(app.status)) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(const _AppEditResult.prepare()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.psychology_alt_outlined, size: 18),
                label: Text(l10n.acCtaPrepareInterview),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(const _AppEditResult.delete()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: Text(l10n.trackerDeleteApplication),
            ),
          ),
        ],
      ),
    );
  }
}
