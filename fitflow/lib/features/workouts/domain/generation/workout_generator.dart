import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_limits.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_section_builder.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

/// Deterministic complete workout generator V1 (5D-3).
///
/// Composes:
/// candidate resolver → section builder → complete WorkoutPlan
///
/// - Uses existing candidate resolver (eligibility+ranking+classification)
/// - Uses existing section builder (default prescriptions, budget fit, max count, transitions)
/// - Uses context.timeBudget for section budgets
/// - Uses explicit duration-based max exercise counts (single source of truth)
/// - Requires all three sections non-empty, otherwise returns null
/// - Returns null if final plan invalid
/// - No movement diversity, no randomization, no volume scaling
class WorkoutGenerator {
  const WorkoutGenerator._();

  /// Main API: generate from arbitrary exercise list and context.
  ///
  /// Returns null when complete valid workout cannot be produced:
  /// - builder returns null unexpectedly
  /// - any required section empty (no candidates, cannot fit, missing defaults)
  /// - final plan invalid
  ///
  /// Does not mutate inputs. Deterministic.
  static WorkoutPlan? generate(
    List<Exercise> exercises,
    WorkoutGenerationContext context,
  ) {
    // 1. Resolve eligible/ranked candidates (5D-1)
    final candidates = WorkoutCandidateResolver.resolve(exercises, context);

    // 2. Explicit count policy single source of truth
    final limits = WorkoutGenerationLimits.fromWorkoutDuration(
        context.userProfile.workoutDuration);

    // 3. Section budgets from context.timeBudget (5C-2)
    final warmupBudget =
        context.timeBudget.budgetFor(WorkoutSectionType.warmup);
    final mainBudget = context.timeBudget.budgetFor(WorkoutSectionType.main);
    final cooldownBudget =
        context.timeBudget.budgetFor(WorkoutSectionType.cooldown);

    // 4. Build each section using existing builder (5D-2)
    final warmupSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.warmup,
      candidates: candidates.warmup,
      budget: warmupBudget,
      maxExercises: limits.warmupMax,
    );

    final mainSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.main,
      candidates: candidates.main,
      budget: mainBudget,
      maxExercises: limits.mainMax,
    );

    final cooldownSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.cooldown,
      candidates: candidates.cooldown,
      budget: cooldownBudget,
      maxExercises: limits.cooldownMax,
    );

    // 5. Builder failure -> null
    if (warmupSection == null ||
        mainSection == null ||
        cooldownSection == null) {
      return null;
    }

    // 6. Empty required section -> null (complete plan requires all three non-empty)
    if (warmupSection.isEmpty ||
        mainSection.isEmpty ||
        cooldownSection.isEmpty) {
      return null;
    }

    // 7. Plan construction using context.timeBudget (no second budget)
    final plan = WorkoutPlan(
      warmup: warmupSection,
      main: mainSection,
      cooldown: cooldownSection,
      timeBudget: context.timeBudget,
    );

    // 8. Final validation
    if (!plan.isValid) {
      return null;
    }

    return plan;
  }

  /// Convenience: generate from full catalog.
  /// Delegates to generate(ExerciseCatalog.all, context)
  static WorkoutPlan? generateCatalog(
    WorkoutGenerationContext context,
  ) {
    return generate(ExerciseCatalog.all, context);
  }
}
