import 'dart:async';

import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomWorkoutTemplate _template(String id, String name, DateTime updatedAt) {
  return CustomWorkoutTemplate(
    id: id,
    name: name,
    targetDuration: WorkoutDuration.fifteenMinutes,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    warmup: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'march_in_place',
        sets: 1,
        workDuration: const Duration(seconds: 20),
        restBetweenSets: Duration.zero,
      ),
    ],
    main: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'squat_chair',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      ),
    ],
    cooldown: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'cobra_stretch',
        sets: 1,
        workDuration: const Duration(seconds: 20),
        restBetweenSets: Duration.zero,
      ),
    ],
  );
}

class _ThrowOnceStorage extends CustomWorkoutStorage {
  _ThrowOnceStorage();
  var thrown = false;

  @override
  Future<List<CustomWorkoutTemplate>?> create(CustomWorkoutTemplate template) async {
    if (!thrown) {
      thrown = true;
      throw StateError('disk');
    }
    return super.create(template);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime.utc(2026, 10, 2, 9);

  Future<ProviderContainer> open(CustomWorkoutStorage storage) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        customWorkoutStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    container.read(customWorkoutControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  CustomWorkoutController notifier(ProviderContainer container) =>
      container.read(customWorkoutControllerProvider.notifier);

  List<String> idsOf(ProviderContainer container) =>
      container
          .read(customWorkoutControllerProvider)
          .value!
          .map((t) => t.id)
          .toList();

  test('two creates launched together both survive', () async {
    final writes = <String>[];
    final storage = CustomWorkoutStorage(
      writeString: (prefs, key, value) async {
        writes.add(value);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        return prefs.setString(key, value);
      },
    );
    final container = await open(storage);
    final n = notifier(container);
    final a = _template('a', 'A', t0);
    final b = _template('b', 'B', t0.add(const Duration(seconds: 1)));

    expect(
      await Future.wait([n.create(a), n.create(b)]),
      [true, true],
    );
    expect(idsOf(container).toSet(), {'a', 'b'});
    expect(writes.last, contains('"a"'));
    expect(writes.last, contains('"b"'));
    expect((await storage.loadAll()).map((t) => t.id).toSet(), {'a', 'b'});
  });

  test('update and create both survive', () async {
    final storage = const CustomWorkoutStorage();
    final container = await open(storage);
    final n = notifier(container);
    final original = _template('a', 'A', t0);
    expect(await n.create(original), isTrue);

    final updated = _template('a', 'A2', t0.add(const Duration(minutes: 1)));
    final created = _template('b', 'B', t0.add(const Duration(minutes: 2)));
    expect(
      await Future.wait([n.update(updated), n.create(created)]),
      [true, true],
    );

    final state = container.read(customWorkoutControllerProvider).value!;
    expect(state.map((t) => t.id).toSet(), {'a', 'b'});
    expect(state.firstWhere((t) => t.id == 'a').name, 'A2');
    final persisted = await storage.loadAll();
    expect(persisted.map((t) => t.id).toSet(), state.map((t) => t.id).toSet());
    expect(persisted.firstWhere((t) => t.id == 'a').name, 'A2');
  });

  test('delete and create produce a deterministic persisted list', () async {
    final storage = const CustomWorkoutStorage();
    final container = await open(storage);
    final n = notifier(container);
    expect(await n.create(_template('a', 'A', t0)), isTrue);

    final created = _template('b', 'B', t0.add(const Duration(seconds: 2)));
    expect(
      await Future.wait([n.delete('a'), n.create(created)]),
      [true, true],
    );

    final state = container.read(customWorkoutControllerProvider).value!;
    expect(state.map((t) => t.id).toList(), ['b']);
    expect((await storage.loadAll()).map((t) => t.id).toList(), ['b']);
  });

  test('a thrown create does not poison the queued create', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = _ThrowOnceStorage();
    final container = await open(storage);
    final n = notifier(container);

    final first = n.create(_template('a', 'A', t0));
    final second = n.create(_template('b', 'B', t0.add(const Duration(seconds: 1))));
    expect(await first, isFalse);
    expect(await second, isTrue);
    expect(idsOf(container), ['b']);
    expect((await storage.loadAll()).map((t) => t.id).toList(), ['b']);
  });

  test('mutation finishing after disposal does not throw', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final storage = CustomWorkoutStorage(
      writeString: (prefs, key, value) async {
        if (!started.isCompleted) started.complete();
        await gate.future;
        return prefs.setString(key, value);
      },
    );
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        customWorkoutStorageProvider.overrideWithValue(storage),
      ],
    );
    container.read(customWorkoutControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final pending = container
        .read(customWorkoutControllerProvider.notifier)
        .create(_template('a', 'A', t0));
    await started.future;
    container.dispose();
    gate.complete();
    await expectLater(pending, completion(isTrue));
    expect((await storage.loadAll()).single.id, 'a');
  });
}
