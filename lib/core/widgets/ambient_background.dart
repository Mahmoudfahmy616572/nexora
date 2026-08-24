import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ambient app background: solid deep-ink, shared by pre-auth screens so they
/// feel part of the main app shell.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: child,
    );
  }
}
