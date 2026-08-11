import 'package:flutter/material.dart';

/// Responsive breakpoints — mirror the approved design's media queries.
///
/// * Desktop: width >= 1100
/// * Tablet: 650 <= width < 1100
/// * Mobile: width < 650
abstract final class Breakpoints {
  static const double tablet = 650;
  static const double desktop = 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= tablet && w < desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;
}

/// Adaptive size helper: returns the value selected for the current width.
abstract final class AppBreakpointValues {
  static T of<T>(BuildContext context, {required T mobile, T? tablet, required T desktop}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= Breakpoints.desktop) return desktop;
    if (w >= Breakpoints.tablet) return tablet ?? desktop;
    return mobile;
  }
}
