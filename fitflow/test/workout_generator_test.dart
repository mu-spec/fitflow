import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_limits.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers
  Exercise createTimedExercise({
    required String id,
    required MovementPattern movementPattern,
    Duration defaultDuration = const Duration(seconds: 30),
    Duration defaultRest = const Duration(seconds: 0),
    Set<String> tags = const {},
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
      difficulty: ExerciseDifficulty.level1,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      bodyPosition: ExercisePosition.standing,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: defaultDuration,
      defaultRest: defaultRest,
      tags: tags,
      active: true,
    );
  }

  Exercise createWarmup(String id,
          {Duration duration = const Duration(seconds: 30)}) =>
      createTimedExercise(
          id: id,
          movementPattern: MovementPattern.warmup,
          defaultDuration: duration);

  Exercise createCooldown(String id,
          {Duration duration = const Duration(seconds: 30)}) =>
      createTimedExercise(
          id: id,
          movementPattern: MovementPattern.cooldown,
          defaultDuration: duration);

  Exercise createMain(String id,
          {Duration duration = const Duration(seconds: 30),
          MovementPattern pattern = MovementPattern.push}) =>
      createTimedExercise(
          id: id, movementPattern: pattern, defaultDuration: duration);

  CapabilityProfile createFullProfile(CapabilityLevel level) {
    final now = DateTime.utc(2026, 1, 1);
    final map = <MovementPattern, MovementCapability>{};
    for (final p in CapabilityProfile.trainablePatterns) {
      map[p] = MovementCapability(
        movementPattern: p,
        level: level,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      );
    }
    return CapabilityProfile.fromMap(map);
  }

  UserFitnessProfile createUserProfile({
    FitnessGoal goal = FitnessGoal.generalFitness,
    TrainingEnvironment env = TrainingEnvironment.largeRoom,
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
    Set<WorkoutPreference> prefs = const {},
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: env,
      equipment: equipment,
      preferences: prefs,
    );
  }

  WorkoutGenerationContext createContext({
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
    TrainingEnvironment env = TrainingEnvironment.largeRoom,
    Set<WorkoutPreference> prefs = const {},
  }) {
    return WorkoutGenerationContext(
      userProfile: createUserProfile(duration: duration, env: env, prefs: prefs),
      capabilityProfile: createFullProfile(CapabilityLevel.level3),
    );
  }

  List<Exercise> richFixture() {
    // Provide enough candidates for all durations: warmup 3, main 8, cooldown 3
    final list = <Exercise>[];
    for (int i = 1; i <= 4; i++) {
      list.add(createWarmup('warmup_$i'));
    }
    for (int i = 1; i <= 10; i++) {
      // cycle patterns to avoid diversity logic interfering (though not implemented)
      final pattern = CapabilityProfile.trainablePatterns[i % CapabilityProfile.trainablePatterns.length];
      list.add(createMain('main_$i', pattern: pattern));
    }
    for (int i = 1; i <= 4; i++) {
      list.add(createCooldown('cooldown_$i'));
    }
    return list;
  }

  group('Count Policy', () {
    test('exact max-count table for every WorkoutDuration', () {
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.fiveMinutes),
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 2, cooldownMax: 1));
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.tenMinutes),
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 3, cooldownMax: 1));
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.fifteenMinutes),
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 4, cooldownMax: 1));
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
          const WorkoutGenerationLimits(warmupMax: 2, mainMax: 5, cooldownMax: 2));
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.thirtyMinutes),
          const WorkoutGenerationLimits(warmupMax: 2, mainMax: 6, cooldownMax: 2));
      expect(WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.fortyFiveMinutes),
          const WorkoutGenerationLimits(warmupMax: 3, mainMax: 8, cooldownMax: 3));
    });

    test('static const values match table', () {
      expect(WorkoutGenerationLimits.fiveMinutes,
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 2, cooldownMax: 1));
      expect(WorkoutGenerationLimits.tenMinutes,
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 3, cooldownMax: 1));
      expect(WorkoutGenerationLimits.fifteenMinutes,
          const WorkoutGenerationLimits(warmupMax: 1, mainMax: 4, cooldownMax: 1));
      expect(WorkoutGenerationLimits.twentyMinutes,
          const WorkoutGenerationLimits(warmupMax: 2, mainMax: 5, cooldownMax: 2));
      expect(WorkoutGenerationLimits.thirtyMinutes,
          const WorkoutGenerationLimits(warmupMax: 2, mainMax: 6, cooldownMax: 2));
      expect(WorkoutGenerationLimits.fortyFiveMinutes,
          const WorkoutGenerationLimits(warmupMax: 3, mainMax: 8, cooldownMax: 3));
    });
  });

  group('Successful Fixture Generation', () {
    test('rich fixture generates valid plan', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final plan = WorkoutGenerator.generate(exercises, context);

      expect(plan, isNotNull);
      expect(plan!.isValid, true);
      expect(plan.warmup.isEmpty, false);
      expect(plan.main.isEmpty, false);
      expect(plan.cooldown.isEmpty, false);
      expect(plan.warmup.type, WorkoutSectionType.warmup);
      expect(plan.main.type, WorkoutSectionType.main);
      expect(plan.cooldown.type, WorkoutSectionType.cooldown);

      for (final p in plan.allPrescriptions) {
        expect(p.isValid, true);
        expect(p.sets, 1);
      }
    });
  });

  group('Count Caps', () {
    test('with more candidates than allowed, counts <= max', () {
      final context = createContext(duration: WorkoutDuration.fiveMinutes);
      final limits = WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.fiveMinutes);
      final exercises = richFixture();

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);
      expect(plan!.warmup.exerciseCount <= limits.warmupMax, true);
      expect(plan.main.exerciseCount <= limits.mainMax, true);
      expect(plan.cooldown.exerciseCount <= limits.cooldownMax, true);
    });

    test('20 min caps respected', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final limits = WorkoutGenerationLimits.fromWorkoutDuration(WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);
      expect(plan!.warmup.exerciseCount <= limits.warmupMax, true);
      expect(plan.main.exerciseCount <= limits.mainMax, true);
      expect(plan.cooldown.exerciseCount <= limits.cooldownMax, true);
    });
  });

  group('Budget Caps', () {
    test('section estimates <= budgets', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);

      final warmupEst = plan!.warmupEstimate;
      final mainEst = plan.mainEstimate;
      final cooldownEst = plan.cooldownEstimate;

      expect(warmupEst, isNotNull);
      expect(mainEst, isNotNull);
      expect(cooldownEst, isNotNull);

      expect(warmupEst!.total <= plan.timeBudget.warmup, true);
      expect(mainEst!.total <= plan.timeBudget.main, true);
      expect(cooldownEst!.total <= plan.timeBudget.cooldown, true);
    });
  });

  group('Eligibility Invariant', () {
    test('every exercise in successful plan eligible', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();
      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);

      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
        userProfile: context.userProfile,
        capabilityProfile: context.capabilityProfile,
      );

      for (final pres in plan!.allPrescriptions) {
        final result = ExerciseEligibilityEngine.evaluate(pres.exercise, eligibilityContext);
        expect(result.eligible, true, reason: 'Exercise ${pres.exercise.id} should be eligible');
      }
    });
  });

  group('Candidate Pool Membership', () {
    test('warmup IDs from warmup pool, main from main, cooldown from cooldown', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final candidates = WorkoutCandidateResolver.resolve(exercises, context);
      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);

      final warmupPoolIds = candidates.warmup.map((r) => r.exercise.id).toSet();
      final mainPoolIds = candidates.main.map((r) => r.exercise.id).toSet();
      final cooldownPoolIds = candidates.cooldown.map((r) => r.exercise.id).toSet();

      for (final pres in plan!.warmup.exercises) {
        expect(warmupPoolIds.contains(pres.exercise.id), true);
        expect(mainPoolIds.contains(pres.exercise.id), false);
        expect(cooldownPoolIds.contains(pres.exercise.id), false);
      }
      for (final pres in plan.main.exercises) {
        expect(mainPoolIds.contains(pres.exercise.id), true);
      }
      for (final pres in plan.cooldown.exercises) {
        expect(cooldownPoolIds.contains(pres.exercise.id), true);
      }
    });
  });

  group('Empty Required Section', () {
    test('no usable warmup -> null', () {
      final context = createContext();
      final exercises = <Exercise>[
        createMain('main_1'),
        createMain('main_2'),
        createCooldown('cooldown_1'),
      ];

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNull);
    });

    test('no usable main -> null', () {
      final context = createContext();
      final exercises = <Exercise>[
        createWarmup('warmup_1'),
        createCooldown('cooldown_1'),
      ];

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNull);
    });

    test('no usable cooldown -> null', () {
      final context = createContext();
      final exercises = <Exercise>[
        createWarmup('warmup_1'),
        createMain('main_1'),
      ];

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNull);
    });
  });

  group('Candidate Exists But Cannot Fit', () {
    test('warmup candidate exceeds warmup budget -> null', () {
      // 5 min workout warmup budget = 1 min = 60 sec
      final context = createContext(duration: WorkoutDuration.fiveMinutes);
      // Warmup 120 sec exceeds 60 sec budget
      final exercises = <Exercise>[
        createWarmup('warmup_big', duration: const Duration(seconds: 120)),
        createMain('main_1'),
        createCooldown('cooldown_1'),
      ];

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNull);
    });
  });

  group('Missing Defaults', () {
    test('all candidates for one section missing defaults -> null', () {
      final context = createContext();
      // Create warmup with missing defaults (reps exercise with no reps)
      final missingWarmup = Exercise(
        id: 'warmup_missing',
        name: 'warmup_missing',
        movementPattern: MovementPattern.warmup,
        difficulty: ExerciseDifficulty.level1,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        bodyPosition: ExercisePosition.standing,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        requiredEquipment: {WorkoutEquipment.none},
        exerciseType: ExerciseType.reps,
        defaultReps: null, // missing
        defaultRest: const Duration(seconds: 30),
        active: true,
      );

      final exercises = <Exercise>[
        missingWarmup,
        createMain('main_1'),
        createCooldown('cooldown_1'),
      ];

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNull);
    });
  });

  group('Empty Input', () {
    test('generate([], context) returns null no crash', () {
      final context = createContext();
      final plan = WorkoutGenerator.generate([], context);
      expect(plan, isNull);
    });
  });

  group('Real Catalog', () {
    test('generateCatalog with permissive context', () {
      // Permissive: largeRoom, level3, no restrictive prefs, generalFitness, 20 min
      final context = createContext(
        duration: WorkoutDuration.twentyMinutes,
        env: TrainingEnvironment.largeRoom,
      );

      final plan = WorkoutGenerator.generateCatalog(context);

      expect(plan, isNotNull, reason: 'Real catalog should produce plan in permissive context');
      expect(plan!.isValid, true);
      expect(plan.warmup.isEmpty, false);
      expect(plan.main.isEmpty, false);
      expect(plan.cooldown.isEmpty, false);

      // All eligible
      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
        userProfile: context.userProfile,
        capabilityProfile: context.capabilityProfile,
      );
      for (final pres in plan.allPrescriptions) {
        final result = ExerciseEligibilityEngine.evaluate(pres.exercise, eligibilityContext);
        expect(result.eligible, true);
        expect(pres.sets, 1);
      }

      // Budgets respected
      expect(plan.warmupEstimate!.total <= plan.timeBudget.warmup, true);
      expect(plan.mainEstimate!.total <= plan.timeBudget.main, true);
      expect(plan.cooldownEstimate!.total <= plan.timeBudget.cooldown, true);
    });
  });

  group('Restrictive Profile Failure Is Safe', () {
    test('very restrictive profile returns null cleanly', () {
      // Apartment, no equipment, NoJumping, LowImpact, StandingOnly, NoFloor, Avoid Wrist/Knee
      // This may leave no cooldown or main candidates
      final restrictivePrefs = {
        WorkoutPreference.noJumping,
        WorkoutPreference.lowImpact,
        WorkoutPreference.standingOnly,
        WorkoutPreference.noFloorExercises,
        WorkoutPreference.avoidWristHeavy,
        WorkoutPreference.avoidDeepKneeBending,
      };
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.generalFitness,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.fiveMinutes,
          environment: TrainingEnvironment.apartment,
          equipment: {WorkoutEquipment.none},
          preferences: restrictivePrefs,
        ),
        capabilityProfile: createFullProfile(CapabilityLevel.level1),
      );

      // Use real catalog to ensure restriction actually hits
      final plan = WorkoutGenerator.generateCatalog(context);
      // Could be null or non-null, but must not crash and if non-null must be valid
      // For this test we force expectation null by using tiny fixture that will be filtered
      // Let's also test with empty pools scenario via restrictive + catalog that likely fails cooldown
      // If plan is null, it's acceptable safe failure
      if (plan == null) {
        expect(plan, isNull);
      } else {
        // If by chance it still produces, ensure it's valid and eligible (not a failure)
        expect(plan.isValid, true);
      }

      // More deterministic restrictive failure: use fixture that only has floor exercises but standingOnly required
      final floorOnlyExercises = <Exercise>[
        Exercise(
          id: 'floor_warmup',
          name: 'floor_warmup',
          movementPattern: MovementPattern.warmup,
          difficulty: ExerciseDifficulty.level1,
          impactLevel: ImpactLevel.low,
          noiseLevel: NoiseLevel.quiet,
          spaceRequirement: SpaceRequirement.small,
          bodyPosition: ExercisePosition.floor, // will be rejected by standingOnly
          wristLoad: JointLoad.none,
          kneeLoad: JointLoad.none,
          requiredEquipment: {WorkoutEquipment.none},
          exerciseType: ExerciseType.timed,
          defaultDuration: const Duration(seconds: 30),
          defaultRest: Duration.zero,
          active: true,
        ),
        Exercise(
          id: 'floor_main',
          name: 'floor_main',
          movementPattern: MovementPattern.push,
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
          defaultRest: Duration.zero,
          active: true,
        ),
        Exercise(
          id: 'floor_cooldown',
          name: 'floor_cooldown',
          movementPattern: MovementPattern.cooldown,
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
          defaultRest: Duration.zero,
          active: true,
        ),
      ];

      final restrictiveContext = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.generalFitness,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.twentyMinutes,
          environment: TrainingEnvironment.largeRoom,
          equipment: {WorkoutEquipment.none},
          preferences: {WorkoutPreference.standingOnly},
        ),
        capabilityProfile: createFullProfile(CapabilityLevel.level3),
      );

      final restrictivePlan = WorkoutGenerator.generate(floorOnlyExercises, restrictiveContext);
      expect(restrictivePlan, isNull, reason: 'StandingOnly with only floor exercises should return null safely');
    });
  });

  group('All Workout Durations', () {
    test('generate for all six durations with rich fixture', () {
      final durations = [
        WorkoutDuration.fiveMinutes,
        WorkoutDuration.tenMinutes,
        WorkoutDuration.fifteenMinutes,
        WorkoutDuration.twentyMinutes,
        WorkoutDuration.thirtyMinutes,
        WorkoutDuration.fortyFiveMinutes,
      ];

      for (final dur in durations) {
        final context = createContext(duration: dur);
        final exercises = richFixture();

        final plan = WorkoutGenerator.generate(exercises, context);
        expect(plan, isNotNull, reason: 'Should generate for $dur with rich fixture');
        expect(plan!.isValid, true, reason: 'Plan for $dur should be valid');

        final limits = WorkoutGenerationLimits.fromWorkoutDuration(dur);
        expect(plan.warmup.exerciseCount <= limits.warmupMax, true, reason: 'Warmup cap for $dur');
        expect(plan.main.exerciseCount <= limits.mainMax, true, reason: 'Main cap for $dur');
        expect(plan.cooldown.exerciseCount <= limits.cooldownMax, true, reason: 'Cooldown cap for $dur');

        expect(plan.warmupEstimate!.total <= plan.timeBudget.warmup, true, reason: 'Warmup budget for $dur');
        expect(plan.mainEstimate!.total <= plan.timeBudget.main, true, reason: 'Main budget for $dur');
        expect(plan.cooldownEstimate!.total <= plan.timeBudget.cooldown, true, reason: 'Cooldown budget for $dur');

        // Under-target is acceptable, but ensure not over target by too much? Actually sections budgets sum to target, so if each <= budget, total <= target
        // We do not require exact target
        for (final pres in plan.allPrescriptions) {
          expect(pres.sets, 1);
        }
      }
    });
  });

  group('Determinism', () {
    test('same input/context twice identical', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final first = WorkoutGenerator.generate(exercises, context);
      final second = WorkoutGenerator.generate(exercises, context);

      expect(first, isNotNull);
      expect(second, isNotNull);
      final firstPlan = first!;
      final secondPlan = second!;

      expect(firstPlan.warmup.exercises.map((p) => p.exercise.id).toList(),
          secondPlan.warmup.exercises.map((p) => p.exercise.id).toList());
      expect(firstPlan.main.exercises.map((p) => p.exercise.id).toList(),
          secondPlan.main.exercises.map((p) => p.exercise.id).toList());
      expect(firstPlan.cooldown.exercises.map((p) => p.exercise.id).toList(),
          secondPlan.cooldown.exercises.map((p) => p.exercise.id).toList());

      final est1 = WorkoutTimeEstimator.estimateSection(firstPlan.warmup);
      final est2 = WorkoutTimeEstimator.estimateSection(secondPlan.warmup);
      expect(est1, est2);

      expect(firstPlan.estimatedDuration, secondPlan.estimatedDuration);
    });
  });

  group('Immutability', () {
    test('source exercise list unchanged', () {
      final context = createContext();
      final exercises = richFixture();
      final originalIds = exercises.map((e) => e.id).toList();

      WorkoutGenerator.generate(exercises, context);

      expect(exercises.map((e) => e.id).toList(), originalIds);
    });

    test('modify caller-owned source after generation plan unchanged', () {
      final context = createContext();
      final exercises = richFixture();

      final plan = WorkoutGenerator.generate(exercises, context);
      expect(plan, isNotNull);
      final countBefore = plan!.totalExerciseCount;

      exercises.clear();
      exercises.add(createMain('new_main'));

      expect(plan.totalExerciseCount, countBefore);
    });
  });

  group('Convenience API', () {
    test('generateCatalog equivalent to generate(ExerciseCatalog.all, context)', () {
      final context = createContext(duration: WorkoutDuration.twentyMinutes);

      final fromCatalog = WorkoutGenerator.generateCatalog(context);
      final fromAll = WorkoutGenerator.generate(ExerciseCatalog.all, context);

      if (fromCatalog == null || fromAll == null) {
        expect(fromCatalog, fromAll, reason: 'Both should be null or both non-null');
      } else {
        expect(fromCatalog.warmup.exercises.map((p) => p.exercise.id).toList(),
            fromAll.warmup.exercises.map((p) => p.exercise.id).toList());
        expect(fromCatalog.main.exercises.map((p) => p.exercise.id).toList(),
            fromAll.main.exercises.map((p) => p.exercise.id).toList());
        expect(fromCatalog.cooldown.exercises.map((p) => p.exercise.id).toList(),
            fromAll.cooldown.exercises.map((p) => p.exercise.id).toList());
        expect(fromCatalog.estimatedDuration, fromAll.estimatedDuration);
      }
    });
  });
}
