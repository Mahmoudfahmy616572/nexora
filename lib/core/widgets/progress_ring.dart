import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular progress ring with centered value — mirrors the "Career DNA
/// Health" gauge in the design (92px, 7px stroke, rounded caps).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.center,
    this.size = 92,
    this.stroke = 7,
    this.color = AppColors.teal,
  });

  final double value;
  final Widget center;
  final double size;
  final double stroke;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(value: value / 100, stroke: stroke, color: color),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.stroke, required this.color});

  final double value;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.stroke != stroke || oldDelegate.color != color;
}

/// Ring center showing a big mono value with a small caption.
class RingScore extends StatelessWidget {
  const RingScore({super.key, required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.metric.copyWith(fontSize: 23, height: 1)),
        const SizedBox(height: 2),
        Text(
          caption,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.textMuted,
            fontFamily: AppTextStyles.monoFont,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
