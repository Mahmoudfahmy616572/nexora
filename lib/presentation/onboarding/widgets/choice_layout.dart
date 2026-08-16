import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/nexora_buttons.dart';
import '../../../l10n/app_localizations.dart';

/// Responsive scaffold shared by the goal / stage / field selection screens:
/// a centered, scrollable column with a title, subtitle, optional progress, the
/// choice cards, and a footer with back / continue.
class ChoiceLayout extends StatelessWidget {
  const ChoiceLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.progress,
    required this.children,
    required this.onContinue,
    this.onBack,
    this.continueLabel,
    this.continueEnabled = true,
    this.footerNote,
  });

  final String title;
  final String subtitle;
  final double? progress;
  final List<Widget> children;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final String? continueLabel;
  final bool continueEnabled;
  final Widget? footerNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = Breakpoints.isDesktop(context) ? 760.0 : 560.0;
            return SingleChildScrollView(
              padding: AppBreakpointValues.of<EdgeInsets>(
                context,
                mobile: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                desktop: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (onBack != null) ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: onBack,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (progress != null) ...[
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.borderViolet,
                          color: AppColors.violet,
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(subtitle, style: AppTextStyles.bodySub.copyWith(height: 1.5)),
                      const SizedBox(height: 22),
                      ...children,
                      const SizedBox(height: 26),
                      NexoraPrimaryButton(
                        label: continueLabel ?? l10n.continueLabel,
                        onPressed: continueEnabled ? onContinue : null,
                      ),
                      if (footerNote != null) ...[
                        const SizedBox(height: 14),
                        footerNote!,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
