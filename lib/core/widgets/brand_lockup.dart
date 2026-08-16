import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// NEXORA brand lockup: twin skewed bars + wordmark/subtitle.
/// Used app-wide (topbars, PDF export header, dashboards).
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false, this.narrow = false});

  /// [compact] reduces the wordmark size for small screens.
  final bool compact;

  /// [narrow] drops the subtitle so the lockup fits very small screens.
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 13),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXORA',
                style: compact ? AppTextStyles.brandNameCompact : AppTextStyles.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!narrow) ...[
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.brandSubtitle,
                  style: AppTextStyles.brandSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The two skewed gradient bars that form the Nexora mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _BrandMarkPainter());
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  static const double _skew = -25; // CSS skewY(-25deg)

  @override
  void paint(Canvas canvas, Size size) {
    final leftRect = Rect.fromLTWH(4, 3, 17, 37);
    final rightRect = Rect.fromLTWH(size.width - 21, 2, 17, 37);
    final skew = math.tan(_skew * math.pi / 180);
    _drawBar(canvas, leftRect, skew, AppColors.brandMarkLeft);
    _drawBar(canvas, rightRect, skew, AppColors.brandMarkRight);
  }

  void _drawBar(Canvas canvas, Rect rect, double skew, List<Color> colors) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.transform((Matrix4.identity()..setEntry(1, 0, skew)).storage);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRRect(
      rrect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}
