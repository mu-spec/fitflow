import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_diversifier.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_limits.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_volume_filler.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTimed({
    required String id,
    required MovementPattern pattern,
    Duration duration = const Duration(seconds: 30),
    Duration rest = const Duration(seconds: 0),
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: pattern,
      difficulty: ExerciseDifficulty.level1,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      bodyPosition: ExercisePosition.standing,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: duration,
      defaultRest: rest,
      active: true,
    );
  }

  WorkoutExercisePrescription prescriptionFromExercise(Exercise ex, {int sets = 1}) {
    final p = WorkoutExercisePrescription.fromExerciseDefaults(ex, sets: sets);
    if (p == null) throw StateError('Failed to create prescription for ${ex.id}');
    return p;
  }

  ExerciseRankingResult rank(Exercise ex, {int cap = 100, int goal = 0}) {
    return ExerciseRankingResult(
      exercise: ex,
      capabilityFitScore: cap,
      goalAffinityScore: goal,
      totalScore: cap + goal,
    );
  }

  CapabilityProfile fullProfile(CapabilityLevel level) {
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

  UserFitnessProfile userProfile({
    FitnessGoal goal = FitnessGoal.generalFitness,
    TrainingEnvironment env = TrainingEnvironment.largeRoom,
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
    Set<WorkoutPreference> prefs = const {},
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: env,
      equipment: {WorkoutEquipment.none},
      preferences: prefs,
    );
  }

  WorkoutGenerationContext ctx({
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
    FitnessGoal goal = FitnessGoal.generalFitness,
    TrainingEnvironment env = TrainingEnvironment.largeRoom,
    Set<WorkoutPreference> prefs = const {},
  }) {
    return WorkoutGenerationContext(
      userProfile: userProfile(duration: duration, goal: goal, env: env, prefs: prefs),
      capabilityProfile: fullProfile(CapabilityLevel.level3),
    );
  }

  List<Exercise> richFixture() {
    final list = <Exercise>[];
    for (int i = 1; i <= 4; i++) {
      list.add(createTimed(id: 'warmup_$i', pattern: MovementPattern.warmup, duration: const Duration(seconds: 20)));
    }
    final patterns = [
      MovementPattern.push,
      MovementPattern.pull,
      MovementPattern.squat,
      MovementPattern.lunge,
      MovementPattern.hinge,
      MovementPattern.core,
      MovementPattern.glute,
      MovementPattern.cardio,
    ];
    for (final pat in patterns) {
      list.add(createTimed(id: 'main_${pat.name}_1', pattern: pat, duration: const Duration(seconds: 20)));
      list.add(createTimed(id: 'main_${pat.name}_2', pattern: pat, duration: const Duration(seconds: 20)));
    }
    for (int i = 1; i <= 4; i++) {
      list.add(createTimed(id: 'cooldown_$i', pattern: MovementPattern.cooldown, duration: const Duration(seconds: 20)));
    }
    return list;
  }

  group('Main Diversity', () {
    test('prioritizes unique movement patterns first', () {
      final pushA = createTimed(id: 'pushA', pattern: MovementPattern.push);
      final pushB = createTimed(id: 'pushB', pattern: MovementPattern.push);
      final squatA = createTimed(id: 'squatA', pattern: MovementPattern.squat);
      final coreA = createTimed(id: 'coreA', pattern: MovementPattern.core);

      final candidates = [
        rank(pushA, cap: 100),
        rank(pushB, cap: 90),
        rank(squatA, cap: 80),
        rank(coreA, cap: 70),
      ];

      final diversified = WorkoutCandidateDiversifier.diversifyMain(candidates);
      expect(diversified.map((r) => r.exercise.id).toList(), ['pushA', 'squatA', 'coreA', 'pushB']);
    });

    test('example from spec', () {
      final pushA = createTimed(id: 'pushA', pattern: MovementPattern.push);
      final pushB = createTimed(id: 'pushB', pattern: MovementPattern.push);
      final squatA = createTimed(id: 'squatA', pattern: MovementPattern.squat);
      final pushC = createTimed(id: 'pushC', pattern: MovementPattern.push);
      final coreA = createTimed(id: 'coreA', pattern: MovementPattern.core);
      final squatB = createTimed(id: 'squatB', pattern: MovementPattern.squat);

      final candidates = [
        rank(pushA),
        rank(pushB),
        rank(squatA),
        rank(pushC),
        rank(coreA),
        rank(squatB),
      ];

      final diversified = WorkoutCandidateDiversifier.diversifyMain(candidates);
      expect(diversified.map((r) => r.exercise.id).toList(),
          ['pushA', 'squatA', 'coreA', 'pushB', 'pushC', 'squatB']);
    });

    test('determinism same input twice same diversified IDs', () {
      final candidates = [
        rank(createTimed(id: 'push1', pattern: MovementPattern.push)),
        rank(createTimed(id: 'push2', pattern: MovementPattern.push)),
        rank(createTimed(id: 'squat1', pattern: MovementPattern.squat)),
        rank(createTimed(id: 'core1', pattern: MovementPattern.core)),
      ];

      final first = WorkoutCandidateDiversifier.diversifyMain(candidates);
      final second = WorkoutCandidateDiversifier.diversifyMain(candidates);
      expect(first.map((r) => r.exercise.id).toList(),
          second.map((r) => r.exercise.id).toList());
    });

    test('single pattern still works, order preserved', () {
      final candidates = [
        rank(createTimed(id: 'push1', pattern: MovementPattern.push)),
        rank(createTimed(id: 'push2', pattern: MovementPattern.push)),
        rank(createTimed(id: 'push3', pattern: MovementPattern.push)),
      ];

      final diversified = WorkoutCandidateDiversifier.diversifyMain(candidates);
      expect(diversified.map((r) => r.exercise.id).toList(), ['push1', 'push2', 'push3']);
    });

    test('ranking scores untouched after diversity', () {
      final exA = createTimed(id: 'pushA', pattern: MovementPattern.push);
      final exB = createTimed(id: 'squatA', pattern: MovementPattern.squat);

      final candidates = [
        rank(exA, cap: 95, goal: 5),
        rank(exB, cap: 80, goal: 10),
      ];

      final diversified = WorkoutCandidateDiversifier.diversifyMain(candidates);
      expect(diversified[0].capabilityFitScore, 95);
      expect(diversified[0].goalAffinityScore, 5);
      expect(diversified[0].totalScore, 100);
      expect(diversified[1].capabilityFitScore, 80);
      expect(diversified[1].goalAffinityScore, 10);
      expect(diversified[1].totalScore, 90);
    });

    test('main section diversity integration via generator', () {
      final candidates = [
        createTimed(id: 'pushA', pattern: MovementPattern.push, duration: const Duration(seconds: 20)),
        createTimed(id: 'pushB', pattern: MovementPattern.push, duration: const Duration(seconds: 20)),
        createTimed(id: 'squatA', pattern: MovementPattern.squat, duration: const Duration(seconds: 20)),
        createTimed(id: 'coreA', pattern: MovementPattern.core, duration: const Duration(seconds: 20)),
        createTimed(id: 'pullA', pattern: MovementPattern.pull, duration: const Duration(seconds: 20)),
        createTimed(id: 'hingeA', pattern: MovementPattern.hinge, duration: const Duration(seconds: 20)),
      ];

      final allExercises = <Exercise>[
        createTimed(id: 'warmup_1', pattern: MovementPattern.warmup),
        createTimed(id: 'warmup_2', pattern: MovementPattern.warmup),
        createTimed(id: 'cooldown_1', pattern: MovementPattern.cooldown),
        createTimed(id: 'cooldown_2', pattern: MovementPattern.cooldown),
        ...candidates,
      ];

      final context = ctx(duration: WorkoutDuration.twentyMinutes);
      final plan = WorkoutGenerator.generate(allExercises, context);
      expect(plan, isNotNull);
      final mainPatterns = plan!.main.exercises.map((p) => p.exercise.movementPattern).toSet();
      expect(mainPatterns.length >= 3, true,
          reason: 'Should have at least 3 different patterns, got $mainPatterns');
    });
  });

  group('Volume Filling', () {
    test('main volume filling increases sets', () {
      final exA = createTimed(id: 'mainA', pattern: MovementPattern.push, duration: const Duration(seconds: 30));
      final exB = createTimed(id: 'mainB', pattern: MovementPattern.squat, duration: const Duration(seconds: 30));
      final exC = createTimed(id: 'mainC', pattern: MovementPattern.core, duration: const Duration(seconds: 30));

      final exercises = <Exercise>[
        createTimed(id: 'warmup_1', pattern: MovementPattern.warmup, duration: const Duration(seconds: 20)),
        createTimed(id: 'cooldown_1', pattern: MovementPattern.cooldown, duration: const Duration(seconds: 20)),
        exA,
        exB,
        exC,
      ];

      final plan = WorkoutGenerator.generate(exercises, ctx(duration: WorkoutDuration.thirtyMinutes));
      expect(plan, isNotNull);
      final mainSets = plan!.main.exercises.map((p) => p.sets).toList();
      expect(mainSets.any((s) => s > 1), true, reason: 'Sets should increase from 1, got $mainSets');
      for (final s in mainSets) {
        expect(s <= 4, true);
      }
      expect(plan.mainEstimate!.total <= plan.timeBudget.main, true);
    });

    test('warmup/cooldown volume caps 2', () {
      final exercises = <Exercise>[
        createTimed(id: 'warmup_1', pattern: MovementPattern.warmup, duration: const Duration(seconds: 20)),
        createTimed(id: 'warmup_2', pattern: MovementPattern.warmup, duration: const Duration(seconds: 20)),
        createTimed(id: 'main_1', pattern: MovementPattern.push, duration: const Duration(seconds: 20)),
        createTimed(id: 'main_2', pattern: MovementPattern.squat, duration: const Duration(seconds: 20)),
        createTimed(id: 'cooldown_1', pattern: MovementPattern.cooldown, duration: const Duration(seconds: 20)),
        createTimed(id: 'cooldown_2', pattern: MovementPattern.cooldown, duration: const Duration(seconds: 20)),
      ];

      final plan = WorkoutGenerator.generate(exercises, ctx(duration: WorkoutDuration.fortyFiveMinutes));
      expect(plan, isNotNull);
      for (final p in plan!.warmup.exercises) {
        expect(p.sets <= 2, true);
      }
      for (final p in plan.cooldown.exercises) {
        expect(p.sets <= 2, true);
      }
    });

    test('round-robin balanced progression', () {
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 30));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 30));
      final exC = createTimed(id: 'C', pattern: MovementPattern.core, duration: const Duration(seconds: 30));

      final exercises = <Exercise>[
        createTimed(id: 'warmup_1', pattern: MovementPattern.warmup, duration: const Duration(seconds: 20)),
        createTimed(id: 'cooldown_1', pattern: MovementPattern.cooldown, duration: const Duration(seconds: 20)),
        exA,
        exB,
        exC,
      ];

      final largeContext = ctx(duration: WorkoutDuration.fortyFiveMinutes);
      final largePlan = WorkoutGenerator.generate(exercises, largeContext);
      expect(largePlan, isNotNull);
      final sets = largePlan!.main.exercises.map((p) => p.sets).toList();
      // With huge budget 35 min main =2100 sec, 3*30=90 work +30 trans =120 initial, can go to 4 each = 3*120=360+30=390 well within budget
      expect(sets.every((s) => s == 4), true, reason: 'All should reach cap 4 with huge budget, got $sets');
    });

    test('candidate too expensive for increment but others can', () {
      // A 40 sec, B 20 sec, budget 100 sec
      // Initial 40+15+20=75 fits
      // A->2: 80+15+20=115 >100 cannot
      // B->2: 40+15+40=95 fits -> B should increase
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 40));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 20));

      final oneSetSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
          prescriptionFromExercise(exB, sets: 1),
        ],
      );

      final budget = const Duration(seconds: 100);
      final filled = WorkoutVolumeFiller.fill(oneSetSection, budget);
      expect(filled, isNotNull);
      // A should stay 1, B should become 2
      expect(filled!.exercises[0].sets, 1, reason: 'A too expensive should stay 1');
      expect(filled.exercises[1].sets, 2, reason: 'B should increase to 2');
      expect(WorkoutTimeEstimator.estimateSection(filled)!.total <= budget, true);
    });

    test('exact budget fit accepted', () {
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 30));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 30));

      final budget = const Duration(seconds: 75); // 30+15+30 exact
      final oneSetSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
          prescriptionFromExercise(exB, sets: 1),
        ],
      );

      final estimate = WorkoutTimeEstimator.estimateSection(oneSetSection);
      expect(estimate!.total, budget);

      final filled = WorkoutVolumeFiller.fill(oneSetSection, budget);
      expect(filled, isNotNull);
      // No increment possible, but exact fit should be accepted (section unchanged, not null)
      expect(filled!.exercises[0].sets, 1);
      expect(filled.exercises[1].sets, 1);
    });

    test('no legal increment remains unchanged no crash', () {
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 50));
      final budget = const Duration(seconds: 60);

      final oneSetSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
        ],
      );

      final filled = WorkoutVolumeFiller.fill(oneSetSection, budget);
      expect(filled, isNotNull);
      expect(filled!.exercises[0].sets, 1);
    });

    test('set caps even with huge budget', () {
      final hugeBudget = const Duration(hours: 10);
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 10));

      final warmupSection = WorkoutSection(
        type: WorkoutSectionType.warmup,
        exercises: [prescriptionFromExercise(exA, sets: 1)],
      );
      final mainSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [prescriptionFromExercise(exA, sets: 1)],
      );
      final cooldownSection = WorkoutSection(
        type: WorkoutSectionType.cooldown,
        exercises: [prescriptionFromExercise(exA, sets: 1)],
      );

      final filledWarmup = WorkoutVolumeFiller.fill(warmupSection, hugeBudget);
      final filledMain = WorkoutVolumeFiller.fill(mainSection, hugeBudget);
      final filledCooldown = WorkoutVolumeFiller.fill(cooldownSection, hugeBudget);

      expect(filledWarmup!.exercises[0].sets, 2);
      expect(filledMain!.exercises[0].sets, 4);
      expect(filledCooldown!.exercises[0].sets, 2);
    });

    test('invalid input safety returns null', () {
      final invalidBudget = const Duration(seconds: -1);
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 30));
      final validSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [prescriptionFromExercise(exA, sets: 1)],
      );

      final result = WorkoutVolumeFiller.fill(validSection, invalidBudget);
      expect(result, isNull);

      // Invalid prescription
      final invalidPrescription = WorkoutExercisePrescription(
        exercise: exA,
        sets: 0, // invalid
        workDuration: const Duration(seconds: 30),
        restBetweenSets: Duration.zero,
      );
      final invalidSection = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [invalidPrescription],
      );
      final result2 = WorkoutVolumeFiller.fill(invalidSection, const Duration(minutes: 5));
      expect(result2, isNull);
    });

    test('over-budget initial section returns null regression', () {
      // Create a valid section whose estimate exceeds supplied smaller budget
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 60));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 60));

      final section = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
          prescriptionFromExercise(exB, sets: 1),
        ],
      );

      final estimate = WorkoutTimeEstimator.estimateSection(section);
      expect(estimate, isNotNull);
      // 60 + 15 + 60 = 135 sec
      expect(estimate!.total, const Duration(seconds: 135));

      final smallerBudget = const Duration(seconds: 100); // less than 135
      final result = WorkoutVolumeFiller.fill(section, smallerBudget);
      expect(result, isNull, reason: 'Section already over budget should return null, not over-budget section');
    });

    test('max sets caps constants', () {
      expect(WorkoutVolumeFiller.warmupMaxSets, 2);
      expect(WorkoutVolumeFiller.mainMaxSets, 4);
      expect(WorkoutVolumeFiller.cooldownMaxSets, 2);
      expect(WorkoutVolumeFiller.capFor(WorkoutSectionType.warmup), 2);
      expect(WorkoutVolumeFiller.capFor(WorkoutSectionType.main), 4);
      expect(WorkoutVolumeFiller.capFor(WorkoutSectionType.cooldown), 2);
    });

    test('exact-budget input works and final result never exceeds budget', () {
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 30));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 30));

      final budget = const Duration(seconds: 75);
      final section = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
          prescriptionFromExercise(exB, sets: 1),
        ],
      );

      final filled = WorkoutVolumeFiller.fill(section, budget);
      expect(filled, isNotNull);
      expect(WorkoutTimeEstimator.estimateSection(filled!)!.total <= budget, true);
    });

    test('under-budget input fills normally and respects budget invariant', () {
      final exA = createTimed(id: 'A', pattern: MovementPattern.push, duration: const Duration(seconds: 20));
      final exB = createTimed(id: 'B', pattern: MovementPattern.squat, duration: const Duration(seconds: 20));

      final budget = const Duration(seconds: 200);
      final section = WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [
          prescriptionFromExercise(exA, sets: 1),
          prescriptionFromExercise(exB, sets: 1),
        ],
      );

      final filled = WorkoutVolumeFiller.fill(section, budget);
      expect(filled, isNotNull);
      // Should have increased at least one set
      final totalSets = filled!.exercises.fold<int>(0, (sum, p) => sum + p.sets);
      expect(totalSets > 2, true, reason: 'Under-budget should fill');
      expect(WorkoutTimeEstimator.estimateSection(filled)!.total <= budget, true);
    });
  });

  group('Full Generator Invariants', () {
    test('valid plan invariants', () {
      final context = ctx(duration: WorkoutDuration.twentyMinutes);
      final plan = WorkoutGenerator.generate(richFixture(), context);
      expect(plan, isNotNull);
      expect(plan!.isValid, true);
      expect(plan.warmup.isEmpty, false);
      expect(plan.main.isEmpty, false);
      expect(plan.cooldown.isEmpty, false);

      expect(plan.warmupEstimate!.total <= plan.timeBudget.warmup, true);
      expect(plan.mainEstimate!.total <= plan.timeBudget.main, true);
      expect(plan.cooldownEstimate!.total <= plan.timeBudget.cooldown, true);

      for (final p in plan.allPrescriptions) {
        expect(p.isValid, true);
      }

      for (final p in plan.warmup.exercises) {
        expect(p.sets >= 1 && p.sets <= 2, true);
      }
      for (final p in plan.main.exercises) {
        expect(p.sets >= 1 && p.sets <= 4, true);
      }
      for (final p in plan.cooldown.exercises) {
        expect(p.sets >= 1 && p.sets <= 2, true);
      }

      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
        userProfile: context.userProfile,
        capabilityProfile: context.capabilityProfile,
      );
      for (final pres in plan.allPrescriptions) {
        final result = ExerciseEligibilityEngine.evaluate(pres.exercise, eligibilityContext);
        expect(result.eligible, true);
      }
    });

    test('no additional legal +1 set can fit unless at cap', () {
      final context = ctx(duration: WorkoutDuration.twentyMinutes);
      final plan = WorkoutGenerator.generate(richFixture(), context);
      expect(plan, isNotNull);
      final nonNullPlan = plan!;

      // For each section, try to increase any exercise that is not at cap, should exceed budget
      void checkSection(WorkoutSection section) {
        final budget = nonNullPlan.timeBudget.budgetFor(section.type);
        final cap = WorkoutVolumeFiller.capFor(section.type);
        for (int i = 0; i < section.exercises.length; i++) {
          final pres = section.exercises[i];
          if (pres.sets >= cap) continue;
          final tentative = WorkoutExercisePrescription(
            exercise: pres.exercise,
            sets: pres.sets + 1,
            repsPerSet: pres.repsPerSet,
            workDuration: pres.workDuration,
            restBetweenSets: pres.restBetweenSets,
          );
          final tentativeList = List<WorkoutExercisePrescription>.from(section.exercises);
          tentativeList[i] = tentative;
          final tentativeSection = WorkoutSection(type: section.type, exercises: tentativeList);
          final est = WorkoutTimeEstimator.estimateSection(tentativeSection);
          if (est != null) {
            expect(est.total > budget, true,
                reason: 'After filling, no legal +1 should fit for ${section.type} index $i, but got ${est.total} <= $budget');
          }
        }
      }

      checkSection(nonNullPlan.warmup);
      checkSection(nonNullPlan.main);
      checkSection(nonNullPlan.cooldown);
    });
  });

  group('All Six Durations', () {
    test('valid for all durations', () {
      for (final dur in WorkoutDuration.values) {
        final context = ctx(duration: dur);
        final plan = WorkoutGenerator.generate(richFixture(), context);
        expect(plan, isNotNull, reason: 'Should generate for $dur');
        expect(plan!.isValid, true, reason: 'Valid for $dur');

        final limits = WorkoutGenerationLimits.fromWorkoutDuration(dur);
        expect(plan.warmup.exerciseCount <= limits.warmupMax, true);
        expect(plan.main.exerciseCount <= limits.mainMax, true);
        expect(plan.cooldown.exerciseCount <= limits.cooldownMax, true);

        expect(plan.warmupEstimate!.total <= plan.timeBudget.warmup, true);
        expect(plan.mainEstimate!.total <= plan.timeBudget.main, true);
        expect(plan.cooldownEstimate!.total <= plan.timeBudget.cooldown, true);
      }
    });
  });

  group('All Seven Goals', () {
    test('deterministic valid for all goals', () {
      for (final goal in FitnessGoal.values) {
        final context = ctx(goal: goal, duration: WorkoutDuration.twentyMinutes);
        final plan = WorkoutGenerator.generate(richFixture(), context);
        expect(plan, isNotNull, reason: 'Should generate for goal $goal');
        final nonNullPlan = plan!;
        expect(nonNullPlan.isValid, true, reason: 'Valid for goal $goal');

        final plan2 = WorkoutGenerator.generate(richFixture(), context);
        expect(plan2, isNotNull);
        final nonNullPlan2 = plan2!;
        expect(nonNullPlan.warmup.exercises.map((p) => p.exercise.id).toList(),
            nonNullPlan2.warmup.exercises.map((p) => p.exercise.id).toList(),
            reason: 'Deterministic warmup for $goal');
        expect(nonNullPlan.main.exercises.map((p) => p.exercise.id).toList(),
            nonNullPlan2.main.exercises.map((p) => p.exercise.id).toList(),
            reason: 'Deterministic main for $goal');
        expect(nonNullPlan.main.exercises.map((p) => p.sets).toList(),
            nonNullPlan2.main.exercises.map((p) => p.sets).toList(),
            reason: 'Deterministic sets for $goal');
      }
    });
  });

  group('Real Catalog Stabilization', () {
    test('general home', () {
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.generalFitness,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.twentyMinutes,
          environment: TrainingEnvironment.normalHome,
          equipment: {WorkoutEquipment.none},
          preferences: {},
        ),
        capabilityProfile: fullProfile(CapabilityLevel.level3),
      );

      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull, reason: 'General home should produce plan');
      expect(plan!.isValid, true);
    });

    test('apartment No Jumping Low Impact', () {
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.generalFitness,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.twentyMinutes,
          environment: TrainingEnvironment.apartment,
          equipment: {WorkoutEquipment.none},
          preferences: {WorkoutPreference.noJumping, WorkoutPreference.lowImpact},
        ),
        capabilityProfile: fullProfile(CapabilityLevel.level3),
      );

      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan != null) {
        expect(plan.isValid, true);
        final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: context.userProfile,
          capabilityProfile: context.capabilityProfile,
        );
        for (final pres in plan.allPrescriptions) {
          final result = ExerciseEligibilityEngine.evaluate(pres.exercise, eligibilityContext);
          expect(result.eligible, true);
        }
      }
    });

    test('equipment user', () {
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.buildMuscle,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.thirtyMinutes,
          environment: TrainingEnvironment.largeRoom,
          equipment: {WorkoutEquipment.none, WorkoutEquipment.dumbbells, WorkoutEquipment.resistanceBands},
          preferences: {},
        ),
        capabilityProfile: fullProfile(CapabilityLevel.level4),
      );

      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull, reason: 'Equipment user should produce plan');
      expect(plan!.isValid, true);
    });

    test('restrictive Avoid Wrist Heavy', () {
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.improveMobility,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.twentyMinutes,
          environment: TrainingEnvironment.normalHome,
          equipment: {WorkoutEquipment.none},
          preferences: {WorkoutPreference.avoidWristHeavy},
        ),
        capabilityProfile: fullProfile(CapabilityLevel.level3),
      );

      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan != null) {
        expect(plan.isValid, true);
      }
    });

    test('restrictive Avoid Deep Knee Bending', () {
      final context = WorkoutGenerationContext(
        userProfile: UserFitnessProfile(
          goal: FitnessGoal.stayActive,
          experience: ExperienceLevel.regularTraining,
          workoutDuration: WorkoutDuration.twentyMinutes,
          environment: TrainingEnvironment.normalHome,
          equipment: {WorkoutEquipment.none},
          preferences: {WorkoutPreference.avoidDeepKneeBending},
        ),
        capabilityProfile: fullProfile(CapabilityLevel.level3),
      );

      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan != null) {
        expect(plan.isValid, true);
      }
    });
  });

  group('Full Catalog Eligibility Audit', () {
    test('every selected exercise eligible', () {
      final contexts = [
        ctx(duration: WorkoutDuration.twentyMinutes, env: TrainingEnvironment.normalHome),
        ctx(duration: WorkoutDuration.thirtyMinutes, env: TrainingEnvironment.largeRoom),
        WorkoutGenerationContext(
          userProfile: UserFitnessProfile(
            goal: FitnessGoal.loseWeight,
            experience: ExperienceLevel.regularTraining,
            workoutDuration: WorkoutDuration.fifteenMinutes,
            environment: TrainingEnvironment.normalHome,
            equipment: {WorkoutEquipment.none},
            preferences: {WorkoutPreference.lowImpact},
          ),
          capabilityProfile: fullProfile(CapabilityLevel.level3),
        ),
      ];

      for (final c in contexts) {
        final plan = WorkoutGenerator.generateCatalog(c);
        if (plan == null) continue;
        final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: c.userProfile,
          capabilityProfile: c.capabilityProfile,
        );
        for (final pres in plan.allPrescriptions) {
          final result = ExerciseEligibilityEngine.evaluate(pres.exercise, eligibilityContext);
          expect(result.eligible, true,
              reason: 'Exercise ${pres.exercise.id} should be eligible');
        }
      }
    });
  });

  group('Determinism', () {
    test('same context repeatedly identical IDs, sets, estimates', () {
      final context = ctx(duration: WorkoutDuration.twentyMinutes);
      final exercises = richFixture();

      final first = WorkoutGenerator.generate(exercises, context);
      final second = WorkoutGenerator.generate(exercises, context);
      final third = WorkoutGenerator.generate(exercises, context);

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(third, isNotNull);

      expect(first!.warmup.exercises.map((p) => p.exercise.id).toList(),
          second!.warmup.exercises.map((p) => p.exercise.id).toList());
      expect(first.main.exercises.map((p) => p.exercise.id).toList(),
          second.main.exercises.map((p) => p.exercise.id).toList());
      expect(first.cooldown.exercises.map((p) => p.exercise.id).toList(),
          second.cooldown.exercises.map((p) => p.exercise.id).toList());

      expect(first.warmup.exercises.map((p) => p.sets).toList(),
          second.warmup.exercises.map((p) => p.sets).toList());
      expect(first.main.exercises.map((p) => p.sets).toList(),
          second.main.exercises.map((p) => p.sets).toList());
      expect(first.cooldown.exercises.map((p) => p.sets).toList(),
          second.cooldown.exercises.map((p) => p.sets).toList());

      expect(first.estimatedDuration, second.estimatedDuration);
      expect(first.estimatedDuration, third!.estimatedDuration);

      expect(first.warmupEstimate, second.warmupEstimate);
      expect(first.mainEstimate, second.mainEstimate);
      expect(first.cooldownEstimate, second.cooldownEstimate);
    });
  });
}
