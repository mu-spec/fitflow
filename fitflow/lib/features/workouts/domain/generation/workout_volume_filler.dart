import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';

/// Deterministic volume filling via round-robin set increments (Final Milestone).
///
/// - Only sets may increase, reps/duration/rest unchanged
/// - Max sets per section: warmup 2, main 4, cooldown 2
/// - Round-robin balanced filling
/// - Budget safe, exact fit allowed
class WorkoutVolumeFiller {
  const WorkoutVolumeFiller._();

  // Centralized V1 caps
  static const int warmupMaxSets = 2;
  static const int mainMaxSets = 4;
  static const int cooldownMaxSets = 2;

  static int capFor(WorkoutSectionType type) {
    switch (type) {
      case WorkoutSectionType.warmup:
        return warmupMaxSets;
      case WorkoutSectionType.main:
        return mainMaxSets;
      case WorkoutSectionType.cooldown:
        return cooldownMaxSets;
    }
  }

  /// Attempts to fill [section] within [budget] using round-robin set increments.
  ///
  /// Returns new section with increased sets, or null if input invalid.
  /// Does not mutate input.
  /// Deterministic, no randomness.
  static WorkoutSection? fill(
    WorkoutSection section,
    Duration budget,
  ) {
    // Invalid budget -> null clean failure (consistent with existing style)
    if (budget < Duration.zero) {
      return null;
    }

    // Empty section -> return as is (no filling needed)
    if (section.isEmpty) {
      return section;
    }

    // Validate all prescriptions valid, otherwise fail cleanly
    for (final p in section.exercises) {
      if (!p.isValid) {
        return null;
      }
      if (p.sets < 1) {
        return null;
      }
    }

    final cap = capFor(section.type);

    // Working copy of prescriptions (mutable list of current sets)
    final current = section.exercises
        .map((p) => WorkoutExercisePrescription(
              exercise: p.exercise,
              sets: p.sets,
              repsPerSet: p.repsPerSet,
              workDuration: p.workDuration,
              restBetweenSets: p.restBetweenSets,
            ))
        .toList();

    // Initial estimate check (should already be <= budget from builder, but defensive)
    final initialSection = WorkoutSection(type: section.type, exercises: current);
    final initialEstimate = WorkoutTimeEstimator.estimateSection(initialSection);
    if (initialEstimate == null) {
      return null;
    }
    if (initialEstimate.total > budget) {
      // Already over budget -> fail cleanly, do not return over-budget section.
      // Enforces invariant: every non-null result satisfies estimate.total <= budget
      return null;
    }

    // Round-robin filling
    bool anyIncrementInPass;
    do {
      anyIncrementInPass = false;

      // Check if all at cap
      bool allAtCap = true;
      for (final p in current) {
        if (p.sets < cap) {
          allAtCap = false;
          break;
        }
      }
      if (allAtCap) {
        break;
      }

      // One round-robin pass over all exercises in order
      for (int i = 0; i < current.length; i++) {
        final pres = current[i];
        if (pres.sets >= cap) {
          continue; // already at cap
        }

        // Attempt +1 set
        final tentativePres = WorkoutExercisePrescription(
          exercise: pres.exercise,
          sets: pres.sets + 1,
          repsPerSet: pres.repsPerSet,
          workDuration: pres.workDuration,
          restBetweenSets: pres.restBetweenSets,
        );

        if (!tentativePres.isValid) {
          continue; // should not happen, but skip
        }

        // Build tentative section
        final tentativeList = List<WorkoutExercisePrescription>.from(current);
        tentativeList[i] = tentativePres;
        final tentativeSection =
            WorkoutSection(type: section.type, exercises: tentativeList);
        final estimate =
            WorkoutTimeEstimator.estimateSection(tentativeSection);

        if (estimate == null) {
          continue; // invalid -> skip
        }

        if (estimate.total <= budget) {
          // Accept increment
          current[i] = tentativePres;
          anyIncrementInPass = true;
        } else {
          // Cannot fit, leave unchanged and continue trying later exercises
          continue;
        }
      }
      // Continue while at least one increment accepted in last pass
    } while (anyIncrementInPass);

    // Final section
    final filledSection = WorkoutSection(type: section.type, exercises: current);
    final finalEstimate = WorkoutTimeEstimator.estimateSection(filledSection);
    if (finalEstimate == null) {
      return null;
    }
    if (finalEstimate.total > budget) {
      // Should never happen due to checks, but defensive -> return null
      return null;
    }

    return filledSection;
  }
}
