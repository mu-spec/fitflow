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

  UserFitnessProfile createUserProfile({
    required FitnessGoal goal,
    TrainingEnvironment environment = TrainingEnvironment.apartment,
    Set<WorkoutEquipment> equipment = const {},
    Set<WorkoutPreference> preferences = const {
      WorkoutPreference.noJumping,
      WorkoutPreference.lowImpact,
      WorkoutPreference.standingOnly,
    },
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: WorkoutDuration.twentyMinutes,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  group('Integration API rankForUser', () {
    test('exists and delegates to eligibility and ranking', () {
      final capabilityProfile = createFullLevel(CapabilityLevel.level3);
      final userProfile = createUserProfile(goal: FitnessGoal.buildStrength);

      final exercises = [
        createTestExercise(id: 'a', difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'b', difficulty: ExerciseDifficulty.level1),
      ];

      final result = ExerciseRankingEngine.rankForUser(
          exercises, userProfile, capabilityProfile);

      // Should be immutable
      expect(() => result.add(result.first), throwsUnsupportedError);

      // Should be sorted descending
      expect(result[0].totalScore >= result[1].totalScore, true);
    });

    test('every item returned by rankForUser is eligible', () {
      final capabilityProfile = createFullLevel(CapabilityLevel.level2);
      final userProfile = createUserProfile(
        goal: FitnessGoal.loseWeight,
        environment: TrainingEnvironment.apartment,
        equipment: {},
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final ranked = ExerciseRankingEngine.rankForUser(
          ExerciseCatalog.all, userProfile, capabilityProfile);

      expect(ranked, isNotEmpty);
      for (final r in ranked) {
        final eval = ExerciseEligibilityEngine.evaluate(
            r.exercise, eligibilityContext);
        expect(eval.eligible, true,
            reason: '${r.exercise.id} should be eligible');
        expect(eval.reasons, isEmpty);
      }
    });
  });

  group('Score Invariants', () {
    test('total == capability + goal and ranges valid for all APIs', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final rankingContext = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildMuscle);
      final eligibilityContext = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
      );
      final userProfile = createUserProfile(goal: FitnessGoal.buildMuscle);

      final exercises = [
        createTestExercise(id: 'push_l3', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'cardio_l2', movementPattern: MovementPattern.cardio, difficulty: ExerciseDifficulty.level2),
        createTestExercise(id: 'warmup', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'null', movementPattern: null),
      ];

      // score
      for (final ex in exercises) {
        final res = ExerciseRankingEngine.score(ex, rankingContext);
        expect(res.totalScore, res.capabilityFitScore + res.goalAffinityScore,
            reason: '${ex.id} total composition');
        expect(res.capabilityFitScore >= 0 && res.capabilityFitScore <= 100, true);
        expect(res.goalAffinityScore >= 0 && res.goalAffinityScore <= 15, true);
        expect(res.totalScore >= 0 && res.totalScore <= 115, true);
      }

      // rank
      final ranked = ExerciseRankingEngine.rank(exercises, rankingContext);
      for (final r in ranked) {
        expect(r.totalScore, r.capabilityFitScore + r.goalAffinityScore);
        expect(r.capabilityFitScore >= 0 && r.capabilityFitScore <= 100, true);
        expect(r.goalAffinityScore >= 0 && r.goalAffinityScore <= 15, true);
        expect(r.totalScore >= 0 && r.totalScore <= 115, true);
      }

      // rankEligible
      final rankedEligible =
          ExerciseRankingEngine.rankEligible(exercises, eligibilityContext, rankingContext);
      for (final r in rankedEligible) {
        expect(r.totalScore, r.capabilityFitScore + r.goalAffinityScore);
        expect(r.capabilityFitScore >= 0 && r.capabilityFitScore <= 100, true);
        expect(r.goalAffinityScore >= 0 && r.goalAffinityScore <= 15, true);
        expect(r.totalScore >= 0 && r.totalScore <= 115, true);
      }

      // rankForUser
      final rankedForUser =
          ExerciseRankingEngine.rankForUser(exercises, userProfile, profile);
      for (final r in rankedForUser) {
        expect(r.totalScore, r.capabilityFitScore + r.goalAffinityScore);
        expect(r.capabilityFitScore >= 0 && r.capabilityFitScore <= 100, true);
        expect(r.goalAffinityScore >= 0 && r.goalAffinityScore <= 15, true);
        expect(r.totalScore >= 0 && r.totalScore <= 115, true);
      }
    });
  });

  group('Full Catalog Integration Test', () {
    test('restrictive profile: every result eligible and scores valid', () {
      final capabilityProfile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
        MovementPattern.pull: CapabilityLevel.level2,
        MovementPattern.squat: CapabilityLevel.level2,
        MovementPattern.lunge: CapabilityLevel.level2,
        MovementPattern.hinge: CapabilityLevel.level2,
        MovementPattern.core: CapabilityLevel.level2,
        MovementPattern.glute: CapabilityLevel.level2,
        MovementPattern.cardio: CapabilityLevel.level2,
        MovementPattern.mobility: CapabilityLevel.level2,
        MovementPattern.balance: CapabilityLevel.level2,
      });

      final userProfile = createUserProfile(
        goal: FitnessGoal.buildStrength,
        environment: TrainingEnvironment.apartment,
        equipment: {},
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      final ranked = ExerciseRankingEngine.rankForUser(
          ExerciseCatalog.all, userProfile, capabilityProfile);

      expect(ranked, isNotEmpty, reason: 'Restrictive catalog should still have eligible');

      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      for (final r in ranked) {
        // eligible
        final eval = ExerciseEligibilityEngine.evaluate(r.exercise, eligibilityContext);
        expect(eval.eligible, true, reason: '${r.exercise.id} eligible');

        // composition
        expect(r.totalScore, r.capabilityFitScore + r.goalAffinityScore);

        // ranges
        expect(r.capabilityFitScore >= 0 && r.capabilityFitScore <= 100, true);
        expect(r.goalAffinityScore >= 0 && r.goalAffinityScore <= 15, true);
        expect(r.totalScore >= 0 && r.totalScore <= 115, true);
      }
    });
  });

  group('All Seven Goals Test', () {
    test('each goal: no crash, eligible, valid ranges, descending order, deterministic ties', () {
      final capabilityProfile = createFullLevel(CapabilityLevel.level3);
      final baseUserProfile = createUserProfile(
        goal: FitnessGoal.generalFitness,
        environment: TrainingEnvironment.apartment,
        equipment: {},
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      for (final goal in FitnessGoal.values) {
        final userProfile = UserFitnessProfile(
          goal: goal,
          experience: baseUserProfile.experience,
          workoutDuration: baseUserProfile.workoutDuration,
          environment: baseUserProfile.environment,
          equipment: baseUserProfile.equipment,
          preferences: baseUserProfile.preferences,
        );

        final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
            userProfile: userProfile, capabilityProfile: capabilityProfile);

        // No crash
        final ranked = ExerciseRankingEngine.rankForUser(
            ExerciseCatalog.all, userProfile, capabilityProfile);

        expect(ranked, isNotEmpty, reason: 'Goal $goal should have eligible');

        // Every eligible
        for (final r in ranked) {
          final eval = ExerciseEligibilityEngine.evaluate(r.exercise, eligibilityContext);
          expect(eval.eligible, true, reason: 'Goal $goal exercise ${r.exercise.id} eligible');
          expect(r.capabilityFitScore >= 0 && r.capabilityFitScore <= 100, true);
          expect(r.goalAffinityScore >= 0 && r.goalAffinityScore <= 15, true);
          expect(r.totalScore >= 0 && r.totalScore <= 115, true);
          expect(r.totalScore, r.capabilityFitScore + r.goalAffinityScore);
        }

        // Descending order
        for (int i = 0; i < ranked.length - 1; i++) {
          expect(ranked[i].totalScore >= ranked[i + 1].totalScore, true,
              reason: 'Goal $goal descending order at $i');
        }

        // Deterministic: equal scores preserve input relative order is already tested in ranking,
        // but we verify that sorting is stable by checking that rank is deterministic
        final rankedAgain = ExerciseRankingEngine.rankForUser(
            ExerciseCatalog.all, userProfile, capabilityProfile);
        expect(ranked.map((e) => e.exercise.id).toList(),
            rankedAgain.map((e) => e.exercise.id).toList(),
            reason: 'Goal $goal determinism');
      }
    });
  });

  group('Capability Dominance Full-Collection', () {
    test('exact 100+0 outranks one below 80+15 via rank()', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
        MovementPattern.cardio: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      final exactLow = createTestExercise(
          id: 'cardio_l3_exact',
          movementPattern: MovementPattern.cardio,
          difficulty: ExerciseDifficulty.level3); // 100+0=100

      final belowHigh = createTestExercise(
          id: 'push_l2_below',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2); // 80+15=95

      final ranked = ExerciseRankingEngine.rank([belowHigh, exactLow], ctx);
      expect(ranked[0].exercise.id, 'cardio_l3_exact');
      expect(ranked[0].totalScore, 100);
      expect(ranked[1].exercise.id, 'push_l2_below');
      expect(ranked[1].totalScore, 95);
    });
  });

  group('Goal Tie-Break', () {
    test('same capability fit, higher goal affinity ranks first', () {
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
      expect(ranked[1].exercise.id, 'push_exact');
    });
  });

  group('Stable Complete Tie', () {
    test('equal capability, goal, total preserve original order', () {
      final profile = createFullLevel(CapabilityLevel.level3);
      final ctx = ExerciseRankingContext(
          capabilityProfile: profile, goal: FitnessGoal.buildStrength);

      final a = createTestExercise(id: 'a', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level2); // 80+15=95
      final b = createTestExercise(id: 'b', movementPattern: MovementPattern.squat, difficulty: ExerciseDifficulty.level2); // 80+15=95
      final c = createTestExercise(id: 'c', movementPattern: MovementPattern.pull, difficulty: ExerciseDifficulty.level2); // 80+15=95

      final ranked = ExerciseRankingEngine.rank([a, b, c], ctx);
      expect(ranked.map((r) => r.exercise.id).toList(), ['a', 'b', 'c']);
    });
  });

  group('Determinism rankForUser', () {
    test('same exercise list, user profile, capability profile yields identical', () {
      final capabilityProfile = createFullLevel(CapabilityLevel.level3);
      final userProfile = createUserProfile(goal: FitnessGoal.stayActive);

      final exercises = [
        createTestExercise(id: 'push_l3', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'squat_l2', movementPattern: MovementPattern.squat, difficulty: ExerciseDifficulty.level2),
        createTestExercise(id: 'cardio_l3', movementPattern: MovementPattern.cardio, difficulty: ExerciseDifficulty.level3),
      ];

      final first = ExerciseRankingEngine.rankForUser(exercises, userProfile, capabilityProfile);
      final second = ExerciseRankingEngine.rankForUser(exercises, userProfile, capabilityProfile);

      expect(first.length, second.length);
      for (int i = 0; i < first.length; i++) {
        expect(first[i].exercise.id, second[i].exercise.id);
        expect(first[i].capabilityFitScore, second[i].capabilityFitScore);
        expect(first[i].goalAffinityScore, second[i].goalAffinityScore);
        expect(first[i].totalScore, second[i].totalScore);
      }
    });
  });

  group('Immutability', () {
    test('source list unchanged and result immutable and contexts immutable', () {
      final capabilityProfile = createFullLevel(CapabilityLevel.level2);
      final userProfile = createUserProfile(goal: FitnessGoal.generalFitness);

      final input = [
        createTestExercise(id: 'a', difficulty: ExerciseDifficulty.level2),
        createTestExercise(id: 'b', difficulty: ExerciseDifficulty.level1),
      ];
      final originalIds = input.map((e) => e.id).toList();

      final ranked = ExerciseRankingEngine.rankForUser(input, userProfile, capabilityProfile);

      // source unchanged
      expect(input.map((e) => e.id).toList(), originalIds);

      // result immutable
      expect(() => ranked.add(ranked.first), throwsUnsupportedError);

      // contexts remain immutable (their fields are final, but test that creating new context doesn't mutate old)
      final ctx = ExerciseRankingContext.fromProfiles(userProfile: userProfile, capabilityProfile: capabilityProfile);
      expect(ctx.goal, FitnessGoal.generalFitness);
      expect(ctx.capabilityProfile, capabilityProfile);
    });
  });

  group('Eligibility vs Direct Ranking distinction', () {
    test('rank() may score ineligible exercises, rankForUser filters them', () {
      final capabilityProfile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level1,
      });
      final userProfile = createUserProfile(goal: FitnessGoal.generalFitness);
      final rankingContext = ExerciseRankingContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final eligibleL1 = createTestExercise(
          id: 'eligible_l1', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level1);
      final ineligibleL5 = createTestExercise(
          id: 'ineligible_l5', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level5);

      // Direct rank includes both, with ineligible scoring 0
      final directRanked = ExerciseRankingEngine.rank([eligibleL1, ineligibleL5], rankingContext);
      expect(directRanked.length, 2);
      expect(directRanked.any((r) => r.exercise.id == 'ineligible_l5'), true);
      final ineligibleResult = directRanked.firstWhere((r) => r.exercise.id == 'ineligible_l5');
      expect(ineligibleResult.capabilityFitScore, 0);

      // rankForUser filters out ineligible
      final safeRanked = ExerciseRankingEngine.rankForUser([eligibleL1, ineligibleL5], userProfile, capabilityProfile);
      expect(safeRanked.length, 1);
      expect(safeRanked[0].exercise.id, 'eligible_l1');
    });
  });
}
