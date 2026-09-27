import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/foundation.dart';

/// Immutable time budget for a workout split into sections (5C-2).
///
/// Invariant: warmup + main + cooldown == target
@immutable
class WorkoutTimeBudget {
  const WorkoutTimeBudget({
    required this.target,
    required this.warmup,
    required this.main,
    required this.cooldown,
  });

  final Duration target;
  final Duration warmup;
  final Duration main;
  final Duration cooldown;

  /// Explicit V1 deterministic budget table (no dynamic percentages).
  static WorkoutTimeBudget fromWorkoutDuration(WorkoutDuration duration) {
    switch (duration) {
      case WorkoutDuration.fiveMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 5),
          warmup: Duration(minutes: 1),
          main: Duration(minutes: 3),
          cooldown: Duration(minutes: 1),
        );
      case WorkoutDuration.tenMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 10),
          warmup: Duration(minutes: 2),
          main: Duration(minutes: 6),
          cooldown: Duration(minutes: 2),
        );
      case WorkoutDuration.fifteenMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 15),
          warmup: Duration(minutes: 2),
          main: Duration(minutes: 11),
          cooldown: Duration(minutes: 2),
        );
      case WorkoutDuration.twentyMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 20),
          warmup: Duration(minutes: 3),
          main: Duration(minutes: 14),
          cooldown: Duration(minutes: 3),
        );
      case WorkoutDuration.thirtyMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 30),
          warmup: Duration(minutes: 4),
          main: Duration(minutes: 22),
          cooldown: Duration(minutes: 4),
        );
      case WorkoutDuration.fortyFiveMinutes:
        return const WorkoutTimeBudget(
          target: Duration(minutes: 45),
          warmup: Duration(minutes: 5),
          main: Duration(minutes: 35),
          cooldown: Duration(minutes: 5),
        );
    }
  }

  /// Returns budget for given section type.
  Duration budgetFor(WorkoutSectionType type) {
    switch (type) {
      case WorkoutSectionType.warmup:
        return warmup;
      case WorkoutSectionType.main:
        return main;
      case WorkoutSectionType.cooldown:
        return cooldown;
    }
  }

  List<String> validate() {
    final problems = <String>[];
    if (target <= Duration.zero) {
      problems.add('target must be > Duration.zero');
    }
    if (warmup < Duration.zero) {
      problems.add('warmup must be >= Duration.zero');
    }
    if (main < Duration.zero) {
      problems.add('main must be >= Duration.zero');
    }
    if (cooldown < Duration.zero) {
      problems.add('cooldown must be >= Duration.zero');
    }
    if (warmup + main + cooldown != target) {
      problems.add('warmup + main + cooldown must equal target');
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutTimeBudget) return false;
    return target == other.target &&
        warmup == other.warmup &&
        main == other.main &&
        cooldown == other.cooldown;
  }

  @override
  int get hashCode => Object.hash(target, warmup, main, cooldown);

  @override
  String toString() =>
      'WorkoutTimeBudget(target: $target, warmup: $warmup, main: $main, cooldown: $cooldown)';
}
