import 'dart:convert';

import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomWorkoutTemplate _makeTemplate(String id, String name) {
  final now = DateTime.now().toUtc();
  return CustomWorkoutTemplate(
    id: id,
    name: name,
    targetDuration: WorkoutDuration.fifteenMinutes,
    createdAt: now,
    updatedAt: now,
    warmup: [
      CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
    ],
    main: [
      CustomWorkoutExerciseEntry(exerciseId: 'squat_chair', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
    ],
    cooldown: [
      CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage failure contract', () {
    test('controller keeps previous state after failed create', () async {
      final t1 = _makeTemplate('custom_1_0', 'First');
      final jsonStr = jsonEncode([t1.toJson()]);
      SharedPreferences.setMockInitialValues({CustomWorkoutStorage.key: jsonStr});

      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      final container = ProviderContainer(overrides: [
        customWorkoutStorageProvider.overrideWithValue(failingStorage),
      ]);
      addTearDown(container.dispose);
      // Trigger load
      container.read(customWorkoutControllerProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      final before = container.read(customWorkoutControllerProvider).value ?? [];
      expect(before.length, 1);

      final t2 = _makeTemplate('custom_2_0', 'Second');
      final success = await container.read(customWorkoutControllerProvider.notifier).create(t2);
      expect(success, false);
      final after = container.read(customWorkoutControllerProvider).value ?? [];
      expect(after.length, 1);
      expect(after.first.id, 'custom_1_0');
    });

    test('controller keeps previous state after failed update', () async {
      final t1 = _makeTemplate('custom_1_0', 'First');
      final jsonStr = jsonEncode([t1.toJson()]);
      SharedPreferences.setMockInitialValues({CustomWorkoutStorage.key: jsonStr});

      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      final container = ProviderContainer(overrides: [
        customWorkoutStorageProvider.overrideWithValue(failingStorage),
      ]);
      addTearDown(container.dispose);
      container.read(customWorkoutControllerProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      final before = container.read(customWorkoutControllerProvider).value ?? [];
      expect(before.length, 1);
      expect(before.first.name, 'First');

      final updated = _makeTemplate('custom_1_0', 'Updated');
      final success = await container.read(customWorkoutControllerProvider.notifier).update(updated);
      expect(success, false);
      final after = container.read(customWorkoutControllerProvider).value ?? [];
      expect(after.length, 1);
      expect(after.first.name, 'First');
    });

    test('controller keeps template after failed delete', () async {
      final t1 = _makeTemplate('custom_1_0', 'First');
      final jsonStr = jsonEncode([t1.toJson()]);
      SharedPreferences.setMockInitialValues({CustomWorkoutStorage.key: jsonStr});

      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      final container = ProviderContainer(overrides: [
        customWorkoutStorageProvider.overrideWithValue(failingStorage),
      ]);
      addTearDown(container.dispose);
      container.read(customWorkoutControllerProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      final before = container.read(customWorkoutControllerProvider).value ?? [];
      expect(before.length, 1);

      final success = await container.read(customWorkoutControllerProvider.notifier).delete('custom_1_0');
      expect(success, false);
      final after = container.read(customWorkoutControllerProvider).value ?? [];
      expect(after.length, 1);
      expect(after.first.id, 'custom_1_0');
    });

    test('save failure UI message remains truthful - controller returns false', () async {
      SharedPreferences.setMockInitialValues({});
      final failingStorage = CustomWorkoutStorage(
        writeString: (prefs, key, value) async => false,
      );
      final container = ProviderContainer(overrides: [
        customWorkoutStorageProvider.overrideWithValue(failingStorage),
      ]);
      addTearDown(container.dispose);

      final t = _makeTemplate('custom_1_0', 'Test');
      final success = await container.read(customWorkoutControllerProvider.notifier).create(t);
      expect(success, false);
    });

    test('successful writes still update state normally', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = CustomWorkoutStorage();
      final container = ProviderContainer(overrides: [
        customWorkoutStorageProvider.overrideWithValue(storage),
      ]);
      addTearDown(container.dispose);

      final t1 = _makeTemplate('custom_1_0', 'First');
      final success = await container.read(customWorkoutControllerProvider.notifier).create(t1);
      expect(success, true);
      final after = container.read(customWorkoutControllerProvider).value ?? [];
      expect(after.length, 1);
    });
  });
}
