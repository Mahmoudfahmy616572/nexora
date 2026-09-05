import '../platform/speech_service.dart';
import '../platform/tts_service.dart';
import 'implementations/web_speech.dart';
import 'implementations/web_tts.dart';

/// Web platform services — uses Web Speech API.
SpeechService createSpeechService() => WebSpeechService();
TextToSpeechService createTtsService() => WebTtsService();
