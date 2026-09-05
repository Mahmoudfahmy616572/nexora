import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'analyze_screen.dart';
import 'dna_screen.dart';
import 'home_screen.dart';
import 'main_tab.dart';
import 'studio_screen.dart';
import 'tracker_screen.dart';

/// The authenticated app shell — bottom nav on mobile, NavigationRail on wide.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = MainTab.home});

  final MainTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late MainTab _tab = widget.initialTab;
  String? _studioTargetId;
  String? _studioAnalysisId;
  String? _pendingDnaSection;
  DateTime? _lastBackPress;

  late final List<Widget> _screens = [
    HomeScreen(onOpenTab: (tab) => setState(() => _tab = tab)),
    const DnaScreen(),
    AnalyzeScreen(onOpenStudio: _openStudio),
    const TrackerScreen(),
  ];

  void _openStudio(String? targetId, String? analysisId) {
    setState(() {
      _studioTargetId = targetId;
      _studioAnalysisId = analysisId;
      _tab = MainTab.studio;
    });
  }

  void openDnaSection(String sectionKey) {
    setState(() {
      _pendingDnaSection = sectionKey;
      _tab = MainTab.dna;
    });
  }

  Widget _currentScreen() {
    if (_tab == MainTab.studio) {
      return StudioScreen(
        key: const ValueKey('studio'),
        targetId: _studioTargetId,
        analysisId: _studioAnalysisId,
        onOpenTab: (tab) => setState(() => _tab = tab),
        onOpenDnaSection: openDnaSection,
      );
    }
    if (_tab == MainTab.dna && _pendingDnaSection != null) {
      final key = _pendingDnaSection;
      _pendingDnaSection = null;
      return DnaScreen(pendingSectionKey: key);
    }
    final index = _tab.index > 2 ? _tab.index - 1 : _tab.index;
    return _screens[index];
  }

  int get _selectedIndex {
    if (_tab == MainTab.studio) return 4;
    return _tab.index > 2 ? _tab.index - 1 : _tab.index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          Navigator.of(context).maybePop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exitConfirm),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    _WideNavRail(
                      current: _tab,
                      onSelected: (t) => setState(() => _tab = t),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.border),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MotionTokens.fast,
                        switchInCurve: MotionTokens.standard,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(_tab),
                          child: _currentScreen(),
                        ),
                      ),
                    ),
                  ],
                )
              : AnimatedSwitcher(
                  duration: MotionTokens.fast,
                  switchInCurve: MotionTokens.standard,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: _currentScreen(),
                  ),
                ),
        ),
        bottomNavigationBar: isWide
            ? null
            : SafeArea(
                top: false,
                child: _BottomNav(current: _tab, onSelected: (t) => setState(() => _tab = t)),
              ),
      ),
    );

    return content;
  }
}

/// Side navigation rail for wide screens.
class _WideNavRail extends StatelessWidget {
  const _WideNavRail({required this.current, required this.onSelected});

  final MainTab current;
  final ValueChanged<MainTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      selectedIndex: current.index,
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.background,
      selectedIconTheme: const IconThemeData(color: AppColors.brand, size: 24),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.brand,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              'NEXORA',
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
      onDestinationSelected: (i) {
        final tabs = [MainTab.home, MainTab.dna, MainTab.analyze, MainTab.track, MainTab.studio];
        onSelected(tabs[i]);
      },
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_rounded),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text(l10n.navHome),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.fingerprint),
          selectedIcon: const Icon(Icons.fingerprint),
          label: Text(l10n.navDna),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.track_changes_rounded),
          selectedIcon: const Icon(Icons.track_changes_rounded),
          label: Text(l10n.navAnalyze),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: Text(l10n.navTrack),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.description_rounded),
          selectedIcon: const Icon(Icons.description_rounded),
          label: Text(l10n.navStudio),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onSelected});

  final MainTab current;
  final ValueChanged<MainTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: Row(
        children: [
          _NavItem(key: const ValueKey('nav_home'), icon: Icons.home_rounded, label: l10n.navHome, tab: MainTab.home, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_dna'), icon: Icons.fingerprint, label: l10n.navDna, tab: MainTab.dna, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_analyze'), icon: Icons.track_changes_rounded, label: l10n.navAnalyze, tab: MainTab.analyze, current: current, onTap: onSelected, center: true),
          _NavItem(key: const ValueKey('nav_studio'), icon: Icons.description_rounded, label: l10n.navStudio, tab: MainTab.studio, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_track'), icon: Icons.bar_chart_rounded, label: l10n.navTrack, tab: MainTab.track, current: current, onTap: onSelected),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.tab,
    required this.current,
    required this.onTap,
    this.center = false,
  });

  final IconData icon;
  final String label;
  final MainTab tab;
  final MainTab current;
  final ValueChanged<MainTab> onTap;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final active = current == tab;
    if (center) {
      return Expanded(
        child: NxPress(
          onTap: () => onTap(tab),
          child: _CenterModule(active: active, icon: icon),
        ),
      );
    }
    return Expanded(
      child: NxPress(
        onTap: () => onTap(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: MotionTokens.fast,
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Icon(icon, size: 22, color: active ? AppColors.brand : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontFamily: AppTextStyles.monoFont,
                letterSpacing: 0.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterModule extends StatelessWidget {
  const _CenterModule({required this.active, required this.icon});

  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MotionTokens.base,
      curve: MotionTokens.standard,
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: active ? AppColors.brand : AppColors.surfaceHi,
        borderRadius: AppRadius.asymmetric,
        border: Border.all(
          color: active ? AppColors.brand : AppColors.tealBdr,
          width: 1.5,
        ),
        boxShadow: active ? AppElevation.low : AppElevation.flat,
      ),
      child: Icon(icon, size: 22, color: active ? AppColors.background : AppColors.brand),
    );
  }
}
