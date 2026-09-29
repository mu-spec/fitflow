import 'dart:convert';

import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedWorkoutExercise makeEx({
  String id = 'ex1',
  MovementPattern? pattern = MovementPattern.push,
  int sets = 3,
  String name = 'Push',
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: name,
    movementPattern: pattern,
    sectionType: WorkoutSectionType.main,
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
  Duration? estimatedDuration,
}) {
  final m = main ?? [makeEx()];
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: estimatedDuration ?? const Duration(minutes: 22),
    totalExerciseCount: m.length,
    totalSetCount: m.fold(0, (s, e) => s + e.sets),
    warmup: const [],
    main: m,
    cooldown: const [],
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 29, 12, 0, 0);

  group('Duplicate tie-break determinism', () {
    test('1. duplicate same ID, different timestamps -> later timestamp retained', () {
      final old = makeWorkout(id: 'dup', completedAt: now.subtract(const Duration(days: 5)));
      final recent = makeWorkout(id: 'dup', completedAt: now.subtract(const Duration(days: 1)));
      final result = TrainingAnalyticsEngine.calculate(history: [old, recent], now: now);
      expect(result.savedWorkoutsCount, 1);
      expect(result.validWorkouts.first.completedAt, recent.completedAt);
    });

    test('2. duplicate same ID, same timestamp, different payloads -> exactly one retained', () {
      final ts = now.subtract(const Duration(days: 1));
      final wA = makeWorkout(
        id: 'dup',
        completedAt: ts,
        main: [makeEx(id: 'exA', name: 'A', sets: 2)],
      );
      final wB = makeWorkout(
        id: 'dup',
        completedAt: ts,
        main: [makeEx(id: 'exB', name: 'B', sets: 5)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [wA, wB], now: now);
      expect(result.savedWorkoutsCount, 1);
      // One of them retained, not both
      final retained = result.validWorkouts.first;
      expect(retained.id, 'dup');
      expect(retained.completedAt, ts);
    });

    test('3. reverse input ordering -> same selected duplicate (payload deterministic)', () {
      final ts = now.subtract(const Duration(days: 1));
      final wA = makeWorkout(
        id: 'dup',
        completedAt: ts,
        main: [makeEx(id: 'exA', name: 'Alpha', sets: 2)],
      );
      final wB = makeWorkout(
        id: 'dup',
        completedAt: ts,
        main: [makeEx(id: 'exB', name: 'Zeta', sets: 5)],
      );

      final fpA = jsonEncode(wA.toJson());
      final fpB = jsonEncode(wB.toJson());
      final expectedGreater = fpA.compareTo(fpB) > 0 ? wA : wB;

      final result1 = TrainingAnalyticsEngine.calculate(history: [wA, wB], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [wB, wA], now: now);

      expect(result1.validWorkouts.first.totalSetCount, expectedGreater.totalSetCount);
      expect(result2.validWorkouts.first.totalSetCount, expectedGreater.totalSetCount);
      expect(result1.validWorkouts.first.main.first.exerciseName,
          result2.validWorkouts.first.main.first.exerciseName);
    });

    test('4. reverse input ordering -> same current period metrics', () {
      final ts = now.subtract(const Duration(days: 1));
      final wA = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 2)]);
      final wB = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 5)]);
      final wOther = makeWorkout(id: 'other', completedAt: now.subtract(const Duration(days: 2)));

      final result1 = TrainingAnalyticsEngine.calculate(history: [wA, wB, wOther], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [wB, wA, wOther], now: now);

      expect(result1.currentPeriod.workoutCount, result2.currentPeriod.workoutCount);
      expect(result1.currentPeriod.mainSets, result2.currentPeriod.mainSets);
      expect(result1.currentPeriod.plannedDuration, result2.currentPeriod.plannedDuration);
    });

    test('5. reverse input ordering -> same previous metrics', () {
      final ts = now.subtract(const Duration(days: 10));
      final wA = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 2)]);
      final wB = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 5)]);
      final result1 = TrainingAnalyticsEngine.calculate(history: [wA, wB], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [wB, wA], now: now);
      expect(result1.previousPeriod.workoutCount, result2.previousPeriod.workoutCount);
      expect(result1.previousPeriod.mainSets, result2.previousPeriod.mainSets);
    });

    test('6. reverse input ordering -> same trend buckets', () {
      final ts = now.subtract(const Duration(days: 1));
      final wA = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 2)]);
      final wB = makeWorkout(id: 'dup', completedAt: ts, main: [makeEx(sets: 5)]);
      final result1 = TrainingAnalyticsEngine.calculate(history: [wA, wB], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [wB, wA], now: now);
      expect(result1.trendBuckets, result2.trendBuckets);
    });

    test('7. reverse input ordering -> same movement analytics', () {
      final ts = now.subtract(const Duration(days: 1));
      final wA = makeWorkout(
          id: 'dup',
          completedAt: ts,
          main: [makeEx(pattern: MovementPattern.push, sets: 2)]);
      final wB = makeWorkout(
          id: 'dup',
          completedAt: ts,
          main: [makeEx(pattern: MovementPattern.pull, sets: 5)]);
      final result1 = TrainingAnalyticsEngine.calculate(history: [wA, wB], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [wB, wA], now: now);
      expect(result1.movementAnalytics, result2.movementAnalytics);
    });

    test('8. duplicate same ID/same timestamp/same payload -> still counted once', () {
      final ts = now.subtract(const Duration(days: 1));
      final w = makeWorkout(id: 'dup', completedAt: ts);
      final result = TrainingAnalyticsEngine.calculate(history: [w, w, w], now: now);
      expect(result.savedWorkoutsCount, 1);
    });
  });

  group('Immutability', () {
    test('1. empty validWorkouts cannot be mutated', () {
      final analytics = TrainingAnalytics.empty(now);
      expect(() => analytics.validWorkouts.add(makeWorkout(completedAt: now)), throwsUnsupportedError);
    });

    test('2. empty trendBuckets cannot be mutated', () {
      final analytics = TrainingAnalytics.empty(now);
      expect(
          () => analytics.trendBuckets.add(TrainingTrendBucket(
                index: 0,
                start: now,
                end: now,
                workoutCount: 0,
                mainSetCount: 0,
                plannedDuration: Duration.zero,
              )),
          throwsUnsupportedError);
    });

    test('3. empty movementAnalytics cannot be mutated', () {
      final analytics = TrainingAnalytics.empty(now);
      expect(
          () => analytics.movementAnalytics.add(MovementTrainingAnalytics(
                movementPattern: MovementPattern.push,
                sessions: 0,
                mainSets: 0,
              )),
          throwsUnsupportedError);
    });

    test('4. non-empty validWorkouts cannot be mutated', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(() => analytics.validWorkouts.add(w), throwsUnsupportedError);
      expect(() => analytics.validWorkouts.removeAt(0), throwsUnsupportedError);
    });

    test('5. non-empty trendBuckets cannot be mutated', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(() => analytics.trendBuckets.clear(), throwsUnsupportedError);
    });

    test('6. non-empty movementAnalytics cannot be mutated', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(() => analytics.movementAnalytics.removeAt(0), throwsUnsupportedError);
    });

    test('7. passing mutable input lists into constructor does not allow later caller mutation to alter result', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final mutableValid = [w];
      final mutableBuckets = [
        TrainingTrendBucket(
            index: 0,
            start: now.subtract(const Duration(days: 56)),
            end: now.subtract(const Duration(days: 49)),
            workoutCount: 1,
            mainSetCount: 3,
            plannedDuration: const Duration(minutes: 20))
      ];
      final mutableMovement = [
        MovementTrainingAnalytics(movementPattern: MovementPattern.push, sessions: 1, mainSets: 3)
      ];

      final analytics = TrainingAnalytics(
        now: now,
        savedWorkoutsCount: 1,
        validWorkouts: mutableValid,
        currentPeriod: const TrainingPeriodSummary(workoutCount: 1, mainSets: 3, plannedDuration: Duration(minutes: 20)),
        previousPeriod: TrainingPeriodSummary.zero,
        last28Days: const TrainingPeriodSummary(workoutCount: 1, mainSets: 3, plannedDuration: Duration(minutes: 20)),
        activeWeeksCount: 1,
        trendBuckets: mutableBuckets,
        movementAnalytics: mutableMovement,
      );

      // Mutate original lists after construction
      mutableValid.clear();
      mutableBuckets.clear();
      mutableMovement.clear();

      // Result should remain unchanged
      expect(analytics.validWorkouts.length, 1);
      expect(analytics.trendBuckets.length, 1);
      expect(analytics.movementAnalytics.length, 1);
    });
  });
}
