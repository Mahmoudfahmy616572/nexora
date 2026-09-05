/// Callback when TTS starts speaking.
typedef OnTtsStart = void Function();

/// Callback when TTS finishes speaking.
typedef OnTtsComplete = void Function();

/// Abstract text-to-speech service.
abstract class TextToSpeechService {
  /// Whether the service is available on this platform.
  Future<bool> get isAvailable;

  /// Whether the service is currently speaking.
  bool get isSpeaking;

  /// Current language code (e.g. 'en-US', 'ar-SA').
  String? get language;

  /// Initialize the service.
  Future<void> initialize({String? language});

  /// Speak the given [text].
  Future<void> speak(String text, {String? language});

  /// Stop speaking.
  Future<void> stop();

  /// Set speech rate (0.0 to 1.0).
  Future<void> setRate(double rate);

  /// Set pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch);

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Set callbacks.
  void setCallbacks({OnTtsStart? onStart, OnTtsComplete? onComplete});

  /// Dispose resources.
  void dispose();
}
