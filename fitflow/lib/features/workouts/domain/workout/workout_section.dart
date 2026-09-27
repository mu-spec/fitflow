import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/foundation.dart';

/// Immutable workout section (warmup/main/cooldown) containing prescriptions (5C-1).
///
/// - Empty sections allowed in 5C-1
/// - No time estimation yet
/// - List is defensively copied and unmodifiable
@immutable
class WorkoutSection {
  WorkoutSection({
    required this.type,
    List<WorkoutExercisePrescription>? exercises,
  }) : _exercises = List<WorkoutExercisePrescription>.unmodifiable(
            exercises ?? const <WorkoutExercisePrescription>[]);

  final WorkoutSectionType type;

  final List<WorkoutExercisePrescription> _exercises;

  /// Externally immutable list of prescriptions, order preserved.
  List<WorkoutExercisePrescription> get exercises => _exercises;

  /// Alias if cleaner terminology preferred.
  List<WorkoutExercisePrescription> get items => _exercises;

  bool get isEmpty => _exercises.isEmpty;
  bool get isNotEmpty => _exercises.isNotEmpty;
  int get exerciseCount => _exercises.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutSection) return false;
    if (type != other.type) return false;
    if (_exercises.length != other._exercises.length) return false;
    for (int i = 0; i < _exercises.length; i++) {
      if (_exercises[i] != other._exercises[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // Combine type and ordered exercise hashes
    var hash = type.hashCode;
    for (final ex in _exercises) {
      hash = Object.hash(hash, ex.hashCode);
    }
    return hash;
  }

  @override
  String toString() =>
      'WorkoutSection(type: $type, count: $exerciseCount, exercises: ${_exercises.map((e) => e.exercise.id).toList()})';
}
