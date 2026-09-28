import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';

/// A deterministic replacement option preserving original workload.
class WorkoutReplacementOption {
  const WorkoutReplacementOption({
    required this.exercise,
    required this.prescription,
    required this.reasons,
  });

  /// Replacement exercise.
  final Exercise exercise;

  /// Replacement prescription with ORIGINAL workload preserved.
  final WorkoutExercisePrescription prescription;

  /// Factual reasons why this alternative is suitable.
  final List<WorkoutReplacementReason> reasons;

  /// Human-readable reason labels.
  List<String> get reasonLabels => reasons.map((r) => r.label).toList();
}
