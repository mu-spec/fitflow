import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_diversifier.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_candidate_resolver.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_limits.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_section_builder.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_volume_filler.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

/// Deterministic complete workout generator — Final Milestone.
///
/// Flow:
/// 1. resolve candidates
/// 2. diversify MAIN candidates (deterministic two-pass unique movement first)
/// 3. build warmup using builder
/// 4. build main using diversified candidates
/// 5. build cooldown using builder
/// 6. require all three non-empty
/// 7. fill warmup/main/cooldown volume via round-robin set increments within budgets
/// 8. build WorkoutPlan
/// 9. validate plan
///
/// Preserves existing pipeline:
/// Eligibility → Ranking → Candidate Pools → Section Builder → WorkoutPlan
/// Reuses all existing systems, no duplication.
class WorkoutGenerator {
  const WorkoutGenerator._();

  /// Main API: generate from arbitrary exercise list and context.
  ///
  /// Returns null when complete valid workout cannot be produced:
  /// - builder returns null unexpectedly
  /// - any required section empty
  /// - volume filler fails
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

    // 4. Diversify MAIN candidates only (Final)
    final diversifiedMain =
        WorkoutCandidateDiversifier.diversifyMain(candidates.main);

    // 5. Build each section using existing builder (5D-2)
    final warmupSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.warmup,
      candidates: candidates.warmup,
      budget: warmupBudget,
      maxExercises: limits.warmupMax,
    );

    final mainSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.main,
      candidates: diversifiedMain,
      budget: mainBudget,
      maxExercises: limits.mainMax,
    );

    final cooldownSection = WorkoutSectionBuilder.build(
      type: WorkoutSectionType.cooldown,
      candidates: candidates.cooldown,
      budget: cooldownBudget,
      maxExercises: limits.cooldownMax,
    );

    // 6. Builder failure -> null
    if (warmupSection == null ||
        mainSection == null ||
        cooldownSection == null) {
      return null;
    }

    // 7. Empty required section -> null
    if (warmupSection.isEmpty ||
        mainSection.isEmpty ||
        cooldownSection.isEmpty) {
      return null;
    }

    // 8. Fill volume within budgets (Final)
    final filledWarmup =
        WorkoutVolumeFiller.fill(warmupSection, warmupBudget);
    final filledMain = WorkoutVolumeFiller.fill(mainSection, mainBudget);
    final filledCooldown =
        WorkoutVolumeFiller.fill(cooldownSection, cooldownBudget);

    if (filledWarmup == null ||
        filledMain == null ||
        filledCooldown == null) {
      return null;
    }

    // Ensure filled sections still non-empty (should be, but defensive)
    if (filledWarmup.isEmpty ||
        filledMain.isEmpty ||
        filledCooldown.isEmpty) {
      return null;
    }

    // 9. Plan construction using context.timeBudget
    final plan = WorkoutPlan(
      warmup: filledWarmup,
      main: filledMain,
      cooldown: filledCooldown,
      timeBudget: context.timeBudget,
    );

    // 10. Final validation
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
