import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:flutter/foundation.dart';

/// Immutable ranking result for 5B-1.
///
/// Contains capability-fit score and total score. For 5B-1 totalScore == capabilityFitScore.
/// Future dimensions will contribute to totalScore.
@immutable
class ExerciseRankingResult {
  const ExerciseRankingResult({
    required this.exercise,
    required this.capabilityFitScore,
    required this.totalScore,
  });

  final Exercise exercise;

  /// Capability-fit score based on explicit table.
  final int capabilityFitScore;

  /// For 5B-1 equals capabilityFitScore.
  final int totalScore;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseRankingResult) return false;
    return exercise.id == other.exercise.id &&
        capabilityFitScore == other.capabilityFitScore &&
        totalScore == other.totalScore;
  }

  @override
  int get hashCode => Object.hash(
        exercise.id,
        capabilityFitScore,
        totalScore,
      );

  @override
  String toString() =>
      'ExerciseRankingResult(exercise: ${exercise.id}, capabilityFitScore: $capabilityFitScore, totalScore: $totalScore)';
}
