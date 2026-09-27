import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_result.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';

/// Deterministic eligibility engine (5A-3 extended with No Jumping).
///
/// Considers:
/// - active status
/// - movement-specific capability (trainable only) using explicit mapping
/// - required equipment
/// - environment space limits
/// - environment noise limits (apartment/hotel only)
/// - Low Impact, No Floor, Standing Only, Avoid Wrist-Heavy, Avoid Deep Knee Bending
/// - No Jumping (metadata-driven, explicit override, high-impact fallback)
class ExerciseEligibilityEngine {
  const ExerciseEligibilityEngine._();

  // Canonical tags used by catalog for jumping classification
  static const String _noJumpingTag = 'no_jumping';
  static const String _jumpingTag = 'jumping';

  static bool _hasExplicitJumpingTag(Exercise exercise) {
    // Use actual jump-related tags present in catalog, never name-based
    return exercise.tags.contains(_jumpingTag);
  }

  /// Evaluates [exercise] against [context] deterministically.
  ///
  /// Returns a result that may contain multiple exclusion reasons.
  /// Same inputs → same result, read-only, no randomness.
  static ExerciseEligibilityResult evaluate(
    Exercise exercise,
    ExerciseEligibilityContext context,
  ) {
    final reasons = <ExerciseExclusionReason>{};
    final missingEquipment = <WorkoutEquipment>{};

    // Active rule – continue evaluating other rules
    if (!exercise.active) {
      reasons.add(ExerciseExclusionReason.inactiveExercise);
    }

    // Equipment rule
    final required = exercise.requiredEquipment;
    final effectiveRequired = required
        .where((e) => e != WorkoutEquipment.none)
        .toSet();

    if (effectiveRequired.isNotEmpty) {
      final missing = effectiveRequired
          .where((e) => !context.availableEquipment.contains(e))
          .toSet();
      if (missing.isNotEmpty) {
        reasons.add(ExerciseExclusionReason.missingEquipment);
        missingEquipment.addAll(missing);
      }
    }

    // Capability rule – trainable patterns only, using explicit mapping (no .index)
    final pattern = exercise.movementPattern;
    if (pattern != null && _isTrainable(pattern)) {
      final capability = context.capabilityProfile.capabilityFor(pattern);
      if (capability == null) {
        reasons.add(ExerciseExclusionReason.missingCapability);
      } else {
        // Use existing 4A mapping: capability.level.toExerciseDifficulty()
        // Compare via stable explicit rank helpers (not enum .index)
        final capabilityDifficulty = capability.level.toExerciseDifficulty();
        final exerciseRank = _exerciseDifficultyRank(exercise.difficulty);
        final capabilityRank = _exerciseDifficultyRank(capabilityDifficulty);
        if (exerciseRank > capabilityRank) {
          reasons.add(ExerciseExclusionReason.aboveCapability);
        }
      }
    }

    // Environment space limits
    final maxSpace = _maxSpaceForEnvironment(context.environment);
    final exerciseSpaceRank = _spaceRequirementRank(exercise.spaceRequirement);
    final maxSpaceRank = _spaceRequirementRank(maxSpace);
    if (exerciseSpaceRank > maxSpaceRank) {
      reasons.add(ExerciseExclusionReason.insufficientSpace);
    }

    // Environment noise limits – only apartment/hotel impose quiet max
    final maxNoise = _maxNoiseForEnvironment(context.environment);
    if (maxNoise != null) {
      final exerciseNoiseRank = _noiseLevelRank(exercise.noiseLevel);
      final maxNoiseRank = _noiseLevelRank(maxNoise);
      if (exerciseNoiseRank > maxNoiseRank) {
        reasons.add(ExerciseExclusionReason.tooNoisy);
      }
    }

    // Low Impact preference
    if (context.preferences.contains(WorkoutPreference.lowImpact)) {
      if (exercise.impactLevel != ImpactLevel.low) {
        reasons.add(ExerciseExclusionReason.lowImpactRequired);
      }
    }

    // No Floor Exercises preference – reject floor and kneeling
    if (context.preferences.contains(WorkoutPreference.noFloorExercises)) {
      final pos = exercise.bodyPosition;
      if (pos == ExercisePosition.floor || pos == ExercisePosition.kneeling) {
        reasons.add(ExerciseExclusionReason.floorRestricted);
      }
    }

    // Standing Only preference – require exactly standing
    if (context.preferences.contains(WorkoutPreference.standingOnly)) {
      if (exercise.bodyPosition != ExercisePosition.standing) {
        reasons.add(ExerciseExclusionReason.standingOnlyRequired);
      }
    }

    // Avoid Wrist-Heavy – reject only high wrist load
    if (context.preferences.contains(WorkoutPreference.avoidWristHeavy)) {
      if (exercise.wristLoad == JointLoad.high) {
        reasons.add(ExerciseExclusionReason.wristLoadRestricted);
      }
    }

    // Avoid Deep Knee Bending – for this milestone reject high knee load only
    if (context.preferences.contains(WorkoutPreference.avoidDeepKneeBending)) {
      if (exercise.kneeLoad == JointLoad.high) {
        reasons.add(ExerciseExclusionReason.kneeLoadRestricted);
      }
    }

    // No Jumping preference – metadata-driven, never name-based
    if (context.preferences.contains(WorkoutPreference.noJumping)) {
      // Explicit no_jumping override takes priority
      if (!exercise.tags.contains(_noJumpingTag)) {
        // Explicit jumping metadata
        if (_hasExplicitJumpingTag(exercise)) {
          reasons.add(ExerciseExclusionReason.jumpingRestricted);
        } else if (exercise.impactLevel == ImpactLevel.high) {
          // High-impact fallback when no explicit no_jumping metadata
          reasons.add(ExerciseExclusionReason.jumpingRestricted);
        }
      }
    }

    return ExerciseEligibilityResult(
      exercise: exercise,
      reasons: reasons,
      missingEquipment: missingEquipment,
    );
  }

  static bool _isTrainable(MovementPattern pattern) {
    return CapabilityProfile.trainablePatterns.contains(pattern);
  }

  // --- Centralized rank helpers (no scattered switch) ---

  static int _exerciseDifficultyRank(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.level1:
        return 1;
      case ExerciseDifficulty.level2:
        return 2;
      case ExerciseDifficulty.level3:
        return 3;
      case ExerciseDifficulty.level4:
        return 4;
      case ExerciseDifficulty.level5:
        return 5;
    }
  }

  static int _spaceRequirementRank(SpaceRequirement req) {
    switch (req) {
      case SpaceRequirement.tiny:
        return 1;
      case SpaceRequirement.small:
        return 2;
      case SpaceRequirement.medium:
        return 3;
      case SpaceRequirement.large:
        return 4;
    }
  }

  static SpaceRequirement _maxSpaceForEnvironment(TrainingEnvironment env) {
    switch (env) {
      case TrainingEnvironment.apartment:
        return SpaceRequirement.small;
      case TrainingEnvironment.smallRoom:
        return SpaceRequirement.small;
      case TrainingEnvironment.hotel:
        return SpaceRequirement.small;
      case TrainingEnvironment.normalHome:
        return SpaceRequirement.medium;
      case TrainingEnvironment.largeRoom:
        return SpaceRequirement.large;
      case TrainingEnvironment.outdoor:
        return SpaceRequirement.large;
    }
  }

  static int _noiseLevelRank(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet:
        return 1;
      case NoiseLevel.moderate:
        return 2;
      case NoiseLevel.loud:
        return 3;
    }
  }

  static NoiseLevel? _maxNoiseForEnvironment(TrainingEnvironment env) {
    switch (env) {
      case TrainingEnvironment.apartment:
        return NoiseLevel.quiet;
      case TrainingEnvironment.hotel:
        return NoiseLevel.quiet;
      case TrainingEnvironment.normalHome:
      case TrainingEnvironment.smallRoom:
      case TrainingEnvironment.largeRoom:
      case TrainingEnvironment.outdoor:
        return null; // No additional noise restriction in 5A-2
    }
  }
}
