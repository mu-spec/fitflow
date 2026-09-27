import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
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
/// is closest to the user's capability for that movement (5B-2 with goal affinity).
///
/// - No eligibility rules duplicated; ranking operates on already-eligible exercises.
/// - Single source of truth for capability-fit and goal-affinity scoring.
/// - Stable tie-breaking via original index.
/// - Capability remains dominant: max goal bonus 15 < 20 diff between capability levels.
class ExerciseRankingEngine {
  const ExerciseRankingEngine._();

  /// Scores a single exercise against [context] deterministically.
  ///
  /// - No crash on above-capability, missing capability, or null movement.
  /// - Read-only, no state mutation.
  /// - Same inputs → same result.
  /// - For 5B-2: total = capabilityFit + goalAffinity
  static ExerciseRankingResult score(
    Exercise exercise,
    ExerciseRankingContext context,
  ) {
    final capabilityFitScore = _capabilityFitScore(exercise, context);
    final goalAffinityScore = _goalAffinityScore(exercise, context.goal);
    final totalScore = capabilityFitScore + goalAffinityScore;
    return ExerciseRankingResult(
      exercise: exercise,
      capabilityFitScore: capabilityFitScore,
      goalAffinityScore: goalAffinityScore,
      totalScore: totalScore,
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
        return 0;
    }
  }

  /// Centralized goal-affinity scoring (0..15) based solely on MovementPattern.
  ///
  /// - No exercise-name matching
  /// - No tag-based scoring
  /// - Warmup/cooldown and null movement → 0
  /// - Capability remains dominant (max 15 < 20)
  static int _goalAffinityScore(Exercise exercise, FitnessGoal goal) {
    final pattern = exercise.movementPattern;

    // Null movement → 0
    if (pattern == null) {
      return 0;
    }

    // Warmup / Cooldown → 0 (do not bias)
    if (pattern == MovementPattern.warmup ||
        pattern == MovementPattern.cooldown) {
      return 0;
    }

    // Non-trainable future-proof → 0
    if (!CapabilityProfile.trainablePatterns.contains(pattern) &&
        pattern != MovementPattern.warmup &&
        pattern != MovementPattern.cooldown) {
      // Already handled warmup/cooldown, but if new non-trainable appears → 0
      // This branch is defensive
    }

    switch (goal) {
      case FitnessGoal.generalFitness:
        return 0;

      case FitnessGoal.buildStrength:
        switch (pattern) {
          case MovementPattern.push:
          case MovementPattern.pull:
          case MovementPattern.squat:
          case MovementPattern.lunge:
          case MovementPattern.hinge:
          case MovementPattern.core:
          case MovementPattern.glute:
            return 15;
          case MovementPattern.balance:
            return 5;
          case MovementPattern.cardio:
          case MovementPattern.mobility:
          case MovementPattern.warmup:
          case MovementPattern.cooldown:
            return 0;
        }

      case FitnessGoal.buildMuscle:
        switch (pattern) {
          case MovementPattern.push:
          case MovementPattern.pull:
          case MovementPattern.squat:
          case MovementPattern.lunge:
          case MovementPattern.hinge:
          case MovementPattern.glute:
            return 15;
          case MovementPattern.core:
            return 10;
          case MovementPattern.cardio:
          case MovementPattern.mobility:
          case MovementPattern.balance:
          case MovementPattern.warmup:
          case MovementPattern.cooldown:
            return 0;
        }

      case FitnessGoal.loseWeight:
      case FitnessGoal.improveEndurance:
        // Shared table for this stage
        switch (pattern) {
          case MovementPattern.cardio:
            return 15;
          case MovementPattern.squat:
          case MovementPattern.lunge:
          case MovementPattern.hinge:
          case MovementPattern.core:
          case MovementPattern.glute:
            return 10;
          case MovementPattern.push:
          case MovementPattern.pull:
          case MovementPattern.balance:
            return 5;
          case MovementPattern.mobility:
          case MovementPattern.warmup:
          case MovementPattern.cooldown:
            return 0;
        }

      case FitnessGoal.improveMobility:
        switch (pattern) {
          case MovementPattern.mobility:
            return 15;
          case MovementPattern.balance:
            return 10;
          case MovementPattern.squat:
          case MovementPattern.lunge:
          case MovementPattern.hinge:
          case MovementPattern.core:
          case MovementPattern.glute:
            return 5;
          case MovementPattern.push:
          case MovementPattern.pull:
          case MovementPattern.cardio:
          case MovementPattern.warmup:
          case MovementPattern.cooldown:
            return 0;
        }

      case FitnessGoal.stayActive:
        switch (pattern) {
          case MovementPattern.cardio:
          case MovementPattern.mobility:
          case MovementPattern.balance:
            return 15;
          case MovementPattern.squat:
          case MovementPattern.lunge:
          case MovementPattern.hinge:
          case MovementPattern.core:
          case MovementPattern.glute:
            return 10;
          case MovementPattern.push:
          case MovementPattern.pull:
            return 5;
          case MovementPattern.warmup:
          case MovementPattern.cooldown:
            return 0;
        }
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
