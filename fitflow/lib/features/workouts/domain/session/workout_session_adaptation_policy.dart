import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_adaptation.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';

/// Pure deterministic policy for temporary session adaptation.
/// No I/O, no mutation, same inputs → same output.
class WorkoutSessionAdaptationPolicy {
  const WorkoutSessionAdaptationPolicy._();

  static WorkoutSessionAdaptation adapt({
    required WorkoutDuration normalDuration,
    required CapabilityProfile persistedCapability,
    required WorkoutSessionMode mode,
  }) {
    // Defensive copy – original must not be mutated
    final effectiveDuration = _effectiveDuration(normalDuration, mode);
    final effectiveCapability = _effectiveCapability(persistedCapability, mode);

    String? explanation;
    switch (mode) {
      case WorkoutSessionMode.standard:
        explanation = null;
        break;
      case WorkoutSessionMode.lowEnergy:
        explanation = 'Low Energy: shorter and one level easier for today.';
        break;
      case WorkoutSessionMode.comeback:
        explanation = 'Comeback: gentler return after time away, temporary.';
        break;
    }

    return WorkoutSessionAdaptation(
      effectiveWorkoutDuration: effectiveDuration,
      effectiveCapabilityProfile: effectiveCapability,
      explanation: explanation,
    );
  }

  static WorkoutDuration _effectiveDuration(WorkoutDuration normal, WorkoutSessionMode mode) {
    switch (mode) {
      case WorkoutSessionMode.standard:
        return normal;
      case WorkoutSessionMode.lowEnergy:
        switch (normal) {
          case WorkoutDuration.fiveMinutes:
            return WorkoutDuration.fiveMinutes;
          case WorkoutDuration.tenMinutes:
            return WorkoutDuration.fiveMinutes;
          case WorkoutDuration.fifteenMinutes:
            return WorkoutDuration.tenMinutes;
          case WorkoutDuration.twentyMinutes:
            return WorkoutDuration.fifteenMinutes;
          case WorkoutDuration.thirtyMinutes:
            return WorkoutDuration.twentyMinutes;
          case WorkoutDuration.fortyFiveMinutes:
            return WorkoutDuration.thirtyMinutes;
        }
      case WorkoutSessionMode.comeback:
        switch (normal) {
          case WorkoutDuration.fiveMinutes:
            return WorkoutDuration.fiveMinutes;
          case WorkoutDuration.tenMinutes:
            return WorkoutDuration.fiveMinutes;
          case WorkoutDuration.fifteenMinutes:
            return WorkoutDuration.tenMinutes;
          case WorkoutDuration.twentyMinutes:
            return WorkoutDuration.tenMinutes;
          case WorkoutDuration.thirtyMinutes:
            return WorkoutDuration.fifteenMinutes;
          case WorkoutDuration.fortyFiveMinutes:
            return WorkoutDuration.fifteenMinutes;
        }
    }
  }

  static CapabilityProfile _effectiveCapability(CapabilityProfile persisted, WorkoutSessionMode mode) {
    if (mode == WorkoutSessionMode.standard) {
      // Return equal but not identical? For standard, preserve exactly same behavior.
      // To ensure byte-for-byte equality check passes for persisted capability unchanged, we return same instance or equal copy.
      // For generation, we need effective capability == persisted capability.
      return persisted;
    }

    // Reduce every trainable movement by exactly one level, floor Level1
    // Preserve source, updatedAt, anchorExerciseId
    final Map<MovementPattern, MovementCapability> newMap = {};
    for (final pattern in CapabilityProfile.trainablePatterns) {
      final existing = persisted.capabilities[pattern];
      if (existing == null) continue;
      final reducedLevel = _reduceOneLevel(existing.level);
      // Preserve metadata
      final newCap = MovementCapability(
        movementPattern: existing.movementPattern,
        level: reducedLevel,
        source: existing.source,
        updatedAt: existing.updatedAt,
        anchorExerciseId: existing.anchorExerciseId,
      );
      newMap[pattern] = newCap;
    }

    // Ensure we produce a complete valid CapabilityProfile – fromMap will handle
    return CapabilityProfile.fromMap(newMap);
  }

  static CapabilityLevel _reduceOneLevel(CapabilityLevel level) {
    switch (level) {
      case CapabilityLevel.level5:
        return CapabilityLevel.level4;
      case CapabilityLevel.level4:
        return CapabilityLevel.level3;
      case CapabilityLevel.level3:
        return CapabilityLevel.level2;
      case CapabilityLevel.level2:
        return CapabilityLevel.level1;
      case CapabilityLevel.level1:
        return CapabilityLevel.level1;
    }
  }
}
