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

/// The authenticated app shell — mirrors the design's phone frame:
/// a 5-item bottom navigation with a raised center "Analyze" module.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = MainTab.home});

  /// Lets auth flows drop a brand-new (empty-profile) user straight onto the
  /// DNA tab so the "Build your Career DNA" nudge shows before anything else.
  final MainTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late MainTab _tab = widget.initialTab;
  String? _studioTargetId;
  String? _studioAnalysisId;

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

  Widget _currentScreen() {
    if (_tab == MainTab.studio) {
      return StudioScreen(
        key: const ValueKey('studio'),
        targetId: _studioTargetId,
        analysisId: _studioAnalysisId,
      );
    }
    final index = _tab.index > 2 ? _tab.index - 1 : _tab.index;
    return _screens[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomNav(current: _tab, onSelected: (t) => setState(() => _tab = t)),
      ),
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
