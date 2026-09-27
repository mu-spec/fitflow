import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTestExercise({
    required String id,
    required MovementPattern? movementPattern,
    required ExerciseDifficulty difficulty,
    Set<WorkoutEquipment> requiredEquipment = const {},
    bool active = true,
  }) {
    return Exercise(
      id: id,
      name: id,
      movementPattern: movementPattern,
      difficulty: difficulty,
      requiredEquipment: requiredEquipment,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: const Duration(seconds: 30),
      active: active,
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

  group('Active', () {
    test('inactive exercise contains inactiveExercise and eligible false', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.none},
      );

      final inactiveExercise = createTestExercise(
        id: 'inactive_test',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
        active: false,
      );

      final result = ExerciseEligibilityEngine.evaluate(inactiveExercise, context);
      expect(result.reasons, contains(ExerciseExclusionReason.inactiveExercise));
      expect(result.eligible, false);
    });

    test('active exercise does not contain inactiveExercise', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final activeExercise = createTestExercise(
        id: 'active_test',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
        active: true,
      );

      final result = ExerciseEligibilityEngine.evaluate(activeExercise, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.inactiveExercise)));
    });
  });

  group('Capability', () {
    test('Push Level 2: Wall Push-Up Level1 does not get aboveCapability', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final wallPushUp = ExerciseCatalog.byId('pushup_wall')!;
      expect(wallPushUp.difficulty, ExerciseDifficulty.level1);
      expect(wallPushUp.movementPattern, MovementPattern.push);

      final result = ExerciseEligibilityEngine.evaluate(wallPushUp, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)));
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingCapability)));
    });

    test('Push Level 2: appropriate Level2 Push passes capability', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final kneePushUp = ExerciseCatalog.byId('pushup_knee')!;
      expect(kneePushUp.difficulty, ExerciseDifficulty.level2);

      final result = ExerciseEligibilityEngine.evaluate(kneePushUp, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)));
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingCapability)));
      expect(result.eligible, true);
    });

    test('Push Level 2: Standard Push-Up Level3 gets aboveCapability', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final standardPushUp = ExerciseCatalog.byId('pushup_standard')!;
      expect(standardPushUp.difficulty, ExerciseDifficulty.level3);

      final result = ExerciseEligibilityEngine.evaluate(standardPushUp, context);
      expect(result.reasons, contains(ExerciseExclusionReason.aboveCapability));
      expect(result.eligible, false);
    });

    test('Push Level 3: Standard Push-Up does not get aboveCapability', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level3,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final standardPushUp = ExerciseCatalog.byId('pushup_standard')!;
      final result = ExerciseEligibilityEngine.evaluate(standardPushUp, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)));
      expect(result.eligible, true);
    });
  });

  group('Independent capability', () {
    test('Level 4 squat uses Squat capability not Push', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level2,
        MovementPattern.squat: CapabilityLevel.level4,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final squatLevel4 = createTestExercise(
        id: 'squat_level4_test',
        movementPattern: MovementPattern.squat,
        difficulty: ExerciseDifficulty.level4,
      );

      final result = ExerciseEligibilityEngine.evaluate(squatLevel4, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)),
          reason: 'Squat L4 should pass with Squat L4 capability even if Push is L2');
      expect(result.eligible, true);

      // Also verify Push L4 would fail with Push L2
      final pushLevel4 = createTestExercise(
        id: 'push_level4_test',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level4,
      );
      final pushResult = ExerciseEligibilityEngine.evaluate(pushLevel4, context);
      expect(pushResult.reasons, contains(ExerciseExclusionReason.aboveCapability));
    });
  });

  group('Missing capability', () {
    test('incomplete profile exercise for missing movement gets missingCapability', () {
      final now = DateTime.utc(2026, 1, 1);
      final full = CapabilityProfile.initial(updatedAt: now);
      // Create map missing push
      final incompleteMap = <MovementPattern, MovementCapability>{};
      for (final p in CapabilityProfile.trainablePatterns) {
        if (p == MovementPattern.push) continue;
        incompleteMap[p] = full.capabilityFor(p)!;
      }
      final incompleteProfile = CapabilityProfile.fromMap(incompleteMap);
      expect(incompleteProfile.isComplete, false);

      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final pushExercise = createTestExercise(
        id: 'push_missing_cap',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
      );

      final result = ExerciseEligibilityEngine.evaluate(pushExercise, context);
      expect(result.reasons, contains(ExerciseExclusionReason.missingCapability));
      expect(result.eligible, false);
    });

    test('does not crash for missing capability', () {
      final now = DateTime.utc(2026, 1, 1);
      final incompleteProfile = CapabilityProfile.fromMap({
        MovementPattern.pull: MovementCapability(
          movementPattern: MovementPattern.pull,
          level: CapabilityLevel.level1,
          source: CapabilitySource.initialAssessment,
          updatedAt: now,
        ),
      });

      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final exercise = createTestExercise(
        id: 'test',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
      );

      expect(() => ExerciseEligibilityEngine.evaluate(exercise, context), returnsNormally);
    });
  });

  group('Warmup/cooldown', () {
    test('warmup does not require capability', () {
      final incompleteProfile = CapabilityProfile.fromMap({});
      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final warmupExercise = createTestExercise(
        id: 'warmup_test',
        movementPattern: MovementPattern.warmup,
        difficulty: ExerciseDifficulty.level1,
      );

      final result = ExerciseEligibilityEngine.evaluate(warmupExercise, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingCapability)));
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)));
    });

    test('cooldown does not require capability', () {
      final incompleteProfile = CapabilityProfile.fromMap({});
      final context = ExerciseEligibilityContext(
        capabilityProfile: incompleteProfile,
        availableEquipment: {},
      );

      final cooldownExercise = createTestExercise(
        id: 'cooldown_test',
        movementPattern: MovementPattern.cooldown,
        difficulty: ExerciseDifficulty.level5,
      );

      final result = ExerciseEligibilityEngine.evaluate(cooldownExercise, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingCapability)));
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.aboveCapability)));
    });

    test('warmup still goes through equipment rule', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final warmupWithChair = createTestExercise(
        id: 'warmup_chair',
        movementPattern: MovementPattern.warmup,
        difficulty: ExerciseDifficulty.level1,
        requiredEquipment: {WorkoutEquipment.chair},
      );

      final result = ExerciseEligibilityEngine.evaluate(warmupWithChair, context);
      expect(result.reasons, contains(ExerciseExclusionReason.missingEquipment));
    });
  });

  group('Equipment', () {
    test('No equipment: Standard Push-Up passes, Chair Dip missing, Towel Row missing', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {}, // no equipment
      );

      final standardPushUp = ExerciseCatalog.byId('pushup_standard')!;
      final chairDip = ExerciseCatalog.byId('dip_chair')!;
      final towelRow = ExerciseCatalog.byId('row_towel')!;

      final pushResult = ExerciseEligibilityEngine.evaluate(standardPushUp, context);
      // Standard Push-Up requires none, so should not have missingEquipment
      expect(pushResult.reasons, isNot(contains(ExerciseExclusionReason.missingEquipment)));

      final dipResult = ExerciseEligibilityEngine.evaluate(chairDip, context);
      expect(dipResult.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(dipResult.missingEquipment, contains(WorkoutEquipment.chair));

      final rowResult = ExerciseEligibilityEngine.evaluate(towelRow, context);
      expect(rowResult.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(rowResult.missingEquipment, contains(WorkoutEquipment.towel));
    });

    test('Chair available: Chair Dip passes equipment', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.chair},
      );

      final chairDip = ExerciseCatalog.byId('dip_chair')!;
      final result = ExerciseEligibilityEngine.evaluate(chairDip, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingEquipment)));
    });

    test('Towel available: Towel Row passes equipment', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.towel},
      );

      final towelRow = ExerciseCatalog.byId('row_towel')!;
      final result = ExerciseEligibilityEngine.evaluate(towelRow, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingEquipment)));
    });

    test('multiple equipment required: all must be present', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final contextChairOnly = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.chair},
      );
      final contextBoth = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {WorkoutEquipment.chair, WorkoutEquipment.towel},
      );

      final multiEquipExercise = createTestExercise(
        id: 'multi_equip',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
        requiredEquipment: {WorkoutEquipment.chair, WorkoutEquipment.towel},
      );

      final resultChairOnly =
          ExerciseEligibilityEngine.evaluate(multiEquipExercise, contextChairOnly);
      expect(resultChairOnly.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(resultChairOnly.missingEquipment, contains(WorkoutEquipment.towel));

      final resultBoth =
          ExerciseEligibilityEngine.evaluate(multiEquipExercise, contextBoth);
      expect(resultBoth.reasons, isNot(contains(ExerciseExclusionReason.missingEquipment)));
    });

    test('none equipment treated as requiring nothing', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final noneEquipExercise = createTestExercise(
        id: 'none_equip',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level1,
        requiredEquipment: {WorkoutEquipment.none},
      );

      final result = ExerciseEligibilityEngine.evaluate(noneEquipExercise, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.missingEquipment)));
    });
  });

  group('Multiple reasons', () {
    test('one result can contain inactive, aboveCapability, missingEquipment', () {
      final profile = createProfileWithLevels({
        MovementPattern.push: CapabilityLevel.level1,
      });
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {}, // no chair
      );

      final exercise = createTestExercise(
        id: 'multi_reason',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level5, // above L1
        requiredEquipment: {WorkoutEquipment.chair},
        active: false, // inactive
      );

      final result = ExerciseEligibilityEngine.evaluate(exercise, context);
      expect(result.reasons, contains(ExerciseExclusionReason.inactiveExercise));
      expect(result.reasons, contains(ExerciseExclusionReason.aboveCapability));
      expect(result.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(result.reasons.length, 3);
      expect(result.eligible, false);
    });
  });

  group('Immutability', () {
    test('exclusion reasons cannot be externally mutated', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: {},
      );

      final exercise = createTestExercise(
        id: 'immutable_test',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level5,
        requiredEquipment: {WorkoutEquipment.chair},
        active: false,
      );

      final result = ExerciseEligibilityEngine.evaluate(exercise, context);
      expect(() => result.reasons.add(ExerciseExclusionReason.inactiveExercise),
          throwsUnsupportedError);
      expect(() => result.missingEquipment.add(WorkoutEquipment.chair),
          throwsUnsupportedError);
    });

    test('available equipment in context cannot be externally mutated', () {
      final profile = CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final mutableSet = {WorkoutEquipment.chair};
      final context = ExerciseEligibilityContext(
        capabilityProfile: profile,
        availableEquipment: mutableSet,
      );

      // Mutate original set after creation
      mutableSet.add(WorkoutEquipment.towel);
      expect(context.availableEquipment, isNot(contains(WorkoutEquipment.towel)));

      // Try to mutate via getter
      expect(() => context.availableEquipment.add(WorkoutEquipment.towel),
          throwsUnsupportedError);
    });

    test('context fromProfiles equipment immutable', () {
      final now = DateTime.utc(2026, 1, 1);
      final userProfile = createUserProfileWithEquipment({WorkoutEquipment.chair});
      final capabilityProfile = CapabilityProfile.initial(updatedAt: now);
      final context = ExerciseEligibilityContext.fromProfiles(
        userProfile: userProfile,
        capabilityProfile: capabilityProfile,
      );

      expect(() => context.availableEquipment.add(WorkoutEquipment.towel),
          throwsUnsupportedError);
    });
  });

  group('Context fromProfiles', () {
    test('extracts equipment from UserFitnessProfile', () {
      final userProfile = createUserProfileWithEquipment(
          {WorkoutEquipment.chair, WorkoutEquipment.towel});
      final capabilityProfile =
          CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));
      final context = ExerciseEligibilityContext.fromProfiles(
        userProfile: userProfile,
        capabilityProfile: capabilityProfile,
      );

      expect(context.availableEquipment, contains(WorkoutEquipment.chair));
      expect(context.availableEquipment, contains(WorkoutEquipment.towel));
      expect(context.capabilityProfile, capabilityProfile);
    });
  });
}

UserFitnessProfile createUserProfileWithEquipment(Set<WorkoutEquipment> equipment) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: equipment,
  );
}
