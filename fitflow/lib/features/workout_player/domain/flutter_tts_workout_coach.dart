import 'package:flutter_tts/flutter_tts.dart';

import 'workout_coach.dart';

/// Production implementation using flutter_tts.
/// Best-effort: never throws through UI, tolerates PlatformException, missing engine, etc.
class FlutterTtsWorkoutCoach implements WorkoutCoach {
  FlutterTtsWorkoutCoach({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (_) {
      // Best-effort, ignore init failures
      _initialized = true;
    }
  }

  @override
  Future<void> speak(String message) async {
    if (message.trim().isEmpty) return;
    try {
      await _ensureInitialized();
      await _tts.speak(message);
    } catch (_) {
      // Never throw, continue workout if TTS fails
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Tolerate stop failures
    }
  }
}
