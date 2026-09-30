import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';

/// Immutable description of a Player session that has just reached the
/// `completed` phase. Handed to [WorkoutCompletionCallback] exactly once per
/// successful callback run (see `WorkoutPlayerSessionView`).
class WorkoutPlayerCompletion {
  const WorkoutPlayerCompletion({
    required this.playerSessionId,
    required this.completedWorkout,
    required this.plan,
    required this.origin,
  });

  /// Stable ID of the Player session (same ID used for the history entry).
  final String playerSessionId;

  /// Snapshot of what was actually performed, including M9 replacements.
  final CompletedWorkout completedWorkout;

  /// The frozen plan the session was executed from.
  final WorkoutPlan plan;

  final WorkoutSessionOrigin origin;
}

/// Optional hook fired by the shared Player when — and only when — the phase
/// becomes `completed`. Return `true` when the caller has durably handled the
/// completion; returning `false` (or throwing) lets a later rebuild retry.
typedef WorkoutCompletionCallback = Future<bool> Function(
  WorkoutPlayerCompletion completion,
);
