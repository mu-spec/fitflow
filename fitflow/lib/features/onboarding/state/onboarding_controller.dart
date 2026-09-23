import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory onboarding selections. Not persisted yet.
class OnboardingState {
  const OnboardingState({
    this.goal,
    this.experience,
  });

  final FitnessGoal? goal;
  final ExperienceLevel? experience;

  OnboardingState copyWith({
    FitnessGoal? goal,
    ExperienceLevel? experience,
  }) {
    return OnboardingState(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
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
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
