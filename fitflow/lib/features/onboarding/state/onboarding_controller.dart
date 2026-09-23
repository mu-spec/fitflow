import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory onboarding selections. Not persisted yet.
class OnboardingState {
  const OnboardingState({
    this.goal,
    this.experience,
    this.workoutDuration,
    this.environment,
  });

  final FitnessGoal? goal;
  final ExperienceLevel? experience;
  final WorkoutDuration? workoutDuration;
  final TrainingEnvironment? environment;

  OnboardingState copyWith({
    FitnessGoal? goal,
    ExperienceLevel? experience,
    WorkoutDuration? workoutDuration,
    TrainingEnvironment? environment,
  }) {
    return OnboardingState(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      environment: environment ?? this.environment,
    );
  }
}

/// Holds the onboarding selections for the active session.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectGoal(FitnessGoal goal) {
    state = state.copyWith(goal: goal);
  }

  void selectExperience(ExperienceLevel experience) {
    state = state.copyWith(experience: experience);
  }

  void selectWorkoutDuration(WorkoutDuration duration) {
    state = state.copyWith(workoutDuration: duration);
  }

  void selectEnvironment(TrainingEnvironment environment) {
    state = state.copyWith(environment: environment);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
