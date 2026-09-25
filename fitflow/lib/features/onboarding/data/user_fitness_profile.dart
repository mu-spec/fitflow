import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';

/// The user's initial FitFlow profile, built from onboarding selections.
///
/// In-memory only for now — it is not persisted yet.
class UserFitnessProfile {
  const UserFitnessProfile({
    required this.goal,
    required this.experience,
    required this.workoutDuration,
    required this.environment,
    this.equipment = const {},
    this.preferences = const {},
  });

  /// Main training goal.
  final FitnessGoal goal;

  /// Current experience level.
  final ExperienceLevel experience;

  /// Typical available workout time.
  final WorkoutDuration workoutDuration;

  /// Usual training environment.
  final TrainingEnvironment environment;

  /// Equipment the user has available.
  final Set<WorkoutEquipment> equipment;

  /// Optional workout preferences; may be empty.
  final Set<WorkoutPreference> preferences;
}
