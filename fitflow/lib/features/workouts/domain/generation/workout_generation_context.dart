import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:flutter/foundation.dart';

/// Immutable generation context for 5D-1.
///
/// Holds user profile and capability profile.
/// Time budget derived from user's workoutDuration via existing factory.
@immutable
class WorkoutGenerationContext {
  const WorkoutGenerationContext({
    required this.userProfile,
    required this.capabilityProfile,
  });

  final UserFitnessProfile userProfile;
  final CapabilityProfile capabilityProfile;

  /// Derived time budget using existing budget factory (no duplication).
  WorkoutTimeBudget get timeBudget =>
      WorkoutTimeBudget.fromWorkoutDuration(userProfile.workoutDuration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutGenerationContext) return false;
    return userProfile == other.userProfile &&
        capabilityProfile == other.capabilityProfile;
  }

  @override
  int get hashCode => Object.hash(userProfile, capabilityProfile);

  @override
  String toString() =>
      'WorkoutGenerationContext(userProfile: ${userProfile.goal}, workoutDuration: ${userProfile.workoutDuration}, capabilityProfile: $capabilityProfile, timeBudget: $timeBudget)';
}
