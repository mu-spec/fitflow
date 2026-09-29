import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/session/comeback_suggestion_policy.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedWorkout makeWorkout(DateTime completedAt, {String id = 'w1'}) {
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    totalExerciseCount: 5,
    totalSetCount: 10,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 18),
    warmup: const <CompletedWorkoutExercise>[],
    main: const <CompletedWorkoutExercise>[],
    cooldown: const <CompletedWorkoutExercise>[],
  );
}

void main() {
  group('ComebackSuggestionPolicy', () {
    final now = DateTime.utc(2026, 9, 29, 12, 0, 0);

    test('no history returns false', () {
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: [], now: now), false);
    });

    test('recent workout <14 days returns false', () {
      final history = [makeWorkout(now.subtract(const Duration(days: 13)))];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), false);
    });

    test('exactly 14 days returns true (boundary ON)', () {
      final history = [makeWorkout(now.subtract(const Duration(days: 14)))];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), true);
    });

    test('more than 14 days returns true', () {
      final history = [makeWorkout(now.subtract(const Duration(days: 20)))];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), true);
    });

    test('future dated workout ignored', () {
      final history = [makeWorkout(now.add(const Duration(days: 1)))];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), false);
    });

    test('mixed future and old picks most recent valid', () {
      final history = [
        makeWorkout(now.add(const Duration(days: 5)), id: 'future'),
        makeWorkout(now.subtract(const Duration(days: 30)), id: 'old'),
      ];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), true);
    });

    test('most recent <14 even if older >14 returns false', () {
      final history = [
        makeWorkout(now.subtract(const Duration(days: 5)), id: 'recent'),
        makeWorkout(now.subtract(const Duration(days: 30)), id: 'old'),
      ];
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), false);
    });

    test('multiple valid picks most recent', () {
      final history = [
        makeWorkout(now.subtract(const Duration(days: 15)), id: 'a'),
        makeWorkout(now.subtract(const Duration(days: 10)), id: 'b'),
        makeWorkout(now.subtract(const Duration(days: 25)), id: 'c'),
      ];
      // Most recent is 10 days ago => false
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history, now: now), false);

      final history2 = [
        makeWorkout(now.subtract(const Duration(days: 15)), id: 'a'),
        makeWorkout(now.subtract(const Duration(days: 20)), id: 'b'),
      ];
      // Most recent is 15 days ago => true
      expect(ComebackSuggestionPolicy.shouldSuggestComeback(history: history2, now: now), true);
    });
  });
}
