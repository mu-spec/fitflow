import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_candidates.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_engine.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';

/// Deterministic candidate pool resolver (5D-1).
///
/// - Uses existing eligibility + ranking via rankForUser (no duplication)
/// - Classifies by movement pattern and tags only (no name/description)
/// - Preserves ranking order within each pool
/// - No duplicate pool membership (precedence warmup > cooldown > main)
/// - Empty pools allowed
class WorkoutCandidateResolver {
  const WorkoutCandidateResolver._();

  static const String _warmupTag = 'warmup';
  static const String _cooldownTag = 'cooldown';

  /// Resolves eligible ranked candidates into warmup/main/cooldown pools.
  static WorkoutGenerationCandidates resolve(
    List<Exercise> exercises,
    WorkoutGenerationContext context,
  ) {
    // Pipeline: eligibility + ranking via existing engine (single source of truth)
    final ranked = ExerciseRankingEngine.rankForUser(
      exercises,
      context.userProfile,
      context.capabilityProfile,
    );

    final warmup = <ExerciseRankingResult>[];
    final cooldown = <ExerciseRankingResult>[];
    final main = <ExerciseRankingResult>[];

    for (final result in ranked) {
      final exercise = result.exercise;
      final pattern = exercise.movementPattern;

      // Warmup candidate: first precedence
      if (pattern == MovementPattern.warmup ||
          exercise.tags.contains(_warmupTag)) {
        warmup.add(result);
        continue;
      }

      // Cooldown candidate: second precedence
      if (pattern == MovementPattern.cooldown ||
          exercise.tags.contains(_cooldownTag)) {
        cooldown.add(result);
        continue;
      }

      // Main candidate: only trainable patterns
      if (pattern != null &&
          CapabilityProfile.trainablePatterns.contains(pattern)) {
        main.add(result);
        continue;
      }

      // Otherwise: not in any pool (no crash)
    }

    return WorkoutGenerationCandidates(
      warmup: warmup,
      main: main,
      cooldown: cooldown,
    );
  }

  /// Convenience that resolves from the full catalog.
  static WorkoutGenerationCandidates resolveCatalog(
    WorkoutGenerationContext context,
  ) {
    return resolve(ExerciseCatalog.all, context);
  }
}
