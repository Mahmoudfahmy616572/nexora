import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Mono pill chip — mirrors the design's `Chip` primitive
/// (10% fill, ~19% stroke, mono text).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color = AppColors.teal,
    this.size = 11,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.19)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          fontFamily: AppTextStyles.monoFont,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.6,
        ),
      ),
    );
  }
}
