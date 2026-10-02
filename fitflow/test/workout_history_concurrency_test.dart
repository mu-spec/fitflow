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

CompletedWorkout _workout(String id, DateTime completedAt) {
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 20),
    totalExerciseCount: 1,
    totalSetCount: 1,
    warmup: const [],
    main: [
      CompletedWorkoutExercise(
        exerciseId: 'ex_$id',
        exerciseName: 'Squat',
        movementPattern: MovementPattern.squat,
        sectionType: WorkoutSectionType.main,
        sets: 1,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 20),
        difficulty: ExerciseDifficulty.level2,
      ),
    ],
    cooldown: const [],
  );
}

class _ThrowOnceHistory extends WorkoutHistoryStorage {
  _ThrowOnceHistory(super.prefs);
  var thrown = false;

  @override
  Future<bool> add(CompletedWorkout workout) async {
    if (!thrown) {
      thrown = true;
      throw StateError('disk');
    }
    return super.add(workout);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<WorkoutHistoryController> controllerFor(
    ProviderContainer container,
  ) async {
    final notifier = container.read(workoutHistoryProvider.notifier);
    await container.read(workoutHistoryProvider.future);
    return notifier;
  }

  test('concurrent unique adds both survive and stay newest-first', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = WorkoutHistoryStorage(
      prefs,
      writeString: (key, value) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return prefs.setString(key, value);
      },
    );
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith((ref) async => storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = await controllerFor(container);

    final older = _workout('a', DateTime.utc(2026, 10, 1));
    final newer = _workout('b', DateTime.utc(2026, 10, 2));
    expect(
      await Future.wait([
        controller.addWorkout(older),
        controller.addWorkout(newer),
      ]),
      [true, true],
    );

    final state = container.read(workoutHistoryProvider).value!;
    expect(state.map((w) => w.id).toList(), ['b', 'a']);
    expect(storage.load().map((w) => w.id).toList(), ['b', 'a']);
  });

  test('concurrent duplicate id is stored once', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = WorkoutHistoryStorage(prefs);
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith((ref) async => storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = await controllerFor(container);
    final workout = _workout('same', DateTime.utc(2026, 10, 2));

    expect(
      await Future.wait([
        controller.addWorkout(workout),
        controller.addWorkout(workout),
      ]),
      [true, true],
    );
    expect(container.read(workoutHistoryProvider).value, hasLength(1));
    expect(storage.load(), hasLength(1));
  });

  test('concurrent adds near the 100 cap stay newest-first and capped',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = WorkoutHistoryStorage(prefs);
    for (var i = 0; i < 99; i++) {
      expect(
        await storage.add(
          _workout('old_$i', DateTime.utc(2024, 1, 1).add(Duration(days: i))),
        ),
        isTrue,
      );
    }
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith((ref) async => storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = await controllerFor(container);

    final first = _workout('new_a', DateTime.utc(2026, 10, 1));
    final second = _workout('new_b', DateTime.utc(2026, 10, 2));
    expect(
      await Future.wait([
        controller.addWorkout(first),
        controller.addWorkout(second),
      ]),
      [true, true],
    );

    final state = container.read(workoutHistoryProvider).value!;
    expect(state, hasLength(100));
    expect(storage.load(), hasLength(100));
    expect(state.map((w) => w.id).take(2).toList(), ['new_b', 'new_a']);
    expect(state.any((w) => w.id == 'old_0'), isFalse);
    expect(state.map((w) => w.id).toList(),
        storage.load().map((w) => w.id).toList());
  });

  test('false write does not publish and a later add still succeeds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var fail = true;
    final storage = WorkoutHistoryStorage(
      prefs,
      writeString: (key, value) async {
        if (fail) {
          fail = false;
          return false;
        }
        return prefs.setString(key, value);
      },
    );
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith((ref) async => storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = await controllerFor(container);

    expect(
      await controller.addWorkout(_workout('nope', DateTime.utc(2026, 10, 1))),
      isFalse,
    );
    expect(container.read(workoutHistoryProvider).value, isEmpty);
    expect(
      await controller.addWorkout(_workout('yes', DateTime.utc(2026, 10, 2))),
      isTrue,
    );
    expect(container.read(workoutHistoryProvider).value!.single.id, 'yes');
    expect(storage.load().single.id, 'yes');
  });

  test('a thrown add does not block the next add', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = _ThrowOnceHistory(prefs);
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith((ref) async => storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = await controllerFor(container);

    final first = controller.addWorkout(_workout('a', DateTime.utc(2026, 10, 1)));
    final second = controller.addWorkout(_workout('b', DateTime.utc(2026, 10, 2)));
    expect(await first, isFalse);
    expect(await second, isTrue);
    expect(container.read(workoutHistoryProvider).value!.single.id, 'b');
    expect(storage.load().single.id, 'b');
  });
}
