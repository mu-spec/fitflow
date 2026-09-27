import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
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

  group('Exact Level - Push L3', () {
    test('L3=100, L2=80, L1=60 and ranking L3 before L2 before L1', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final rankingContext =
          ExerciseRankingContext(capabilityProfile: profile);

      final l1 = createTestExercise(
          id: 'push_l1', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level1);
      final l2 = createTestExercise(
          id: 'push_l2', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level2);
      final l3 = createTestExercise(
          id: 'push_l3', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level3);

      final s1 = ExerciseRankingEngine.score(l1, rankingContext);
      final s2 = ExerciseRankingEngine.score(l2, rankingContext);
      final s3 = ExerciseRankingEngine.score(l3, rankingContext);

      expect(s1.capabilityFitScore, 60);
      expect(s2.capabilityFitScore, 80);
      expect(s3.capabilityFitScore, 100);

      // totalScore == capabilityFitScore for 5B-1
      expect(s1.totalScore, s1.capabilityFitScore);
      expect(s2.totalScore, s2.capabilityFitScore);
      expect(s3.totalScore, s3.capabilityFitScore);

      final ranked = ExerciseRankingEngine.rank([l1, l2, l3], rankingContext);
      expect(ranked[0].exercise.id, 'push_l3');
      expect(ranked[1].exercise.id, 'push_l2');
      expect(ranked[2].exercise.id, 'push_l1');
      expect(ranked[0].capabilityFitScore, 100);
      expect(ranked[1].capabilityFitScore, 80);
      expect(ranked[2].capabilityFitScore, 60);
    });
  });

  group('Level 5', () {
    test('Push L5: L5=100 L4=80 L3=60 L2=40 L1=20', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level5,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      final l1 = createTestExercise(id: 'l1', difficulty: ExerciseDifficulty.level1);
      final l2 = createTestExercise(id: 'l2', difficulty: ExerciseDifficulty.level2);
      final l3 = createTestExercise(id: 'l3', difficulty: ExerciseDifficulty.level3);
      final l4 = createTestExercise(id: 'l4', difficulty: ExerciseDifficulty.level4);
      final l5 = createTestExercise(id: 'l5', difficulty: ExerciseDifficulty.level5);

      expect(ExerciseRankingEngine.score(l1, ctx).capabilityFitScore, 20);
      expect(ExerciseRankingEngine.score(l2, ctx).capabilityFitScore, 40);
      expect(ExerciseRankingEngine.score(l3, ctx).capabilityFitScore, 60);
      expect(ExerciseRankingEngine.score(l4, ctx).capabilityFitScore, 80);
      expect(ExerciseRankingEngine.score(l5, ctx).capabilityFitScore, 100);

      final ranked = ExerciseRankingEngine.rank([l1, l2, l3, l4, l5], ctx);
      expect(ranked.map((r) => r.exercise.id).toList(),
          ['l5', 'l4', 'l3', 'l2', 'l1']);
    });
  });

  group('Movement Independence', () {
    test('Push L2 and Squat L4 scored independently', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
        MovementPattern.squat: CapabilityLevel.level4,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      final pushL2 = createTestExercise(
          id: 'push_l2',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2);
      final pushL1 = createTestExercise(
          id: 'push_l1',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level1);
      final squatL4 = createTestExercise(
          id: 'squat_l4',
          movementPattern: MovementPattern.squat,
          difficulty: ExerciseDifficulty.level4);
      final squatL2 = createTestExercise(
          id: 'squat_l2',
          movementPattern: MovementPattern.squat,
          difficulty: ExerciseDifficulty.level2);

      // Push L2 should be 100 against Push L2 capability
      expect(ExerciseRankingEngine.score(pushL2, ctx).capabilityFitScore, 100);
      // Push L1 should be 80 against Push L2
      expect(ExerciseRankingEngine.score(pushL1, ctx).capabilityFitScore, 80);
      // Squat L4 should be 100 against Squat L4
      expect(ExerciseRankingEngine.score(squatL4, ctx).capabilityFitScore, 100);
      // Squat L2 should be 60 against Squat L4 (diff 2)
      expect(ExerciseRankingEngine.score(squatL2, ctx).capabilityFitScore, 60);
    });
  });

  group('Above Capability', () {
    test('Push L2 capability, Push L3 exercise scores 0 no crash', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);
      final above = createTestExercise(
          id: 'push_l3',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level3);

      expect(() => ExerciseRankingEngine.score(above, ctx), returnsNormally);
      final result = ExerciseRankingEngine.score(above, ctx);
      expect(result.capabilityFitScore, 0);
      expect(result.totalScore, 0);
    });

    test('Above capability does not outrank eligible', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);
      final eligibleL1 = createTestExercise(
          id: 'eligible_l1',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level1);
      final aboveL3 = createTestExercise(
          id: 'above_l3',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level3);

      final ranked = ExerciseRankingEngine.rank([aboveL3, eligibleL1], ctx);
      // eligible should be first (80 vs 0)
      expect(ranked[0].exercise.id, 'eligible_l1');
      expect(ranked[1].exercise.id, 'above_l3');
    });
  });

  group('Missing Capability', () {
    test('incomplete profile missing Push scores 0 no crash', () {
      final now = DateTime.utc(2026, 1, 1);
      final incompleteMap = <MovementPattern, MovementCapability>{
        MovementPattern.squat: MovementCapability(
            movementPattern: MovementPattern.squat,
            level: CapabilityLevel.level3,
            source: CapabilitySource.initialAssessment,
            updatedAt: now),
      };
      final incompleteProfile = CapabilityProfile.fromMap(incompleteMap);
      final ctx =
          ExerciseRankingContext(capabilityProfile: incompleteProfile);
      final pushEx = createTestExercise(
          id: 'push_ex', movementPattern: MovementPattern.push);

      expect(() => ExerciseRankingEngine.score(pushEx, ctx), returnsNormally);
      expect(ExerciseRankingEngine.score(pushEx, ctx).capabilityFitScore, 0);
    });
  });

  group('Null Movement', () {
    test('null movement scores 0 no crash', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);
      final nullEx = createTestExercise(id: 'null', movementPattern: null);

      expect(() => ExerciseRankingEngine.score(nullEx, ctx), returnsNormally);
      expect(ExerciseRankingEngine.score(nullEx, ctx).capabilityFitScore, 0);
    });
  });

  group('Warmup / Cooldown', () {
    test('warmup and cooldown receive neutral 50 without capability', () {
      final incompleteProfile = CapabilityProfile.fromMap({});
      final ctx =
          ExerciseRankingContext(capabilityProfile: incompleteProfile);

      final warmup = createTestExercise(
          id: 'warmup', movementPattern: MovementPattern.warmup);
      final cooldown = createTestExercise(
          id: 'cooldown', movementPattern: MovementPattern.cooldown);

      final warmupResult = ExerciseRankingEngine.score(warmup, ctx);
      final cooldownResult = ExerciseRankingEngine.score(cooldown, ctx);

      expect(warmupResult.capabilityFitScore, 50);
      expect(cooldownResult.capabilityFitScore, 50);
      expect(warmupResult.totalScore, 50);
      expect(cooldownResult.totalScore, 50);
    });
  });

  group('Stable Ties', () {
    test('three exercises equal scores preserve original order', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      // All same difficulty and movement => same score
      final a = createTestExercise(id: 'a', difficulty: ExerciseDifficulty.level2);
      final b = createTestExercise(id: 'b', difficulty: ExerciseDifficulty.level2);
      final c = createTestExercise(id: 'c', difficulty: ExerciseDifficulty.level2);

      final ranked = ExerciseRankingEngine.rank([a, b, c], ctx);
      expect(ranked.length, 3);
      expect(ranked[0].exercise.id, 'a');
      expect(ranked[1].exercise.id, 'b');
      expect(ranked[2].exercise.id, 'c');
      // All same score 80
      expect(ranked[0].capabilityFitScore, 80);
      expect(ranked[1].capabilityFitScore, 80);
      expect(ranked[2].capabilityFitScore, 80);
    });

    test('stable ties with mixed scores', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      final l3a = createTestExercise(id: 'l3a', difficulty: ExerciseDifficulty.level3);
      final l3b = createTestExercise(id: 'l3b', difficulty: ExerciseDifficulty.level3);
      final l2a = createTestExercise(id: 'l2a', difficulty: ExerciseDifficulty.level2);
      final l2b = createTestExercise(id: 'l2b', difficulty: ExerciseDifficulty.level2);

      // Input order: l2a, l3a, l2b, l3b
      // Expected ranking: l3a, l3b (100) preserve input order among ties, then l2a, l2b (80)
      final ranked = ExerciseRankingEngine.rank([l2a, l3a, l2b, l3b], ctx);
      expect(ranked.map((r) => r.exercise.id).toList(),
          ['l3a', 'l3b', 'l2a', 'l2b']);
    });
  });

  group('Input Immutability', () {
    test('ranking does not modify input list', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      final input = [
        createTestExercise(id: 'a', difficulty: ExerciseDifficulty.level1),
        createTestExercise(id: 'b', difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'c', difficulty: ExerciseDifficulty.level2),
      ];
      final originalIds = input.map((e) => e.id).toList();
      ExerciseRankingEngine.rank(input, ctx);
      expect(input.map((e) => e.id).toList(), originalIds);
      expect(input.length, 3);
    });

    test('returned ranked list cannot be externally mutated', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);
      final input = [
        createTestExercise(id: 'a'),
        createTestExercise(id: 'b'),
      ];
      final ranked = ExerciseRankingEngine.rank(input, ctx);
      expect(() => ranked.add(ranked.first), throwsUnsupportedError);
    });
  });

  group('Determinism', () {
    test('ranking twice identical yields identical ordered IDs and scores', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
        MovementPattern.squat: CapabilityLevel.level2,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);

      final input = [
        createTestExercise(
            id: 'push_l1',
            movementPattern: MovementPattern.push,
            difficulty: ExerciseDifficulty.level1),
        createTestExercise(
            id: 'push_l3',
            movementPattern: MovementPattern.push,
            difficulty: ExerciseDifficulty.level3),
        createTestExercise(
            id: 'squat_l2',
            movementPattern: MovementPattern.squat,
            difficulty: ExerciseDifficulty.level2),
      ];

      final first = ExerciseRankingEngine.rank(input, ctx);
      final second = ExerciseRankingEngine.rank(input, ctx);

      expect(first.length, second.length);
      for (int i = 0; i < first.length; i++) {
        expect(first[i].exercise.id, second[i].exercise.id);
        expect(first[i].capabilityFitScore, second[i].capabilityFitScore);
        expect(first[i].totalScore, second[i].totalScore);
      }
    });

    test('single score deterministic', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final ctx = ExerciseRankingContext(capabilityProfile: profile);
      final ex = createTestExercise(id: 'ex', difficulty: ExerciseDifficulty.level2);

      final first = ExerciseRankingEngine.score(ex, ctx);
      final second = ExerciseRankingEngine.score(ex, ctx);

      expect(first.exercise.id, second.exercise.id);
      expect(first.capabilityFitScore, second.capabilityFitScore);
      expect(first.totalScore, second.totalScore);
    });
  });

  group('rankEligible convenience', () {
    test('rankEligible filters then ranks using existing eligibility', () {
      final capabilityProfile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final rankingContext =
          ExerciseRankingContext(capabilityProfile: capabilityProfile);

      final eligibilityContext = ExerciseEligibilityContext(
        capabilityProfile: capabilityProfile,
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
        preferences: {},
      );

      final eligibleL2 = createTestExercise(
          id: 'eligible_l2',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level2);
      final eligibleL1 = createTestExercise(
          id: 'eligible_l1',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level1);
      final ineligibleL3 = createTestExercise(
          id: 'ineligible_l3',
          movementPattern: MovementPattern.push,
          difficulty: ExerciseDifficulty.level3);

      final input = [eligibleL1, ineligibleL3, eligibleL2];
      final ranked = ExerciseRankingEngine.rankEligible(
          input, eligibilityContext, rankingContext);

      // ineligible should be filtered out, and remaining ranked L2 before L1
      expect(ranked.length, 2);
      expect(ranked[0].exercise.id, 'eligible_l2');
      expect(ranked[1].exercise.id, 'eligible_l1');
    });
  });
}
