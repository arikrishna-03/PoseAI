import 'package:flutter_tts/flutter_tts.dart';

class VoiceCoachService {
  static final FlutterTts _tts = FlutterTts();
  static bool enabled = true;
  static String _lastSpoken = '';
  static int _lastSpokenTime = 0;

  static Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  static Future<void> speak(String text) async {
    if (!enabled || text.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Debounce duplicate utterances within 3 seconds
    if (_lastSpoken == text && (now - _lastSpokenTime < 3000)) return;
    // Debounce any speech within 1.5 seconds to avoid overlapping
    if (now - _lastSpokenTime < 1500) return;

    _lastSpoken = text;
    _lastSpokenTime = now;

    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
