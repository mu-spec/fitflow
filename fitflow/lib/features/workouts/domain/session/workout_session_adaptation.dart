import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter/foundation.dart';

/// Result of adaptation policy – effective duration + temporary capability.
@immutable
class WorkoutSessionAdaptation {
  const WorkoutSessionAdaptation({
    required this.effectiveWorkoutDuration,
    required this.effectiveCapabilityProfile,
    this.explanation,
  });

  final WorkoutDuration effectiveWorkoutDuration;
  final CapabilityProfile effectiveCapabilityProfile;
  final String? explanation;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutSessionAdaptation) return false;
    return effectiveWorkoutDuration == other.effectiveWorkoutDuration &&
        effectiveCapabilityProfile == other.effectiveCapabilityProfile &&
        explanation == other.explanation;
  }

  @override
  int get hashCode => Object.hash(effectiveWorkoutDuration, effectiveCapabilityProfile, explanation);
}
