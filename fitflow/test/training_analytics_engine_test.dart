import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedWorkoutExercise makeEx({
  String id = 'ex1',
  MovementPattern? pattern = MovementPattern.push,
  WorkoutSectionType section = WorkoutSectionType.main,
  int sets = 3,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: 'Test ${pattern?.name ?? 'null'}',
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
  List<CompletedWorkoutExercise>? warmup,
  List<CompletedWorkoutExercise>? cooldown,
  Duration? targetDuration,
  Duration? estimatedDuration,
}) {
  final m = main ?? [makeEx()];
  final w = warmup ?? const <CompletedWorkoutExercise>[];
  final c = cooldown ?? const <CompletedWorkoutExercise>[];
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: targetDuration ?? const Duration(minutes: 20),
    estimatedDuration: estimatedDuration,
    totalExerciseCount: m.length + w.length + c.length,
    totalSetCount: [...m, ...w, ...c].fold(0, (s, e) => s + e.sets),
    warmup: w,
    main: m,
    cooldown: c,
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 29, 12, 0, 0);

  group('TrainingAnalyticsEngine', () {
    test('1. empty history', () {
      final result = TrainingAnalyticsEngine.calculate(history: [], now: now);
      expect(result.savedWorkoutsCount, 0);
      expect(result.isEmpty, true);
      expect(result.currentPeriod.workoutCount, 0);
      expect(result.previousPeriod.workoutCount, 0);
      expect(result.last28Days.workoutCount, 0);
      expect(result.activeWeeksCount, 0);
      expect(result.trendBuckets.length, 8);
      expect(result.movementAnalytics.length, CapabilityProfile.trainablePatterns.length);
    });

    test('2. one workout', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.savedWorkoutsCount, 1);
      expect(result.currentPeriod.workoutCount, 1);
      expect(result.currentPeriod.mainSets, 3);
    });

    test('3. unordered history', () {
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 1)));
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 2)));
      final w3 = makeWorkout(id: 'w3', completedAt: now.subtract(const Duration(days: 3)));
      final result1 = TrainingAnalyticsEngine.calculate(history: [w1, w2, w3], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [w3, w1, w2], now: now);
      expect(result1.savedWorkoutsCount, result2.savedWorkoutsCount);
      expect(result1.currentPeriod.workoutCount, result2.currentPeriod.workoutCount);
      expect(result1.validWorkouts.map((e) => e.id).toSet(),
          result2.validWorkouts.map((e) => e.id).toSet());
    });

    test('4. future workout ignored', () {
      final future = makeWorkout(completedAt: now.add(const Duration(days: 1)));
      final past = makeWorkout(id: 'past', completedAt: now.subtract(const Duration(days: 1)));
      final result = TrainingAnalyticsEngine.calculate(history: [future, past], now: now);
      expect(result.savedWorkoutsCount, 1);
      expect(result.validWorkouts.first.id, 'past');
      expect(result.currentPeriod.workoutCount, 1);
    });

    test('5. duplicate ID counted once, most recent retained', () {
      final old = makeWorkout(id: 'dup', completedAt: now.subtract(const Duration(days: 5)));
      final recent = makeWorkout(id: 'dup', completedAt: now.subtract(const Duration(days: 1)));
      final result = TrainingAnalyticsEngine.calculate(history: [old, recent], now: now);
      expect(result.savedWorkoutsCount, 1);
      expect(result.validWorkouts.first.completedAt, recent.completedAt);
    });

    test('6. current 7-day workout count', () {
      final wCurrent = makeWorkout(completedAt: now.subtract(const Duration(days: 2)));
      final wOld = makeWorkout(id: 'old', completedAt: now.subtract(const Duration(days: 10)));
      final result = TrainingAnalyticsEngine.calculate(history: [wCurrent, wOld], now: now);
      expect(result.currentPeriod.workoutCount, 1);
    });

    test('7. previous 7-day workout count', () {
      final wPrev = makeWorkout(completedAt: now.subtract(const Duration(days: 10)));
      final result = TrainingAnalyticsEngine.calculate(history: [wPrev], now: now);
      expect(result.previousPeriod.workoutCount, 1);
      expect(result.currentPeriod.workoutCount, 0);
    });

    test('8. exact 7-day boundary belongs current', () {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final w = makeWorkout(completedAt: sevenDaysAgo);
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.workoutCount, 1);
      expect(result.previousPeriod.workoutCount, 0);
      // Also should be in current bucket (index 7)
      expect(result.trendBuckets[7].workoutCount, 1);
      expect(result.trendBuckets[6].workoutCount, 0);
    });

    test('9. exact 14-day boundary behavior', () {
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      final w = makeWorkout(completedAt: fourteenDaysAgo);
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.previousPeriod.workoutCount, 1);
      expect(result.currentPeriod.workoutCount, 0);
      // Bucket 6 is [now-14d, now-7d)
      expect(result.trendBuckets[6].workoutCount, 1);
      expect(result.trendBuckets[5].workoutCount, 0);
    });

    test('10. exact 28-day boundary included', () {
      final twentyEightDaysAgo = now.subtract(const Duration(days: 28));
      final w = makeWorkout(completedAt: twentyEightDaysAgo);
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.last28Days.workoutCount, 1);
      // Bucket 4 starts at now-28d
      expect(result.trendBuckets[4].workoutCount, 1);
    });

    test('11. planned duration uses estimate first', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: const Duration(minutes: 30),
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.plannedDuration, const Duration(minutes: 30));
    });

    test('12. falls back to target', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: null,
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.plannedDuration, const Duration(minutes: 20));
    });

    test('13. both null -> zero', () {
      final w = CompletedWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(days: 1)),
        targetDuration: null,
        estimatedDuration: null,
        totalExerciseCount: 1,
        totalSetCount: 3,
        warmup: const [],
        main: [makeEx()],
        cooldown: const [],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.plannedDuration, Duration.zero);
    });

    test('14. Main sets exclude warmup', () {
      final w = CompletedWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(days: 1)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: const Duration(minutes: 20),
        totalExerciseCount: 2,
        totalSetCount: 5,
        warmup: [makeEx(id: 'warm', pattern: MovementPattern.push, section: WorkoutSectionType.warmup, sets: 2)],
        main: [makeEx(id: 'main', pattern: MovementPattern.push, sets: 3)],
        cooldown: const [],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.mainSets, 3);
    });

    test('15. Main sets exclude cooldown', () {
      final w = CompletedWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(days: 1)),
        targetDuration: const Duration(minutes: 20),
        estimatedDuration: const Duration(minutes: 20),
        totalExerciseCount: 2,
        totalSetCount: 5,
        warmup: const [],
        main: [makeEx(id: 'main', pattern: MovementPattern.push, sets: 3)],
        cooldown: [makeEx(id: 'cool', pattern: MovementPattern.push, section: WorkoutSectionType.cooldown, sets: 2)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.mainSets, 3);
    });

    test('16. Main sets sum correctly', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [
          makeEx(id: 'ex1', sets: 2),
          makeEx(id: 'ex2', sets: 3),
          makeEx(id: 'ex3', sets: 1),
        ],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.mainSets, 6);
    });

    test('17. current-vs-previous workout delta', () {
      final current = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final prev = makeWorkout(id: 'prev', completedAt: now.subtract(const Duration(days: 10)));
      final result = TrainingAnalyticsEngine.calculate(history: [current, prev], now: now);
      expect(result.workoutDelta, 0); // 1 -1 =0
      final result2 = TrainingAnalyticsEngine.calculate(history: [current], now: now);
      expect(result2.workoutDelta, 1);
    });

    test('18. sets delta', () {
      final current = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(sets: 5)],
      );
      final prev = makeWorkout(
        id: 'prev',
        completedAt: now.subtract(const Duration(days: 10)),
        main: [makeEx(sets: 2)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [current, prev], now: now);
      expect(result.mainSetsDelta, 3);
    });

    test('19. planned-time delta', () {
      final current = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        estimatedDuration: const Duration(minutes: 30),
      );
      final prev = makeWorkout(
        id: 'prev',
        completedAt: now.subtract(const Duration(days: 10)),
        estimatedDuration: const Duration(minutes: 20),
      );
      final result = TrainingAnalyticsEngine.calculate(history: [current, prev], now: now);
      expect(result.plannedDurationDelta, const Duration(minutes: 10));
    });

    test('20. equal -> zero delta', () {
      final current = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final prev = makeWorkout(id: 'prev', completedAt: now.subtract(const Duration(days: 10)));
      final result = TrainingAnalyticsEngine.calculate(history: [current, prev], now: now);
      expect(result.workoutDelta, 0);
      expect(result.mainSetsDelta, 0);
      expect(result.plannedDurationDelta, Duration.zero);
    });

    test('21. four-week active-period count', () {
      // Create workouts in 3 of last 4 weeks
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 1))); // week 7
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 8))); // week 6
      final w3 = makeWorkout(id: 'w3', completedAt: now.subtract(const Duration(days: 15))); // week 5
      // No workout in week 4 (days 21-28)
      final result = TrainingAnalyticsEngine.calculate(history: [w1, w2, w3], now: now);
      expect(result.activeWeeksCount, 3);
    });

    test('22. eight trend buckets complete', () {
      final result = TrainingAnalyticsEngine.calculate(history: [], now: now);
      expect(result.trendBuckets.length, 8);
      for (int i = 0; i < 8; i++) {
        expect(result.trendBuckets[i].index, i);
      }
    });

    test('23. no bucket double count', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 7)));
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      int totalInBuckets = result.trendBuckets.fold(0, (sum, b) => sum + b.workoutCount);
      expect(totalInBuckets, 1);
    });

    test('24. movement sessions deduplicate same movement within one workout', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [
          makeEx(id: 'ex1', pattern: MovementPattern.push, sets: 2),
          makeEx(id: 'ex2', pattern: MovementPattern.push, sets: 3),
        ],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      final push = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.push);
      expect(push.sessions, 1);
      expect(push.mainSets, 5);
    });

    test('25. movement sets sum all Main entries', () {
      final w1 = makeWorkout(
        id: 'w1',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.squat, sets: 3)],
      );
      final w2 = makeWorkout(
        id: 'w2',
        completedAt: now.subtract(const Duration(days: 2)),
        main: [makeEx(pattern: MovementPattern.squat, sets: 4)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w1, w2], now: now);
      final squat = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.squat);
      expect(squat.mainSets, 7);
      expect(squat.sessions, 2);
    });

    test('26. null movement ignored', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: null)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      // All movement analytics should have 0 sessions/sets because null ignored
      for (final m in result.movementAnalytics) {
        expect(m.sessions, 0);
        expect(m.mainSets, 0);
      }
    });

    test('27. movement ordering deterministic', () {
      final wPush = makeWorkout(
        id: 'push',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.push, sets: 10)],
      );
      final wSquat = makeWorkout(
        id: 'squat',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.squat, sets: 5)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [wPush, wSquat], now: now);
      expect(result.movementAnalytics.first.movementPattern, MovementPattern.push);
      expect(result.movementAnalytics[1].movementPattern, MovementPattern.squat);
    });

    test('28. canonical tie-break', () {
      // Same sets and sessions, should use canonical order
      final wPush = makeWorkout(
        id: 'push',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.push, sets: 3)],
      );
      final wPull = makeWorkout(
        id: 'pull',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.pull, sets: 3)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [wPush, wPull], now: now);
      // Both have 3 sets, 1 session, canonical order push before pull
      final pushIdx = result.movementAnalytics.indexWhere((m) => m.movementPattern == MovementPattern.push);
      final pullIdx = result.movementAnalytics.indexWhere((m) => m.movementPattern == MovementPattern.pull);
      expect(pushIdx < pullIdx, true);
    });

    test('29. same inputs deterministic', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final result1 = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      final result2 = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result1.savedWorkoutsCount, result2.savedWorkoutsCount);
      expect(result1.currentPeriod, result2.currentPeriod);
      expect(result1.trendBuckets, result2.trendBuckets);
      expect(result1.movementAnalytics, result2.movementAnalytics);
    });

    test('30. input history not mutated', () {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final history = [w];
      final originalLength = history.length;
      TrainingAnalyticsEngine.calculate(history: history, now: now);
      expect(history.length, originalLength);
    });

    // Edge tests
    test('edge: all metrics zero', () {
      final result = TrainingAnalyticsEngine.calculate(history: [], now: now);
      expect(result.currentPeriod.workoutCount, 0);
      expect(result.currentPeriod.mainSets, 0);
      expect(result.currentPeriod.plannedDuration, Duration.zero);
    });

    test('edge: all eight trend buckets zero', () {
      final result = TrainingAnalyticsEngine.calculate(history: [], now: now);
      for (final b in result.trendBuckets) {
        expect(b.workoutCount, 0);
        expect(b.mainSetCount, 0);
        expect(b.plannedDuration, Duration.zero);
      }
    });

    test('edge: very large set counts', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(sets: 1000000)],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.mainSets, 1000000);
    });

    test('edge: 100 retained workouts', () {
      final workouts = List.generate(100, (i) {
        return makeWorkout(
          id: 'w$i',
          completedAt: now.subtract(Duration(days: i % 30, hours: i)),
          main: [makeEx(sets: 1)],
        );
      });
      final result = TrainingAnalyticsEngine.calculate(history: workouts, now: now);
      expect(result.savedWorkoutsCount, 100);
    });

    test('edge: multiple movements in one workout', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [
          makeEx(id: 'push', pattern: MovementPattern.push, sets: 2),
          makeEx(id: 'pull', pattern: MovementPattern.pull, sets: 3),
          makeEx(id: 'squat', pattern: MovementPattern.squat, sets: 1),
        ],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      final push = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.push);
      final pull = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.pull);
      final squat = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.squat);
      expect(push.sessions, 1);
      expect(pull.sessions, 1);
      expect(squat.sessions, 1);
    });

    test('edge: same movement multiple exercises', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [
          makeEx(id: 'ex1', pattern: MovementPattern.push, sets: 2),
          makeEx(id: 'ex2', pattern: MovementPattern.push, sets: 2),
          makeEx(id: 'ex3', pattern: MovementPattern.push, sets: 2),
        ],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      final push = result.movementAnalytics.firstWhere((m) => m.movementPattern == MovementPattern.push);
      expect(push.sessions, 1);
      expect(push.mainSets, 6);
    });

    test('edge: mixed reps/timed history', () {
      final timedEx = CompletedWorkoutExercise(
        exerciseId: 'timed',
        exerciseName: 'Timed',
        movementPattern: MovementPattern.cardio,
        sectionType: WorkoutSectionType.main,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 15),
        difficulty: ExerciseDifficulty.level2,
      );
      final repsEx = makeEx(pattern: MovementPattern.push, sets: 3);
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [timedEx, repsEx],
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.mainSets, 5);
    });

    test('edge: durations with seconds', () {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        estimatedDuration: const Duration(minutes: 20, seconds: 45),
      );
      final result = TrainingAnalyticsEngine.calculate(history: [w], now: now);
      expect(result.currentPeriod.plannedDuration.inSeconds, 20 * 60 + 45);
    });

    test('edge: future-only history', () {
      final future = makeWorkout(completedAt: now.add(const Duration(days: 5)));
      final result = TrainingAnalyticsEngine.calculate(history: [future], now: now);
      expect(result.savedWorkoutsCount, 0);
      expect(result.currentPeriod.workoutCount, 0);
    });
  });
}
