import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:flutter/foundation.dart';

/// Immutable prescription of one selected exercise plus its prescribed work (5C-1).
///
/// Represents work inside warmup/main/cooldown without copying exercise metadata.
/// The [exercise] reference remains source of truth for name, movement, difficulty, etc.
@immutable
class WorkoutExercisePrescription {
  const WorkoutExercisePrescription({
    required this.exercise,
    required this.sets,
    this.repsPerSet,
    this.workDuration,
    required this.restBetweenSets,
  });

  /// The exercise being prescribed.
  final Exercise exercise;

  /// Number of sets, must be >=1.
  final int sets;

  /// Repetitions per set for reps-type exercises, null for timed.
  final int? repsPerSet;

  /// Work duration per set for timed exercises, null for reps.
  final Duration? workDuration;

  /// Rest between sets, must be >= Duration.zero.
  final Duration restBetweenSets;

  /// Convenience factory using exercise defaults (no intelligence yet).
  ///
  /// - For reps: uses exercise.defaultReps and defaultRest
  /// - For timed: uses exercise.defaultDuration and defaultRest
  /// - sets defaults to 1
  /// - Returns null if required defaults missing (no fabrication)
  /// - 5C-2 cleanup: missing defaultRest or negative rest now returns null
  /// - Zero rest valid only when exercise explicitly has defaultRest == Duration.zero
  static WorkoutExercisePrescription? fromExerciseDefaults(
    Exercise exercise, {
    int sets = 1,
  }) {
    if (sets < 1) {
      return null;
    }
    final rest = exercise.defaultRest;
    if (rest == null) {
      return null;
    }
    if (rest < Duration.zero) {
      return null;
    }

    switch (exercise.exerciseType) {
      case ExerciseType.reps:
        final reps = exercise.defaultReps;
        if (reps == null || reps <= 0) {
          return null;
        }
        return WorkoutExercisePrescription(
          exercise: exercise,
          sets: sets,
          repsPerSet: reps,
          workDuration: null,
          restBetweenSets: rest,
        );
      case ExerciseType.timed:
        final duration = exercise.defaultDuration;
        if (duration == null || duration <= Duration.zero) {
          return null;
        }
        return WorkoutExercisePrescription(
          exercise: exercise,
          sets: sets,
          repsPerSet: null,
          workDuration: duration,
          restBetweenSets: rest,
        );
    }
  }

  /// Lightweight validation returning human-readable problems.
  /// Empty list means valid.
  List<String> validate() {
    final problems = <String>[];

    if (sets < 1) {
      problems.add('sets must be >= 1');
    }

    if (restBetweenSets < Duration.zero) {
      problems.add('restBetweenSets must be >= Duration.zero');
    }

    // Check for both supplied or neither supplied
    final hasReps = repsPerSet != null;
    final hasDuration = workDuration != null;

    if (hasReps && hasDuration) {
      problems.add('must not supply both repsPerSet and workDuration');
    }

    if (!hasReps && !hasDuration) {
      problems.add('must supply either repsPerSet or workDuration');
    }

    switch (exercise.exerciseType) {
      case ExerciseType.reps:
        if (repsPerSet == null) {
          problems.add('reps exercise requires repsPerSet');
        } else if (repsPerSet! <= 0) {
          problems.add('repsPerSet must be > 0');
        }
        if (workDuration != null) {
          problems.add('reps exercise must not have workDuration');
        }
        break;
      case ExerciseType.timed:
        if (workDuration == null) {
          problems.add('timed exercise requires workDuration');
        } else if (workDuration! <= Duration.zero) {
          problems.add('workDuration must be > Duration.zero');
        }
        if (repsPerSet != null) {
          problems.add('timed exercise must not have repsPerSet');
        }
        break;
    }

    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutExercisePrescription) return false;
    return exercise.id == other.exercise.id &&
        sets == other.sets &&
        repsPerSet == other.repsPerSet &&
        workDuration == other.workDuration &&
        restBetweenSets == other.restBetweenSets;
  }

  @override
  int get hashCode => Object.hash(
        exercise.id,
        sets,
        repsPerSet,
        workDuration,
        restBetweenSets,
      );

  @override
  String toString() =>
      'WorkoutExercisePrescription(exercise: ${exercise.id}, sets: $sets, repsPerSet: $repsPerSet, workDuration: $workDuration, rest: $restBetweenSets, type: ${exercise.exerciseType})';
}
