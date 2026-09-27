import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_result.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Core deterministic eligibility engine (5A-1 only).
///
/// Considers:
/// - active status
/// - movement-specific capability (trainable only)
/// - required equipment
///
/// Environment/preferences will be added in 5A-2.
class ExerciseEligibilityEngine {
  const ExerciseEligibilityEngine._();

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
    // Treat WorkoutEquipment.none as requiring nothing
    final required = exercise.requiredEquipment;
    // Filter out none
    final effectiveRequired = required
        .where((e) => e != WorkoutEquipment.none)
        .toSet();

    if (effectiveRequired.isNotEmpty) {
      // All must be present
      final missing = effectiveRequired
          .where((e) => !context.availableEquipment.contains(e))
          .toSet();
      if (missing.isNotEmpty) {
        reasons.add(ExerciseExclusionReason.missingEquipment);
        missingEquipment.addAll(missing);
      }
    }

    // Capability rule – trainable patterns only
    final pattern = exercise.movementPattern;
    if (pattern != null && _isTrainable(pattern)) {
      final capability = context.capabilityProfile.capabilityFor(pattern);
      if (capability == null) {
        reasons.add(ExerciseExclusionReason.missingCapability);
      } else {
        // exercise difficulty <= movement capability
        // Compare via index (both enums ordered level1..level5)
        final exerciseRank = exercise.difficulty.index;
        final capabilityRank = capability.level.index;
        if (exerciseRank > capabilityRank) {
          reasons.add(ExerciseExclusionReason.aboveCapability);
        }
      }
    }
    // Warmup/cooldown do NOT require capability – skipped

    return ExerciseEligibilityResult(
      exercise: exercise,
      reasons: reasons,
      missingEquipment: missingEquipment,
    );
  }

  static bool _isTrainable(MovementPattern pattern) {
    return CapabilityProfile.trainablePatterns.contains(pattern);
  }
}
