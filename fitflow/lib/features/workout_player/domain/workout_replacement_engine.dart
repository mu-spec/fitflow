import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
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
  /// 2b. for mobility, a shared focus (primary muscle or joint-specific tag).
  ///     The mobility pattern alone is not "same movement focus".
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
      if (candidate.movementPattern != currentExercise.movementPattern) {
        continue;
      }

      // 2b. Mobility is a catch-all. Pattern equality is not same focus unless
      // primary muscles or a joint-specific tag actually overlap. Secondary
      // muscles and generic tags (mobility, static_stretch) do not count.
      // If nothing shares a focus, return no option rather than invent one.
      if (!_sharesReplacementFocus(currentExercise, candidate)) continue;

      // 3. same exerciseType exact
      if (candidate.exerciseType != currentExercise.exerciseType) continue;

      // 5. difficulty NOT exceed current
      if (_difficultyRank(candidate.difficulty) >
          _difficultyRank(currentExercise.difficulty)) {
        continue;
      }

      // 6. duplicate protection: not already elsewhere in effective session
      if (effectiveExerciseIdsElsewhere.contains(candidate.id)) continue;

      // 4. eligibility via existing engine
      final eligibility =
          ExerciseEligibilityEngine.evaluate(candidate, eligibilityContext);
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
    final ranked = ExerciseRankingEngine.rankForUser(
        candidates, userProfile, capabilityProfile);

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

      // Same movement focus — true only after the focus filter above.
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

  /// Generic mobility vocabulary. These name a category or role, not a joint.
  static const Set<String> _genericMobilityTags = {
    'mobility',
    'dynamic_mobility',
    'static_stretch',
    'bodyweight',
    'floor_contact',
    'warmup',
    'cooldown',
    'reps_per_side',
    'duration_per_side',
    'prone',
    'full_body',
    'deep_knee_flexion',
    'lunge_plus_rotation',
  };

  /// True when [candidate] may be described as the same movement focus.
  ///
  /// Specific patterns (push, squat, and so on) already name the focus, so
  /// exact pattern equality is enough. [MovementPattern.mobility] does not.
  static bool _sharesReplacementFocus(Exercise current, Exercise candidate) {
    if (current.movementPattern != MovementPattern.mobility) {
      return true;
    }
    if (_mobilityRolesConflict(current, candidate)) {
      return false;
    }
    if (_sharedPrimaryFocus(current, candidate)) {
      return true;
    }
    final currentFocus = _jointFocusTags(current);
    final candidateFocus = _jointFocusTags(candidate);
    return currentFocus.isNotEmpty &&
        currentFocus.intersection(candidateFocus).isNotEmpty;
  }

  /// Warm-up and cooldown are opposite roles. An untagged exercise is not
  /// treated as either, because role tags are incomplete in the catalog.
  static bool _mobilityRolesConflict(Exercise current, Exercise candidate) {
    final currentWarmup = current.tags.contains('warmup');
    final currentCooldown = current.tags.contains('cooldown');
    final candidateWarmup = candidate.tags.contains('warmup');
    final candidateCooldown = candidate.tags.contains('cooldown');
    return (currentWarmup && candidateCooldown) ||
        (currentCooldown && candidateWarmup);
  }

  /// Primary muscles only. Secondary overlap (for example shoulders listed
  /// beside a lat stretch) must not create a shoulder-mobility match.
  /// [MuscleGroup.fullBody] is not a wildcard.
  static bool _sharedPrimaryFocus(Exercise current, Exercise candidate) {
    for (final muscle in current.primaryMuscles) {
      if (muscle == MuscleGroup.fullBody) continue;
      if (candidate.primaryMuscles.contains(muscle)) return true;
    }
    return false;
  }

  static Set<String> _jointFocusTags(Exercise exercise) {
    final focus = <String>{};
    for (final tag in exercise.tags) {
      if (_isJointFocusTag(tag)) focus.add(tag);
    }
    return focus;
  }

  static bool _isJointFocusTag(String tag) {
    if (_genericMobilityTags.contains(tag)) return false;
    return tag.endsWith('_mobility') ||
        tag.endsWith('_stretch') ||
        tag.endsWith('_focus') ||
        tag == 'back_extension';
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
