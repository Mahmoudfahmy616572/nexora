import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Ambient gradient + signature radial glows behind the welcome content.
class WelcomeBackgroundPainter extends CustomPainter {
  const WelcomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.5, 1],
          colors: [
            AppColors.background,
            AppColors.backgroundGradientMid,
            AppColors.background,
          ],
        ).createShader(rect),
    );

    void radial(Offset center, double radius, List<Color> colors, List<double> stops) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: colors,
            stops: stops,
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    radial(
      Offset(size.width * 0.72, size.height * 0.32),
      size.width * 0.28,
      const [Color(0x215D2BAA), Colors.transparent],
      const [0, 1],
    );
    radial(
      Offset(size.width * 0.90, size.height * 0.50),
      size.width * 0.30,
      const [Color(0x1A2563EB), Colors.transparent],
      const [0, 1],
    );
    radial(
      Offset(size.width * 0.85, size.height * 0.10),
      math.min(size.width, size.height) * 0.30,
      const [Color(0x407C3AED), Color(0x147C3AED), Colors.transparent],
      const [0, 0.5, 1],
    );
    radial(
      Offset(size.width * 0.95, size.height * 0.80),
      math.min(size.width, size.height) * 0.24,
      const [Color(0x402563EB), Color(0x142563EB), Colors.transparent],
      const [0, 0.5, 1],
    );
  }

  @override
  bool shouldRepaint(covariant WelcomeBackgroundPainter oldDelegate) => false;
}
