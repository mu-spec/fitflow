import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_candidates.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_engine.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

/// Deterministic candidate pool resolver (5D-1 + M12 + M13).
///
/// - Uses existing eligibility + ranking via rankForUser (no duplication)
/// - M12: uses effectiveCapabilityProfile for ranking but original UserFitnessProfile for goal/equipment/etc
/// - M13: delegates classification to CustomWorkoutSectionClassifier (single source of truth)
/// - Preserves ranking order within each pool
/// - No duplicate pool membership (precedence warmup > cooldown > main)
/// - Empty pools allowed
class WorkoutCandidateResolver {
  const WorkoutCandidateResolver._();

  /// Resolves eligible ranked candidates into warmup/main/cooldown pools.
  static WorkoutGenerationCandidates resolve(
    List<Exercise> exercises,
    WorkoutGenerationContext context,
  ) {
    // Pipeline: eligibility + ranking via existing engine (single source of truth)
    // M12: use effectiveCapabilityProfile for ranking, original userProfile unchanged
    final ranked = ExerciseRankingEngine.rankForUser(
      exercises,
      context.userProfile,
      context.effectiveCapabilityProfile,
    );

    final warmup = <ExerciseRankingResult>[];
    final cooldown = <ExerciseRankingResult>[];
    final main = <ExerciseRankingResult>[];

    for (final result in ranked) {
      final exercise = result.exercise;
      final section = CustomWorkoutSectionClassifier.classify(exercise);

      if (section == WorkoutSectionType.warmup) {
        warmup.add(result);
        continue;
      }
      if (section == WorkoutSectionType.cooldown) {
        cooldown.add(result);
        continue;
      }
      if (section == WorkoutSectionType.main) {
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
