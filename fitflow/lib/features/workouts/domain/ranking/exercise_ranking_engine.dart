import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_context.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';

/// Deterministic ranking engine that prefers exercises whose difficulty
/// is closest to the user's capability for that movement (5B-1).
///
/// - No eligibility rules duplicated; ranking operates on already-eligible exercises.
/// - Single source of truth for capability-fit scoring.
/// - Stable tie-breaking via original index.
class ExerciseRankingEngine {
  const ExerciseRankingEngine._();

  /// Scores a single exercise against [context] deterministically.
  ///
  /// - No crash on above-capability, missing capability, or null movement.
  /// - Read-only, no state mutation.
  /// - Same inputs → same result.
  static ExerciseRankingResult score(
    Exercise exercise,
    ExerciseRankingContext context,
  ) {
    final capabilityFitScore = _capabilityFitScore(exercise, context);
    // For 5B-1 totalScore == capabilityFitScore
    return ExerciseRankingResult(
      exercise: exercise,
      capabilityFitScore: capabilityFitScore,
      totalScore: capabilityFitScore,
    );
  }

  /// Ranks [exercises] by descending totalScore (capability-fit for 5B-1).
  ///
  /// - Highest totalScore first
  /// - Deterministic, no randomness
  /// - Returns immutable list
  /// - Does not mutate caller input
  /// - Stable tie: preserves original relative input order
  static List<ExerciseRankingResult> rank(
    List<Exercise> exercises,
    ExerciseRankingContext context,
  ) {
    // Build scored list with original index for stable tie-breaking
    final scored = <_ScoredWithIndex>[];
    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final result = score(ex, context);
      scored.add(_ScoredWithIndex(result: result, originalIndex: i));
    }

    // Sort descending by totalScore, then ascending by originalIndex
    scored.sort((a, b) {
      final scoreCompare = b.result.totalScore.compareTo(a.result.totalScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.originalIndex.compareTo(b.originalIndex);
    });

    final ranked = scored.map((e) => e.result).toList();
    return List<ExerciseRankingResult>.unmodifiable(ranked);
  }

  /// Convenience API that first filters via existing eligibility engine,
  /// then ranks the eligible subset.
  ///
  /// - Eligibility remains owned by ExerciseEligibilityEngine
  /// - No duplicated eligibility logic
  static List<ExerciseRankingResult> rankEligible(
    List<Exercise> exercises,
    ExerciseEligibilityContext eligibilityContext,
    ExerciseRankingContext rankingContext,
  ) {
    final eligible =
        ExerciseEligibilityEngine.filterEligible(exercises, eligibilityContext);
    return rank(eligible, rankingContext);
  }

  // --- Core scoring logic ---

  static int _capabilityFitScore(
    Exercise exercise,
    ExerciseRankingContext context,
  ) {
    final pattern = exercise.movementPattern;

    // Null movement defensive → 0
    if (pattern == null) {
      return 0;
    }

    // Warmup / Cooldown neutral fixed score 50, without capability lookup
    if (pattern == MovementPattern.warmup ||
        pattern == MovementPattern.cooldown) {
      return 50;
    }

    // Non-trainable but not warmup/cooldown (future-proof) → 0
    if (!CapabilityProfile.trainablePatterns.contains(pattern)) {
      return 0;
    }

    // Missing capability defensive → 0 (do not fabricate Level1)
    final capability = context.capabilityProfile.capabilityFor(pattern);
    if (capability == null) {
      return 0;
    }

    final capRank = _capabilityLevelRank(capability.level);
    final exRank = _exerciseDifficultyRank(exercise.difficulty);

    // Above capability defensive → 0, must not outrank eligible
    if (exRank > capRank) {
      return 0;
    }

    final diff = capRank - exRank;
    // Explicit deterministic table, no index magic
    switch (diff) {
      case 0:
        return 100;
      case 1:
        return 80;
      case 2:
        return 60;
      case 3:
        return 40;
      case 4:
        return 20;
      default:
        // diff >4 shouldn't happen with 5 levels, but defensive → lowest eligible score
        // However spec says above capability is 0, below up to 4 levels is 20.
        // If diff >4, return 0 as safe fallback? But to keep monotonic, return 0.
        // Since max diff is 4, we treat >4 as 0 to avoid unexpected high score.
        return 0;
    }
  }

  static int _capabilityLevelRank(CapabilityLevel level) {
    // CapabilityLevel.rank is explicit switch, not index
    return level.rank;
  }

  static int _exerciseDifficultyRank(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.level1:
        return 1;
      case ExerciseDifficulty.level2:
        return 2;
      case ExerciseDifficulty.level3:
        return 3;
      case ExerciseDifficulty.level4:
        return 4;
      case ExerciseDifficulty.level5:
        return 5;
    }
  }
}

class _ScoredWithIndex {
  _ScoredWithIndex({required this.result, required this.originalIndex});
  final ExerciseRankingResult result;
  final int originalIndex;
}
