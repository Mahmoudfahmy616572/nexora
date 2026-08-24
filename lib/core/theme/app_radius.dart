import 'package:flutter/material.dart';

/// Nexora shape language — controlled, intentional corners.
/// Not every surface is a large rounded rectangle.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  /// Editorial block — sharp, confident.
  static const double block = 2;
  static const double module = 14;

  /// Asymmetric corner set for distinctive cards (top-left sharp, rest soft).
  static const BorderRadius asymmetric = BorderRadius.only(
    topLeft: Radius.circular(block),
    topRight: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
    bottomLeft: Radius.circular(lg),
  );
}
