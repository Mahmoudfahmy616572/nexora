import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_chip.dart';
import 'widgets/progress_bar.dart';
import 'widgets/progress_ring.dart';
import 'widgets/section_label.dart';

/// Home dashboard — mirrors the design's Home screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHeader(),
          SizedBox(height: 4),
          _DnaHealthCard(),
          SizedBox(height: 14),
          _QuickActions(),
          _RecentActivity(),
          _Upcoming(),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('☀️ Good morning', style: AppTextStyles.mono),
              SizedBox(height: 2),
              Text('Ahmed Al-Rashidi', style: AppTextStyles.screenTitle),
            ],
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 15, color: AppColors.textSub),
              ),
              const SizedBox(width: 9),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.signatureGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    fontFamily: AppTextStyles.displayFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
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

class _DnaHealthCard extends StatelessWidget {
  const _DnaHealthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.cardHi],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderMed),
      ),
      child: Row(
        children: [
          const ProgressRing(
            value: 82,
            center: RingScore(value: '82', caption: 'DNA'),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text('Career DNA Health', style: AppTextStyles.cardTitle),
                    ),
                    const SizedBox(width: 8),
                    const AppChip(label: 'On Track'),
                  ],
                ),
                const SizedBox(height: 6),
                const ProgressBar(label: 'Profile', value: 95),
                const ProgressBar(label: 'Activity', value: 68, color: AppColors.purple),
                ProgressBar(label: 'Match Rate', value: 84, color: AppColors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem(this.icon, this.label, this.sub, this.color);
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _items = [
    _QuickActionItem(Icons.track_changes_rounded, 'Analyze Job', 'Match & gaps', AppColors.teal),
    _QuickActionItem(Icons.description_rounded, 'Create CV', 'AI-powered', AppColors.purple),
    _QuickActionItem(Icons.mic_rounded, 'Practice', 'AI interview', AppColors.amber),
    _QuickActionItem(Icons.bar_chart_rounded, 'Track Apps', '6 active', AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Quick Actions'),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              mainAxisExtent: 106,
            ),
            children: [
              for (final item in _items)
                Container(
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 16, color: item.color),
                      ),
                      const Spacer(),
                      Text(item.label, style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(item.sub, style: AppTextStyles.bodySmall),
                    ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Recent Activity'),
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
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _items[i].color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(_items[i].icon, size: 13, color: _items[i].color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _items[i].text,
                            style: AppTextStyles.bodySub.copyWith(fontSize: 12, height: 1.45),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Upcoming'),
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
                          Icon(Icons.schedule_rounded, size: 11, color: AppColors.teal),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Interview · Tomorrow 3:00 PM',
                              style: TextStyle(
                                fontSize: 11,
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic_rounded, size: 17, color: AppColors.background),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
