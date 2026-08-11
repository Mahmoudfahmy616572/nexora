import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Trust indicator: icon + bold title + muted subtitle.
class TrustItem extends StatelessWidget {
  const TrustItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 11),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.trustTitle),
            const SizedBox(height: 3),
            Text(subtitle, style: AppTextStyles.trustSubtitle),
          ],
        ),
      ],
    );
  }
}
