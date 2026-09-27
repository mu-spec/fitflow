import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_section_builder.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createRepsExercise({
    required String id,
    int? defaultReps = 10,
    Duration? defaultRest = const Duration(seconds: 30),
    MovementPattern? movementPattern = MovementPattern.push,
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
      exerciseType: ExerciseType.reps,
      defaultReps: defaultReps,
      defaultRest: defaultRest,
      active: true,
    );
  }

  Exercise createTimedExercise({
    required String id,
    Duration? defaultDuration = const Duration(seconds: 30),
    Duration? defaultRest = const Duration(seconds: 30),
    MovementPattern? movementPattern = MovementPattern.core,
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
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

  ExerciseRankingResult rankingResult(Exercise ex,
      {int capabilityFit = 100, int goalAffinity = 0}) {
    return ExerciseRankingResult(
      exercise: ex,
      capabilityFitScore: capabilityFit,
      goalAffinityScore: goalAffinity,
      totalScore: capabilityFit + goalAffinity,
    );
  }

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
    TrainingEnvironment env = TrainingEnvironment.normalHome,
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: env,
      equipment: {WorkoutEquipment.none},
      preferences: {},
    );
  }

  group('Invalid Builder Inputs', () {
    test('negative budget -> null', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
      ];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: -1),
        maxExercises: 3,
      );
      expect(result, isNull);
    });

    test('negative maxExercises -> null', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
      ];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: -1,
      );
      expect(result, isNull);
    });

    test('no crash on invalid inputs', () {
      expect(
          () => WorkoutSectionBuilder.build(
                type: WorkoutSectionType.main,
                candidates: [],
                budget: const Duration(seconds: -10),
                maxExercises: -5,
              ),
          returnsNormally);
    });
  });

  group('Valid Empty Cases', () {
    test('budget zero -> empty section', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
      ];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: Duration.zero,
        maxExercises: 3,
      );
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
      expect(result.type, WorkoutSectionType.main);
    });

    test('maxExercises zero -> empty section', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
      ];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.warmup,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 0,
      );
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
      expect(result.type, WorkoutSectionType.warmup);
    });

    test('empty candidates -> empty section', () {
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.cooldown,
        candidates: [],
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });

    test('no candidate can produce valid prescription -> empty', () {
      final missingReps = createRepsExercise(id: 'missing', defaultReps: null);
      final candidates = [
        rankingResult(missingReps),
      ];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });

    test('no candidate fits budget -> empty', () {
      final long = createTimedExercise(
          id: 'long', defaultDuration: const Duration(minutes: 10));
      final candidates = [rankingResult(long)];
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 30),
        maxExercises: 3,
      );
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });
  });

  group('Simple Ranked Selection', () {
    test('three candidates, large budget, max 3 -> all selected same order, 1 set each', () {
      final exA = createRepsExercise(id: 'A');
      final exB = createRepsExercise(id: 'B');
      final exC = createRepsExercise(id: 'C');

      final candidates = [
        rankingResult(exA, capabilityFit: 100),
        rankingResult(exB, capabilityFit: 80),
        rankingResult(exC, capabilityFit: 60),
      ];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 10),
        maxExercises: 3,
      );

      expect(result, isNotNull);
      expect(result!.exerciseCount, 3);
      expect(result.exercises[0].exercise.id, 'A');
      expect(result.exercises[1].exercise.id, 'B');
      expect(result.exercises[2].exercise.id, 'C');
      for (final pres in result.exercises) {
        expect(pres.sets, 1);
      }
    });
  });

  group('maxExercises', () {
    test('A,B,C large budget max 2 -> A,B selected', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'A')),
        rankingResult(createRepsExercise(id: 'B')),
        rankingResult(createRepsExercise(id: 'C')),
      ];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 10),
        maxExercises: 2,
      );

      expect(result!.exerciseCount, 2);
      expect(result.exercises[0].exercise.id, 'A');
      expect(result.exercises[1].exercise.id, 'B');
    });
  });

  group('Budget Includes Transition', () {
    test('A=30s B=30s budget 70s -> only A, budget 75s -> both', () {
      final exA = createTimedExercise(
          id: 'A', defaultDuration: const Duration(seconds: 30));
      final exB = createTimedExercise(
          id: 'B', defaultDuration: const Duration(seconds: 30));

      final candidates = [
        rankingResult(exA),
        rankingResult(exB),
      ];

      final result70 = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 70),
        maxExercises: 3,
      );

      expect(result70!.exerciseCount, 1);
      expect(result70.exercises[0].exercise.id, 'A');

      final result75 = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 75),
        maxExercises: 3,
      );

      expect(result75!.exerciseCount, 2);
      // Together 30 +15 +30 =75
      final estimate = WorkoutTimeEstimator.estimateSection(result75);
      expect(estimate!.total, const Duration(seconds: 75));
    });
  });

  group('Continue After Non-Fitting', () {
    test('A=30s B=60s C=20s budget 70s -> A,C', () {
      final exA = createTimedExercise(
          id: 'A', defaultDuration: const Duration(seconds: 30));
      final exB = createTimedExercise(
          id: 'B', defaultDuration: const Duration(seconds: 60));
      final exC = createTimedExercise(
          id: 'C', defaultDuration: const Duration(seconds: 20));

      final candidates = [
        rankingResult(exA),
        rankingResult(exB),
        rankingResult(exC),
      ];

      // A alone 30 fits
      // A+B =30+60+15=105 does NOT fit 70
      // A+C =30+20+15=65 DOES fit 70
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 70),
        maxExercises: 3,
      );

      expect(result!.exerciseCount, 2);
      expect(result.exercises[0].exercise.id, 'A');
      expect(result.exercises[1].exercise.id, 'C');
    });
  });

  group('Missing Defaults', () {
    test('A missing defaults skipped, B valid selected', () {
      final missing = createRepsExercise(id: 'missing', defaultReps: null);
      final valid = createRepsExercise(id: 'valid');

      final candidates = [
        rankingResult(missing),
        rankingResult(valid),
      ];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(result!.exerciseCount, 1);
      expect(result.exercises[0].exercise.id, 'valid');
    });

    test('no fabricated prescription', () {
      final missing = createRepsExercise(id: 'missing', defaultReps: null);
      final candidates = [rankingResult(missing)];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(result!.isEmpty, true);
    });
  });

  group('Explicit Zero Rest', () {
    test('explicit zero rest valid and selectable', () {
      final zeroRest = createRepsExercise(
          id: 'zero_rest', defaultRest: Duration.zero);
      final candidates = [rankingResult(zeroRest)];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(result!.exerciseCount, 1);
      expect(result.exercises[0].restBetweenSets, Duration.zero);
      expect(result.exercises[0].isValid, true);
    });
  });

  group('Duplicate Candidate ID', () {
    test('same ID more than once -> at most once selected', () {
      final ex = createRepsExercise(id: 'dup');
      final candidates = [
        rankingResult(ex),
        rankingResult(createRepsExercise(id: 'other')),
        rankingResult(ex), // duplicate
        rankingResult(createRepsExercise(id: 'another')),
      ];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 10),
        maxExercises: 10,
      );

      final ids = result!.exercises.map((p) => p.exercise.id).toList();
      expect(ids.where((id) => id == 'dup').length, 1);
      expect(ids.toSet().length, ids.length);
    });
  });

  group('Exact Fit', () {
    test('estimate equals budget exactly accepted', () {
      final exA = createTimedExercise(
          id: 'A', defaultDuration: const Duration(seconds: 30));
      final exB = createTimedExercise(
          id: 'B', defaultDuration: const Duration(seconds: 30));

      final candidates = [
        rankingResult(exA),
        rankingResult(exB),
      ];

      // 30+15+30=75 exact
      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 75),
        maxExercises: 3,
      );

      expect(result!.exerciseCount, 2);
      final est = WorkoutTimeEstimator.estimateSection(result);
      expect(est!.total, const Duration(seconds: 75));
    });
  });

  group('Section Types', () {
    test('builder preserves requested type', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
      ];

      final warmup = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.warmup,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );
      final main = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );
      final cooldown = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.cooldown,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(warmup!.type, WorkoutSectionType.warmup);
      expect(main!.type, WorkoutSectionType.main);
      expect(cooldown!.type, WorkoutSectionType.cooldown);
    });

    test('builder does not reclassify candidates', () {
      // Candidate with warmup tag but requested as main should still be built as main
      final warmupTagged = Exercise(
        id: 'warmup_tagged',
        name: 'warmup_tagged',
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
        tags: {'warmup'},
        active: true,
      );

      final candidates = [rankingResult(warmupTagged)];

      final result = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(result!.type, WorkoutSectionType.main);
      expect(result.exerciseCount, 1);
    });
  });

  group('Budget Invariant', () {
    test('estimate.total <= budget for multiple builds', () {
      final candidates = [
        rankingResult(createTimedExercise(id: 'a', defaultDuration: const Duration(seconds: 20))),
        rankingResult(createTimedExercise(id: 'b', defaultDuration: const Duration(seconds: 30))),
        rankingResult(createTimedExercise(id: 'c', defaultDuration: const Duration(seconds: 40))),
      ];

      final budgets = [
        const Duration(seconds: 50),
        const Duration(seconds: 70),
        const Duration(seconds: 100),
        const Duration(minutes: 5),
      ];

      for (final budget in budgets) {
        final section = WorkoutSectionBuilder.build(
          type: WorkoutSectionType.main,
          candidates: candidates,
          budget: budget,
          maxExercises: 5,
        );
        expect(section, isNotNull);
        final estimate = WorkoutTimeEstimator.estimateSection(section!);
        if (estimate != null) {
          expect(estimate.total <= budget, true,
              reason: 'Budget $budget estimate ${estimate.total} should be <= budget');
        }
      }
    });
  });

  group('Input Immutability', () {
    test('candidate source list not modified', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
        rankingResult(createRepsExercise(id: 'b')),
      ];
      final originalIds = candidates.map((r) => r.exercise.id).toList();

      WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      expect(candidates.map((r) => r.exercise.id).toList(), originalIds);
    });

    test('source modified after build does not affect section', () {
      final candidates = [
        rankingResult(createRepsExercise(id: 'a')),
        rankingResult(createRepsExercise(id: 'b')),
      ];

      final section = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(minutes: 5),
        maxExercises: 3,
      );

      final countBefore = section!.exerciseCount;

      candidates.add(rankingResult(createRepsExercise(id: 'c')));
      candidates.clear();

      expect(section.exerciseCount, countBefore);
    });
  });

  group('Determinism', () {
    test('same build twice identical', () {
      final candidates = [
        rankingResult(createTimedExercise(id: 'a', defaultDuration: const Duration(seconds: 30))),
        rankingResult(createTimedExercise(id: 'b', defaultDuration: const Duration(seconds: 20))),
        rankingResult(createTimedExercise(id: 'c', defaultDuration: const Duration(seconds: 40))),
      ];

      final first = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 80),
        maxExercises: 3,
      );

      final second = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates,
        budget: const Duration(seconds: 80),
        maxExercises: 3,
      );

      expect(first!.exercises.map((p) => p.exercise.id).toList(),
          second!.exercises.map((p) => p.exercise.id).toList());

      final est1 = WorkoutTimeEstimator.estimateSection(first);
      final est2 = WorkoutTimeEstimator.estimateSection(second);
      expect(est1, est2);
    });
  });

  group('Real Candidate Pool Integration', () {
    test('main pool from catalog with reasonable budget and max 3', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile(
        goal: FitnessGoal.generalFitness,
        env: TrainingEnvironment.largeRoom,
        duration: WorkoutDuration.twentyMinutes,
      );

      final generationContext = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final candidates = WorkoutCandidateResolver.resolveCatalog(generationContext);
      expect(candidates.main, isNotEmpty, reason: 'Main pool should have candidates in permissive context');

      final budget = generationContext.timeBudget.main; // e.g., 14 min for 20 min

      final section = WorkoutSectionBuilder.build(
        type: WorkoutSectionType.main,
        candidates: candidates.main,
        budget: budget,
        maxExercises: 3,
      );

      expect(section, isNotNull);
      expect(section!.type, WorkoutSectionType.main);
      expect(section.exerciseCount <= 3, true);
      for (final pres in section.exercises) {
        expect(pres.isValid, true);
        expect(pres.sets, 1);
      }

      // IDs follow pool-relative order
      final poolIds = candidates.main.map((r) => r.exercise.id).toList();
      final selectedIds = section.exercises.map((p) => p.exercise.id).toList();
      List<String> filteredPoolOrder() {
        return poolIds.where((id) => selectedIds.contains(id)).toList();
      }
      expect(selectedIds, filteredPoolOrder());

      // Estimated total <= budget
      final estimate = WorkoutTimeEstimator.estimateSection(section);
      expect(estimate, isNotNull);
      expect(estimate!.total <= budget, true);
    });
  });
}
