import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';

/// Pure helper that derives a TEMPORARY generation profile for one program
/// session.
///
/// It copies the CURRENT [UserFitnessProfile] and preserves experience,
/// workoutDuration, environment, equipment and preferences. Only `goal` is
/// overridden with the planned session's generation goal.
///
/// The result is never persisted and the real profile is never mutated.
class AdaptiveProgramGenerationProfile {
  AdaptiveProgramGenerationProfile._();

  static UserFitnessProfile forSession({
    required UserFitnessProfile current,
    required AdaptiveProgramSession session,
  }) {
    return UserFitnessProfile(
      goal: session.generationGoal,
      experience: current.experience,
      workoutDuration: current.workoutDuration,
      environment: current.environment,
      equipment: Set.unmodifiable(current.equipment),
      preferences: Set.unmodifiable(current.preferences),
    );
  }
}
