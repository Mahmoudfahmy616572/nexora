import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Profile-section row (icon + label + 3px progress + % + chevron) —
/// mirrors the design's `SectionRow` primitive.
class SectionRow extends StatelessWidget {
  const SectionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.pct,
    this.color = AppColors.teal,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double pct;
  final Color color;

  /// Invoked when the row is tapped (e.g. to open a section detail sheet).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = pct >= 100;
    final Color pctColor = done
        ? AppColors.teal
        : pct >= 80
            ? AppColors.textSub
            : AppColors.amber;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 3,
                      color: done ? AppColors.teal : color,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${pct.round()}%',
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppTextStyles.monoFont,
                fontWeight: FontWeight.w600,
                color: pctColor,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
