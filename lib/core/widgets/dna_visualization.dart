import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The Career DNA scene — the product's signature visual.
///
/// Designed at a fixed 620x590 "design size", then scaled to fit any container
/// via [FittedBox]. It can never overflow and adapts to every device size.
class DnaVisualization extends StatelessWidget {
  const DnaVisualization({super.key});

  static const double designWidth = 620;
  static const double designHeight = 590;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : designWidth;
        final height = (width * designHeight / designWidth).clamp(300.0, designHeight);
        return SizedBox(
          width: width,
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: const _Scene(),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Scene: painter (glow/orbits/platform/dna) + nodes + label
// -----------------------------------------------------------------------------

class _Scene extends StatelessWidget {
  const _Scene();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const double w = DnaVisualization.designWidth;
    const double h = DnaVisualization.designHeight;
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _DnaScenePainter())),
        Positioned(
          left: w * 0.02,
          top: h * 0.21,
          child: _DnaNode(
            icon: Icons.work_outline,
            label: l10n.dnaExperience,
            color: const Color(0xFFDCE1EB),
            borderColor: const Color(0xB3A855F7),
          ),
        ),
        Positioned(
          right: 0,
          top: h * 0.21,
          child: _DnaNode(
            icon: Icons.code_rounded,
            label: l10n.dnaSkills,
            color: const Color(0xFF69A3FF),
            borderColor: const Color(0xCC3B82F6),
          ),
        ),
        Positioned(
          left: 0,
          top: h * 0.42,
          child: _DnaNode(
            icon: Icons.developer_mode_rounded,
            label: l10n.dnaProjects,
            color: const Color(0xFFDCE1EB),
            borderColor: const Color(0xB3A855F7),
          ),
        ),
        Positioned(
          right: 0,
          top: h * 0.42,
          child: _DnaNode(
            icon: Icons.school_outlined,
            label: l10n.dnaEducation,
            color: const Color(0xFF69A3FF),
            borderColor: const Color(0xCC3B82F6),
          ),
        ),
        Positioned(
          left: w * 0.06,
          top: h * 0.68,
          child: _DnaNode(
            icon: Icons.emoji_events_outlined,
            label: l10n.dnaAchievements,
            color: const Color(0xFFDCE1EB),
            borderColor: const Color(0xB3A855F7),
          ),
        ),
        Positioned(
          right: w * 0.04,
          top: h * 0.68,
          child: _DnaNode(
            icon: Icons.workspace_premium_outlined,
            label: l10n.dnaCertifications,
            color: const Color(0xFF3BE4EF),
            borderColor: const Color(0xBF22D3EE),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: const _DnaLabel(),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Nodes
// -----------------------------------------------------------------------------

class _DnaNode extends StatelessWidget {
  const _DnaNode({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0x457C3AED), Color(0xD90F172A)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(color: AppColors.dnaLabelShadow, blurRadius: 18),
            ],
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 7),
        Text(label, style: AppTextStyles.dnaNode),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Center label
// -----------------------------------------------------------------------------

class _DnaLabel extends StatelessWidget {
  const _DnaLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xE0110C27), Color(0xE0090F28)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x7A8B5CF6)),
        boxShadow: [
          BoxShadow(color: AppColors.dnaLabelShadow, blurRadius: 30),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0x66A855F7), Color(0x262563EB)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x73A855F7)),
            ),
            child: const Icon(Icons.adjust, size: 20, color: Color(0xFFD8B4FE)),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dnaVisualLabel, style: AppTextStyles.dnaLabelTitle),
              const SizedBox(height: 3),
              Text(l10n.dnaVisualSubtitle, style: AppTextStyles.dnaLabelSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Painter: glow, orbits, platform, dna strands + rungs
// -----------------------------------------------------------------------------

class _DnaScenePainter extends CustomPainter {
  const _DnaScenePainter();

  static const double _w = DnaVisualization.designWidth;
  static const double _h = DnaVisualization.designHeight;
  static const Offset _center = Offset(_w / 2, _h / 2);

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(canvas);
    _paintOrbits(canvas);
    _paintPlatform(canvas);
    _paintDna(canvas);
  }

  void _paintGlow(Canvas canvas) {
    final rect = Rect.fromCenter(center: _center, width: 360, height: 500);
    final shader = RadialGradient(
      colors: const [Color(0x42A855F7), Color(0x1A2563EB), Colors.transparent],
      stops: const [0, 0.45, 0.7],
    ).createShader(rect);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
  }

  void _paintOrbits(Canvas canvas) {
    const orbits = [
      (520.0, 230.0, -10.0),
      (610.0, 300.0, 12.0),
      (470.0, 420.0, 65.0),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x3B8159FF);
    for (final (w, h, deg) in orbits) {
      canvas.save();
      canvas.translate(_center.dx, _center.dy);
      canvas.rotate(deg * math.pi / 180);
      canvas.translate(-_center.dx, -_center.dy);
      canvas.drawOval(Rect.fromCenter(center: _center, width: w, height: h), paint);
      canvas.restore();
    }
  }

  void _paintPlatform(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset(_w / 2, _h * 0.91 - 40),
      width: 370,
      height: 80,
    );
    final shader = RadialGradient(
      colors: const [Color(0x737C3AED), Colors.transparent],
      stops: const [0, 0.65],
    ).createShader(rect);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x80A855F7);
    void ring(double w, double h) {
      canvas.drawOval(
        Rect.fromCenter(center: rect.center, width: w, height: h),
        ringPaint,
      );
    }

    ring(320, 45);
    ring(245, 35);
    ring(160, 25);

    final coreRect = Rect.fromCenter(center: rect.center, width: 70, height: 16);
    final coreShader = RadialGradient(
      colors: const [Color(0xFFC084FC), Color(0x7F7C3AED), Colors.transparent],
      stops: const [0, 0.5, 0.75],
    ).createShader(coreRect);
    canvas.drawOval(
      coreRect,
      Paint()
        ..shader = coreShader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintDna(Canvas canvas) {
    // Strands offset by +-45.5 from the container center.
    _drawStrand(
      canvas,
      _center.translate(-45.5, 0),
      AppColors.strandLeftGradient,
      rotationDeg: 11,
    );
    _drawStrand(
      canvas,
      _center.translate(45.5, 0),
      AppColors.strandRightGradient,
      rotationDeg: -11,
    );
    _paintRungs(canvas);
  }

  void _drawStrand(
    Canvas canvas,
    Offset center,
    List<Color> colors, {
    required double rotationDeg,
  }) {
    const double w = 15;
    const double h = 470;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(w / 2),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDeg * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xE5A855F7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w + 8, height: h + 8),
        const Radius.circular((w + 8) / 2),
      ),
      Paint()
        ..color = const Color(0x992563EB)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawRRect(
      body,
      Paint()..shader = LinearGradient(colors: colors).createShader(body.outerRect),
    );
    canvas.restore();
  }

  void _paintRungs(Canvas canvas) {
    const tops = [0.07, 0.18, 0.29, 0.40, 0.51, 0.62, 0.73, 0.84, 0.95];
    final topY = _center.dy - 235;
    const double w = 96;
    const double h = 5;
    for (final t in tops) {
      final center = Offset(_center.dx, topY + t * 470);
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        const Radius.circular(2.5),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-4 * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xCCA855F7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(
        body,
        Paint()..shader = LinearGradient(colors: AppColors.rungGradient).createShader(body.outerRect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DnaScenePainter oldDelegate) => false;
}
