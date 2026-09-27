import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter/foundation.dart';

/// Immutable context for eligibility evaluation (5A-2 extended).
///
/// Contains:
/// - [capabilityProfile] – per-movement capability (10 trainable)
/// - [availableEquipment] – equipment the user has
/// - [environment] – training environment with space/noise limits
/// - [preferences] – workout preferences (lowImpact, noFloor, standingOnly, wrist, knee)
///
/// Extracted from [UserFitnessProfile] via [fromProfiles].
@immutable
class ExerciseEligibilityContext {
  ExerciseEligibilityContext({
    required this.capabilityProfile,
    Set<WorkoutEquipment>? availableEquipment,
    this.environment = TrainingEnvironment.normalHome,
    Set<WorkoutPreference>? preferences,
  })  : availableEquipment = Set.unmodifiable(
            availableEquipment ?? const <WorkoutEquipment>{}),
        preferences = Set.unmodifiable(
            preferences ?? const <WorkoutPreference>{});

  final CapabilityProfile capabilityProfile;

  /// Externally immutable set of available equipment.
  final Set<WorkoutEquipment> availableEquipment;

  /// Training environment for space/noise limits.
  final TrainingEnvironment environment;

  /// Externally immutable set of preferences.
  final Set<WorkoutPreference> preferences;

  /// Factory from existing profiles, extracting equipment, environment, preferences.
  factory ExerciseEligibilityContext.fromProfiles({
    required UserFitnessProfile userProfile,
    required CapabilityProfile capabilityProfile,
  }) {
    return ExerciseEligibilityContext(
      capabilityProfile: capabilityProfile,
      availableEquipment: userProfile.equipment,
      environment: userProfile.environment,
      preferences: userProfile.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseEligibilityContext) return false;
    if (capabilityProfile != other.capabilityProfile) return false;
    if (environment != other.environment) return false;
    if (availableEquipment.length != other.availableEquipment.length) return false;
    if (!availableEquipment.containsAll(other.availableEquipment)) return false;
    if (preferences.length != other.preferences.length) return false;
    if (!preferences.containsAll(other.preferences)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        capabilityProfile,
        environment,
        Object.hashAllUnordered(availableEquipment),
        Object.hashAllUnordered(preferences),
      );

  @override
  String toString() =>
      'ExerciseEligibilityContext(capabilities: $capabilityProfile, equipment: $availableEquipment, environment: $environment, preferences: $preferences)';
}
