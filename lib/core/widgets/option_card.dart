import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tappable option used by the goal / stage / field choice screens.
///
/// Selected state uses the brand violet with a check well; the whole card is a
/// large hit target so it works on mobile and desktop alike.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.violet : AppColors.borderViolet;
    return Material(
      color: selected
          ? AppColors.violet.withValues(alpha: 0.12)
          : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: border.withValues(alpha: selected ? 0.9 : 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.violet.withValues(alpha: 0.22)
                      : AppColors.violet.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.violet : AppColors.violet,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTextStyles.bodySub.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.violet,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
