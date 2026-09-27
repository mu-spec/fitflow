import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter/foundation.dart';

/// Immutable ranking context for 5B-2.
///
/// Contains capability profile and fitness goal.
/// Goal defaults to generalFitness for backward compatibility.
@immutable
class ExerciseRankingContext {
  const ExerciseRankingContext({
    required this.capabilityProfile,
    this.goal = FitnessGoal.generalFitness,
  });

  final CapabilityProfile capabilityProfile;

  /// User's fitness goal for goal-affinity scoring.
  final FitnessGoal goal;

  /// Factory extracting goal and capability from existing profiles.
  factory ExerciseRankingContext.fromProfiles({
    required UserFitnessProfile userProfile,
    required CapabilityProfile capabilityProfile,
  }) {
    return ExerciseRankingContext(
      capabilityProfile: capabilityProfile,
      goal: userProfile.goal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseRankingContext) return false;
    return capabilityProfile == other.capabilityProfile && goal == other.goal;
  }

  @override
  int get hashCode => Object.hash(capabilityProfile, goal);

  @override
  String toString() =>
      'ExerciseRankingContext(capabilityProfile: $capabilityProfile, goal: $goal)';
}
