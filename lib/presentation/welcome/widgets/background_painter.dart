import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Solid deep-ink background behind the welcome content.
class WelcomeBackgroundPainter extends CustomPainter {
  const WelcomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(covariant WelcomeBackgroundPainter oldDelegate) => false;
}
