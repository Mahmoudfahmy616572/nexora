import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// "Your data is private and secure. We never share your information."
/// Uses a [Wrap] so the tagline can flow across lines on narrow screens.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 4,
      children: const [
        Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFB66CFF)),
        Text('Your data is private and secure.', style: AppTextStyles.privacyNote),
        Text('We never share your information.', style: AppTextStyles.privacyNoteStrong),
      ],
    );
  }
}
