import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Uppercase mono section label — mirrors the design's `Label` primitive.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
    );
  }
}
