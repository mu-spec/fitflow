import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimate.dart';

/// Deterministic estimator for workout time (5C-2).
///
/// Domain-only utility, no UI, no randomness.
///
/// Constants:
/// - estimatedSecondsPerRep = 3 (planning estimate only, not tempo)
/// - transitionBetweenExercises = 15 seconds between exercises
class WorkoutTimeEstimator {
  const WorkoutTimeEstimator._();

  static const int estimatedSecondsPerRep = 3;
  static const Duration transitionBetweenExercises =
      Duration(seconds: 15);

  /// Estimates a single prescription.
  ///
  /// Returns null if prescription is invalid.
  /// Does not throw for ordinary validation failure.
  static WorkoutTimeEstimate? estimatePrescription(
      WorkoutExercisePrescription prescription) {
    if (!prescription.isValid) {
      return null;
    }

    final sets = prescription.sets;
    final restBetween = prescription.restBetweenSets;

    // Rest only between sets
    final restMultiplier = sets - 1;
    final rest = restMultiplier <= 0
        ? Duration.zero
        : Duration(
            microseconds:
                restBetween.inMicroseconds * restMultiplier);

    Duration work;
    if (prescription.repsPerSet != null) {
      // Reps: sets * reps * 3 sec
      final totalReps = sets * prescription.repsPerSet!;
      work = Duration(seconds: totalReps * estimatedSecondsPerRep);
    } else if (prescription.workDuration != null) {
      // Timed: sets * workDuration
      work = Duration(
          microseconds:
              prescription.workDuration!.inMicroseconds * sets);
    } else {
      // Should not happen because isValid checks, but defensive
      return null;
    }

    // Transition zero at prescription level
    return WorkoutTimeEstimate.fromComponents(
      work: work,
      rest: rest,
      transition: Duration.zero,
    );
  }

  /// Estimates a whole section.
  ///
  /// - Sums work and rest of all prescriptions
  /// - Adds 15 sec transition BETWEEN exercises only
  /// - No transition before first or after last
  /// - Returns null if any contained prescription invalid
  /// - Empty section → zero estimate (valid)
  static WorkoutTimeEstimate? estimateSection(WorkoutSection section) {
    if (section.exercises.isEmpty) {
      return WorkoutTimeEstimate.zero;
    }

    Duration totalWork = Duration.zero;
    Duration totalRest = Duration.zero;

    for (final prescription in section.exercises) {
      final estimate = estimatePrescription(prescription);
      if (estimate == null) {
        return null; // Do not silently skip invalid
      }
      totalWork += estimate.work;
      totalRest += estimate.rest;
    }

    final transitionCount = section.exerciseCount - 1;
    final transition = transitionCount <= 0
        ? Duration.zero
        : Duration(
            microseconds: transitionBetweenExercises.inMicroseconds *
                transitionCount);

    return WorkoutTimeEstimate.fromComponents(
      work: totalWork,
      rest: totalRest,
      transition: transition,
    );
  }
}
