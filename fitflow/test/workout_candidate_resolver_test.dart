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
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_engine.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTestExercise({
    required String id,
    MovementPattern? movementPattern = MovementPattern.push,
    ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
    Set<String> tags = const {},
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    SpaceRequirement space = SpaceRequirement.small,
    NoiseLevel noise = NoiseLevel.quiet,
    ImpactLevel impact = ImpactLevel.low,
    ExercisePosition? position = ExercisePosition.standing,
    bool active = true,
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
      difficulty: difficulty,
      impactLevel: impact,
      noiseLevel: noise,
      spaceRequirement: space,
      bodyPosition: position,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: equipment,
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: const Duration(seconds: 30),
      tags: tags,
      active: active,
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
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  group('Context', () {
    test('holds exactly supplied profiles and timeBudget matches duration', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile(
        goal: FitnessGoal.buildStrength,
        duration: WorkoutDuration.fifteenMinutes,
      );

      final context = WorkoutGenerationContext(
        userProfile: userProfile,
        capabilityProfile: capabilityProfile,
      );

      expect(identical(context.userProfile, userProfile), true);
      expect(identical(context.capabilityProfile, capabilityProfile), true);
      expect(context.timeBudget.target.inMinutes,
          userProfile.workoutDuration.minutes);
      expect(context.timeBudget.target,
          const Duration(minutes: 15)); // 15 min table
    });
  });

  group('Explicit Warmup Pattern', () {
    test('MovementPattern.warmup appears in warmup not main/cooldown', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final warmupEx = createTestExercise(
          id: 'warmup_explicit', movementPattern: MovementPattern.warmup);

      final candidates =
          WorkoutCandidateResolver.resolve([warmupEx], context);

      expect(candidates.warmup.map((r) => r.exercise.id), contains('warmup_explicit'));
      expect(candidates.main.map((r) => r.exercise.id), isNot(contains('warmup_explicit')));
      expect(candidates.cooldown.map((r) => r.exercise.id), isNot(contains('warmup_explicit')));
    });

    test('March in Place real catalog regression', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level5);
      final userProfile = createUserProfile(
        equipment: {WorkoutEquipment.none},
        environment: TrainingEnvironment.largeRoom,
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final march = ExerciseCatalog.byId('march_in_place')!;
      expect(march.movementPattern, MovementPattern.warmup);

      final candidates =
          WorkoutCandidateResolver.resolve([march], context);

      // Should be eligible in this permissive context
      expect(candidates.warmup.map((r) => r.exercise.id), contains('march_in_place'));
      expect(candidates.main, isNot(contains('march_in_place')));
      expect(candidates.cooldown, isNot(contains('march_in_place')));
    });
  });

  group('Warmup Tag', () {
    test('eligible trainable tagged warmup -> warmup precedence', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final warmupTagged = createTestExercise(
        id: 'warmup_tagged',
        movementPattern: MovementPattern.push, // trainable
        tags: {'warmup', 'bodyweight'},
      );

      final candidates =
          WorkoutCandidateResolver.resolve([warmupTagged], context);

      expect(candidates.warmup.map((r) => r.exercise.id), contains('warmup_tagged'));
      expect(candidates.main.map((r) => r.exercise.id), isNot(contains('warmup_tagged')));
      expect(candidates.cooldown.map((r) => r.exercise.id), isNot(contains('warmup_tagged')));
    });
  });

  group('Explicit Cooldown Pattern', () {
    test('MovementPattern.cooldown appears in cooldown only', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final cooldownEx = createTestExercise(
          id: 'cooldown_explicit', movementPattern: MovementPattern.cooldown);

      final candidates =
          WorkoutCandidateResolver.resolve([cooldownEx], context);

      expect(candidates.cooldown.map((r) => r.exercise.id), contains('cooldown_explicit'));
      expect(candidates.warmup.map((r) => r.exercise.id), isNot(contains('cooldown_explicit')));
      expect(candidates.main.map((r) => r.exercise.id), isNot(contains('cooldown_explicit')));
    });
  });

  group('Cooldown Tag', () {
    test('real catalog cooldown-tagged exercise appears in cooldown not main', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level5);
      final userProfile = createUserProfile(
        equipment: {WorkoutEquipment.none},
        environment: TrainingEnvironment.largeRoom,
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      // Find at least one real exercise with cooldown tag
      final cooldownTagged = ExerciseCatalog.all
          .where((e) => e.tags.contains('cooldown'))
          .toList();
      expect(cooldownTagged, isNotEmpty,
          reason: 'Catalog should have cooldown-tagged exercises');

      final example = cooldownTagged.first;
      final candidates =
          WorkoutCandidateResolver.resolve([example], context);

      // If eligible, should be in cooldown, not main
      // Check eligibility first
      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);
      final eval = ExerciseEligibilityEngine.evaluate(example, eligibilityContext);

      if (eval.eligible) {
        expect(candidates.cooldown.map((r) => r.exercise.id), contains(example.id),
            reason: '${example.id} with cooldown tag should be in cooldown');
        expect(candidates.main.map((r) => r.exercise.id), isNot(contains(example.id)),
            reason: '${example.id} should NOT also be in main');
      } else {
        // If ineligible for some reason, it should be in no pool
        expect(candidates.totalCount, 0);
      }
    });

    test('all cooldown-tagged catalog exercises do not leak into main', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level5);
      final userProfile = createUserProfile(
        equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.largeRoom,
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final candidates = WorkoutCandidateResolver.resolveCatalog(context);

      // Every cooldown-tagged eligible should be in cooldown, not main
      for (final r in candidates.cooldown) {
        expect(r.exercise.tags.contains('cooldown') ||
            r.exercise.movementPattern == MovementPattern.cooldown, true,
            reason: '${r.exercise.id} in cooldown should have cooldown intent');
      }

      // Ensure no cooldown-tagged appears in main
      final mainIds = candidates.main.map((r) => r.exercise.id).toSet();
      for (final r in candidates.cooldown) {
        if (r.exercise.tags.contains('cooldown')) {
          expect(mainIds.contains(r.exercise.id), false,
              reason: '${r.exercise.id} with cooldown tag leaked into main');
        }
      }
    });
  });

  group('Normal Main Exercise', () {
    test('trainable no warmup/cooldown tag -> main only', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final normal = createTestExercise(
        id: 'normal_main',
        movementPattern: MovementPattern.squat,
        tags: {'bodyweight'},
      );

      final candidates = WorkoutCandidateResolver.resolve([normal], context);

      expect(candidates.main.map((r) => r.exercise.id), contains('normal_main'));
      expect(candidates.warmup.map((r) => r.exercise.id), isNot(contains('normal_main')));
      expect(candidates.cooldown.map((r) => r.exercise.id), isNot(contains('normal_main')));
    });
  });

  group('Classification Precedence', () {
    test('trainable + cooldown tag -> cooldown wins over main', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final trainableCooldown = createTestExercise(
        id: 'trainable_cooldown',
        movementPattern: MovementPattern.mobility,
        tags: {'cooldown'},
      );

      final candidates =
          WorkoutCandidateResolver.resolve([trainableCooldown], context);

      expect(candidates.cooldown.map((r) => r.exercise.id), contains('trainable_cooldown'));
      expect(candidates.main.map((r) => r.exercise.id), isNot(contains('trainable_cooldown')));
    });

    test('warmup tag + cooldown tag -> warmup wins deterministically', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final bothTags = createTestExercise(
        id: 'both_tags',
        movementPattern: MovementPattern.push,
        tags: {'warmup', 'cooldown'},
      );

      final candidates = WorkoutCandidateResolver.resolve([bothTags], context);

      expect(candidates.warmup.map((r) => r.exercise.id), contains('both_tags'));
      expect(candidates.main.map((r) => r.exercise.id), isNot(contains('both_tags')));
      expect(candidates.cooldown.map((r) => r.exercise.id), isNot(contains('both_tags')));
    });

    test('explicit warmup pattern + cooldown tag -> warmup wins', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final warmupPatternCooldownTag = createTestExercise(
        id: 'warmup_pattern_cooldown_tag',
        movementPattern: MovementPattern.warmup,
        tags: {'cooldown'},
      );

      final candidates =
          WorkoutCandidateResolver.resolve([warmupPatternCooldownTag], context);

      expect(candidates.warmup.map((r) => r.exercise.id), contains('warmup_pattern_cooldown_tag'));
      expect(candidates.cooldown.map((r) => r.exercise.id), isNot(contains('warmup_pattern_cooldown_tag')));
    });
  });

  group('Ineligible Section-Intent Exercise', () {
    test('warmup intent but fails eligibility appears in no pool', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level1);
      final userProfile = createUserProfile(
        equipment: {}, // no chair
        environment: TrainingEnvironment.normalHome,
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final warmupIneligible = createTestExercise(
        id: 'warmup_ineligible',
        movementPattern: MovementPattern.warmup,
        equipment: {WorkoutEquipment.chair}, // missing
      );

      final candidates =
          WorkoutCandidateResolver.resolve([warmupIneligible], context);

      expect(candidates.totalCount, 0,
          reason: 'Ineligible warmup should be in no pool');

      // Verify against 5A
      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);
      final eval = ExerciseEligibilityEngine.evaluate(warmupIneligible, eligibilityContext);
      expect(eval.eligible, false);
    });

    test('cooldown intent but fails eligibility appears in no pool', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level1);
      final userProfile = createUserProfile(
        equipment: {},
        environment: TrainingEnvironment.apartment, // small max, quiet max
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final cooldownIneligible = createTestExercise(
        id: 'cooldown_ineligible',
        movementPattern: MovementPattern.mobility,
        tags: {'cooldown'},
        space: SpaceRequirement.large, // insufficient for apartment
      );

      final candidates =
          WorkoutCandidateResolver.resolve([cooldownIneligible], context);

      expect(candidates.totalCount, 0);
    });
  });

  group('Restrictive Real Profile', () {
    test('Apartment, no equipment, No Jumping, Low Impact, Standing Only', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level2);
      final userProfile = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.regularTraining,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: {},
        preferences: {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final candidates = WorkoutCandidateResolver.resolveCatalog(context);

      final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      for (final pool in [candidates.warmup, candidates.main, candidates.cooldown]) {
        for (final result in pool) {
          final eval = ExerciseEligibilityEngine.evaluate(result.exercise, eligibilityContext);
          expect(eval.eligible, true,
              reason: '${result.exercise.id} in candidate pool must be eligible');
        }
      }

      // Do not require all three pools non-empty under restrictive profile
      // Just ensure no crash and eligibility invariant
      expect(candidates.totalCount >= 0, true);
    });
  });

  group('Ordering', () {
    test('candidate pools preserve relative order from rankForUser', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile(goal: FitnessGoal.buildStrength);
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final exercises = [
        createTestExercise(id: 'push_l3', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'squat_l2', movementPattern: MovementPattern.squat, difficulty: ExerciseDifficulty.level2),
        createTestExercise(id: 'warmup_a', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'push_l1', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level1),
        createTestExercise(id: 'cooldown_a', movementPattern: MovementPattern.mobility, tags: {'cooldown'}),
        createTestExercise(id: 'balance_l3', movementPattern: MovementPattern.balance, difficulty: ExerciseDifficulty.level3),
      ];

      final ranked = ExerciseRankingEngine.rankForUser(exercises, userProfile, capabilityProfile);
      final candidates = WorkoutCandidateResolver.resolve(exercises, context);

      // For each pool, order should equal relative order of matching items in ranked
      List<String> filterIds(List<String> poolIds, List<String> rankedIds) {
        return rankedIds.where((id) => poolIds.contains(id)).toList();
      }

      final rankedIds = ranked.map((r) => r.exercise.id).toList();

      final warmupIds = candidates.warmup.map((r) => r.exercise.id).toList();
      expect(warmupIds, filterIds(warmupIds, rankedIds));

      final mainIds = candidates.main.map((r) => r.exercise.id).toList();
      expect(mainIds, filterIds(mainIds, rankedIds));

      final cooldownIds = candidates.cooldown.map((r) => r.exercise.id).toList();
      expect(cooldownIds, filterIds(cooldownIds, rankedIds));
    });
  });

  group('Uniqueness', () {
    test('no ID appears in multiple pools', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final exercises = [
        createTestExercise(id: 'warmup1', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'main1', movementPattern: MovementPattern.push),
        createTestExercise(id: 'cooldown1', movementPattern: MovementPattern.mobility, tags: {'cooldown'}),
        createTestExercise(id: 'main2', movementPattern: MovementPattern.squat),
      ];

      final candidates = WorkoutCandidateResolver.resolve(exercises, context);

      final allIds = [
        ...candidates.warmup.map((r) => r.exercise.id),
        ...candidates.main.map((r) => r.exercise.id),
        ...candidates.cooldown.map((r) => r.exercise.id),
      ];

      final uniqueIds = allIds.toSet();
      expect(allIds.length, uniqueIds.length,
          reason: 'No ID should appear in multiple pools');

      // For unique input IDs, combined membership also unique
      expect(uniqueIds.length, candidates.totalCount);
    });

    test('real catalog uniqueness', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level5);
      final userProfile = createUserProfile(
        equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        environment: TrainingEnvironment.largeRoom,
      );
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final candidates = WorkoutCandidateResolver.resolveCatalog(context);

      final allIds = [
        ...candidates.warmup.map((r) => r.exercise.id),
        ...candidates.main.map((r) => r.exercise.id),
        ...candidates.cooldown.map((r) => r.exercise.id),
      ];

      expect(allIds.length, allIds.toSet().length);
    });
  });

  group('Immutability', () {
    test('source list not mutated', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final input = [
        createTestExercise(id: 'a'),
        createTestExercise(id: 'b'),
      ];
      final originalIds = input.map((e) => e.id).toList();

      WorkoutCandidateResolver.resolve(input, context);

      expect(input.map((e) => e.id).toList(), originalIds);
    });

    test('candidate lists immutable', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final input = [
        createTestExercise(id: 'a', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'b', movementPattern: MovementPattern.push),
        createTestExercise(id: 'c', movementPattern: MovementPattern.mobility, tags: {'cooldown'}),
      ];

      final candidates = WorkoutCandidateResolver.resolve(input, context);

      expect(() => candidates.warmup.add(candidates.warmup.first), throwsUnsupportedError);
      expect(() => candidates.main.add(candidates.main.first), throwsUnsupportedError);
      expect(() => candidates.cooldown.add(candidates.cooldown.first), throwsUnsupportedError);
    });

    test('source-list mutation after resolution does not alter result', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final source = [
        createTestExercise(id: 'a', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'b', movementPattern: MovementPattern.push),
      ];

      final candidates = WorkoutCandidateResolver.resolve(source, context);
      final warmupCountBefore = candidates.warmupCount;
      final mainCountBefore = candidates.mainCount;

      source.add(createTestExercise(id: 'c', movementPattern: MovementPattern.push));
      source.clear();

      expect(candidates.warmupCount, warmupCountBefore);
      expect(candidates.mainCount, mainCountBefore);
    });
  });

  group('Determinism', () {
    test('twice identical inputs yields same counts, IDs, scores', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile(goal: FitnessGoal.improveMobility);
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final exercises = [
        createTestExercise(id: 'push_l3', movementPattern: MovementPattern.push, difficulty: ExerciseDifficulty.level3),
        createTestExercise(id: 'warmup', movementPattern: MovementPattern.warmup),
        createTestExercise(id: 'mobility_cooldown', movementPattern: MovementPattern.mobility, tags: {'cooldown'}),
        createTestExercise(id: 'squat_l2', movementPattern: MovementPattern.squat, difficulty: ExerciseDifficulty.level2),
      ];

      final first = WorkoutCandidateResolver.resolve(exercises, context);
      final second = WorkoutCandidateResolver.resolve(exercises, context);

      expect(first.warmupCount, second.warmupCount);
      expect(first.mainCount, second.mainCount);
      expect(first.cooldownCount, second.cooldownCount);

      expect(first.warmup.map((r) => r.exercise.id).toList(),
          second.warmup.map((r) => r.exercise.id).toList());
      expect(first.main.map((r) => r.exercise.id).toList(),
          second.main.map((r) => r.exercise.id).toList());
      expect(first.cooldown.map((r) => r.exercise.id).toList(),
          second.cooldown.map((r) => r.exercise.id).toList());

      for (int i = 0; i < first.main.length; i++) {
        expect(first.main[i].capabilityFitScore, second.main[i].capabilityFitScore);
        expect(first.main[i].goalAffinityScore, second.main[i].goalAffinityScore);
        expect(first.main[i].totalScore, second.main[i].totalScore);
      }
    });
  });

  group('Empty Input', () {
    test('resolve([]) returns empty pools no crash', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level1);
      final userProfile = createUserProfile();
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final candidates = WorkoutCandidateResolver.resolve([], context);

      expect(candidates.warmup, isEmpty);
      expect(candidates.main, isEmpty);
      expect(candidates.cooldown, isEmpty);
      expect(candidates.totalCount, 0);
      expect(candidates.hasWarmupCandidates, false);
      expect(candidates.hasMainCandidates, false);
      expect(candidates.hasCooldownCandidates, false);
    });
  });

  group('Ranking preserved', () {
    test('candidate pools contain ExerciseRankingResult with scores', () {
      final capabilityProfile = createFullProfile(CapabilityLevel.level3);
      final userProfile = createUserProfile(goal: FitnessGoal.buildStrength);
      final context = WorkoutGenerationContext(
          userProfile: userProfile, capabilityProfile: capabilityProfile);

      final ex = createTestExercise(id: 'push_l3', difficulty: ExerciseDifficulty.level3);
      final candidates = WorkoutCandidateResolver.resolve([ex], context);

      expect(candidates.main.length, 1);
      final result = candidates.main.first;
      expect(result.capabilityFitScore, 100);
      expect(result.goalAffinityScore, 15);
      expect(result.totalScore, 115);
    });
  });
}
