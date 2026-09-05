import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../tts_service.dart';

/// Web implementation of [TextToSpeechService] using the Web Speech Synthesis API.
class WebTtsService extends TextToSpeechService {
  bool _initialized = false;
  bool _speaking = false;
  String? _language;
  double _rate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  OnTtsStart? _onStart;
  OnTtsComplete? _onComplete;

  @override
  Future<bool> get isAvailable async {
    try {
      // ignore: avoid_dynamic_calls
      return (web.window as dynamic).hasOwnProperty('speechSynthesis') as bool;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isSpeaking => _speaking;

  @override
  String? get language => _language;

  @override
  Future<void> initialize({String? language}) async {
    if (_initialized) return;
    _language = language ?? 'en-US';
    _initialized = true;
  }

  @override
  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty) return;

    // Cancel any ongoing speech.
    web.window.speechSynthesis.cancel();

    final utterance = web.SpeechSynthesisUtterance(text);
    utterance.lang = (language ?? _language ?? 'en-US');
    utterance.rate = _rate;
    utterance.pitch = _pitch;
    utterance.volume = _volume;

    final completer = Completer<void>();
    _speaking = true;
    _onStart?.call();

    utterance.addEventListener('end', (() {
      _speaking = false;
      _onComplete?.call();
      if (!completer.isCompleted) completer.complete();
    }).toJS);

    utterance.addEventListener('error', ((web.Event event) {
      _speaking = false;
      _onComplete?.call();
      if (!completer.isCompleted) completer.complete();
    }).toJS);

    web.window.speechSynthesis.speak(utterance);
    return completer.future;
  }

  @override
  Future<void> stop() async {
    _speaking = false;
    web.window.speechSynthesis.cancel();
  }

  @override
  Future<void> setRate(double rate) async => _rate = rate;

  @override
  Future<void> setPitch(double pitch) async => _pitch = pitch;

  @override
  Future<void> setVolume(double volume) async => _volume = volume;

  @override
  void setCallbacks({OnTtsStart? onStart, OnTtsComplete? onComplete}) {
    _onStart = onStart;
    _onComplete = onComplete;
  }

  @override
  void dispose() {
    web.window.speechSynthesis.cancel();
  }
}
