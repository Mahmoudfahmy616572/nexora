import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Feature tile: icon well + title + subtitle (from the landing feature strip).
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.borderColor,
    this.center = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color borderColor;

  /// Whether to center the tile content within its cell.
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x1F6366F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.featureTitle),
              const SizedBox(height: 5),
              Text(subtitle, style: AppTextStyles.featureSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
