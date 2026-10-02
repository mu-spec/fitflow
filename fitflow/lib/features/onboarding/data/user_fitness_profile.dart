import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:flutter/foundation.dart';

/// The user's FitFlow fitness profile.
///
/// Created from the onboarding selections and editable from the Profile tab
/// (M19). Persisted as a single JSON object under
/// `UserFitnessProfileStorage.profileKey` (`user_fitness_profile`) — this is
/// the app's only persisted profile object; there is one profile per device.
class UserFitnessProfile {
  UserFitnessProfile({
    required this.goal,
    required this.experience,
    required this.workoutDuration,
    required this.environment,
    Set<WorkoutEquipment> equipment = const {},
    Set<WorkoutPreference> preferences = const {},
  }) : equipment = Set<WorkoutEquipment>.unmodifiable(equipment),
       preferences = Set<WorkoutPreference>.unmodifiable(preferences);

  /// Main training goal.
  final FitnessGoal goal;

  /// Current experience level.
  final ExperienceLevel experience;

  /// Typical available workout time.
  final WorkoutDuration workoutDuration;

  /// Usual training environment.
  final TrainingEnvironment environment;

  /// Equipment the user has available. Unmodifiable; never mutated after
  /// construction (externally changing the input set has no effect here).
  final Set<WorkoutEquipment> equipment;

  /// Optional workout preferences; may be empty. Unmodifiable; never mutated
  /// after construction (externally changing the input set has no effect
  /// here).
  final Set<WorkoutPreference> preferences;

  /// A copy of this profile with the given fields replaced. Unspecified
  /// fields keep their current values. Set arguments are defensively copied,
  /// just like in the constructor.
  UserFitnessProfile copyWith({
    FitnessGoal? goal,
    ExperienceLevel? experience,
    WorkoutDuration? workoutDuration,
    TrainingEnvironment? environment,
    Set<WorkoutEquipment>? equipment,
    Set<WorkoutPreference>? preferences,
  }) {
    return UserFitnessProfile(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      environment: environment ?? this.environment,
      equipment: equipment ?? this.equipment,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserFitnessProfile &&
          goal == other.goal &&
          experience == other.experience &&
          workoutDuration == other.workoutDuration &&
          environment == other.environment &&
          setEquals(equipment, other.equipment) &&
          setEquals(preferences, other.preferences);

  @override
  int get hashCode => Object.hash(
        goal,
        experience,
        workoutDuration,
        environment,
        Object.hashAllUnordered(equipment),
        Object.hashAllUnordered(preferences),
      );

  @override
  String toString() =>
      'UserFitnessProfile(goal: $goal, experience: $experience, '
      'workoutDuration: $workoutDuration, environment: $environment, '
      'equipment: $equipment, preferences: $preferences)';
}
