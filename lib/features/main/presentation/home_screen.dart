import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/app_language.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../data/data_sources/auth_remote_data_source.dart';
import '../../../data/data_sources/career_local_data_source.dart';
import '../../../data/data_sources/career_remote_data_source.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/career_dna_repository_impl.dart';
import '../../../data/repositories/career_repository_impl.dart';
import '../../../data/repositories/cv_evaluation_repository_impl.dart';
import '../../../data/repositories/cv_suggestion_repository_impl.dart';
import '../../../features/main/presentation/home/action_center_cubit.dart';
import '../../../features/main/presentation/home/action_center_hero.dart';
import 'main_tab.dart';
import 'widgets/section_label.dart';

/// Home dashboard — mirrors the design's Home screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the app shell to the given destination tab.
  final ValueChanged<MainTab> onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = '';

  late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<_ActivityItem> _activityItems = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadActivity();
  }

  ActionCenterCubit _buildActionCenterCubit(SharedPreferences prefs) {
    final local = CareerLocalDataSource(prefs);
    final remote = CareerRemoteDataSource();
    return ActionCenterCubit(
      dnaRepo: CareerDnaRepositoryImpl(remote: remote, local: local),
      targetRepo: CareerTargetRepositoryImpl(remote, local),
      analysisRepo: JobAnalysisRepositoryImpl(remote, local),
      docRepo: CvDocumentRepositoryImpl(remote, local),
      evalRepo: CvEvaluationRepositoryImpl(remote, local, CvSuggestionRepositoryImpl(local)),
      suggestionRepo: CvSuggestionRepositoryImpl(local),
      applicationRepo: JobApplicationRepositoryImpl(remote, local),
    );
  }

  void _loadUser() {
    try {
      final user = AuthRepositoryImpl(AuthRemoteDataSource()).currentUser;
      if (user == null) return;
      final fullName = user.fullName?.trim() ?? '';
      if (fullName.isNotEmpty) {
        _displayName = fullName;
      } else if (user.email.isNotEmpty) {
        _displayName = user.email.split('@').first;
      }
    } catch (_) {
      // Supabase may be unavailable (e.g., widget tests) — keep the fallback.
    }
  }

  Future<void> _loadActivity() async {
    final prefs = await _prefs;
    final ds = CareerLocalDataSource(prefs);
    final log = await ds.readActivityLog();
    if (!mounted) return;
    setState(() {
      _activityItems = [
        for (final e in log)
          _ActivityItem(
            _iconForType(e['type'] as String? ?? ''),
            e['text'] as String? ?? '',
            _relativeTime(e['timestamp'] as String? ?? ''),
            _colorForType(e['type'] as String? ?? ''),
          ),
      ];
    });
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.track_changes_rounded;
      case 'cv':
        return Icons.bolt_rounded;
      case 'interview':
        return Icons.mic_rounded;
      case 'analysis':
        return Icons.analytics_rounded;
      default:
        return Icons.circle;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'match':
        return AppColors.teal;
      case 'cv':
        return AppColors.purple;
      case 'interview':
        return AppColors.amber;
      case 'analysis':
        return AppColors.brand;
      default:
        return AppColors.muted;
    }
  }

  static String _relativeTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 18) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NxReveal(
                child: _HomeHeader(
                  name: _displayName.isEmpty ? l10n.guestName : _displayName,
                  greeting: _greeting(l10n),
                  onOpenProfile: () => GoRouter.of(context).push(Routes.settings),
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<SharedPreferences>(
            future: _prefs,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done ||
                  snap.data == null) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return BlocProvider<ActionCenterCubit>(
                create: (_) => _buildActionCenterCubit(snap.data!)..load(),
                child: ActionCenterHero(onOpenTab: widget.onOpenTab),
              );
            },
          ),
          const SizedBox(height: 14),
          NxReveal(
            delay: const Duration(milliseconds: 80),
            child: _QuickActions(onOpenTab: widget.onOpenTab),
          ),
          NxReveal(
            delay: const Duration(milliseconds: 160),
            child: _RecentActivity(items: _activityItems),
          ),
        ],
       ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.greeting,
    this.onOpenProfile,
  });

  final String name;
  final String greeting;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.watch<LocaleCubit>();
    final targetLabel = localeCubit.state.language == AppLanguage.english ? l10n.langArabic : l10n.langEnglish;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTextStyles.mono),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: AppTextStyles.screenTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              IconButton(
                onPressed: localeCubit.toggleLanguage,
                icon: const Icon(Icons.language_rounded, color: AppColors.textSub),
                tooltip: targetLabel,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.textSub),
              ),
              const SizedBox(width: 9),
              GestureDetector(
                onTap: onOpenProfile,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: AppRadius.asymmetric,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isEmpty ? 'N' : name[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.background,
                    ),
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

class _QuickActionItem {
  const _QuickActionItem(this.icon, this.label, this.sub, this.color, this.tab);
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  /// Destination tab, or `null` when the action has no screen yet.
  final MainTab? tab;
}

class _QuickActions extends StatefulWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<MainTab> onOpenTab;

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadActiveCount();
  }

  Future<void> _loadActiveCount() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = JobApplicationRepositoryImpl(
      CareerRemoteDataSource(),
      CareerLocalDataSource(prefs),
    );
    final apps = await repo.load();
    if (!mounted) return;
    if (apps != null) {
      setState(() => _activeCount = apps.where((a) => a.active).length);
    }
  }

  List<_QuickActionItem> _items(AppLocalizations l10n) => [
        _QuickActionItem(Icons.track_changes_rounded, l10n.homeAnalyzeJob, l10n.homeMatchGaps, AppColors.teal, MainTab.analyze),
        _QuickActionItem(Icons.description_rounded, l10n.homeCreateCv, l10n.homeAiPowered, AppColors.purple, MainTab.studio),
        _QuickActionItem(Icons.mic_rounded, l10n.homePractice, l10n.homeAiInterview, AppColors.amber, null),
        _QuickActionItem(Icons.bar_chart_rounded, l10n.homeTrackApps, '$_activeCount active', AppColors.green, MainTab.track),
      ];

  void _onTap(BuildContext context, _QuickActionItem item) {
    final tab = item.tab;
    if (tab == null) {
      GoRouter.of(context).push(
        Routes.interviewPractice,
        extra: {'role': '', 'company': ''},
      );
      return;
    }
    widget.onOpenTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.homeQuickActions),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              mainAxisExtent: 120,
            ),
            children: [
              for (final item in _items(l10n))
                NxPress(
                  onTap: () => _onTap(context, item),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.module),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(item.icon, size: 18, color: item.color),
                        ),
                        const Spacer(),
                        Text(
                          item.label,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.sub,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _ActivityItem {
  const _ActivityItem(this.icon, this.text, this.time, this.color);
  final IconData icon;
  final String text;
  final String time;
  final Color color;
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.homeRecentActivity),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: i < items.length - 1
                        ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border)))
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: items[i].color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(items[i].icon, size: 15, color: items[i].color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            items[i].text,
                            style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.45),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(items[i].time, style: AppTextStyles.mono),
                      ],
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
