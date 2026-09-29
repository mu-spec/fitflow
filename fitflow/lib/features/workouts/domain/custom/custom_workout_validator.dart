import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_limits.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

class CustomWorkoutValidationResult {
  const CustomWorkoutValidationResult({
    required this.isValid,
    required this.issues,
  });

  final bool isValid;
  final List<String> issues;

  static const valid = CustomWorkoutValidationResult(isValid: true, issues: []);
}

class CustomWorkoutValidator {
  const CustomWorkoutValidator._();

  /// Pure validation – no silent discard.
  static CustomWorkoutValidationResult validateTemplate({
    required CustomWorkoutTemplate template,
    required Map<String, Exercise> catalogById,
  }) {
    final issues = <String>[];

    final trimmedName = template.name.trim();
    if (trimmedName.isEmpty) {
      issues.add('Workout name is required.');
    } else if (trimmedName.length > CustomWorkoutLimits.nameMaxLength) {
      issues.add('Workout name must be at most ${CustomWorkoutLimits.nameMaxLength} characters.');
    }

    if (template.warmup.isEmpty) {
      issues.add('Add at least one warm-up exercise.');
    }
    if (template.main.isEmpty) {
      issues.add('Add at least one main exercise.');
    }
    if (template.cooldown.isEmpty) {
      issues.add('Add at least one cool-down exercise.');
    }

    // Validate all prescriptions
    for (final e in template.allEntries) {
      final presIssue = _validateEntry(e);
      if (presIssue != null) {
        issues.add('Invalid prescription for ${e.exerciseId}: $presIssue');
      }
    }

    // Every exerciseId resolves
    for (final e in template.allEntries) {
      if (!catalogById.containsKey(e.exerciseId)) {
        issues.add('Exercise not found: ${e.exerciseId}.');
      }
    }

    // Check active and valid and correct section, duplicate detection
    final seen = <String>{};
    for (final entry in template.allEntries) {
      final ex = catalogById[entry.exerciseId];
      if (ex == null) continue;

      if (!ex.active) {
        issues.add('Exercise is no longer available: ${ex.name}.');
      }

      // Correct section
      final expectedSection = _sectionForEntry(entry, template);
      final actualSection = CustomWorkoutSectionClassifier.classify(ex);
      if (actualSection == null) {
        issues.add('Exercise is not available for custom workouts: ${ex.name}.');
      } else if (expectedSection != actualSection) {
        issues.add('Exercise ${ex.name} does not belong to ${expectedSection.name} section.');
      }

      // Duplicate check across entire workout
      if (!seen.add(entry.exerciseId)) {
        issues.add('Duplicate exercise: ${ex.name}. Each exercise can only be used once.');
      }
    }

    return CustomWorkoutValidationResult(
      isValid: issues.isEmpty,
      issues: List.unmodifiable(issues),
    );
  }

  static WorkoutSectionType _sectionForEntry(CustomWorkoutExerciseEntry entry, CustomWorkoutTemplate template) {
    if (template.warmup.contains(entry)) return WorkoutSectionType.warmup;
    if (template.main.contains(entry)) return WorkoutSectionType.main;
    return WorkoutSectionType.cooldown;
  }

  static String? _validateEntry(CustomWorkoutExerciseEntry entry) {
    if (entry.sets < CustomWorkoutLimits.setsMin || entry.sets > CustomWorkoutLimits.setsMax) {
      return 'Sets must be ${CustomWorkoutLimits.setsMin}..${CustomWorkoutLimits.setsMax}.';
    }
    if (entry.restBetweenSets.inSeconds < CustomWorkoutLimits.restMinSec ||
        entry.restBetweenSets.inSeconds > CustomWorkoutLimits.restMaxSec) {
      return 'Rest must be ${CustomWorkoutLimits.restMinSec}..${CustomWorkoutLimits.restMaxSec} sec.';
    }
    if (entry.isTimed) {
      final dur = entry.workDuration!.inSeconds;
      if (dur < CustomWorkoutLimits.timedWorkMinSec || dur > CustomWorkoutLimits.timedWorkMaxSec) {
        return 'Work duration must be ${CustomWorkoutLimits.timedWorkMinSec}..${CustomWorkoutLimits.timedWorkMaxSec} sec.';
      }
      if (entry.repsPerSet != null) {
        return 'Timed exercise cannot have reps.';
      }
    } else {
      final reps = entry.repsPerSet;
      if (reps == null) {
        return 'Reps required for rep-based exercise.';
      }
      if (reps < CustomWorkoutLimits.repsMin || reps > CustomWorkoutLimits.repsMax) {
        return 'Reps must be ${CustomWorkoutLimits.repsMin}..${CustomWorkoutLimits.repsMax}.';
      }
      if (entry.workDuration != null) {
        return 'Rep-based exercise cannot have work duration.';
      }
    }
    return null;
  }

  static String? validateName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Workout name is required.';
    if (trimmed.length > CustomWorkoutLimits.nameMaxLength) {
      return 'Workout name must be at most ${CustomWorkoutLimits.nameMaxLength} characters.';
    }
    return null;
  }

  static String? validateDuration(WorkoutDuration? duration) {
    if (duration == null) return 'Select a target duration.';
    return null;
  }
}
