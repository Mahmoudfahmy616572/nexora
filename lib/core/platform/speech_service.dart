import 'dart:async';

/// Callback when speech is recognized.
typedef OnSpeechResult = void Function(String text, bool isFinal);

/// Callback for partial (live) results.
typedef OnPartialResult = void Function(String text);

/// Callback when listening status changes.
typedef OnListeningChange = void Function(bool isListening);

/// Abstract speech-to-text service.
abstract class SpeechService {
  /// Whether the service is available on this platform.
  Future<bool> get isAvailable;

  /// Whether the service is currently listening.
  bool get isListening;

  /// Current locale ID (e.g. 'en-US', 'ar-SA').
  String? get localeId;

  /// Initialize the service. Must be called once before use.
  Future<void> initialize({String? localeId});

  /// Start listening for speech.
  ///
  /// [onResult] is called with the transcribed text.
  /// [onPartial] is called with partial (live) results.
  /// [onListening] is called when listening state changes.
  Future<void> listen({
    OnSpeechResult? onResult,
    OnPartialResult? onPartial,
    OnListeningChange? onListening,
    Duration? timeout,
    String? localeId,
  });

  /// Stop listening (user-controlled stop).
  Future<void> stop();

  /// Cancel listening entirely.
  Future<void> cancel();

  /// Dispose resources.
  void dispose();
}
