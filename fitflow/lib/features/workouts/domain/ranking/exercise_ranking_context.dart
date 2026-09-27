import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter/foundation.dart';

/// Immutable ranking context for 5B-1.
///
/// Only contains capability profile. Future milestones may add goal,
/// duration, history, etc., but 5B-1 must not include them.
@immutable
class ExerciseRankingContext {
  const ExerciseRankingContext({
    required this.capabilityProfile,
  });

  final CapabilityProfile capabilityProfile;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseRankingContext) return false;
    return capabilityProfile == other.capabilityProfile;
  }

  @override
  int get hashCode => capabilityProfile.hashCode;

  @override
  String toString() =>
      'ExerciseRankingContext(capabilityProfile: $capabilityProfile)';
}
