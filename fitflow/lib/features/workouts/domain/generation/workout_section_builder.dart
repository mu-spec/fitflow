import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';

/// Deterministic budget-fit section builder (5D-2).
///
/// Generic building block for full generator:
/// - Considers candidates in ranking order
/// - Converts each to Exercise defaults with exactly 1 set
/// - Adds only when tentative section still fits budget (including 15s transitions)
/// - Respects maxExercises cap
/// - No eligibility/classification/ranking duplication
/// - No volume scaling, no diversity logic
class WorkoutSectionBuilder {
  const WorkoutSectionBuilder._();

  /// Builds a [WorkoutSection] of [type] from already eligible+ranked [candidates].
  ///
  /// Returns null for invalid inputs (negative budget or maxExercises).
  /// Returns empty section for valid empty cases (zero budget, zero max, empty candidates, none fit).
  ///
  /// - Ranking order preserved (no re-sort)
  /// - Every prescription uses exactly 1 set via fromExerciseDefaults
  /// - Budget check delegates to WorkoutTimeEstimator (includes 15s transitions)
  /// - Exact fit accepted (total == budget), only total > budget rejected
  /// - Duplicate exercise IDs skipped after first selection
  static WorkoutSection? build({
    required WorkoutSectionType type,
    required List<ExerciseRankingResult> candidates,
    required Duration budget,
    required int maxExercises,
  }) {
    // Invalid inputs -> null (do not throw, do not silently convert)
    if (budget < Duration.zero) {
      return null;
    }
    if (maxExercises < 0) {
      return null;
    }

    // Valid empty cases -> empty section of requested type
    if (maxExercises == 0) {
      return WorkoutSection(type: type, exercises: []);
    }
    if (budget == Duration.zero) {
      return WorkoutSection(type: type, exercises: []);
    }
    if (candidates.isEmpty) {
      return WorkoutSection(type: type, exercises: []);
    }

    final selected = <WorkoutExercisePrescription>[];
    final selectedIds = <String>{};

    for (final candidate in candidates) {
      if (selected.length == maxExercises) {
        break; // hard cap
      }

      final exerciseId = candidate.exercise.id;
      if (selectedIds.contains(exerciseId)) {
        continue; // duplicate ID within this section
      }

      // Default prescription creation only via existing factory, 1 set
      final prescription =
          WorkoutExercisePrescription.fromExerciseDefaults(candidate.exercise, sets: 1);
      if (prescription == null) {
        continue; // skip missing/invalid defaults, no fabrication
      }

      // Ensure exactly 1 set (factory already does, but defensive)
      if (prescription.sets != 1) {
        continue;
      }

      // Tentatively append and estimate
      final tentative = [...selected, prescription];
      final tentativeSection =
          WorkoutSection(type: type, exercises: tentative);
      final estimate =
          WorkoutTimeEstimator.estimateSection(tentativeSection);

      if (estimate == null) {
        continue; // invalid prescription (should not happen, but defensive)
      }

      if (estimate.total <= budget) {
        // Accept
        selected.add(prescription);
        selectedIds.add(exerciseId);
      } else {
        // Skip, continue to later shorter candidates
        continue;
      }
    }

    // Return section (may be empty) - never exceeds budget by construction
    return WorkoutSection(type: type, exercises: selected);
  }
}
