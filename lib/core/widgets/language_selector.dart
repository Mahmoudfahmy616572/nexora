import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Glassy pill language selector (globe + label + chevron).
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.onPressed, this.compact = false});

  final VoidCallback? onPressed;

  /// [compact] reduces padding on small screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 12.0 : 16.0;
    final vertical = compact ? 9.0 : 11.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x3894A0B8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 17, color: Color(0xFFD1D5DB)),
              const SizedBox(width: 9),
              const Text(
                'English',
                style: TextStyle(fontSize: 14, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
