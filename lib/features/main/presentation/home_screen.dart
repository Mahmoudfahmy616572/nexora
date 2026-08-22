import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/locale_cubit.dart';
import '../../../core/theme/app_colors.dart';
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
  /// Falls back to the design's sample profile when no session is available
  /// (cold start without a stored session, widget tests, etc.).
  String _displayName = 'Ahmed Al-Rashidi';

  late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _loadUser();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHeader(
            name: _displayName,
            greeting: _greeting(l10n),
            onOpenProfile: () => GoRouter.of(context).push(Routes.settings),
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
          _QuickActions(onOpenTab: widget.onOpenTab),
          const _RecentActivity(),
          const _Upcoming(),
        ],
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.signatureGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isEmpty ? 'N' : name[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<MainTab> onOpenTab;

  List<_QuickActionItem> _items(AppLocalizations l10n) => [
        _QuickActionItem(Icons.track_changes_rounded, l10n.homeAnalyzeJob, l10n.homeMatchGaps, AppColors.teal, MainTab.analyze),
        _QuickActionItem(Icons.description_rounded, l10n.homeCreateCv, l10n.homeAiPowered, AppColors.purple, MainTab.studio),
        _QuickActionItem(Icons.mic_rounded, l10n.homePractice, l10n.homeAiInterview, AppColors.amber, null),
        _QuickActionItem(Icons.bar_chart_rounded, l10n.homeTrackApps, l10n.homeSixActive, AppColors.green, MainTab.track),
      ];

  void _onTap(BuildContext context, _QuickActionItem item) {
    final l10n = AppLocalizations.of(context)!;
    final tab = item.tab;
    if (tab == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.homeComingSoon),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.cardHi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      return;
    }
    onOpenTab(tab);
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
                GestureDetector(
                  onTap: () => _onTap(context, item),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
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
  const _RecentActivity();

  static const _items = [
    _ActivityItem(Icons.track_changes_rounded, 'New 91% match for Google Flutter role', '2h ago', AppColors.teal),
    _ActivityItem(Icons.bolt_rounded, 'CV optimized · +3 ATS points (89→92)', 'Yesterday', AppColors.purple),
    _ActivityItem(Icons.mic_rounded, 'Interview practice · HR round · Score 78%', '2d ago', AppColors.amber),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                for (var i = 0; i < _items.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: i < _items.length - 1
                        ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border)))
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _items[i].color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_items[i].icon, size: 15, color: _items[i].color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _items[i].text,
                            style: AppTextStyles.bodySub.copyWith(fontSize: 13, height: 1.45),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_items[i].time, style: AppTextStyles.mono),
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

class _Upcoming extends StatelessWidget {
  const _Upcoming();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.homeUpcoming),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.tealBdr),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google · Flutter Engineer', style: AppTextStyles.body),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: AppColors.teal),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Interview · Tomorrow 3:00 PM',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppTextStyles.monoFont,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.mic_rounded, size: 18, color: AppColors.background),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
