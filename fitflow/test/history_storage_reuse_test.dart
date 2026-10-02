import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M21 Part 1: the history controller must use one canonical storage seam
/// instead of re-acquiring SharedPreferences and reconstructing storage on
/// every add/refresh/clear.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CompletedWorkout workout(String id) {
    CompletedWorkoutExercise exercise() => CompletedWorkoutExercise(
          exerciseId: 'ex_$id',
          exerciseName: 'Bodyweight Squat',
          movementPattern: MovementPattern.squat,
          sectionType: WorkoutSectionType.main,
          sets: 2,
          repsPerSet: 10,
          workDuration: null,
          restBetweenSets: const Duration(seconds: 30),
          difficulty: ExerciseDifficulty.level2,
        );
    return CompletedWorkout(
      id: id,
      completedAt: DateTime.utc(2026, 10, 2, 12),
      targetDuration: const Duration(minutes: 20),
      estimatedDuration: const Duration(minutes: 20),
      totalExerciseCount: 1,
      totalSetCount: 2,
      warmup: const [],
      main: [exercise()],
      cooldown: const [],
    );
  }

  test('sharedPreferencesProvider caches one instance across reads',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = await container.read(sharedPreferencesProvider.future);
    final second = await container.read(sharedPreferencesProvider.future);
    expect(identical(first, second), isTrue,
        reason: 'SharedPreferences must be acquired once per container');
  });

  test('workoutHistoryStorageProvider builds storage once and reuses it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = await container.read(workoutHistoryStorageProvider.future);
    final second = await container.read(workoutHistoryStorageProvider.future);
    expect(identical(first, second), isTrue,
        reason: 'history storage must be constructed once and reused');
  });

  group('controller via injected storage seam', () {
    test('add/refresh/clear all go through the provided storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      var constructions = 0;

      final container = ProviderContainer(
        overrides: [
          workoutHistoryStorageProvider.overrideWith((ref) async {
            constructions += 1;
            return storage;
          }),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(workoutHistoryProvider.notifier);

      // Initial build loads through the injected storage.
      await container.read(workoutHistoryProvider.future);
      expect(container.read(workoutHistoryProvider).valueOrNull, isEmpty);

      // Successful add updates state only after persistence succeeds.
      final added = await controller.addWorkout(workout('session_a'));
      expect(added, isTrue);
      expect(
        container.read(workoutHistoryProvider).valueOrNull!.single.id,
        'session_a',
      );

      // Duplicate add remains truthfully successful without duplicating state.
      expect(await controller.addWorkout(workout('session_a')), isTrue);
      expect(
        container.read(workoutHistoryProvider).valueOrNull,
        hasLength(1),
      );

      // Refresh re-reads through the same storage instance.
      await controller.refresh();
      expect(
        container.read(workoutHistoryProvider).valueOrNull!.single.id,
        'session_a',
      );

      // Clear empties persisted storage and state.
      expect(await controller.clear(), isTrue);
      expect(container.read(workoutHistoryProvider).valueOrNull, isEmpty);
      expect(storage.load(), isEmpty);

      expect(constructions, 1,
          reason: 'the injected storage seam must be resolved exactly once; '
              'operations must not rebuild storage');
    });

    test('failed add returns false and leaves state unchanged', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final seeded = WorkoutHistoryStorage(prefs);
      await seeded.add(workout('existing'));

      final container = ProviderContainer(
        overrides: [
          workoutHistoryStorageProvider.overrideWith(
            (ref) async => _FailingAddStorage(prefs),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(workoutHistoryProvider.notifier);
      await container.read(workoutHistoryProvider.future);
      expect(
        container.read(workoutHistoryProvider).valueOrNull!.single.id,
        'existing',
      );

      final added = await controller.addWorkout(workout('new_session'));
      expect(added, isFalse);
      expect(
        container.read(workoutHistoryProvider).valueOrNull!.single.id,
        'existing',
        reason: 'state must only change after successful persistence',
      );
    });
  });
}

/// Storage whose add always throws, simulating a persistence failure.
class _FailingAddStorage extends WorkoutHistoryStorage {
  _FailingAddStorage(super.prefs);

  @override
  Future<bool> add(CompletedWorkout workout) async {
    throw StateError('simulated persistence failure');
  }
}
