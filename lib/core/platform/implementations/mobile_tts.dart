import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../tts_service.dart';

/// Mobile implementation of [TextToSpeechService] using `flutter_tts` package.
class MobileTtsService extends TextToSpeechService {
  MobileTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  bool _speaking = false;
  String? _language;
  OnTtsStart? _onStart;
  OnTtsComplete? _onComplete;

  @override
  Future<bool> get isAvailable async {
    try {
      return await _tts.awaitSpeakCompletion(true);
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
    await _tts.setLanguage(_language!);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _speaking = true;
      _onStart?.call();
    });

    _tts.setCompletionHandler(() {
      _speaking = false;
      _onComplete?.call();
    });

    _initialized = true;
  }

  @override
  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty) return;
    final lang = language ?? _language ?? 'en-US';
    if (lang != _language) {
      await _tts.setLanguage(lang);
      _language = lang;
    }
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }

  @override
  Future<void> setRate(double rate) async => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) async => _tts.setPitch(pitch);

  @override
  Future<void> setVolume(double volume) async => _tts.setVolume(volume);

  @override
  void setCallbacks({OnTtsStart? onStart, OnTtsComplete? onComplete}) {
    _onStart = onStart;
    _onComplete = onComplete;
  }

  @override
  void dispose() {
    _tts.stop();
  }
}
