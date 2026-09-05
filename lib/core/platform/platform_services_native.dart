import '../platform/speech_service.dart';
import '../platform/tts_service.dart';
import 'implementations/mobile_speech.dart';
import 'implementations/mobile_tts.dart';

/// Native (mobile/desktop) platform services — no web dependencies.
SpeechService createSpeechService() => MobileSpeechService();
TextToSpeechService createTtsService() => MobileTtsService();
