import '../platform/speech_service.dart';
import '../platform/tts_service.dart';

import 'platform_services_native.dart'
    if (dart.library.js) 'platform_services_web.dart';

/// Factory that returns the correct platform implementation.
class PlatformServices {
  PlatformServices._();

  static SpeechService? _speech;
  static TextToSpeechService? _tts;

  /// Get the speech-to-text service for the current platform.
  static SpeechService get speech {
    return _speech ??= createSpeechService();
  }

  /// Get the text-to-speech service for the current platform.
  static TextToSpeechService get tts {
    return _tts ??= createTtsService();
  }

  /// Dispose both services.
  static void dispose() {
    _speech?.dispose();
    _tts?.dispose();
    _speech = null;
    _tts = null;
  }
}
