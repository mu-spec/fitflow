import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise createTestExercise({
    required String id,
    String? name,
    MovementPattern? movementPattern = MovementPattern.cardio,
    ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
    ImpactLevel impact = ImpactLevel.low,
    Set<String> tags = const {},
  }) {
    return Exercise(
      id: id,
      name: name ?? id,
      movementPattern: movementPattern,
      difficulty: difficulty,
      impactLevel: impact,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      bodyPosition: ExercisePosition.standing,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: const Duration(seconds: 30),
      tags: tags,
      active: true,
    );
  }

  CapabilityProfile fullProfile() =>
      CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1));

  ExerciseEligibilityContext contextWithNoJumping() {
    return ExerciseEligibilityContext(
      capabilityProfile: fullProfile(),
      availableEquipment: {},
      environment: TrainingEnvironment.normalHome,
      preferences: {WorkoutPreference.noJumping},
    );
  }

  ExerciseEligibilityContext contextWithoutNoJumping() {
    return ExerciseEligibilityContext(
      capabilityProfile: fullProfile(),
      availableEquipment: {},
      environment: TrainingEnvironment.normalHome,
      preferences: {},
    );
  }

  group('Preference absent', () {
    test('Without noJumping, Jumping Jacks does NOT get jumpingRestricted', () {
      final context = contextWithoutNoJumping();
      final jumpingJacks = ExerciseCatalog.byId('jumping_jacks')!;
      final result = ExerciseEligibilityEngine.evaluate(jumpingJacks, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Jumping Jacks', () {
    test('With noJumping, Jumping Jacks gets jumpingRestricted', () {
      final context = contextWithNoJumping();
      final jumpingJacks = ExerciseCatalog.byId('jumping_jacks')!;
      final result = ExerciseEligibilityEngine.evaluate(jumpingJacks, context);
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
      expect(result.eligible, false);
    });
  });

  group('Step Jack', () {
    test('With noJumping, Step Jack does NOT get jumpingRestricted', () {
      final context = contextWithNoJumping();
      final stepJack = ExerciseCatalog.byId('step_jack')!;
      final result = ExerciseEligibilityEngine.evaluate(stepJack, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Low-Impact Burpee', () {
    test('With noJumping, Low-Impact Burpee does NOT get jumpingRestricted', () {
      final context = contextWithNoJumping();
      final burpee = ExerciseCatalog.byId('burpee_low_impact')!;
      final result = ExerciseEligibilityEngine.evaluate(burpee, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Standing Mountain Climber', () {
    test('With noJumping, Standing Mountain Climber does NOT get jumpingRestricted', () {
      final context = contextWithNoJumping();
      final standingMc = ExerciseCatalog.byId('mountain_climber_standing')!;
      final result = ExerciseEligibilityEngine.evaluate(standingMc, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Explicit override', () {
    test('high impact but tagged no_jumping does NOT get jumpingRestricted', () {
      final context = contextWithNoJumping();
      final highImpactNoJump = createTestExercise(
        id: 'high_impact_no_jumping',
        impact: ImpactLevel.high,
        tags: {'no_jumping', 'bodyweight'},
      );

      final result = ExerciseEligibilityEngine.evaluate(highImpactNoJump, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('High-impact fallback', () {
    test('high-impact without no_jumping gets jumpingRestricted', () {
      final context = contextWithNoJumping();
      final highImpact = createTestExercise(
        id: 'high_impact',
        impact: ImpactLevel.high,
        tags: {'bodyweight'},
      );

      final result = ExerciseEligibilityEngine.evaluate(highImpact, context);
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
    });

    test('moderate impact without jump tag does NOT get jumpingRestricted', () {
      final context = contextWithNoJumping();
      final moderate = createTestExercise(
        id: 'moderate_no_jump_tag',
        impact: ImpactLevel.moderate,
        tags: {'bodyweight'},
      );

      final result = ExerciseEligibilityEngine.evaluate(moderate, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Explicit jumping tag', () {
    test('exercise with canonical jumping tag gets jumpingRestricted', () {
      final context = contextWithNoJumping();
      final jumpingTagged = createTestExercise(
        id: 'explicit_jumping',
        impact: ImpactLevel.low, // low impact but explicit jumping tag
        tags: {'jumping', 'bodyweight'},
      );

      final result = ExerciseEligibilityEngine.evaluate(jumpingTagged, context);
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
    });

    test('moderate impact with jumping tag gets jumpingRestricted', () {
      final context = contextWithNoJumping();
      final mountainClimbers = ExerciseCatalog.byId('mountain_climbers')!;
      // mountain_climbers is moderate + jumping
      expect(mountainClimbers.impactLevel, ImpactLevel.moderate);
      expect(mountainClimbers.tags, contains('jumping'));

      final result = ExerciseEligibilityEngine.evaluate(mountainClimbers, context);
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
    });
  });

  group('No name heuristic', () {
    test('exercise with Jump in name but low impact and no jump metadata NOT rejected', () {
      final context = contextWithNoJumping();
      final jumpNameLowImpact = createTestExercise(
        id: 'test_jump_name',
        name: 'Super Jump Extravaganza',
        impact: ImpactLevel.low,
        tags: {'bodyweight'},
      );

      final result = ExerciseEligibilityEngine.evaluate(jumpNameLowImpact, context);
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
    });
  });

  group('Combined reasons', () {
    test('No Jumping can coexist with existing exclusion reasons', () {
      final context = ExerciseEligibilityContext(
        capabilityProfile: CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 1, 1)),
        availableEquipment: {}, // missing chair
        environment: TrainingEnvironment.apartment, // small max
        preferences: {WorkoutPreference.noJumping},
      );

      final exercise2 = Exercise(
        id: 'combined_jump',
        name: 'combined_jump',
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level5,
        impactLevel: ImpactLevel.high,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.large,
        bodyPosition: ExercisePosition.standing,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        requiredEquipment: {WorkoutEquipment.chair},
        exerciseType: ExerciseType.reps,
        defaultReps: 10,
        defaultRest: const Duration(seconds: 30),
        tags: {'jumping'},
        active: true,
      );

      final result = ExerciseEligibilityEngine.evaluate(exercise2, context);
      expect(result.reasons, contains(ExerciseExclusionReason.aboveCapability));
      expect(result.reasons, contains(ExerciseExclusionReason.missingEquipment));
      expect(result.reasons, contains(ExerciseExclusionReason.insufficientSpace));
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
    });
  });

  group('Interaction with Low Impact', () {
    test('exercise may receive both jumpingRestricted and lowImpactRequired', () {
      final context = ExerciseEligibilityContext(
        capabilityProfile: fullProfile(),
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
        preferences: {WorkoutPreference.noJumping, WorkoutPreference.lowImpact},
      );

      final highImpactJumping = createTestExercise(
        id: 'high_jump',
        impact: ImpactLevel.high,
        tags: {'jumping'},
      );

      final result = ExerciseEligibilityEngine.evaluate(highImpactJumping, context);
      expect(result.reasons, contains(ExerciseExclusionReason.jumpingRestricted));
      expect(result.reasons, contains(ExerciseExclusionReason.lowImpactRequired));
    });

    test('no_jumping override does NOT bypass Low Impact', () {
      final context = ExerciseEligibilityContext(
        capabilityProfile: fullProfile(),
        availableEquipment: {},
        environment: TrainingEnvironment.normalHome,
        preferences: {WorkoutPreference.noJumping, WorkoutPreference.lowImpact},
      );

      final highImpactNoJump = createTestExercise(
        id: 'high_no_jump',
        impact: ImpactLevel.high,
        tags: {'no_jumping'},
      );

      final result = ExerciseEligibilityEngine.evaluate(highImpactNoJump, context);
      // Should NOT have jumpingRestricted due to override
      expect(result.reasons, isNot(contains(ExerciseExclusionReason.jumpingRestricted)));
      // But SHOULD have lowImpactRequired because high impact
      expect(result.reasons, contains(ExerciseExclusionReason.lowImpactRequired));
    });
  });
}
