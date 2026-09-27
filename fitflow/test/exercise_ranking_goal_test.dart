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
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_context.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_engine.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTestExercise({
    required String id,
    MovementPattern? movementPattern = MovementPattern.push,
    ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
      difficulty: difficulty,
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

  CapabilityProfile createProfileWithLevels(
      Map<MovementPattern, CapabilityLevel> levels) {
    final now = DateTime.utc(2026, 1, 1);
    final map = <MovementPattern, MovementCapability>{};
    for (final pattern in CapabilityProfile.trainablePatterns) {
      final level = levels[pattern] ?? CapabilityLevel.level1;
      map[pattern] = MovementCapability(
        movementPattern: pattern,
        level: level,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      );
    }
    return CapabilityProfile.fromMap(map);
  }

  CapabilityProfile createFullLevel(CapabilityLevel level) {
    return createProfileWithLevels({
      for (final p in CapabilityProfile.trainablePatterns) p: level,
    });
  }

  group('General Fitness Compatibility', () {
    test('default/generalFitness preserves 5B-1 capability results', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctxDefault = ExerciseRankingContext(capabilityProfile: profile);
      final ctxGeneral = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.generalFitness);

      final l3 = createTestExercise(
          id: 'push_l3', difficulty: ExerciseDifficulty.level3);
      final l2 = createTestExercise(
          id: 'push_l2', difficulty: ExerciseDifficulty.level2);

      final rDefaultL3 = ExerciseRankingEngine.score(l3, ctxDefault);
      final rGeneralL3 = ExerciseRankingEngine.score(l3, ctxGeneral);
      final rDefaultL2 = ExerciseRankingEngine.score(l2, ctxDefault);

      expect(rDefaultL3.capabilityFitScore, 100);
      expect(rDefaultL3.goalAffinityScore, 0);
      expect(rDefaultL3.totalScore, 100);

      expect(rGeneralL3.capabilityFitScore, 100);
      expect(rGeneralL3.goalAffinityScore, 0);
      expect(rGeneralL3.totalScore, 100);

      expect(rDefaultL2.capabilityFitScore, 80);
      expect(rDefaultL2.goalAffinityScore, 0);
      expect(rDefaultL2.totalScore, 80);
    });
  });

  group('Build Strength', () {
    test('representative movement affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'push', movementPattern: MovementPattern.push),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'squat', movementPattern: MovementPattern.squat),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'core', movementPattern: MovementPattern.core),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'balance', movementPattern: MovementPattern.balance),
                  ctx)
              .goalAffinityScore,
          5);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          0);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'mobility', movementPattern: MovementPattern.mobility),
                  ctx)
              .goalAffinityScore,
          0);
    });
  });

  group('Build Muscle', () {
    test('representative affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildMuscle);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'push', movementPattern: MovementPattern.push),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'glute', movementPattern: MovementPattern.glute),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'core', movementPattern: MovementPattern.core),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          0);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'balance', movementPattern: MovementPattern.balance),
                  ctx)
              .goalAffinityScore,
          0);
    });
  });

  group('Lose Weight', () {
    test('representative affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.loseWeight);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'squat', movementPattern: MovementPattern.squat),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'push', movementPattern: MovementPattern.push),
                  ctx)
              .goalAffinityScore,
          5);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'mobility', movementPattern: MovementPattern.mobility),
                  ctx)
              .goalAffinityScore,
          0);
    });
  });

  group('Improve Endurance', () {
    test('representative affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.improveEndurance);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'lunge', movementPattern: MovementPattern.lunge),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'core', movementPattern: MovementPattern.core),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'pull', movementPattern: MovementPattern.pull),
                  ctx)
              .goalAffinityScore,
          5);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'mobility', movementPattern: MovementPattern.mobility),
                  ctx)
              .goalAffinityScore,
          0);
    });
  });

  group('Improve Mobility', () {
    test('representative affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.improveMobility);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'mobility', movementPattern: MovementPattern.mobility),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'balance', movementPattern: MovementPattern.balance),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'hinge', movementPattern: MovementPattern.hinge),
                  ctx)
              .goalAffinityScore,
          5);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'push', movementPattern: MovementPattern.push),
                  ctx)
              .goalAffinityScore,
          0);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          0);
    });
  });

  group('Stay Active', () {
    test('representative affinities', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.stayActive);

      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'cardio', movementPattern: MovementPattern.cardio),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'mobility', movementPattern: MovementPattern.mobility),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'balance', movementPattern: MovementPattern.balance),
                  ctx)
              .goalAffinityScore,
          15);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'hinge', movementPattern: MovementPattern.hinge),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'core', movementPattern: MovementPattern.core),
                  ctx)
              .goalAffinityScore,
          10);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'push', movementPattern: MovementPattern.push),
                  ctx)
              .goalAffinityScore,
          5);
      expect(
          ExerciseRankingEngine.score(
                  createTestExercise(id: 'pull', movementPattern: MovementPattern.pull),
                  ctx)
              .goalAffinityScore,
          5);
    });
  });

  group('Critical Capability-Dominance', () {
    test('exact match 100+0 outranks one level below 80+15', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
        MovementPattern.cardio: CapabilityLevel.level3,
      });
      // Goal that gives cardio +15 but push 0 for improveMobility
      // For dominance test, we want A exact match with 0 affinity, B one below with +15
      // Use buildStrength where push gets +15, but we need A with 0 and B with 15.
      // So construct: A = push L3 exact, but goal = improveMobility gives push 0
      // B = cardio L2 one below with +15? Let's use same movement but different capability?
      // Actually requirement: A exact capability match, goal 0, total 100
      // B one level easier, strongest affinity +15, total 95
      // So need two exercises same movement? No, same capability level but different goal affinities
      // We need context where A gets 0 affinity and B gets 15, but both same capability pattern? 
      // That would require same movement can't have different affinities.
      // Instead use different patterns but same capability level profile:
      // Profile: push L3, cardio L3
      // A: push L3 exact, goal improveMobility -> push affinity 0, total 100
      // B: cardio L2 one below, goal improveMobility -> cardio affinity 0 actually (push/cardio 0 in improveMobility)
      // So not good.
      // Use goal = buildStrength: push L3 exact affinity 15, but we want A with 0 affinity.
      // Let's instead directly test invariant: max goal 15 < 20 diff.
      // Create two exercises:
      // A: push L3 exact, goal generalFitness (0) => 100
      // B: push L2 one below, goal buildStrength (15) => 95
      // But they share same context? Can't have two different goals in same ranking.
      // So we need to test ranking within same goal context where A gets 0 and B gets 15 but A still higher.
      // Example: goal = improveMobility
      // - mobility L3 exact: 100+15=115
      // - push L3 exact: 100+0=100
      // That's not dominance test.
      // For dominance, we need A exact with low affinity, B one below with high affinity.
      // Choose goal = buildStrength:
      // - balance L3 exact: capability 100 + goal 5 =105? Actually balance 5, not 0.
      // Need a movement with 0 affinity in that goal.
      // buildStrength: cardio 0, mobility 0
      // So A: cardio L3 exact: 100+0=100
      // B: push L2 one below: 80+15=95
      // Different movements but same capability profile L3 for both patterns.
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      final exactLowAffinity = createTestExercise(
          id: 'cardio_l3_exact',
          movementPattern: MovementPattern.cardio,
          difficulty: ExerciseDifficulty.level3); // 100+0=100

      final oneBelowHighAffinity = createTestExercise(
          id: 'push_l2_one_below',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2); // 80+15=95

      final scoreA = ExerciseRankingEngine.score(exactLowAffinity, ctx);
      final scoreB = ExerciseRankingEngine.score(oneBelowHighAffinity, ctx);

      expect(scoreA.capabilityFitScore, 100);
      expect(scoreA.goalAffinityScore, 0);
      expect(scoreA.totalScore, 100);

      expect(scoreB.capabilityFitScore, 80);
      expect(scoreB.goalAffinityScore, 15);
      expect(scoreB.totalScore, 95);

      final ranked = ExerciseRankingEngine.rank(
          [oneBelowHighAffinity, exactLowAffinity], ctx);
      expect(ranked[0].exercise.id, 'cardio_l3_exact',
          reason: 'Exact match must outrank one level below even with max goal bonus');
      expect(ranked[1].exercise.id, 'push_l2_one_below');
    });
  });

  group('Goal Breaks Same-Capability Tie', () {
    test('improveMobility: mobility exact 115 outranks push exact 100', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.improveMobility);

      final mobilityExact = createTestExercise(
          id: 'mobility_exact',
          movementPattern: MovementPattern.mobility,
          difficulty: ExerciseDifficulty.level3); // 100+15=115

      final pushExact = createTestExercise(
          id: 'push_exact',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level3); // 100+0=100

      final ranked = ExerciseRankingEngine.rank([pushExact, mobilityExact], ctx);
      expect(ranked[0].exercise.id, 'mobility_exact');
      expect(ranked[0].totalScore, 115);
      expect(ranked[1].exercise.id, 'push_exact');
      expect(ranked[1].totalScore, 100);
    });
  });

  group('Stable Tie Still Works with Goal', () {
    test('equal capability and equal goal preserve original order', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      final a = createTestExercise(
          id: 'a',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2); // 80+15=95
      final b = createTestExercise(
          id: 'b',
          movementPattern: MovementPattern.squat,
          difficulty: ExerciseDifficulty.level2); // 80+15=95
      final c = createTestExercise(
          id: 'c',
          movementPattern: MovementPattern.pull,
          difficulty: ExerciseDifficulty.level2); // 80+15=95

      final ranked = ExerciseRankingEngine.rank([a, b, c], ctx);
      expect(ranked.map((r) => r.exercise.id).toList(), ['a', 'b', 'c']);
      expect(ranked[0].totalScore, 95);
      expect(ranked[1].totalScore, 95);
      expect(ranked[2].totalScore, 95);
    });
  });

  group('fromProfiles', () {
    test('correctly extracts capabilityProfile and goal', () {
      final now = DateTime.utc(2026, 1, 1);
      final capabilityProfile = CapabilityProfile.initial(updatedAt: now);
      final userProfile = UserFitnessProfile(
        goal: FitnessGoal.buildMuscle,
        experience: ExperienceLevel.regularTraining,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none},
      );

      final ctx = ExerciseRankingContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      expect(ctx.capabilityProfile, capabilityProfile);
      expect(ctx.goal, FitnessGoal.buildMuscle);
    });
  });

  group('Defensive Cases', () {
    test('null movement goal 0 total 0 no crash', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);
      final nullEx = createTestExercise(id: 'null', movementPattern: null);

      final result = ExerciseRankingEngine.score(nullEx, ctx);
      expect(result.capabilityFitScore, 0);
      expect(result.goalAffinityScore, 0);
      expect(result.totalScore, 0);
    });

    test('warmup goal 0 capability 50 total 50 no crash', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);
      final warmup = createTestExercise(
          id: 'warmup', movementPattern: MovementPattern.warmup);

      final result = ExerciseRankingEngine.score(warmup, ctx);
      expect(result.capabilityFitScore, 50);
      expect(result.goalAffinityScore, 0);
      expect(result.totalScore, 50);
    });

    test('cooldown goal 0 capability 50 total 50', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.loseWeight);
      final cooldown = createTestExercise(
          id: 'cooldown', movementPattern: MovementPattern.cooldown);

      final result = ExerciseRankingEngine.score(cooldown, ctx);
      expect(result.capabilityFitScore, 50);
      expect(result.goalAffinityScore, 0);
      expect(result.totalScore, 50);
    });

    test('missing capability still computes goal affinity', () {
      final now = DateTime.utc(2026, 1, 1);
      final incompleteMap = <MovementPattern, MovementCapability>{
        MovementPattern.squat: MovementCapability(
            movementPattern: MovementPattern.squat,
            level: CapabilityLevel.level3,
            source: CapabilitySource.initialAssessment,
            updatedAt: now),
      };
      final incompleteProfile = CapabilityProfile.fromMap(incompleteMap);
      final ctx = ExerciseRankingContext(
          capabilityProfile: incompleteProfile,
          goal: FitnessGoal.buildStrength);

      final pushEx = createTestExercise(
          id: 'push_missing', movementPattern: MovementPattern.push);

      final result = ExerciseRankingEngine.score(pushEx, ctx);
      // capability 0 because missing, but goal affinity 15 because push is strength
      expect(result.capabilityFitScore, 0);
      expect(result.goalAffinityScore, 15);
      expect(result.totalScore, 15);
    });

    test('goal affinity never exceeds 15', () {
      final profile = createFullLevel(CapabilityLevel.level5);
      final exercises = [
        for (final pattern in MovementPattern.values)
          createTestExercise(id: pattern.name, movementPattern: pattern)
      ];

      for (final goal in FitnessGoal.values) {
        final ctx = ExerciseRankingContext(
            capabilityProfile: profile, goal: goal);
        for (final ex in exercises) {
          final result = ExerciseRankingEngine.score(ex, ctx);
          expect(result.goalAffinityScore >= 0, true);
          expect(result.goalAffinityScore <= 15, true,
              reason:
                  'Goal ${goal.name} pattern ${ex.movementPattern} score ${result.goalAffinityScore} exceeds 15');
        }
      }
    });
  });

  group('Total Score Composition', () {
    test('total = capability + goal', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      final ex = createTestExercise(
          id: 'push_l2',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2); // 80+15=95

      final result = ExerciseRankingEngine.score(ex, ctx);
      expect(result.capabilityFitScore, 80);
      expect(result.goalAffinityScore, 15);
      expect(result.totalScore, 95);
      expect(result.totalScore,
          result.capabilityFitScore + result.goalAffinityScore);
    });
  });
}
