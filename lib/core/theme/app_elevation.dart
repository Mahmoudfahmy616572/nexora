import 'package:flutter/material.dart';

/// Nexora elevation — controlled shadows, not glowy halos.
abstract final class AppElevation {
  /// Hairline separation for flat panels.
  static const List<BoxShadow> flat = [];

  /// Subtle lift for raised editorial modules.
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  /// Stronger lift for floating-but-non-glass elements.
  static const List<BoxShadow> mid = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// Pressed / selected emphasis.
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}
