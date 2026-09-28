/// Abstraction for voice coaching, isolates flutter_tts plugin code.
abstract interface class WorkoutCoach {
  Future<void> speak(String message);
  Future<void> stop();
}

/// Production will be implemented via flutter_tts.
/// For tests, use NoOp / Fake / Throwing.
class NoOpWorkoutCoach implements WorkoutCoach {
  @override
  Future<void> speak(String message) async {}

  @override
  Future<void> stop() async {}
}

class FakeWorkoutCoach implements WorkoutCoach {
  final List<String> spoken = [];
  int stopCalls = 0;
  bool throwOnSpeak = false;
  bool throwOnStop = false;

  @override
  Future<void> speak(String message) async {
    if (throwOnSpeak) {
      throw Exception('Fake speak failure');
    }
    spoken.add(message);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    if (throwOnStop) {
      throw Exception('Fake stop failure');
    }
  }

  void clear() {
    spoken.clear();
    stopCalls = 0;
  }
}

class ThrowingWorkoutCoach implements WorkoutCoach {
  @override
  Future<void> speak(String message) async {
    throw Exception('Throwing speak');
  }

  @override
  Future<void> stop() async {
    throw Exception('Throwing stop');
  }
}
