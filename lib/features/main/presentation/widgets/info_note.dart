import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Colored callout note (evidence / weak-evidence / recommendation) —
/// mirrors the design's amber/purple note boxes.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppTextStyles.monoFont,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: AppTextStyles.bodySub.copyWith(
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
