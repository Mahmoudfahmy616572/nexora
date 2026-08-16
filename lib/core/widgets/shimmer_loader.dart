import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading placeholders built from the `shimmer` package.
///
/// Nexora convention: every loading state uses shimmer instead of a spinner.
class NexoraShimmer extends StatelessWidget {
  const NexoraShimmer({super.key, this.baseColor, this.highlightColor, required this.child});

  final Color? baseColor;
  final Color? highlightColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFF141A2E),
      highlightColor: highlightColor ?? const Color(0xFF242E4A),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A single shimmering rounded block.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Default screen-level shimmer: an avatar + headline + card blocks, used on
/// any screen that loads data before first paint.
class ScreenShimmer extends StatelessWidget {
  const ScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return NexoraShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Row(
              children: [
                ShimmerBlock(width: 44, height: 44, radius: 12),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(width: 150, height: 14),
                    SizedBox(height: 8),
                    ShimmerBlock(width: 90, height: 10),
                  ],
                ),
              ],
            ),
            SizedBox(height: 22),
            ShimmerBlock(height: 130, radius: 20),
            SizedBox(height: 14),
            ShimmerBlock(height: 90, radius: 16),
            SizedBox(height: 14),
            ShimmerBlock(height: 110, radius: 16),
            SizedBox(height: 14),
            ShimmerBlock(height: 80, radius: 16),
          ],
        ),
      ),
    );
  }
}
