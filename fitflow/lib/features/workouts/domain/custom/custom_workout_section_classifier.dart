import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';

/// Pure reusable section classification helper – single source of truth for M13 and refactored resolver.
class CustomWorkoutSectionClassifier {
  const CustomWorkoutSectionClassifier._();

  static const String warmupTag = 'warmup';
  static const String cooldownTag = 'cooldown';

  static WorkoutSectionType? classify(Exercise exercise) {
    final pattern = exercise.movementPattern;

    if (pattern == MovementPattern.warmup || exercise.tags.contains(warmupTag)) {
      return WorkoutSectionType.warmup;
    }
    if (pattern == MovementPattern.cooldown || exercise.tags.contains(cooldownTag)) {
      return WorkoutSectionType.cooldown;
    }
    if (pattern != null && CapabilityProfile.trainablePatterns.contains(pattern)) {
      return WorkoutSectionType.main;
    }
    return null; // unclassified
  }

  static bool isWarmup(Exercise ex) => classify(ex) == WorkoutSectionType.warmup;
  static bool isCooldown(Exercise ex) => classify(ex) == WorkoutSectionType.cooldown;
  static bool isMain(Exercise ex) => classify(ex) == WorkoutSectionType.main;
}
