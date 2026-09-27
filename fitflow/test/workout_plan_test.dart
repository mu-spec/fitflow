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
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createRepsExercise(String id) {
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
      defaultReps: 10,
      defaultRest: const Duration(seconds: 30),
      active: true,
    );
  }

  Exercise createTimedExercise(String id) {
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
      defaultDuration: const Duration(seconds: 30),
      defaultRest: const Duration(seconds: 30),
      active: true,
    );
  }

  WorkoutExercisePrescription validReps(String id,
      {int sets = 1, int reps = 10, Duration rest = const Duration(seconds: 30)}) {
    final ex = createRepsExercise(id);
    return WorkoutExercisePrescription(
      exercise: ex,
      sets: sets,
      repsPerSet: reps,
      workDuration: null,
      restBetweenSets: rest,
    );
  }

  WorkoutExercisePrescription validTimed(String id,
      {int sets = 1, Duration work = const Duration(seconds: 30), Duration rest = const Duration(seconds: 30)}) {
    final ex = createTimedExercise(id);
    return WorkoutExercisePrescription(
      exercise: ex,
      sets: sets,
      repsPerSet: null,
      workDuration: work,
      restBetweenSets: rest,
    );
  }

  group('Valid Plan', () {
    test('build valid plan with 1 warmup, 1 main, 1 cooldown', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);

      final plan = WorkoutPlan(
        warmup: warmup,
        main: main,
        cooldown: cooldown,
        timeBudget: budget,
      );

      expect(plan.isValid, true);
      expect(plan.validate(), isEmpty);
      expect(plan.totalExerciseCount, 3);
      expect(plan.targetDuration, const Duration(minutes: 20));
      expect(plan.warmupEstimate, isNotNull);
      expect(plan.mainEstimate, isNotNull);
      expect(plan.cooldownEstimate, isNotNull);
      expect(plan.estimatedDuration, isNotNull);
      expect(plan.estimatedDuration,
          plan.warmupEstimate!.total + plan.mainEstimate!.total + plan.cooldownEstimate!.total);
    });
  });

  group('Section Type Mismatch', () {
    test('main section passed as warmup field invalid', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      // Intentionally wrong types
      final wrongWarmup = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [warmupEx]); // should be warmup
      final correctMain =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final correctCooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);

      final plan = WorkoutPlan(
        warmup: wrongWarmup,
        main: correctMain,
        cooldown: correctCooldown,
        timeBudget: budget,
      );

      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('warmup') && m.contains('type')), true);
    });

    test('warmup type in main field invalid', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final correctWarmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final wrongMain = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [mainEx]); // wrong
      final correctCooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);

      final plan = WorkoutPlan(
        warmup: correctWarmup,
        main: wrongMain,
        cooldown: correctCooldown,
        timeBudget: budget,
      );

      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('main') && m.contains('type')), true);
    });

    test('main type in cooldown field invalid', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final correctWarmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final correctMain =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final wrongCooldown = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [cooldownEx]); // wrong

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);

      final plan = WorkoutPlan(
        warmup: correctWarmup,
        main: correctMain,
        cooldown: wrongCooldown,
        timeBudget: budget,
      );

      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('cooldown') && m.contains('type')), true);
    });

    test('no crash on type mismatch', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final wrongWarmup =
          WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [ex]);
      final wrongMain =
          WorkoutSection(type: WorkoutSectionType.warmup, exercises: [ex]);
      final wrongCooldown =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [ex]);
      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes);

      expect(
          () => WorkoutPlan(
                warmup: wrongWarmup,
                main: wrongMain,
                cooldown: wrongCooldown,
                timeBudget: budget,
              ),
          returnsNormally);

      final plan = WorkoutPlan(
        warmup: wrongWarmup,
        main: wrongMain,
        cooldown: wrongCooldown,
        timeBudget: budget,
      );
      expect(() => plan.validate(), returnsNormally);
      expect(() => plan.estimatedDuration, returnsNormally);
    });
  });

  group('Empty Sections', () {
    test('warmup empty invalid, but WorkoutSection itself still allowed empty', () {
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final emptyWarmup = WorkoutSection(type: WorkoutSectionType.warmup);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      // Section itself allowed empty
      expect(emptyWarmup.isEmpty, true);
      // But plan requires non-empty
      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);
      final plan = WorkoutPlan(
          warmup: emptyWarmup, main: main, cooldown: cooldown, timeBudget: budget);
      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('warmup') && m.contains('non-empty')), true);
    });

    test('main empty invalid', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final emptyMain = WorkoutSection(type: WorkoutSectionType.main);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);
      final plan = WorkoutPlan(
          warmup: warmup, main: emptyMain, cooldown: cooldown, timeBudget: budget);
      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('main') && m.contains('non-empty')), true);
    });

    test('cooldown empty invalid', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final emptyCooldown =
          WorkoutSection(type: WorkoutSectionType.cooldown);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);
      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: emptyCooldown, timeBudget: budget);
      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('cooldown') && m.contains('non-empty')), true);
    });
  });

  group('Invalid Prescription', () {
    test('invalid prescription inside section invalidates plan and null estimates', () {
      final validWarmup = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final validCooldown = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final invalidPrescription = WorkoutExercisePrescription(
        exercise: ExerciseCatalog.byId('pushup_standard')!,
        sets: 0, // invalid
        repsPerSet: 10,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [validWarmup]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [invalidPrescription]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [validCooldown]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan.isValid, false);
      expect(plan.validate().any((m) => m.contains('main') && m.contains('invalid')), true);
      expect(plan.mainEstimate, isNull);
      expect(plan.estimatedDuration, isNull);
    });

    test('no crash on invalid prescription', () {
      final invalid = WorkoutExercisePrescription(
        exercise: ExerciseCatalog.byId('pushup_standard')!,
        sets: -1,
        repsPerSet: null,
        workDuration: null,
        restBetweenSets: const Duration(seconds: 30),
      );
      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [invalid]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main,
          exercises: [
            WorkoutExercisePrescription.fromExerciseDefaults(
                ExerciseCatalog.byId('pushup_wall')!)!
          ]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown,
          exercises: [
            WorkoutExercisePrescription.fromExerciseDefaults(
                ExerciseCatalog.byId('childs_pose')!)!
          ]);
      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes);

      expect(
          () => WorkoutPlan(
                warmup: warmup,
                main: main,
                cooldown: cooldown,
                timeBudget: budget,
              ).validate(),
          returnsNormally);
    });
  });

  group('Invalid Budget', () {
    test('custom invalid budget invalidates plan no normalization', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final invalidBudget = WorkoutTimeBudget(
        target: const Duration(minutes: 10),
        warmup: const Duration(minutes: 2),
        main: const Duration(minutes: 5),
        cooldown: const Duration(minutes: 2), // sum 9 !=10
      );

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: invalidBudget);

      expect(plan.isValid, false);
      expect(plan.timeBudget.isValid, false);
      // No normalization
      expect(plan.timeBudget.warmup + plan.timeBudget.main + plan.timeBudget.cooldown,
          const Duration(minutes: 9));
    });
  });

  group('Estimated Duration', () {
    test('exact sum of section estimates no hidden inter-section transition', () {
      // Build known prescriptions
      // Warmup: 1 set x 10 reps = 30 sec work, no rest
      final warmupPres = validReps('warmup_A', sets: 1, reps: 10, rest: Duration.zero);
      // Main: 2 sets x 10 reps = 60 work, 30 rest =90
      final mainPres = validReps('main_C', sets: 2, reps: 10, rest: const Duration(seconds: 30));
      // Cooldown: 1 set x 20 sec timed =20 work
      final cooldownPres = validTimed('cooldown_E', sets: 1, work: const Duration(seconds: 20), rest: Duration.zero);

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupPres]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [mainPres]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownPres]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      final warmupEst = WorkoutTimeEstimator.estimateSection(warmup)!;
      final mainEst = WorkoutTimeEstimator.estimateSection(main)!;
      final cooldownEst = WorkoutTimeEstimator.estimateSection(cooldown)!;

      // No hidden inter-section transition, just sum
      expect(plan.estimatedDuration,
          warmupEst.total + mainEst.total + cooldownEst.total);

      // Verify individual: warmup 30, main 90, cooldown 20 = 140
      expect(warmupEst.total, const Duration(seconds: 30));
      expect(mainEst.total, const Duration(seconds: 90));
      expect(cooldownEst.total, const Duration(seconds: 20));
      expect(plan.estimatedDuration, const Duration(seconds: 140));
    });
  });

  group('Over Target', () {
    test('structurally valid but over budget remains valid', () {
      // Budget 5 min =300 sec
      // Create plan that estimates 600 sec
      final warmupPres = validTimed('w1', sets: 2, work: const Duration(seconds: 60), rest: const Duration(seconds: 60)); // work 120 rest 60 =180
      final mainPres = validTimed('m1', sets: 3, work: const Duration(seconds: 60), rest: const Duration(seconds: 60)); // work 180 rest 120=300
      final cooldownPres = validTimed('c1', sets: 2, work: const Duration(seconds: 60), rest: const Duration(seconds: 60)); // 180

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupPres]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [mainPres]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownPres]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes); // target 300

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan.isValid, true);
      expect(plan.estimatedDuration, isNotNull);
      expect(plan.estimatedDuration!.inSeconds, 660); // 180+300+180
      expect(plan.isOverTarget, true);
      expect(plan.isUnderTarget, false);
      expect(plan.differenceFromTarget! > Duration.zero, true);
    });
  });

  group('Under Target', () {
    test('valid plan under budget', () {
      final warmupPres = validReps('w1', sets: 1, reps: 5, rest: Duration.zero); // 15 sec
      final mainPres = validReps('m1', sets: 1, reps: 5, rest: Duration.zero); // 15
      final cooldownPres = validReps('c1', sets: 1, reps: 5, rest: Duration.zero); // 15

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupPres]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [mainPres]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownPres]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes); // 300 sec

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan.isValid, true);
      expect(plan.estimatedDuration, const Duration(seconds: 45));
      expect(plan.isUnderTarget, true);
      expect(plan.isOverTarget, false);
      expect(plan.differenceFromTarget! < Duration.zero, true);
      expect(plan.differenceFromTarget, const Duration(seconds: -255));
    });
  });

  group('Exact Target', () {
    test('exact target plan', () {
      // 5 min budget: warmup 1 min=60, main 3 min=180, cooldown 1 min=60
      final warmupPres = validTimed('w', sets: 1, work: const Duration(seconds: 60), rest: Duration.zero);
      final mainPres = validTimed('m', sets: 3, work: const Duration(seconds: 60), rest: Duration.zero); // 180
      final cooldownPres = validTimed('c', sets: 1, work: const Duration(seconds: 60), rest: Duration.zero);

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupPres]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [mainPres]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownPres]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan.isValid, true);
      expect(plan.estimatedDuration, const Duration(minutes: 5));
      expect(plan.differenceFromTarget, Duration.zero);
      expect(plan.isOverTarget, false);
      expect(plan.isUnderTarget, false);
    });
  });

  group('Ordered Flattening', () {
    test('A,B + C,D + E order and immutable', () {
      final a = validReps('A');
      final b = validReps('B');
      final c = validReps('C');
      final d = validReps('D');
      final e = validReps('E');

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [a, b]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [c, d]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [e]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan.allPrescriptions.map((p) => p.exercise.id).toList(),
          ['A', 'B', 'C', 'D', 'E']);
      expect(plan.allExercises.map((ex) => ex.id).toList(),
          ['A', 'B', 'C', 'D', 'E']);

      // Immutable
      expect(() => plan.allPrescriptions.add(a), throwsUnsupportedError);
      expect(() => plan.allExercises.add(a.exercise), throwsUnsupportedError);
    });
  });

  group('Factory', () {
    test('withWorkoutDuration uses fromWorkoutDuration and target matches', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      for (final duration in WorkoutDuration.values) {
        final plan = WorkoutPlan.withWorkoutDuration(
          workoutDuration: duration,
          warmup: warmup,
          main: main,
          cooldown: cooldown,
        );

        final expectedBudget =
            WorkoutTimeBudget.fromWorkoutDuration(duration);
        expect(plan.timeBudget, expectedBudget);
        expect(plan.targetDuration.inMinutes, duration.minutes);
      }
    });
  });

  group('Determinism', () {
    test('repeated reads equivalent', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.twentyMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      final est1 = plan.estimatedDuration;
      final est2 = plan.estimatedDuration;
      expect(est1, est2);

      final wEst1 = plan.warmupEstimate;
      final wEst2 = plan.warmupEstimate;
      expect(wEst1, wEst2);

      final flat1 = plan.allPrescriptions.map((p) => p.exercise.id).toList();
      final flat2 = plan.allPrescriptions.map((p) => p.exercise.id).toList();
      expect(flat1, flat2);

      final diff1 = plan.differenceFromTarget;
      final diff2 = plan.differenceFromTarget;
      expect(diff1, diff2);
    });
  });

  group('Duplicate Exercises allowed', () {
    test('duplicate IDs not invalid structurally', () {
      final ex = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [ex]);
      final main = WorkoutSection(
          type: WorkoutSectionType.main, exercises: [ex, ex]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [ex]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.fiveMinutes);

      final plan = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      // Should be valid despite duplicates
      expect(plan.isValid, true);
      expect(plan.totalExerciseCount, 4);
    });
  });

  group('Equality', () {
    test('equality uses warmup, main, cooldown, timeBudget', () {
      final warmupEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('march_in_place')!)!;
      final mainEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('pushup_wall')!)!;
      final cooldownEx = WorkoutExercisePrescription.fromExerciseDefaults(
          ExerciseCatalog.byId('childs_pose')!)!;

      final warmup = WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [warmupEx]);
      final main =
          WorkoutSection(type: WorkoutSectionType.main, exercises: [mainEx]);
      final cooldown = WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [cooldownEx]);

      final budget = WorkoutTimeBudget.fromWorkoutDuration(
          WorkoutDuration.tenMinutes);

      final plan1 = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);
      final plan2 = WorkoutPlan(
          warmup: warmup, main: main, cooldown: cooldown, timeBudget: budget);

      expect(plan1, plan2);
      expect(plan1.hashCode, plan2.hashCode);
    });
  });
}
