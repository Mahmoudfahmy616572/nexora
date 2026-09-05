import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../speech_service.dart';

/// Web implementation of [SpeechService] using the Web Speech API.
class WebSpeechService extends SpeechService {
  web.SpeechRecognition? _recognition;
  bool _listening = false;
  String? _localeId;
  OnSpeechResult? _onResult;
  OnPartialResult? _onPartial;
  OnListeningChange? _onListening;

  @override
  Future<bool> get isAvailable async {
    try {
      // ignore: avoid_dynamic_calls
      return (web.window as dynamic).hasOwnProperty('SpeechRecognition') as bool;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isListening => _listening;

  @override
  String? get localeId => _localeId;

  @override
  Future<void> initialize({String? localeId}) async {
    _localeId = localeId ?? 'en-US';
    final available = await isAvailable;
    if (!available) {
      throw UnsupportedError('Web Speech Recognition API is not available in this browser.');
    }
  }

  @override
  Future<void> listen({
    OnSpeechResult? onResult,
    OnPartialResult? onPartial,
    OnListeningChange? onListening,
    Duration? timeout,
    String? localeId,
  }) async {
    _onResult = onResult;
    _onPartial = onPartial;
    _onListening = onListening;

    _recognition = web.SpeechRecognition();
    final lang = localeId ?? _localeId ?? 'en-US';
    _recognition!.lang = lang;
    _recognition!.continuous = true;
    _recognition!.interimResults = true;
    _recognition!.maxAlternatives = 1;

    _recognition!.addEventListener('result', ((web.Event event) {
      final e = event as web.SpeechRecognitionEvent;
      final results = e.results;
      for (var i = e.resultIndex; i < results.length; i++) {
        final result = results.item(i);
        final transcript = result.item(0).transcript;
        final isFinal = result.isFinal;
        if (transcript.isNotEmpty) {
          _onResult?.call(transcript.toString(), isFinal);
          if (!isFinal) {
            _onPartial?.call(transcript.toString());
          }
        }
      }
    }).toJS);

    _recognition!.addEventListener('end', (() {
      _listening = false;
      _onListening?.call(false);
    }).toJS);

    _recognition!.addEventListener('error', ((web.Event event) {
      _listening = false;
      _onListening?.call(false);
    }).toJS);

    _recognition!.start();
    _listening = true;
    _onListening?.call(true);
  }

  @override
  Future<void> stop() async {
    _listening = false;
    _recognition?.stop();
    _onListening?.call(false);
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    _recognition?.abort();
    _recognition = null;
    _onListening?.call(false);
  }

  @override
  void dispose() {
    _recognition?.abort();
    _recognition = null;
  }
}
