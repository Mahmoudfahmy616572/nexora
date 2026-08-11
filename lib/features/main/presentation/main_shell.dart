import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'analyze_screen.dart';
import 'dna_screen.dart';
import 'home_screen.dart';
import 'studio_screen.dart';
import 'tracker_screen.dart';

enum MainTab { home, dna, analyze, studio, track }

/// The authenticated app shell — mirrors the design's phone frame:
/// a 5-item bottom navigation with a raised center "Analyze" button.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  MainTab _tab = MainTab.home;

  static const _screens = <Widget>[
    HomeScreen(),
    DnaScreen(),
    AnalyzeScreen(),
    StudioScreen(),
    TrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020510), Color(0xFF060919), Color(0xFF0A051E)],
            stops: [0, 0.4, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 90,
              left: -80,
              child: _Glow(size: 300, color: Color(0x0F00D4AA)),
            ),
            const Positioned(
              bottom: 60,
              right: -60,
              child: _Glow(size: 380, color: Color(0x0F8B7EFF)),
            ),
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _tab.index,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomNav(current: _tab, onSelected: (t) => setState(() => _tab = t)),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF08091E),
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Row(
        children: [
          _NavItem(key: const ValueKey('nav_home'), icon: Icons.home_rounded, label: 'Home', tab: MainTab.home, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_dna'), icon: Icons.fingerprint, label: 'DNA', tab: MainTab.dna, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_analyze'), icon: Icons.track_changes_rounded, label: 'Analyze', tab: MainTab.analyze, current: current, onTap: onSelected, center: true),
          _NavItem(key: const ValueKey('nav_studio'), icon: Icons.description_rounded, label: 'Studio', tab: MainTab.studio, current: current, onTap: onSelected),
          _NavItem(key: const ValueKey('nav_track'), icon: Icons.bar_chart_rounded, label: 'Track', tab: MainTab.track, current: current, onTap: onSelected),
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
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!center) ...[
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: active ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
            SizedBox(
              height: center ? 56 : 24,
              child: center
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _CenterButton(active: active, icon: icon),
                    )
                  : Icon(icon, size: 20, color: active ? AppColors.teal : const Color(0x47E8EEFF)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.teal : const Color(0x47E8EEFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.active, required this.icon});

  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: active ? AppColors.teal : const Color(0x2400D4AA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? AppColors.teal : AppColors.tealBdr),
        boxShadow: active
            ? [BoxShadow(color: AppColors.fabShadow, blurRadius: 20, offset: const Offset(0, 4))]
            : null,
      ),
      child: Icon(icon, size: 20, color: active ? AppColors.background : AppColors.teal),
    );
  }
}
