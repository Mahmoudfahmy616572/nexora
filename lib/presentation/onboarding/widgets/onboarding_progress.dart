import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Segmented progress bar for the onboarding carousel.
///
/// Each segment represents one slide; segments up to the current one are
/// filled, so the user always sees how many of the [count] steps remain.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 176),
        child: Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.teal : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: i <= current
                        ? [BoxShadow(color: AppColors.tealBg, blurRadius: 8)]
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
