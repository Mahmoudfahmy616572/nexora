import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_chip.dart';
import 'widgets/section_label.dart';

/// Application Tracker — mirrors the design's Track screen.
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TrackerHeader(),
          const SizedBox(height: 4),
          const _StatsRow(),
          const _Pipeline(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Active'),
                for (final app in _AppModel.all.where((a) => a.active)) _AppCard(app: app),
                const SizedBox(height: 6),
                const SectionLabel('Completed'),
                for (final app in _AppModel.all.where((a) => !a.active)) _AppCard(app: app, completed: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppModel {
  const _AppModel({
    required this.company,
    required this.role,
    required this.status,
    required this.date,
    required this.match,
    required this.color,
    required this.ats,
    required this.active,
  });

  final String company;
  final String role;
  final String status;
  final String date;
  final int match;
  final Color color;
  final int ats;
  final bool active;

  static const List<_AppModel> all = [
    _AppModel(company: 'Google', role: 'Flutter Engineer', status: 'Interview', date: 'Aug 17', match: 91, color: AppColors.teal, ats: 92, active: true),
    _AppModel(company: 'Careem', role: 'Mobile Developer', status: 'Under Review', date: 'Applied Aug 10', match: 82, color: AppColors.purple, ats: 87, active: true),
    _AppModel(company: 'Noon', role: 'Frontend Engineer', status: 'Assessment', date: 'Due Aug 14', match: 78, color: AppColors.amber, ats: 81, active: true),
    _AppModel(company: 'Noon Commerce', role: 'Frontend Engineer', status: 'Offer 🎉', date: 'Aug 1', match: 88, color: AppColors.green, ats: 89, active: false),
    _AppModel(company: 'Jumia', role: 'Mobile Developer', status: 'Rejected', date: 'Jul 28', match: 71, color: AppColors.red, ats: 75, active: false),
  ];
}

class _TrackerHeader extends StatelessWidget {
  const _TrackerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Applications', style: AppTextStyles.screenTitle),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: AppColors.background),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  static const _stats = [
    _Stat('Total', 14, AppColors.textSub),
    _Stat('Active', 6, AppColors.teal),
    _Stat('Interviews', 3, AppColors.purple),
    _Stat('Offers', 1, AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _stats[i];
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
  const _Pipeline();

  static const _stages = [
    ('Applied', 6, AppColors.textSub),
    ('Review', 4, AppColors.purple),
    ('Interview', 3, AppColors.teal),
    ('Offer', 1, AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Pipeline'),
          Row(
            children: [
              for (var i = 0; i < _stages.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _stages[i].$3.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: _stages[i].$3.withValues(alpha: 0.19)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_stages[i].$2}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTextStyles.monoFont,
                            color: _stages[i].$3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(_stages[i].$1, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted.copyWith(fontSize: 9)),
                    ],
                  ),
                ),
                if (i < _stages.length - 1)
                  Container(width: 16, height: 1, color: AppColors.border),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, this.completed = false});

  final _AppModel app;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final icon = completed && app.status.contains('Offer') ? Icons.emoji_events_rounded : Icons.work_rounded;
    return Opacity(
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
                    color: app.color.withValues(alpha: completed ? 0.06 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: completed ? null : Border.all(color: app.color.withValues(alpha: 0.15)),
                  ),
                  child: Icon(icon, size: 17, color: app.color),
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
                      AppChip(label: app.status, color: app.color, size: 9),
                      const SizedBox(height: 4),
                      Text('${app.match}% match', style: AppTextStyles.mono),
                    ],
                  ),
                ] else
                  AppChip(label: app.status, color: app.color, size: 9),
              ],
            ),
            if (!completed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MetaPill(icon: Icons.schedule_rounded, text: app.date)),
                  const SizedBox(width: 6),
                  Expanded(child: _MetaPill(icon: Icons.verified_user_outlined, text: 'ATS ${app.ats}')),
                ],
              ),
            ],
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardHi,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 10, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.mono),
        ],
      ),
    );
  }
}
