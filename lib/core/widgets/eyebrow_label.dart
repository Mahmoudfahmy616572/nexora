import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Section eyebrow label (e.g. "WELCOME TO NEXORA").
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.eyebrow);
  }
}
