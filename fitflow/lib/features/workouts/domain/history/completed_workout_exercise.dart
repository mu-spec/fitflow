import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/foundation.dart';

/// Immutable snapshot of a single exercise as actually performed in a completed session.
/// Self-contained – does not rely on future catalog lookups.
@immutable
class CompletedWorkoutExercise {
  const CompletedWorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.movementPattern,
    required this.sectionType,
    required this.sets,
    this.repsPerSet,
    this.workDuration,
    required this.restBetweenSets,
    required this.difficulty,
  });

  final String exerciseId;
  final String exerciseName;
  final MovementPattern movementPattern;
  final WorkoutSectionType sectionType;
  final int sets;
  final int? repsPerSet;
  final Duration? workDuration;
  final Duration restBetweenSets;
  final ExerciseDifficulty difficulty;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'movementPattern': movementPattern.name,
      'sectionType': sectionType.name,
      'sets': sets,
      'repsPerSet': repsPerSet,
      'workDurationSeconds': workDuration?.inSeconds,
      'restBetweenSetsSeconds': restBetweenSets.inSeconds,
      'difficulty': difficulty.name,
    };
  }

  static CompletedWorkoutExercise? fromJson(Map<String, dynamic> json) {
    try {
      final exerciseId = json['exerciseId'] as String?;
      final exerciseName = json['exerciseName'] as String?;
      final movementPatternName = json['movementPattern'] as String?;
      final sectionTypeName = json['sectionType'] as String?;
      final sets = json['sets'] as int?;
      final restSeconds = json['restBetweenSetsSeconds'] as int?;
      final difficultyName = json['difficulty'] as String?;

      if (exerciseId == null || exerciseName == null || movementPatternName == null || sectionTypeName == null || sets == null || restSeconds == null || difficultyName == null) {
        return null;
      }

      final movementPattern = _movementPatternFromName(movementPatternName);
      final sectionType = _sectionTypeFromName(sectionTypeName);
      final difficulty = _difficultyFromName(difficultyName);

      if (movementPattern == null || sectionType == null || difficulty == null) {
        return null;
      }

      final repsPerSet = json['repsPerSet'] as int?;
      final workDurationSeconds = json['workDurationSeconds'] as int?;

      // Validate: must have either reps or workDuration, not both, not neither
      final hasReps = repsPerSet != null;
      final hasWork = workDurationSeconds != null;
      if (hasReps && hasWork) return null;
      if (!hasReps && !hasWork) return null;
      if (hasReps && repsPerSet <= 0) return null;
      if (hasWork && workDurationSeconds <= 0) return null;
      if (sets <= 0) return null;
      if (restSeconds < 0) return null;

      return CompletedWorkoutExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        movementPattern: movementPattern,
        sectionType: sectionType,
        sets: sets,
        repsPerSet: repsPerSet,
        workDuration: workDurationSeconds != null ? Duration(seconds: workDurationSeconds) : null,
        restBetweenSets: Duration(seconds: restSeconds),
        difficulty: difficulty,
      );
    } catch (_) {
      return null;
    }
  }

  static MovementPattern? _movementPatternFromName(String name) {
    for (final v in MovementPattern.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static WorkoutSectionType? _sectionTypeFromName(String name) {
    for (final v in WorkoutSectionType.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static ExerciseDifficulty? _difficultyFromName(String name) {
    for (final v in ExerciseDifficulty.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CompletedWorkoutExercise) return false;
    return exerciseId == other.exerciseId &&
        exerciseName == other.exerciseName &&
        movementPattern == other.movementPattern &&
        sectionType == other.sectionType &&
        sets == other.sets &&
        repsPerSet == other.repsPerSet &&
        workDuration == other.workDuration &&
        restBetweenSets == other.restBetweenSets &&
        difficulty == other.difficulty;
  }

  @override
  int get hashCode => Object.hash(
        exerciseId,
        exerciseName,
        movementPattern,
        sectionType,
        sets,
        repsPerSet,
        workDuration,
        restBetweenSets,
        difficulty,
      );

  @override
  String toString() => 'CompletedWorkoutExercise(id:$exerciseId name:$exerciseName pattern:${movementPattern.name} section:${sectionType.name} sets:$sets reps:$repsPerSet work:${workDuration?.inSeconds}s rest:${restBetweenSets.inSeconds}s diff:${difficulty.name})';
}
