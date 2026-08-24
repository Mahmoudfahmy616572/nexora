import 'dart:async';

import 'package:flutter/material.dart';

/// Nexora motion system — every motion has purpose.
///
/// Signature timings + reusable primitives. All primitives respect
/// [MediaQueryData.disableAnimations] (reduced-motion mode).
class MotionTokens {
  MotionTokens._();

  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration deliberate = Duration(milliseconds: 640);

  // Curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphatic = Curves.easeOutBack;
  static const Curve settle = Curves.easeInOutCubic;
}

/// Reduced-motion aware helpers.
class NxMotion {
  NxMotion._();

  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Returns [d] unless reduced motion is requested.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  static Curve curve(BuildContext context, Curve c) =>
      reduced(context) ? Curves.linear : c;
}

/// Tactile press feedback — subtle scale on tap.
class NxPress extends StatefulWidget {
  const NxPress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<NxPress> createState() => _NxPressState();
}

class _NxPressState extends State<NxPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = NxMotion.reduced(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: reduced ? 1 : (_pressed ? widget.scale : 1),
        duration: MotionTokens.fast,
        curve: MotionTokens.standard,
        child: widget.child,
      ),
    );
  }
}

/// Mount reveal — fades + lifts content in; supports staggered [delay].
class NxReveal extends StatefulWidget {
  const NxReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.shift = 14,
  });
  final Widget child;
  final Duration delay;
  final double shift;

  @override
  State<NxReveal> createState() => _NxRevealState();
}

class _NxRevealState extends State<NxReveal> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final reduced = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .reduceMotion ||
        _reduceFromContext();
    if (reduced) {
      _shown = true;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  bool _reduceFromContext() {
    try {
      return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = NxMotion.reduced(context);
    if (reduced) return widget.child;
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: MotionTokens.base,
      curve: MotionTokens.standard,
      child: AnimatedContainer(
        duration: MotionTokens.base,
        curve: MotionTokens.standard,
        transform: Matrix4.translationValues(0, _shown ? 0 : widget.shift, 0),
        child: widget.child,
      ),
    );
  }
}

/// Animated metric — the number travels through its delta instead of
/// snapping. Used for score / count changes.
class NxMetric extends StatefulWidget {
  const NxMetric({
    super.key,
    required this.value,
    required this.builder,
    this.style,
    this.duration = MotionTokens.slow,
  });
  final num value;
  final String Function(num value) builder;
  final TextStyle? style;
  final Duration duration;

  @override
  State<NxMetric> createState() => _NxMetricState();
}

class _NxMetricState extends State<NxMetric> {
  late num _from;
  @override
  void initState() {
    super.initState();
    _from = widget.value;
  }

  @override
  void didUpdateWidget(covariant NxMetric old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = NxMotion.reduced(context);
    if (reduced) {
      return Text(widget.builder(widget.value), style: widget.style);
    }
    return TweenAnimationBuilder<num>(
      tween: Tween<num>(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: MotionTokens.settle,
      builder: (context, v, _) => Text(widget.builder(v), style: widget.style),
    );
  }
}
