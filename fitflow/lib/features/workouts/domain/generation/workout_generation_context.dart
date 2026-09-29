import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_adaptation_policy.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:flutter/foundation.dart';

/// Immutable generation context for 5D-1 + M12 session mode.
/// Holds user profile, capability profile, and temporary session mode.
/// Time budget derived from effectiveWorkoutDuration, not permanent profile duration.
@immutable
class WorkoutGenerationContext {
  const WorkoutGenerationContext({
    required this.userProfile,
    required this.capabilityProfile,
    this.sessionMode = WorkoutSessionMode.standard,
  });

  final UserFitnessProfile userProfile;
  final CapabilityProfile capabilityProfile;
  final WorkoutSessionMode sessionMode;

  /// Effective workout duration after temporary adaptation.
  WorkoutDuration get effectiveWorkoutDuration {
    final adaptation = WorkoutSessionAdaptationPolicy.adapt(
      normalDuration: userProfile.workoutDuration,
      persistedCapability: capabilityProfile,
      mode: sessionMode,
    );
    return adaptation.effectiveWorkoutDuration;
  }

  /// Temporary effective capability for generation only, preserves metadata.
  CapabilityProfile get effectiveCapabilityProfile {
    final adaptation = WorkoutSessionAdaptationPolicy.adapt(
      normalDuration: userProfile.workoutDuration,
      persistedCapability: capabilityProfile,
      mode: sessionMode,
    );
    return adaptation.effectiveCapabilityProfile;
  }

  /// Derived time budget using effective duration (M12).
  WorkoutTimeBudget get timeBudget => WorkoutTimeBudget.fromWorkoutDuration(effectiveWorkoutDuration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutGenerationContext) return false;
    return userProfile == other.userProfile &&
        capabilityProfile == other.capabilityProfile &&
        sessionMode == other.sessionMode;
  }

  @override
  int get hashCode => Object.hash(userProfile, capabilityProfile, sessionMode);

  @override
  String toString() =>
      'WorkoutGenerationContext(userProfile: ${userProfile.goal}, workoutDuration: ${userProfile.workoutDuration}, effectiveDuration: $effectiveWorkoutDuration, capabilityProfile: $capabilityProfile, effectiveCapability: $effectiveCapabilityProfile, sessionMode: $sessionMode, timeBudget: $timeBudget)';
}
