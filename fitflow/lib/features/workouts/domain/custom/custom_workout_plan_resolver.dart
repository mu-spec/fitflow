import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

class CustomWorkoutResolverIssue {
  const CustomWorkoutResolverIssue(this.message);
  final String message;
}

class CustomWorkoutPlanResolution {
  const CustomWorkoutPlanResolution({
    required this.plan,
    required this.issues,
  });

  final WorkoutPlan? plan;
  final List<CustomWorkoutResolverIssue> issues;

  bool get isValid => plan != null && issues.isEmpty;
}

/// Pure resolver – input template + catalog + profiles → valid WorkoutPlan OR explicit issues.
/// Does NOT silently remove entries. Does NOT mutate original profile.
class CustomWorkoutPlanResolver {
  const CustomWorkoutPlanResolver._();

  static CustomWorkoutPlanResolution resolve({
    required CustomWorkoutTemplate template,
    required Map<String, Exercise> catalogById,
    required dynamic userFitnessProfile, // UserFitnessProfile – avoid tight import cycle
    required CapabilityProfile capabilityProfile,
  }) {
    final issues = <CustomWorkoutResolverIssue>[];

    // Build eligibility context
    ExerciseEligibilityContext eligibilityContext;
    try {
      eligibilityContext = ExerciseEligibilityContext.fromProfiles(
        userProfile: userFitnessProfile,
        capabilityProfile: capabilityProfile,
      );
    } catch (e) {
      issues.add(CustomWorkoutResolverIssue('Unable to build eligibility context: $e'));
      return CustomWorkoutPlanResolution(plan: null, issues: issues);
    }

    // Duplicate check
    final seenIds = <String>{};
    for (final entry in template.allEntries) {
      if (!seenIds.add(entry.exerciseId)) {
        final ex = catalogById[entry.exerciseId];
        issues.add(CustomWorkoutResolverIssue(
            'Duplicate exercise: ${ex?.name ?? entry.exerciseId}. Each exercise can only be used once.'));
      }
    }

    // Helper to resolve section entries to prescriptions
    List<WorkoutExercisePrescription>? resolveSection(
      List<CustomWorkoutExerciseEntry> entries,
      WorkoutSectionType expectedType,
    ) {
      final prescriptions = <WorkoutExercisePrescription>[];
      for (final entry in entries) {
        final exercise = catalogById[entry.exerciseId];
        if (exercise == null) {
          issues.add(CustomWorkoutResolverIssue('Exercise not found: ${entry.exerciseId}.'));
          continue;
        }

        if (!exercise.active) {
          issues.add(CustomWorkoutResolverIssue('Exercise is no longer available: ${exercise.name}.'));
          continue;
        }

        // Section classification
        final actualSection = CustomWorkoutSectionClassifier.classify(exercise);
        if (actualSection == null) {
          issues.add(CustomWorkoutResolverIssue('Exercise not available for custom workouts: ${exercise.name}.'));
          continue;
        }
        if (actualSection != expectedType) {
          issues.add(CustomWorkoutResolverIssue(
              'Exercise ${exercise.name} does not belong to ${expectedType.name} section.'));
          continue;
        }

        // Eligibility – warmup/cooldown exempt per existing logic
        final isWarmupOrCooldown = expectedType != WorkoutSectionType.main;
        if (!isWarmupOrCooldown) {
          // For main section, check eligibility via engine
          final result = ExerciseEligibilityEngine.evaluate(exercise, eligibilityContext);
          if (!result.eligible) {
            issues.add(CustomWorkoutResolverIssue(
                'Exercise ${exercise.name} is not eligible for your current setup.'));
            continue;
          }
        }

        // Build prescription from entry – do not fabricate
        final prescription = _prescriptionFromEntry(entry, exercise);
        if (prescription == null) {
          issues.add(CustomWorkoutResolverIssue('Invalid prescription for ${exercise.name}.'));
          continue;
        }

        prescriptions.add(prescription);
      }
      return prescriptions;
    }

    final warmupPres = resolveSection(template.warmup, WorkoutSectionType.warmup);
    final mainPres = resolveSection(template.main, WorkoutSectionType.main);
    final cooldownPres = resolveSection(template.cooldown, WorkoutSectionType.cooldown);

    if (issues.isNotEmpty) {
      return CustomWorkoutPlanResolution(plan: null, issues: List.unmodifiable(issues));
    }

    if (warmupPres == null || mainPres == null || cooldownPres == null) {
      return CustomWorkoutPlanResolution(plan: null, issues: List.unmodifiable(issues));
    }

    if (warmupPres.isEmpty || mainPres.isEmpty || cooldownPres.isEmpty) {
      if (warmupPres.isEmpty) issues.add(const CustomWorkoutResolverIssue('Warm-up section is empty.'));
      if (mainPres.isEmpty) issues.add(const CustomWorkoutResolverIssue('Main section is empty.'));
      if (cooldownPres.isEmpty) issues.add(const CustomWorkoutResolverIssue('Cool-down section is empty.'));
      return CustomWorkoutPlanResolution(plan: null, issues: List.unmodifiable(issues));
    }

    try {
      final plan = WorkoutPlan.withWorkoutDuration(
        workoutDuration: template.targetDuration,
        warmup: WorkoutSection(
          type: WorkoutSectionType.warmup,
          exercises: warmupPres,
        ),
        main: WorkoutSection(
          type: WorkoutSectionType.main,
          exercises: mainPres,
        ),
        cooldown: WorkoutSection(
          type: WorkoutSectionType.cooldown,
          exercises: cooldownPres,
        ),
      );

      return CustomWorkoutPlanResolution(plan: plan, issues: const []);
    } catch (e) {
      issues.add(CustomWorkoutResolverIssue('Failed to build workout plan: $e'));
      return CustomWorkoutPlanResolution(plan: null, issues: List.unmodifiable(issues));
    }
  }

  static WorkoutExercisePrescription? _prescriptionFromEntry(
    CustomWorkoutExerciseEntry entry,
    Exercise exercise,
  ) {
    try {
      if (entry.isTimed) {
        return WorkoutExercisePrescription(
          exercise: exercise,
          sets: entry.sets,
          workDuration: entry.workDuration,
          restBetweenSets: entry.restBetweenSets,
        );
      } else {
        return WorkoutExercisePrescription(
          exercise: exercise,
          sets: entry.sets,
          repsPerSet: entry.repsPerSet,
          restBetweenSets: entry.restBetweenSets,
        );
      }
    } catch (_) {
      return null;
    }
  }
}
