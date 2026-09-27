import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimate.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:flutter/foundation.dart';

/// Immutable complete structured workout plan (5C-3 domain + validation only).
///
/// - Warm-up, Main, Cooldown sections
/// - Target time budget
/// - Deterministic estimated duration derived from existing estimator
/// - Whole-plan validation (structure, not time closeness)
///
/// No generation, selection, or UI logic.
@immutable
class WorkoutPlan {
  const WorkoutPlan({
    required this.warmup,
    required this.main,
    required this.cooldown,
    required this.timeBudget,
  });

  final WorkoutSection warmup;
  final WorkoutSection main;
  final WorkoutSection cooldown;
  final WorkoutTimeBudget timeBudget;

  /// Convenience factory using WorkoutDuration to create budget.
  factory WorkoutPlan.withWorkoutDuration({
    required WorkoutDuration workoutDuration,
    required WorkoutSection warmup,
    required WorkoutSection main,
    required WorkoutSection cooldown,
  }) {
    final budget = WorkoutTimeBudget.fromWorkoutDuration(workoutDuration);
    return WorkoutPlan(
      warmup: warmup,
      main: main,
      cooldown: cooldown,
      timeBudget: budget,
    );
  }

  // --- Derived estimates (delegate, no duplication) ---

  WorkoutTimeEstimate? get warmupEstimate =>
      WorkoutTimeEstimator.estimateSection(warmup);

  WorkoutTimeEstimate? get mainEstimate =>
      WorkoutTimeEstimator.estimateSection(main);

  WorkoutTimeEstimate? get cooldownEstimate =>
      WorkoutTimeEstimator.estimateSection(cooldown);

  /// Total estimated duration = sum of three section totals, if all obtainable.
  /// No extra inter-section transition added (transitions only within sections).
  Duration? get estimatedDuration {
    final w = warmupEstimate;
    final m = mainEstimate;
    final c = cooldownEstimate;
    if (w == null || m == null || c == null) {
      return null;
    }
    return w.total + m.total + c.total;
  }

  /// Target duration from budget (source of truth).
  Duration get targetDuration => timeBudget.target;

  /// Delegates to timeBudget.
  Duration budgetFor(WorkoutSectionType type) => timeBudget.budgetFor(type);

  // --- Over / Under diagnostics (target is not hard validity) ---

  /// estimated - target, positive = over, negative = under, null if estimate unavailable.
  Duration? get differenceFromTarget {
    final est = estimatedDuration;
    if (est == null) {
      return null;
    }
    return est - targetDuration;
  }

  bool? get isOverTarget {
    final diff = differenceFromTarget;
    if (diff == null) return null;
    return diff > Duration.zero;
  }

  bool? get isUnderTarget {
    final diff = differenceFromTarget;
    if (diff == null) return null;
    return diff < Duration.zero;
  }

  // --- Exercise counts and flattening ---

  int get totalExerciseCount =>
      warmup.exerciseCount + main.exerciseCount + cooldown.exerciseCount;

  /// Ordered view: warmup + main + cooldown prescriptions, immutable.
  List<WorkoutExercisePrescription> get allPrescriptions {
    final list = <WorkoutExercisePrescription>[
      ...warmup.exercises,
      ...main.exercises,
      ...cooldown.exercises,
    ];
    return List<WorkoutExercisePrescription>.unmodifiable(list);
  }

  /// Derived ordered exercises, immutable.
  List<Exercise> get allExercises {
    final list = allPrescriptions.map((p) => p.exercise).toList();
    return List<Exercise>.unmodifiable(list);
  }

  // --- Validation ---

  List<String> validate() {
    final problems = <String>[];

    if (!timeBudget.isValid) {
      problems.add('timeBudget invalid: ${timeBudget.validate().join(', ')}');
    }

    if (warmup.type != WorkoutSectionType.warmup) {
      problems.add('warmup section must have type warmup, found ${warmup.type}');
    }
    if (main.type != WorkoutSectionType.main) {
      problems.add('main section must have type main, found ${main.type}');
    }
    if (cooldown.type != WorkoutSectionType.cooldown) {
      problems.add('cooldown section must have type cooldown, found ${cooldown.type}');
    }

    if (warmup.isEmpty) {
      problems.add('warmup must be non-empty');
    }
    if (main.isEmpty) {
      problems.add('main must be non-empty');
    }
    if (cooldown.isEmpty) {
      problems.add('cooldown must be non-empty');
    }

    // Every prescription valid
    for (final p in warmup.exercises) {
      if (!p.isValid) {
        problems.add('warmup prescription ${p.exercise.id} invalid: ${p.validate().join(', ')}');
      }
    }
    for (final p in main.exercises) {
      if (!p.isValid) {
        problems.add('main prescription ${p.exercise.id} invalid: ${p.validate().join(', ')}');
      }
    }
    for (final p in cooldown.exercises) {
      if (!p.isValid) {
        problems.add('cooldown prescription ${p.exercise.id} invalid: ${p.validate().join(', ')}');
      }
    }

    // All section estimates obtainable
    if (warmupEstimate == null) {
      problems.add('warmup estimate unavailable (invalid prescription)');
    }
    if (mainEstimate == null) {
      problems.add('main estimate unavailable (invalid prescription)');
    }
    if (cooldownEstimate == null) {
      problems.add('cooldown estimate unavailable (invalid prescription)');
    }

    // Note: Do NOT require estimatedDuration == targetDuration
    // Over/under target does NOT invalidate

    return problems;
  }

  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutPlan) return false;
    return warmup == other.warmup &&
        main == other.main &&
        cooldown == other.cooldown &&
        timeBudget == other.timeBudget;
  }

  @override
  int get hashCode => Object.hash(warmup, main, cooldown, timeBudget);

  @override
  String toString() =>
      'WorkoutPlan(warmup: ${warmup.exerciseCount}, main: ${main.exerciseCount}, cooldown: ${cooldown.exerciseCount}, target: $targetDuration, estimated: $estimatedDuration, budgetValid: ${timeBudget.isValid})';
}
