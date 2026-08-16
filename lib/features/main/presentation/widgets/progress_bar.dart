import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Labeled horizontal progress bar — mirrors the design's `Bar` primitive
/// (4px track, rounded, mono % value). The fill animates up from zero on first
/// paint for a touch of delight.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.teal,
    this.height = 4,
  });

  final String label;
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  '${value.round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: AppTextStyles.monoFont,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: value.clamp(0, 100) / 100),
            builder: (context, fill, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: height,
                color: color,
                backgroundColor: AppColors.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
