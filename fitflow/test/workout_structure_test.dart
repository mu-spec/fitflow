import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createRepsExercise({
    String id = 'test_reps',
    int? defaultReps = 10,
    Duration? defaultRest = const Duration(seconds: 30),
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level1,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      bodyPosition: ExercisePosition.standing,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: defaultReps,
      defaultRest: defaultRest,
      active: true,
    );
  }

  Exercise createTimedExercise({
    String id = 'test_timed',
    Duration? defaultDuration = const Duration(seconds: 30),
    Duration? defaultRest = const Duration(seconds: 30),
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level1,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      bodyPosition: ExercisePosition.floor,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: defaultDuration,
      defaultRest: defaultRest,
      active: true,
    );
  }

  group('Section Type', () {
    test('exactly warmup, main, cooldown', () {
      expect(WorkoutSectionType.values.length, 3);
      expect(WorkoutSectionType.values, contains(WorkoutSectionType.warmup));
      expect(WorkoutSectionType.values, contains(WorkoutSectionType.main));
      expect(WorkoutSectionType.values, contains(WorkoutSectionType.cooldown));
    });
  });

  group('Reps Prescription - real catalog exercise', () {
    test('valid reps prescription from catalog', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      expect(pushUp.exerciseType, ExerciseType.reps);

      final prescription = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 45),
      );

      expect(prescription.validate(), isEmpty);
      expect(prescription.isValid, true);
      expect(prescription.sets, 3);
      expect(prescription.repsPerSet, 8);
      expect(prescription.workDuration, isNull);
      expect(prescription.restBetweenSets, const Duration(seconds: 45));
    });

    test('invalid reps combinations', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;

      // zero sets
      final zeroSets = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 0,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(zeroSets.isValid, false);
      expect(zeroSets.validate(), contains(contains('sets')));

      // negative sets
      final negativeSets = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: -1,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(negativeSets.isValid, false);

      // zero reps
      final zeroReps = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 0,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(zeroReps.isValid, false);
      expect(zeroReps.validate(), contains(contains('repsPerSet')));

      // negative reps
      final negReps = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: -5,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(negReps.isValid, false);

      // negative rest
      final negRest = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: -10),
      );
      expect(negRest.isValid, false);
      expect(negRest.validate(), contains(contains('restBetweenSets')));

      // reps exercise given timed prescription (workDuration supplied)
      final timedForReps = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 8,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(timedForReps.isValid, false);
      expect(timedForReps.validate(), contains(contains('both')));

      // reps exercise with only duration (missing reps, has duration)
      final onlyDurationForReps = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(onlyDurationForReps.isValid, false);

      // neither supplied
      final neither = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: null,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(neither.isValid, false);
      expect(neither.validate(), contains(contains('either')));

      // both supplied
      final both = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 8,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(both.isValid, false);
    });
  });

  group('Timed Prescription - real catalog exercise', () {
    test('valid timed prescription from catalog', () {
      final plank = ExerciseCatalog.byId('plank_forearm')!;
      expect(plank.exerciseType, ExerciseType.timed);

      final prescription = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );

      expect(prescription.isValid, true);
      expect(prescription.validate(), isEmpty);
      expect(prescription.sets, 2);
      expect(prescription.workDuration, const Duration(seconds: 30));
      expect(prescription.repsPerSet, isNull);
    });

    test('invalid timed combinations', () {
      final plank = ExerciseCatalog.byId('plank_forearm')!;

      // zero sets
      final zeroSets = WorkoutExercisePrescription(
        exercise: plank,
        sets: 0,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: Duration.zero,
      );
      expect(zeroSets.isValid, false);

      // zero duration
      final zeroDur = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: Duration.zero,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(zeroDur.isValid, false);
      expect(zeroDur.validate(), contains(contains('workDuration')));

      // negative duration
      final negDur = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: -5),
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(negDur.isValid, false);

      // negative rest
      final negRest = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: -1),
      );
      expect(negRest.isValid, false);

      // timed exercise given reps prescription
      final repsForTimed = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(repsForTimed.isValid, false);

      // both supplied
      final both = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: 10,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(both.isValid, false);

      // neither supplied
      final neither = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      expect(neither.isValid, false);
    });
  });

  group('Defaults Factory', () {
    test('reps exercise copies defaultReps and defaultRest', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(pushUp, sets: 3);

      expect(prescription, isNotNull);
      expect(prescription!.exercise.id, pushUp.id);
      expect(prescription.sets, 3);
      expect(prescription.repsPerSet, pushUp.defaultReps);
      expect(prescription.workDuration, isNull);
      expect(prescription.restBetweenSets, pushUp.defaultRest);
      expect(prescription.isValid, true);
    });

    test('timed exercise copies defaultDuration and defaultRest', () {
      final plank = ExerciseCatalog.byId('plank_forearm')!;
      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(plank, sets: 2);

      expect(prescription, isNotNull);
      expect(prescription!.exercise.id, plank.id);
      expect(prescription.sets, 2);
      expect(prescription.workDuration, plank.defaultDuration);
      expect(prescription.repsPerSet, isNull);
      expect(prescription.restBetweenSets, plank.defaultRest);
      expect(prescription.isValid, true);
    });

    test('factory does not modify Exercise', () {
      final pushUp = ExerciseCatalog.byId('pushup_wall')!;
      final originalReps = pushUp.defaultReps;
      final originalRest = pushUp.defaultRest;

      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(pushUp);

      expect(pushUp.defaultReps, originalReps);
      expect(pushUp.defaultRest, originalRest);
      expect(prescription, isNotNull);
    });

    test('default sets is 1', () {
      final pushUp = ExerciseCatalog.byId('pushup_wall')!;
      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(pushUp);
      expect(prescription!.sets, 1);
    });
  });

  group('Missing Defaults', () {
    test('missing reps on reps exercise fails cleanly', () {
      final missingReps = createRepsExercise(defaultReps: null);
      final result =
          WorkoutExercisePrescription.fromExerciseDefaults(missingReps);
      expect(result, isNull,
          reason: 'Should return null when defaultReps missing');
    });

    test('missing duration on timed exercise fails cleanly', () {
      final missingDur = createTimedExercise(defaultDuration: null);
      final result =
          WorkoutExercisePrescription.fromExerciseDefaults(missingDur);
      expect(result, isNull,
          reason: 'Should return null when defaultDuration missing');
    });

    test('zero reps missing also fails', () {
      final zeroReps = createRepsExercise(defaultReps: 0);
      final result = WorkoutExercisePrescription.fromExerciseDefaults(zeroReps);
      expect(result, isNull);
    });

    test('zero duration missing also fails', () {
      final zeroDur = createTimedExercise(defaultDuration: Duration.zero);
      final result = WorkoutExercisePrescription.fromExerciseDefaults(zeroDur);
      expect(result, isNull);
    });

    test('no fabricated values', () {
      final missingReps = createRepsExercise(defaultReps: null);
      final result =
          WorkoutExercisePrescription.fromExerciseDefaults(missingReps);
      // Must be null, not fabricated 10 reps
      expect(result, isNull);
      expect(missingReps.defaultReps, isNull);
    });
  });

  group('WorkoutSection', () {
    test('create sections for warmup, main, cooldown', () {
      final pushUp = ExerciseCatalog.byId('pushup_wall')!;
      final plank = ExerciseCatalog.byId('plank_forearm')!;
      final march = ExerciseCatalog.byId('march_in_place')!;

      final warmupPrescription =
          WorkoutExercisePrescription.fromExerciseDefaults(march)!;
      final mainPrescription =
          WorkoutExercisePrescription.fromExerciseDefaults(pushUp)!;
      final cooldownPrescription =
          WorkoutExercisePrescription.fromExerciseDefaults(plank)!;

      final warmupSection = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupPrescription]);
      final mainSection = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [mainPrescription]);
      final cooldownSection = WorkoutSection(
          type: WorkoutSectionType.cooldown,
          exercises: [cooldownPrescription]);

      expect(warmupSection.type, WorkoutSectionType.warmup);
      expect(mainSection.type, WorkoutSectionType.main);
      expect(cooldownSection.type, WorkoutSectionType.cooldown);

      expect(warmupSection.exerciseCount, 1);
      expect(mainSection.exerciseCount, 1);
      expect(cooldownSection.exerciseCount, 1);

      expect(warmupSection.isEmpty, false);
      expect(warmupSection.isNotEmpty, true);
    });

    test('ordering preserved', () {
      final ex1 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final ex2 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('squat_bodyweight')!)!;
      final ex3 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('plank_forearm')!)!;

      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex1, ex2, ex3]);

      expect(section.exercises[0].exercise.id, ex1.exercise.id);
      expect(section.exercises[1].exercise.id, ex2.exercise.id);
      expect(section.exercises[2].exercise.id, ex3.exercise.id);
    });

    test('empty allowed', () {
      final emptyWarmup =
          WorkoutSection(type: WorkoutSectionType.warmup, exercises: []);
      final emptyMain = WorkoutSection(type: WorkoutSectionType.main);
      final emptyCooldown =
          WorkoutSection(type: WorkoutSectionType.cooldown, exercises: null);

      expect(emptyWarmup.isEmpty, true);
      expect(emptyWarmup.exerciseCount, 0);
      expect(emptyMain.isEmpty, true);
      expect(emptyCooldown.isEmpty, true);
    });

    test('list immutable - cannot mutate exposed list', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex]);

      expect(() => section.exercises.add(ex), throwsUnsupportedError);
      expect(() => section.items.add(ex), throwsUnsupportedError);
    });

    test('source-list mutation cannot affect section', () {
      final ex1 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final ex2 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('squat_bodyweight')!)!;

      final sourceList = [ex1, ex2];
      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: sourceList);

      expect(section.exerciseCount, 2);

      // Mutate source list
      sourceList.add(WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('plank_forearm')!)!);
      sourceList.clear();

      // Section should remain unchanged
      expect(section.exerciseCount, 2);
      expect(section.exercises[0].exercise.id, ex1.exercise.id);
    });

    test('equality and hash', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;

      final section1 = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex]);
      final section2 = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex]);

      expect(section1, section2);
      expect(section1.hashCode, section2.hashCode);

      final differentType = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [ex]);
      expect(section1 == differentType, false);
    });

    test('prescription equality uses exercise.id', () {
      final pushUp = ExerciseCatalog.byId('pushup_wall')!;
      final p1 = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      final p2 = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
    });
  });
}
