import 'package:flutter/foundation.dart';

/// Simple platform detection for choosing implementations.
class PlatformInfo {
  PlatformInfo._();

  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
}
