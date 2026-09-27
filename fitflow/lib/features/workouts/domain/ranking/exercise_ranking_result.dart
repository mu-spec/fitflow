import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:flutter/foundation.dart';

/// Immutable ranking result for 5B-2.
///
/// Contains capability-fit score, goal affinity, and total score.
/// For 5B-2: totalScore = capabilityFitScore + goalAffinityScore.
/// Future dimensions will contribute to totalScore.
@immutable
class ExerciseRankingResult {
  const ExerciseRankingResult({
    required this.exercise,
    required this.capabilityFitScore,
    this.goalAffinityScore = 0,
    required this.totalScore,
  });

  final Exercise exercise;

  /// Capability-fit score based on explicit table.
  final int capabilityFitScore;

  /// Goal-affinity score based on movement pattern and FitnessGoal (0..15).
  final int goalAffinityScore;

  /// For 5B-2 equals capabilityFitScore + goalAffinityScore.
  final int totalScore;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseRankingResult) return false;
    return exercise.id == other.exercise.id &&
        capabilityFitScore == other.capabilityFitScore &&
        goalAffinityScore == other.goalAffinityScore &&
        totalScore == other.totalScore;
  }

  @override
  int get hashCode => Object.hash(
        exercise.id,
        capabilityFitScore,
        goalAffinityScore,
        totalScore,
      );

  @override
  String toString() =>
      'ExerciseRankingResult(exercise: ${exercise.id}, capabilityFitScore: $capabilityFitScore, goalAffinityScore: $goalAffinityScore, totalScore: $totalScore)';
}
