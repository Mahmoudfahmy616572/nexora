import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/nexora_buttons.dart';

/// Temporary target for flows whose approved design is not yet delivered.
/// Each instance is replaced by its real screen as screens arrive.
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction_rounded, color: AppColors.purple, size: 44),
                const SizedBox(height: 20),
                Text(title, style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Text(
                  'Design pending — this screen will be implemented '
                  'from the approved design.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.featureSubtitle,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 260,
                  child: NexoraSecondaryButton(
                    label: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
