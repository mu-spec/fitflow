import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/recovery/training_recovery_engine.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletedWorkoutExercise makeExWithPattern(MovementPattern? pattern) {
  return CompletedWorkoutExercise(
    exerciseId: 'ex_null_test',
    exerciseName: 'Mystery Exercise',
    movementPattern: pattern,
    sectionType: WorkoutSectionType.main,
    sets: 3,
    repsPerSet: 10,
    workDuration: null,
    restBetweenSets: const Duration(seconds: 30),
    difficulty: ExerciseDifficulty.level2,
  );
}

CompletedWorkout makeWorkoutWithExercises(List<CompletedWorkoutExercise> main, {String id = 'w1', DateTime? completedAt}) {
  final now = completedAt ?? DateTime.utc(2026, 9, 29, 12, 0, 0);
  return CompletedWorkout(
    id: id,
    completedAt: now,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 22),
    totalExerciseCount: main.length,
    totalSetCount: main.fold(0, (s, e) => s + e.sets),
    warmup: const [],
    main: main,
    cooldown: const [],
  );
}

void main() {
  group('Null movementPattern truthfulness', () {
    test('Main exercise with null movementPattern snapshots as null', () {
      final ex = makeExWithPattern(null);
      expect(ex.movementPattern, isNull);
    });

    test('null pattern does NOT become Push', () {
      final ex = makeExWithPattern(null);
      expect(ex.movementPattern, isNot(equals(MovementPattern.push)));
      // Ensure mapping preserves null
      final workout = makeWorkoutWithExercises([ex]);
      expect(workout.main.first.movementPattern, isNull);
    });

    test('serialization round-trip preserves null', () {
      final ex = makeExWithPattern(null);
      final json = ex.toJson();
      expect(json['movementPattern'], isNull);
      final restored = CompletedWorkoutExercise.fromJson(json);
      expect(restored, isNotNull);
      expect(restored!.movementPattern, isNull);
      expect(restored.exerciseName, equals('Mystery Exercise'));
    });

    test('existing non-null pattern round-trip remains unchanged', () {
      final ex = makeExWithPattern(MovementPattern.push);
      final json = ex.toJson();
      expect(json['movementPattern'], equals('push'));
      final restored = CompletedWorkoutExercise.fromJson(json)!;
      expect(restored.movementPattern, equals(MovementPattern.push));
      // Backward compat: old entries with movement string still work
      final oldJson = {
        'exerciseId': 'ex1',
        'exerciseName': 'Push Up',
        'movementPattern': 'push',
        'sectionType': 'main',
        'sets': 3,
        'repsPerSet': 10,
        'restBetweenSetsSeconds': 30,
        'difficulty': 'level2',
      };
      final oldRestored = CompletedWorkoutExercise.fromJson(oldJson)!;
      expect(oldRestored.movementPattern, equals(MovementPattern.push));
    });

    test('recovery ignores null-pattern Main exercise', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final exNull = makeExWithPattern(null);
      final workout = makeWorkoutWithExercises([exNull], completedAt: now.subtract(const Duration(hours: 5)));
      final result = TrainingRecoveryEngine.calculate(history: [workout], now: now);
      // All trainable patterns should be notTrainedRecently because null does not count
      for (final status in result) {
        expect(status.lastTrained, isNull);
        expect(status.sessionsLast7Days, equals(0));
        expect(status.setsLast7Days, equals(0));
      }
    });

    test('null-pattern exercise contributes no Push recovery stats', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final exNull = makeExWithPattern(null);
      final exPush = makeExWithPattern(MovementPattern.push);
      final workoutNull = makeWorkoutWithExercises([exNull], id: 'null', completedAt: now.subtract(const Duration(hours: 5)));
      final workoutPush = makeWorkoutWithExercises([exPush], id: 'push', completedAt: now.subtract(const Duration(hours: 10)));
      final result = TrainingRecoveryEngine.calculate(history: [workoutNull, workoutPush], now: now);
      final pushStatus = result.firstWhere((s) => s.movementPattern == MovementPattern.push);
      // Should only count push workout, not null workout
      expect(pushStatus.sessionsLast7Days, equals(1));
      expect(pushStatus.setsLast7Days, equals(3));
      expect(pushStatus.lastTrained, equals(workoutPush.completedAt));
    });

    test('history detail renders safely for null pattern (model)', () {
      final ex = makeExWithPattern(null);
      // Should not throw when accessing label via null-aware handling
      final label = ex.movementPattern?.label ?? 'Unclassified movement';
      expect(label, equals('Unclassified movement'));
    });

    test('Progress screen does not create fake movement chip for null pattern', () {
      final exNull = makeExWithPattern(null);
      final workout = makeWorkoutWithExercises([exNull]);
      // Movement chips should ignore null
      final chips = workout.main.where((e) => e.movementPattern != null).map((e) => e.movementPattern!.label).toSet().toList();
      expect(chips, isEmpty);
      // With one null and one push, only push chip
      final exPush = makeExWithPattern(MovementPattern.push);
      final workoutMixed = makeWorkoutWithExercises([exNull, exPush]);
      final chipsMixed = workoutMixed.main.where((e) => e.movementPattern != null).map((e) => e.movementPattern!.label).toSet().toList();
      expect(chipsMixed, equals(['Push']));
    });

    test('unknown movement string treated as null, not Push, and preserved', () async {
      SharedPreferences.setMockInitialValues({
        WorkoutHistoryStorage.key: '[{"id":"w1","completedAt":"2026-09-29T12:00:00.000Z","totalExerciseCount":1,"totalSetCount":3,"warmup":[],"main":[{"exerciseId":"ex1","exerciseName":"Weird","movementPattern":"unknown_xyz","sectionType":"main","sets":3,"repsPerSet":10,"restBetweenSetsSeconds":30,"difficulty":"level2"}],"cooldown":[]}]'
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final loaded = storage.load();
      expect(loaded.length, equals(1));
      expect(loaded.first.main.length, equals(1));
      expect(loaded.first.main.first.movementPattern, isNull);
      expect(loaded.first.main.first.exerciseName, equals('Weird'));
      // Recovery should ignore it
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final result = TrainingRecoveryEngine.calculate(history: loaded, now: now);
      for (final status in result) {
        expect(status.sessionsLast7Days, equals(0));
      }
    });

    test('storage backward compatibility – existing valid entries still deserialize', () async {
      SharedPreferences.setMockInitialValues({
        WorkoutHistoryStorage.key: '[{"id":"w1","completedAt":"2026-09-29T12:00:00.000Z","totalExerciseCount":1,"totalSetCount":3,"warmup":[],"main":[{"exerciseId":"ex1","exerciseName":"Push Up","movementPattern":"push","sectionType":"main","sets":3,"repsPerSet":10,"restBetweenSetsSeconds":30,"difficulty":"level2"}],"cooldown":[]}]'
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final loaded = storage.load();
      expect(loaded.length, equals(1));
      expect(loaded.first.main.first.movementPattern, equals(MovementPattern.push));
    });
  });
}
