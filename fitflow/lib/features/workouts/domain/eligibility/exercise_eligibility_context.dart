import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter/foundation.dart';

/// Immutable context for eligibility evaluation (5A-1 core only).
///
/// Contains:
/// - [capabilityProfile] – per-movement capability (10 trainable)
/// - [availableEquipment] – equipment the user has
///
/// For 5A-1 only equipment is extracted from [UserFitnessProfile].
/// Environment/preferences will be added in 5A-2.
@immutable
class ExerciseEligibilityContext {
  ExerciseEligibilityContext({
    required this.capabilityProfile,
    Set<WorkoutEquipment>? availableEquipment,
  }) : availableEquipment = Set.unmodifiable(
            availableEquipment ?? const <WorkoutEquipment>{});

  final CapabilityProfile capabilityProfile;

  /// Externally immutable set of available equipment.
  final Set<WorkoutEquipment> availableEquipment;

  /// Factory from existing profiles, extracting only equipment for 5A-1.
  factory ExerciseEligibilityContext.fromProfiles({
    required UserFitnessProfile userProfile,
    required CapabilityProfile capabilityProfile,
  }) {
    return ExerciseEligibilityContext(
      capabilityProfile: capabilityProfile,
      availableEquipment: userProfile.equipment,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseEligibilityContext) return false;
    if (capabilityProfile != other.capabilityProfile) return false;
    if (availableEquipment.length != other.availableEquipment.length) return false;
    if (!availableEquipment.containsAll(other.availableEquipment)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        capabilityProfile,
        Object.hashAllUnordered(availableEquipment),
      );

  @override
  String toString() =>
      'ExerciseEligibilityContext(capabilities: $capabilityProfile, equipment: $availableEquipment)';
}
