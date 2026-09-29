import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:flutter/foundation.dart';

/// Immutable completed workout snapshot, self-contained, no catalog lookup required.
@immutable
class CompletedWorkout {
  const CompletedWorkout({
    required this.id,
    required this.completedAt,
    this.targetDuration,
    this.estimatedDuration,
    required this.totalExerciseCount,
    required this.totalSetCount,
    required this.warmup,
    required this.main,
    required this.cooldown,
  });

  /// Stable session ID, generated once when Player session created.
  final String id;

  /// When workout completed (final cooldown set).
  final DateTime completedAt;

  /// Planned/target duration from WorkoutPlan.timeBudget.target.
  final Duration? targetDuration;

  /// Estimated duration from WorkoutPlan.estimatedDuration.
  final Duration? estimatedDuration;

  final int totalExerciseCount;
  final int totalSetCount;

  /// Ordered effective warmup exercises actually performed.
  final List<CompletedWorkoutExercise> warmup;

  /// Ordered effective Main exercises actually performed – source for recovery.
  final List<CompletedWorkoutExercise> main;

  /// Ordered effective cooldown exercises actually performed.
  final List<CompletedWorkoutExercise> cooldown;

  /// All exercises in order warmup+main+cooldown for display.
  List<CompletedWorkoutExercise> get allExercises => [...warmup, ...main, ...cooldown];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'targetDurationSeconds': targetDuration?.inSeconds,
      'estimatedDurationSeconds': estimatedDuration?.inSeconds,
      'totalExerciseCount': totalExerciseCount,
      'totalSetCount': totalSetCount,
      'warmup': warmup.map((e) => e.toJson()).toList(),
      'main': main.map((e) => e.toJson()).toList(),
      'cooldown': cooldown.map((e) => e.toJson()).toList(),
    };
  }

  static CompletedWorkout? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final completedAtStr = json['completedAt'] as String?;
      final totalExerciseCount = json['totalExerciseCount'] as int?;
      final totalSetCount = json['totalSetCount'] as int?;

      if (id == null || completedAtStr == null || totalExerciseCount == null || totalSetCount == null) {
        return null;
      }

      final completedAt = DateTime.tryParse(completedAtStr);
      if (completedAt == null) return null;

      final targetSeconds = json['targetDurationSeconds'] as int?;
      final estimatedSeconds = json['estimatedDurationSeconds'] as int?;

      final warmupRaw = json['warmup'] as List<dynamic>?;
      final mainRaw = json['main'] as List<dynamic>?;
      final cooldownRaw = json['cooldown'] as List<dynamic>?;

      if (warmupRaw == null || mainRaw == null || cooldownRaw == null) return null;

      final warmup = <CompletedWorkoutExercise>[];
      for (final entry in warmupRaw) {
        if (entry is Map<String, dynamic>) {
          final ex = CompletedWorkoutExercise.fromJson(entry);
          if (ex != null) warmup.add(ex);
        } else if (entry is Map) {
          final ex = CompletedWorkoutExercise.fromJson(Map<String, dynamic>.from(entry));
          if (ex != null) warmup.add(ex);
        }
      }

      final main = <CompletedWorkoutExercise>[];
      for (final entry in mainRaw) {
        if (entry is Map<String, dynamic>) {
          final ex = CompletedWorkoutExercise.fromJson(entry);
          if (ex != null) main.add(ex);
        } else if (entry is Map) {
          final ex = CompletedWorkoutExercise.fromJson(Map<String, dynamic>.from(entry));
          if (ex != null) main.add(ex);
        }
      }

      final cooldown = <CompletedWorkoutExercise>[];
      for (final entry in cooldownRaw) {
        if (entry is Map<String, dynamic>) {
          final ex = CompletedWorkoutExercise.fromJson(entry);
          if (ex != null) cooldown.add(ex);
        } else if (entry is Map) {
          final ex = CompletedWorkoutExercise.fromJson(Map<String, dynamic>.from(entry));
          if (ex != null) cooldown.add(ex);
        }
      }

      // Preserve truth: total counts should match actual lists? Use stored counts but allow mismatch? For safety, use stored counts.
      return CompletedWorkout(
        id: id,
        completedAt: completedAt,
        targetDuration: targetSeconds != null ? Duration(seconds: targetSeconds) : null,
        estimatedDuration: estimatedSeconds != null ? Duration(seconds: estimatedSeconds) : null,
        totalExerciseCount: totalExerciseCount,
        totalSetCount: totalSetCount,
        warmup: List.unmodifiable(warmup),
        main: List.unmodifiable(main),
        cooldown: List.unmodifiable(cooldown),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CompletedWorkout) return false;
    if (id != other.id) return false;
    if (completedAt != other.completedAt) return false;
    if (targetDuration != other.targetDuration) return false;
    if (estimatedDuration != other.estimatedDuration) return false;
    if (totalExerciseCount != other.totalExerciseCount) return false;
    if (totalSetCount != other.totalSetCount) return false;
    if (warmup.length != other.warmup.length) return false;
    if (main.length != other.main.length) return false;
    if (cooldown.length != other.cooldown.length) return false;
    for (int i = 0; i < warmup.length; i++) {
      if (warmup[i] != other.warmup[i]) return false;
    }
    for (int i = 0; i < main.length; i++) {
      if (main[i] != other.main[i]) return false;
    }
    for (int i = 0; i < cooldown.length; i++) {
      if (cooldown[i] != other.cooldown[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        completedAt,
        targetDuration,
        estimatedDuration,
        totalExerciseCount,
        totalSetCount,
        Object.hashAll(warmup),
        Object.hashAll(main),
        Object.hashAll(cooldown),
      );

  @override
  String toString() => 'CompletedWorkout(id:$id at:$completedAt exercises:$totalExerciseCount sets:$totalSetCount)';
}
