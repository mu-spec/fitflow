import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:flutter/foundation.dart';

/// Immutable result of eligibility evaluation for one exercise.
@immutable
class ExerciseEligibilityResult {
  ExerciseEligibilityResult({
    required this.exercise,
    Set<ExerciseExclusionReason>? reasons,
    Set<WorkoutEquipment>? missingEquipment,
  })  : _reasons = Set.unmodifiable(
            reasons ?? const <ExerciseExclusionReason>{}),
        _missingEquipment = Set.unmodifiable(
            missingEquipment ?? const <WorkoutEquipment>{});

  final Exercise exercise;

  final Set<ExerciseExclusionReason> _reasons;

  /// Immutable exclusion reasons. Empty means eligible.
  Set<ExerciseExclusionReason> get reasons => _reasons;

  /// Alias for readability.
  Set<ExerciseExclusionReason> get exclusionReasons => _reasons;

  final Set<WorkoutEquipment> _missingEquipment;

  /// Equipment required but not available (only meaningful when missingEquipment reason present).
  Set<WorkoutEquipment> get missingEquipment => _missingEquipment;

  bool get eligible => _reasons.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseEligibilityResult) return false;
    if (exercise.id != other.exercise.id) return false;
    if (_reasons.length != other._reasons.length) return false;
    if (!_reasons.containsAll(other._reasons)) return false;
    if (_missingEquipment.length != other._missingEquipment.length) return false;
    if (!_missingEquipment.containsAll(other._missingEquipment)) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        exercise.id,
        Object.hashAllUnordered(_reasons),
        Object.hashAllUnordered(_missingEquipment),
      );

  @override
  String toString() =>
      'ExerciseEligibilityResult(exercise: ${exercise.id}, eligible: $eligible, reasons: $_reasons, missingEquipment: $_missingEquipment)';
}
