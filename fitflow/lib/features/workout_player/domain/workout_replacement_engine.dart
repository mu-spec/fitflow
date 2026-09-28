import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_engine.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';

/// Transparent, deterministic, constraint-safe exercise replacement engine.
///
/// Reuses existing eligibility and ranking engines.
/// No randomness, no fake AI claims.
class WorkoutReplacementEngine {
  const WorkoutReplacementEngine._();

  /// Returns up to 3 deterministic replacement options for [currentPrescription].
  ///
  /// Rules (must satisfy ALL):
  /// 1. candidate ID != current ID
  /// 2. same movementPattern exact
  /// 3. same exerciseType exact
  /// 4. eligible via ExerciseEligibilityEngine
  /// 5. difficulty NOT exceeding current difficulty
  /// 6. not already used elsewhere in effective session
  /// 7. valid metadata
  /// 8. valid replacement prescription (preserved workload)
  static List<WorkoutReplacementOption> getAlternatives({
    required WorkoutExercisePrescription currentPrescription,
    required ExerciseEligibilityContext eligibilityContext,
    required UserFitnessProfile userProfile,
    required CapabilityProfile capabilityProfile,
    required Set<String> effectiveExerciseIdsElsewhere,
    List<Exercise>? catalog,
    int maxOptions = 3,
  }) {
    final currentExercise = currentPrescription.exercise;
    final all = catalog ?? ExerciseCatalog.all;

    // Validate current has movement pattern (defensive)
    if (currentExercise.movementPattern == null) {
      return const [];
    }

    final candidates = <Exercise>[];

    for (final candidate in all) {
      // 1. ID != current
      if (candidate.id == currentExercise.id) continue;

      // 7. valid metadata
      if (!candidate.isValid) continue;

      // 2. same movementPattern exact
      if (candidate.movementPattern != currentExercise.movementPattern) continue;

      // 3. same exerciseType exact
      if (candidate.exerciseType != currentExercise.exerciseType) continue;

      // 5. difficulty NOT exceed current
      if (_difficultyRank(candidate.difficulty) > _difficultyRank(currentExercise.difficulty)) continue;

      // 6. duplicate protection: not already elsewhere in effective session
      if (effectiveExerciseIdsElsewhere.contains(candidate.id)) continue;

      // 4. eligibility via existing engine
      final eligibility = ExerciseEligibilityEngine.evaluate(candidate, eligibilityContext);
      if (!eligibility.eligible) continue;

      // 8. produce valid replacement prescription preserving workload
      final replacementPrescription = WorkoutExercisePrescription(
        exercise: candidate,
        sets: currentPrescription.sets,
        repsPerSet: currentPrescription.repsPerSet,
        workDuration: currentPrescription.workDuration,
        restBetweenSets: currentPrescription.restBetweenSets,
      );

      if (!replacementPrescription.isValid) continue;

      candidates.add(candidate);
    }

    if (candidates.isEmpty) {
      return const [];
    }

    // 5. Deterministic ranking using existing ranking engine
    final ranked = ExerciseRankingEngine.rankForUser(candidates, userProfile, capabilityProfile);

    final top = ranked.take(maxOptions).toList();

    final options = <WorkoutReplacementOption>[];
    for (final result in top) {
      final exercise = result.exercise;
      final prescription = WorkoutExercisePrescription(
        exercise: exercise,
        sets: currentPrescription.sets,
        repsPerSet: currentPrescription.repsPerSet,
        workDuration: currentPrescription.workDuration,
        restBetweenSets: currentPrescription.restBetweenSets,
      );

      // Build factual reasons
      final reasons = <WorkoutReplacementReason>[];

      // Same movement focus – always true for filtered candidates
      reasons.add(WorkoutReplacementReason.sameMovementFocus);

      // Difficulty reasons
      final currentRank = _difficultyRank(currentExercise.difficulty);
      final candidateRank = _difficultyRank(exercise.difficulty);
      if (candidateRank == currentRank) {
        reasons.add(WorkoutReplacementReason.sameDifficulty);
      } else if (candidateRank < currentRank) {
        reasons.add(WorkoutReplacementReason.easierVariation);
      }

      // Fits setup – true because eligible
      reasons.add(WorkoutReplacementReason.fitsSetup);

      // Matches preferences – true if preferences non-empty and eligible (factual)
      if (eligibilityContext.preferences.isNotEmpty) {
        reasons.add(WorkoutReplacementReason.matchesPreferences);
      }

      // Same progression family
      if (exercise.progressionFamilyId != null &&
          exercise.progressionFamilyId == currentExercise.progressionFamilyId) {
        reasons.add(WorkoutReplacementReason.sameProgressionFamily);
      }

      // Keeps workload – always true
      reasons.add(WorkoutReplacementReason.keepsWorkload);

      options.add(
        WorkoutReplacementOption(
          exercise: exercise,
          prescription: prescription,
          reasons: List.unmodifiable(reasons),
        ),
      );
    }

    return List.unmodifiable(options);
  }

  static int _difficultyRank(ExerciseDifficulty d) {
    switch (d) {
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
