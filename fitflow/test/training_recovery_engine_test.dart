import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/recovery/movement_recovery_status.dart';
import 'package:fitflow/features/workouts/domain/recovery/training_recovery_engine.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedWorkoutExercise makeEx({
  String id = 'ex1',
  MovementPattern pattern = MovementPattern.push,
  WorkoutSectionType section = WorkoutSectionType.main,
  int sets = 3,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: 'Test $pattern',
    movementPattern: pattern,
    sectionType: section,
    sets: sets,
    repsPerSet: 10,
    workDuration: null,
    restBetweenSets: const Duration(seconds: 30),
    difficulty: ExerciseDifficulty.level2,
  );
}

CompletedWorkout makeWorkout({
  String id = 'w1',
  required DateTime completedAt,
  List<CompletedWorkoutExercise>? main,
}) {
  final m = main ?? [makeEx()];
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 22),
    totalExerciseCount: m.length,
    totalSetCount: m.fold(0, (s, e) => s + e.sets),
    warmup: const [],
    main: m,
    cooldown: const [],
  );
}

void main() {
  group('TrainingRecoveryEngine', () {
    test('empty history', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final result = TrainingRecoveryEngine.calculate(history: [], now: now);
      expect(result.length, equals(CapabilityProfile.trainablePatterns.length));
      for (final status in result) {
        expect(status.lastTrained, isNull);
        expect(status.category, equals(RecoveryCategory.notTrainedRecently));
        expect(status.sessionsLast7Days, equals(0));
        expect(status.setsLast7Days, equals(0));
      }
    });

    test('explicit now', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 5)), main: [makeEx(pattern: MovementPattern.push)]);
      final result1 = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final result2 = TrainingRecoveryEngine.calculate(history: [workout], now: now.add(const Duration(hours: 1)));
      // Hours since should differ by 1
      final push1 = result1.firstWhere((s) => s.movementPattern == MovementPattern.push);
      final push2 = result2.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push1.hoursSinceLastTrained, isNot(equals(push2.hoursSinceLastTrained)));
    });

    test('<24h → trained recently', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 5)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.category, equals(RecoveryCategory.trainedRecently));
    });

    test('exactly 24h boundary', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 24)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      // At exactly 24h, should be resting (24 to <48)
      expect(push.category, equals(RecoveryCategory.resting));
    });

    test('24–<48h → resting', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 30)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.category, equals(RecoveryCategory.resting));
    });

    test('exactly 48h boundary', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 48)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.category, equals(RecoveryCategory.wellRested));
    });

    test('>=48h → more rested', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 72)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.category, equals(RecoveryCategory.wellRested));
    });

    test('last trained correct', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(hours: 10)), main: [makeEx(pattern: MovementPattern.push)]);
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(hours: 2)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [w1, w2], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.lastTrained, equals(w2.completedAt));
    });

    test('session count deduplicates multiple exercises same movement', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(
        completedAt: now.subtract(const Duration(hours: 5)),
        main: [
          makeEx(id: 'ex1', pattern: MovementPattern.push, sets: 3),
          makeEx(id: 'ex2', pattern: MovementPattern.push, sets: 3),
          makeEx(id: 'ex3', pattern: MovementPattern.push, sets: 3),
        ],
      );
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.sessionsLast7Days, equals(1));
      expect(push.setsLast7Days, equals(9));
    });

    test('set count sums effective Main sets', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 1)), main: [makeEx(pattern: MovementPattern.squat, sets: 3)]);
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 2)), main: [makeEx(pattern: MovementPattern.squat, sets: 4)]);
      final result = TrainingRecoveryEngine.calculate(history: [w1, w2], now: now);
      final squat = result.firstWhere((s) => s.movementPattern == MovementPattern.squat);
      expect(squat.sessionsLast7Days, equals(2));
      expect(squat.setsLast7Days, equals(7));
    });

    test('warmup excluded', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = CompletedWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(hours: 5)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: const Duration(minutes: 22),
        totalExerciseCount: 1,
        totalSetCount: 3,
        warmup: [makeEx(pattern: MovementPattern.push, section: WorkoutSectionType.warmup)],
        main: const [],
        cooldown: const [],
      );
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.lastTrained, isNull);
      expect(push.sessionsLast7Days, equals(0));
    });

    test('cooldown excluded', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = CompletedWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(hours: 5)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: const Duration(minutes: 22),
        totalExerciseCount: 1,
        totalSetCount: 3,
        warmup: const [],
        main: const [],
        cooldown: [makeEx(pattern: MovementPattern.push, section: WorkoutSectionType.cooldown)],
      );
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.lastTrained, isNull);
    });

    test('different movements independent', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(
        completedAt: now.subtract(const Duration(hours: 5)),
        main: [
          makeEx(pattern: MovementPattern.push, sets: 3),
          makeEx(id: 'ex2', pattern: MovementPattern.squat, sets: 2),
        ],
      );
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      final squat = result.firstWhere((s) => s.movementPattern == MovementPattern.squat);
      final pull = result.firstWhere((s) => s.movementPattern == MovementPattern.pull);
      expect(push.sessionsLast7Days, equals(1));
      expect(squat.sessionsLast7Days, equals(1));
      expect(pull.sessionsLast7Days, equals(0));
    });

    test('only last 7 days counted for weekly counts', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final wRecent = makeWorkout(id: 'recent', completedAt: now.subtract(const Duration(days: 2)), main: [makeEx(pattern: MovementPattern.push)]);
      final wOld = makeWorkout(id: 'old', completedAt: now.subtract(const Duration(days: 10)), main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [wRecent, wOld], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      expect(push.sessionsLast7Days, equals(1));
      // lastTrained should be recent, not old
      expect(push.lastTrained, equals(wRecent.completedAt));
    });

    test('exactly 7-day boundary defined/tested', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final workout = makeWorkout(completedAt: sevenDaysAgo, main: [makeEx(pattern: MovementPattern.push)]);
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final push = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      // Inclusive boundary: exactly 7 days ago should count
      expect(push.sessionsLast7Days, equals(1));
    });

    test('deterministic ordering', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final wPush = makeWorkout(id: 'push', completedAt: now.subtract(const Duration(hours: 1)), main: [makeEx(pattern: MovementPattern.push)]);
      final wSquat = makeWorkout(id: 'squat', completedAt: now.subtract(const Duration(hours: 5)), main: [makeEx(pattern: MovementPattern.squat)]);
      final result = TrainingRecoveryEngine.calculate(history: [wSquat, wPush], now: now);
      // Most recent first: push then squat, then never-trained in canonical order
      expect(result.first.movementPattern, equals(MovementPattern.push));
      expect(result[1].movementPattern, equals(MovementPattern.squat));
    });

    test('same inputs → same output', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 5)), main: [makeEx(pattern: MovementPattern.push)]);
      final result1 = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      final result2 = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      expect(result1, equals(result2));
    });

    test('inputs not mutated', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final workout = makeWorkout(completedAt: now.subtract(const Duration(hours: 5)), main: [makeEx(pattern: MovementPattern.push)]);
      final history = [workout];
      final originalLength = history.length;
      TrainingRecoveryEngine.calculate(history: history, now: now);
      expect(history.length, equals(originalLength));
    });
  });
}
