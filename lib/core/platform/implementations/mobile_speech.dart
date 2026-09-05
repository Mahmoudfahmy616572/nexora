import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../speech_service.dart';

/// Mobile implementation of [SpeechService] using `speech_to_text` package.
class MobileSpeechService extends SpeechService {
  MobileSpeechService() : _stt = SpeechToText();

  final SpeechToText _stt;
  bool _listening = false;
  String? _localeId;

  @override
  Future<bool> get isAvailable async => _stt.isAvailable;

  @override
  bool get isListening => _listening;

  @override
  String? get localeId => _localeId;

  @override
  Future<void> initialize({String? localeId}) async {
    await _stt.initialize();
    _localeId = localeId;
  }

  @override
  Future<void> listen({
    OnSpeechResult? onResult,
    OnPartialResult? onPartial,
    OnListeningChange? onListening,
    Duration? timeout,
    String? localeId,
  }) async {
    _listening = true;
    onListening?.call(true);

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        final text = result.recognizedWords;
        final isFinal = result.finalResult;
        if (text.isNotEmpty) {
          onResult?.call(text, isFinal);
          if (!isFinal) {
            onPartial?.call(text);
          }
        }
      },
      listenFor: timeout ?? const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 60),
      localeId: localeId ?? _localeId,
      cancelOnError: false,
      partialResults: true,
      onDevice: false,
    );
  }

  @override
  Future<void> stop() async {
    _listening = false;
    await _stt.stop();
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    await _stt.cancel();
  }

  @override
  void dispose() {
    _stt.cancel();
  }
}
