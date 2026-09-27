import 'package:fitflow/features/onboarding/data/workout_duration.dart';
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
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimate.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
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

  group('Defaults Cleanup - 5C-2', () {
    test('missing defaultRest -> factory returns null', () {
      final missingRestReps = createRepsExercise(defaultRest: null);
      final missingRestTimed = createTimedExercise(defaultRest: null);

      expect(
          WorkoutExercisePrescription.fromExerciseDefaults(missingRestReps),
          isNull);
      expect(
          WorkoutExercisePrescription.fromExerciseDefaults(missingRestTimed),
          isNull);
    });

    test('negative defaultRest -> null', () {
      final negRestReps = createRepsExercise(
          defaultRest: const Duration(seconds: -5));
      final negRestTimed = createTimedExercise(
          defaultRest: const Duration(seconds: -10));

      expect(
          WorkoutExercisePrescription.fromExerciseDefaults(negRestReps),
          isNull);
      expect(
          WorkoutExercisePrescription.fromExerciseDefaults(negRestTimed),
          isNull);
    });

    test('explicit zero defaultRest -> valid prescription', () {
      final zeroRestReps =
          createRepsExercise(defaultRest: Duration.zero);
      final zeroRestTimed =
          createTimedExercise(defaultRest: Duration.zero);

      final repsPrescription =
          WorkoutExercisePrescription.fromExerciseDefaults(zeroRestReps);
      final timedPrescription =
          WorkoutExercisePrescription.fromExerciseDefaults(zeroRestTimed);

      expect(repsPrescription, isNotNull);
      expect(repsPrescription!.restBetweenSets, Duration.zero);
      expect(repsPrescription.isValid, true);

      expect(timedPrescription, isNotNull);
      expect(timedPrescription!.restBetweenSets, Duration.zero);
      expect(timedPrescription.isValid, true);
    });

    test('normal positive defaultRest still copied exactly', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(pushUp);

      expect(prescription, isNotNull);
      expect(prescription!.restBetweenSets, pushUp.defaultRest);
    });
  });

  group('WorkoutTimeEstimate', () {
    test('invariant total == work+rest+transition', () {
      final est = WorkoutTimeEstimate.fromComponents(
        work: const Duration(seconds: 90),
        rest: const Duration(seconds: 60),
        transition: Duration.zero,
      );
      expect(est.total, const Duration(seconds: 150));
      expect(est.work + est.rest + est.transition, est.total);
    });

    test('zero constant', () {
      expect(WorkoutTimeEstimate.zero.work, Duration.zero);
      expect(WorkoutTimeEstimate.zero.rest, Duration.zero);
      expect(WorkoutTimeEstimate.zero.transition, Duration.zero);
      expect(WorkoutTimeEstimate.zero.total, Duration.zero);
      expect(WorkoutTimeEstimate.zero.isValid, true);
    });

    test('non-negative validation', () {
      final valid = WorkoutTimeEstimate(
        work: const Duration(seconds: 10),
        rest: Duration.zero,
        transition: Duration.zero,
        total: const Duration(seconds: 10),
      );
      expect(valid.isValid, true);
    });
  });

  group('Reps Estimate', () {
    test('3 sets x 10 reps, 30 sec rest', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      final prescription = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      final estimate =
          WorkoutTimeEstimator.estimatePrescription(prescription);

      expect(estimate, isNotNull);
      expect(estimate!.work, const Duration(seconds: 90)); // 3*10*3
      expect(estimate.rest, const Duration(seconds: 60)); // (3-1)*30
      expect(estimate.transition, Duration.zero);
      expect(estimate.total, const Duration(seconds: 150));
    });

    test('1 set -> zero rest', () {
      final pushUp = ExerciseCatalog.byId('pushup_wall')!;
      final prescription = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 1,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      final estimate =
          WorkoutTimeEstimator.estimatePrescription(prescription);

      expect(estimate, isNotNull);
      expect(estimate!.work, const Duration(seconds: 30)); // 1*10*3
      expect(estimate.rest, Duration.zero);
      expect(estimate.total, const Duration(seconds: 30));
    });

    test('determinism', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      final prescription = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 2,
        repsPerSet: 8,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 45),
      );

      final first =
          WorkoutTimeEstimator.estimatePrescription(prescription);
      final second =
          WorkoutTimeEstimator.estimatePrescription(prescription);

      expect(first, second);
    });
  });

  group('Timed Estimate', () {
    test('2 sets x 30 sec, 30 sec rest', () {
      final plank = ExerciseCatalog.byId('plank_forearm')!;
      final prescription = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );

      final estimate =
          WorkoutTimeEstimator.estimatePrescription(prescription);

      expect(estimate, isNotNull);
      expect(estimate!.work, const Duration(seconds: 60)); // 2*30
      expect(estimate.rest, const Duration(seconds: 30)); // (2-1)*30
      expect(estimate.transition, Duration.zero);
      expect(estimate.total, const Duration(seconds: 90));
    });

    test('1 timed set -> no rest', () {
      final plank = ExerciseCatalog.byId('plank_forearm')!;
      final prescription = WorkoutExercisePrescription(
        exercise: plank,
        sets: 1,
        repsPerSet: null,
        workDuration: const Duration(seconds: 20),
        restBetweenSets: const Duration(seconds: 30),
      );

      final estimate =
          WorkoutTimeEstimator.estimatePrescription(prescription);

      expect(estimate, isNotNull);
      expect(estimate!.work, const Duration(seconds: 20));
      expect(estimate.rest, Duration.zero);
      expect(estimate.total, const Duration(seconds: 20));
    });
  });

  group('Invalid Prescription Estimate', () {
    test('invalid returns null no crash', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;

      final invalidZeroSets = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 0,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      expect(() => WorkoutTimeEstimator.estimatePrescription(invalidZeroSets),
          returnsNormally);
      expect(
          WorkoutTimeEstimator.estimatePrescription(invalidZeroSets), isNull);

      final invalidBoth = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 10,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      );

      expect(WorkoutTimeEstimator.estimatePrescription(invalidBoth), isNull);
    });
  });

  group('Section Estimate', () {
    test('reps + timed with 2 exercises, one transition', () {
      final pushUp = ExerciseCatalog.byId('pushup_standard')!;
      final plank = ExerciseCatalog.byId('plank_forearm')!;

      final repsPrescription = WorkoutExercisePrescription(
        exercise: pushUp,
        sets: 3,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      ); // work 90, rest 60

      final timedPrescription = WorkoutExercisePrescription(
        exercise: plank,
        sets: 2,
        repsPerSet: null,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 30),
      ); // work 60, rest 30

      final section = WorkoutSection(
          type: WorkoutSectionType.main,
          exercises: [repsPrescription, timedPrescription]);

      final estimate = WorkoutTimeEstimator.estimateSection(section);

      expect(estimate, isNotNull);
      // work = 90+60=150
      expect(estimate!.work, const Duration(seconds: 150));
      // rest = 60+30=90
      expect(estimate.rest, const Duration(seconds: 90));
      // transition = 1 *15 =15
      expect(estimate.transition, const Duration(seconds: 15));
      // total = 150+90+15=255
      expect(estimate.total, const Duration(seconds: 255));
    });

    test('3 exercises -> 30 sec transitions', () {
      final ex1 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final ex2 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('squat_bodyweight')!)!;
      final ex3 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('plank_forearm')!)!;

      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex1, ex2, ex3]);

      final estimate = WorkoutTimeEstimator.estimateSection(section);
      expect(estimate, isNotNull);
      expect(estimate!.transition, const Duration(seconds: 30));
    });

    test('1 exercise -> no transition', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex]);

      final estimate = WorkoutTimeEstimator.estimateSection(section);
      expect(estimate, isNotNull);
      expect(estimate!.transition, Duration.zero);
    });

    test('invalid contained prescription returns null', () {
      final valid = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final invalid = WorkoutExercisePrescription(
        exercise: ExerciseCatalog.byId('pushup_standard')!,
        sets: 0,
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [valid, invalid]);

      expect(WorkoutTimeEstimator.estimateSection(section), isNull);
    });

    test('determinism', () {
      final ex1 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final ex2 = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('squat_bodyweight')!)!;
      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex1, ex2]);

      final first = WorkoutTimeEstimator.estimateSection(section);
      final second = WorkoutTimeEstimator.estimateSection(section);

      expect(first, second);
    });
  });

  group('Empty Section', () {
    test('zero estimate', () {
      final empty = WorkoutSection(type: WorkoutSectionType.warmup);
      final estimate = WorkoutTimeEstimator.estimateSection(empty);

      expect(estimate, isNotNull);
      expect(estimate!.work, Duration.zero);
      expect(estimate.rest, Duration.zero);
      expect(estimate.transition, Duration.zero);
      expect(estimate.total, Duration.zero);
    });

    test('explicit empty list', () {
      final empty = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: []);
      final estimate = WorkoutTimeEstimator.estimateSection(empty);
      expect(estimate, WorkoutTimeEstimate.zero);
    });
  });

  group('WorkoutTimeBudget - All Durations', () {
    test('exact table values and sum', () {
      final expectations = {
        WorkoutDuration.fiveMinutes: {
          'target': const Duration(minutes: 5),
          'warmup': const Duration(minutes: 1),
          'main': const Duration(minutes: 3),
          'cooldown': const Duration(minutes: 1),
        },
        WorkoutDuration.tenMinutes: {
          'target': const Duration(minutes: 10),
          'warmup': const Duration(minutes: 2),
          'main': const Duration(minutes: 6),
          'cooldown': const Duration(minutes: 2),
        },
        WorkoutDuration.fifteenMinutes: {
          'target': const Duration(minutes: 15),
          'warmup': const Duration(minutes: 2),
          'main': const Duration(minutes: 11),
          'cooldown': const Duration(minutes: 2),
        },
        WorkoutDuration.twentyMinutes: {
          'target': const Duration(minutes: 20),
          'warmup': const Duration(minutes: 3),
          'main': const Duration(minutes: 14),
          'cooldown': const Duration(minutes: 3),
        },
        WorkoutDuration.thirtyMinutes: {
          'target': const Duration(minutes: 30),
          'warmup': const Duration(minutes: 4),
          'main': const Duration(minutes: 22),
          'cooldown': const Duration(minutes: 4),
        },
        WorkoutDuration.fortyFiveMinutes: {
          'target': const Duration(minutes: 45),
          'warmup': const Duration(minutes: 5),
          'main': const Duration(minutes: 35),
          'cooldown': const Duration(minutes: 5),
        },
      };

      for (final entry in expectations.entries) {
        final duration = entry.key;
        final expected = entry.value;

        final budget = WorkoutTimeBudget.fromWorkoutDuration(duration);

        expect(budget.target, expected['target'],
            reason: '${duration.name} target');
        expect(budget.warmup, expected['warmup'],
            reason: '${duration.name} warmup');
        expect(budget.main, expected['main'],
            reason: '${duration.name} main');
        expect(budget.cooldown, expected['cooldown'],
            reason: '${duration.name} cooldown');

        expect(budget.warmup + budget.main + budget.cooldown,
            budget.target,
            reason: '${duration.name} sum must equal target');

        expect(budget.isValid, true,
            reason: '${duration.name} should be valid');
      }
    });

    test('uses WorkoutDuration.minutes', () {
      for (final d in WorkoutDuration.values) {
        final budget = WorkoutTimeBudget.fromWorkoutDuration(d);
        expect(budget.target.inMinutes, d.minutes);
      }
    });
  });

  group('budgetFor', () {
    test('returns matching budget', () {
      final budget =
          WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes);

      expect(budget.budgetFor(WorkoutSectionType.warmup), budget.warmup);
      expect(budget.budgetFor(WorkoutSectionType.main), budget.main);
      expect(budget.budgetFor(WorkoutSectionType.cooldown), budget.cooldown);
    });
  });

  group('Invalid Custom Budget', () {
    test('section total does not equal target fails validation', () {
      final invalid = WorkoutTimeBudget(
        target: const Duration(minutes: 10),
        warmup: const Duration(minutes: 2),
        main: const Duration(minutes: 5),
        cooldown: const Duration(minutes: 2), // sum 9 !=10
      );

      expect(invalid.isValid, false);
      expect(invalid.validate(), contains(contains('equal target')));
    });

    test('negative values invalid', () {
      final negative = WorkoutTimeBudget(
        target: const Duration(minutes: 10),
        warmup: const Duration(minutes: -1),
        main: const Duration(minutes: 10),
        cooldown: const Duration(minutes: 1),
      );

      expect(negative.isValid, false);
    });

    test('zero target invalid', () {
      final zeroTarget = WorkoutTimeBudget(
        target: Duration.zero,
        warmup: Duration.zero,
        main: Duration.zero,
        cooldown: Duration.zero,
      );

      expect(zeroTarget.isValid, false);
    });

    test('no automatic correction', () {
      final invalid = WorkoutTimeBudget(
        target: const Duration(minutes: 10),
        warmup: const Duration(minutes: 2),
        main: const Duration(minutes: 6),
        cooldown: const Duration(minutes: 3), // sum 11
      );

      // Must remain invalid, not auto-corrected to 10
      expect(invalid.warmup + invalid.main + invalid.cooldown,
          const Duration(minutes: 11));
      expect(invalid.isValid, false);
    });
  });

  group('Determinism', () {
    test('same prescription/section/budget identical', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_standard')!)!;
      final section = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex]);
      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);

      final est1 = WorkoutTimeEstimator.estimatePrescription(ex);
      final est2 = WorkoutTimeEstimator.estimatePrescription(ex);
      expect(est1, est2);

      final sec1 = WorkoutTimeEstimator.estimateSection(section);
      final sec2 = WorkoutTimeEstimator.estimateSection(section);
      expect(sec1, sec2);

      final bud1 = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);
      final bud2 = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);
      expect(bud1, bud2);
      expect(bud1, budget);
    });
  });
}
