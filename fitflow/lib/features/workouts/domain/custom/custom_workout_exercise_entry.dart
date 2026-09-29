import 'package:flutter/foundation.dart';

/// Immutable entry for a custom workout exercise configuration.
/// Does NOT snapshot exercise metadata – resolves from catalog at runtime.
@immutable
class CustomWorkoutExerciseEntry {
  const CustomWorkoutExerciseEntry({
    required this.exerciseId,
    required this.sets,
    this.repsPerSet,
    this.workDuration,
    required this.restBetweenSets,
  });

  final String exerciseId;
  final int sets;
  final int? repsPerSet;
  final Duration? workDuration;
  final Duration restBetweenSets;

  bool get isReps => repsPerSet != null;
  bool get isTimed => workDuration != null;

  List<String> validate() {
    final problems = <String>[];
    if (exerciseId.trim().isEmpty) {
      problems.add('exerciseId must be non-empty');
    }
    if (sets < 1 || sets > 10) {
      problems.add('sets must be 1..10');
    }
    final hasReps = repsPerSet != null;
    final hasDuration = workDuration != null;
    if (hasReps && hasDuration) {
      problems.add('must not have both reps and duration');
    }
    if (!hasReps && !hasDuration) {
      problems.add('must have either reps or duration');
    }
    if (hasReps) {
      if (repsPerSet! < 1 || repsPerSet! > 100) {
        problems.add('reps must be 1..100');
      }
    }
    if (hasDuration) {
      if (workDuration!.inSeconds < 5 || workDuration!.inSeconds > 300) {
        problems.add('work duration must be 5..300 sec');
      }
    }
    if (restBetweenSets.inSeconds < 0 || restBetweenSets.inSeconds > 300) {
      problems.add('rest must be 0..300 sec');
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'repsPerSet': repsPerSet,
      'workDurationSeconds': workDuration?.inSeconds,
      'restBetweenSetsSeconds': restBetweenSets.inSeconds,
    };
  }

  static CustomWorkoutExerciseEntry? fromJson(Map<String, dynamic> json) {
    try {
      final exerciseId = json['exerciseId'] as String?;
      final sets = json['sets'] as int?;
      final repsPerSet = json['repsPerSet'] as int?;
      final workDurationSeconds = json['workDurationSeconds'] as int?;
      final restSeconds = json['restBetweenSetsSeconds'] as int?;

      if (exerciseId == null || sets == null || restSeconds == null) {
        return null;
      }
      if (exerciseId.trim().isEmpty) return null;

      Duration? workDuration;
      if (workDurationSeconds != null) {
        workDuration = Duration(seconds: workDurationSeconds);
      }

      final entry = CustomWorkoutExerciseEntry(
        exerciseId: exerciseId,
        sets: sets,
        repsPerSet: repsPerSet,
        workDuration: workDuration,
        restBetweenSets: Duration(seconds: restSeconds),
      );
      // Even if invalid, we still return to allow storage to persist and resolver to report issues?
      // For storage safety, we return even if invalid – validation layer will catch.
      // But if both reps and duration present, still return.
      return entry;
    } catch (_) {
      return null;
    }
  }

  CustomWorkoutExerciseEntry copyWith({
    String? exerciseId,
    int? sets,
    int? repsPerSet,
    Duration? workDuration,
    bool clearReps = false,
    bool clearDuration = false,
    Duration? restBetweenSets,
  }) {
    return CustomWorkoutExerciseEntry(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      repsPerSet: clearReps ? null : (repsPerSet ?? this.repsPerSet),
      workDuration: clearDuration ? null : (workDuration ?? this.workDuration),
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomWorkoutExerciseEntry) return false;
    return exerciseId == other.exerciseId &&
        sets == other.sets &&
        repsPerSet == other.repsPerSet &&
        workDuration == other.workDuration &&
        restBetweenSets == other.restBetweenSets;
  }

  @override
  int get hashCode => Object.hash(exerciseId, sets, repsPerSet, workDuration, restBetweenSets);

  @override
  String toString() => 'CustomEntry($exerciseId sets:$sets reps:$repsPerSet dur:$workDuration rest:$restBetweenSets)';
}
