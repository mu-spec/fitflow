import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';

/// Deterministic main-section movement diversity (Final Milestone).
///
/// Two-pass ordering:
/// Pass 1 - first candidate per unique trainable MovementPattern, preserving
/// order in which patterns first appear.
/// Pass 2 - remaining candidates in original ranked order.
///
/// No randomness, no new scores, ranking order preserved within each pattern.
class WorkoutCandidateDiversifier {
  const WorkoutCandidateDiversifier._();

  /// Diversifies [candidates] (expected to be main pool, already ranked).
  ///
  /// Returns new list, does not mutate input.
  static List<ExerciseRankingResult> diversifyMain(
    List<ExerciseRankingResult> candidates,
  ) {
    if (candidates.isEmpty) {
      return const [];
    }

    final seenPatterns = <MovementPattern>{};
    final firstPass = <ExerciseRankingResult>[];
    final firstIndices = <int>{};

    // Pass 1: first per movement pattern, preserving order of first appearance
    for (int i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final pattern = c.exercise.movementPattern;
      if (pattern == null) {
        continue; // defensive, main should have pattern
      }
      if (!seenPatterns.contains(pattern)) {
        seenPatterns.add(pattern);
        firstPass.add(c);
        firstIndices.add(i);
      }
    }

    // Pass 2: remaining candidates in original ranked order
    final result = <ExerciseRankingResult>[];
    result.addAll(firstPass);
    for (int i = 0; i < candidates.length; i++) {
      if (!firstIndices.contains(i)) {
        result.add(candidates[i]);
      }
    }

    return List<ExerciseRankingResult>.unmodifiable(result);
  }
}
