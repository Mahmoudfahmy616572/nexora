import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// "Your data is private and secure. We never share your information."
/// Uses a [Wrap] so the tagline can flow across lines on narrow screens.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 4,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.purple),
        Text(l10n.privacySecure, style: AppTextStyles.privacyNote),
        Text(l10n.privacyShare, style: AppTextStyles.privacyNoteStrong),
      ],
    );
  }
}
