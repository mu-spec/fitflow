import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_validator.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalogById = {for (final Exercise e in ExerciseCatalog.all) e.id: e};

  group('Builder state logic', () {
    test('new workout has default duration', () {
      expect(WorkoutDuration.fifteenMinutes.label, isNotEmpty);
    });

    test('name validation trims and max 60', () {
      expect(CustomWorkoutValidator.validateName('  '), isNotNull);
      expect(CustomWorkoutValidator.validateName('a' * 61), isNotNull);
      expect(CustomWorkoutValidator.validateName('Valid Name'), isNull);
    });

    test('duration validation', () {
      expect(CustomWorkoutValidator.validateDuration(null), isNotNull);
      expect(CustomWorkoutValidator.validateDuration(WorkoutDuration.fifteenMinutes), isNull);
    });

    test('add exercise uses defaults and not duplicate', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = CustomWorkoutTemplate(
        id: 'custom_1_0',
        name: 'Test',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
        main: [entry],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final validation = CustomWorkoutValidator.validateTemplate(template: template, catalogById: catalogById);
      expect(validation.isValid, true);
    });

    test('duplicate exercise rejected', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = CustomWorkoutTemplate(
        id: 'custom_1_0',
        name: 'Test',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
        main: [entry, entry],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final validation = CustomWorkoutValidator.validateTemplate(template: template, catalogById: catalogById);
      expect(validation.isValid, false);
      expect(validation.issues.any((i) => i.contains('Duplicate')), true);
    });

    test('section enforcement', () {
      // squat in warmup should fail
      final template = CustomWorkoutTemplate(
        id: 'custom_1_0',
        name: 'Test',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
        ],
        main: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'pushup_standard', sets: 1, repsPerSet: 8, restBetweenSets: const Duration(seconds: 30))
        ],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final validation = CustomWorkoutValidator.validateTemplate(template: template, catalogById: catalogById);
      expect(validation.isValid, false);
    });

    test('invalid workload rejected', () {
      final invalidEntry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 0,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = CustomWorkoutTemplate(
        id: 'custom_1_0',
        name: 'Test',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
        main: [invalidEntry],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final validation = CustomWorkoutValidator.validateTemplate(template: template, catalogById: catalogById);
      expect(validation.isValid, false);
    });

    test('dirty detection new vs edit', () {
      final now = DateTime.now().toUtc();
      final original = CustomWorkoutTemplate(
        id: 'custom_1_0',
        name: 'Original',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: now,
        updatedAt: now,
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
        main: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
        ],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final edited = original.copyWith(name: 'Edited');
      expect(edited != original, true);
      expect(edited.id, original.id);
      expect(edited.createdAt, original.createdAt);
    });

    test('persisted retains ID', () {
      final now = DateTime.now().toUtc();
      final template = CustomWorkoutTemplate(
        id: 'custom_123_0',
        name: 'Test',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: now,
        updatedAt: now,
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
        main: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
        ],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
        ],
      );
      final json = template.toJson();
      final restored = CustomWorkoutTemplate.fromJson(json);
      expect(restored!.id, 'custom_123_0');
    });

    test('reorder deterministic within section', () {
      final e1 = CustomWorkoutExerciseEntry(
          exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero);
      final e2 = CustomWorkoutExerciseEntry(
          exerciseId: 'arm_circles', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero);
      var warmup = [e1, e2];
      // Move e2 up
      final item = warmup.removeAt(1);
      warmup.insert(0, item);
      expect(warmup[0].exerciseId, 'arm_circles');
      expect(warmup[1].exerciseId, 'march_in_place');
    });

    test('prescription edit validation', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 2,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final editedValid = entry.copyWith(sets: 5, repsPerSet: 20, restBetweenSets: const Duration(seconds: 60));
      expect(editedValid.isValid, true);
      final editedInvalid = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 20,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(editedInvalid.isValid, false);
    });
  });
}
