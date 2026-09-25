import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory onboarding selections. Not persisted yet.
class OnboardingState {
  const OnboardingState({
    this.goal,
    this.experience,
    this.workoutDuration,
    this.environment,
    this.equipment = const <WorkoutEquipment>{},
    this.preferences = const <WorkoutPreference>{},
  });

  final FitnessGoal? goal;
  final ExperienceLevel? experience;
  final WorkoutDuration? workoutDuration;
  final TrainingEnvironment? environment;

  /// Equipment the user has available. Selecting [WorkoutEquipment.none]
  /// clears every other item; selecting any other item removes `none`.
  final Set<WorkoutEquipment> equipment;

  /// Optional workout preferences. May stay empty.
  final Set<WorkoutPreference> preferences;

  OnboardingState copyWith({
    FitnessGoal? goal,
    ExperienceLevel? experience,
    WorkoutDuration? workoutDuration,
    TrainingEnvironment? environment,
    Set<WorkoutEquipment>? equipment,
    Set<WorkoutPreference>? preferences,
  }) {
    return OnboardingState(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      environment: environment ?? this.environment,
      equipment: equipment ?? this.equipment,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Whether every value required for a valid profile is present.
  bool get hasRequiredProfileFields =>
      goal != null &&
      experience != null &&
      workoutDuration != null &&
      environment != null &&
      equipment.isNotEmpty;

  /// Builds the user's initial fitness profile if all required fields are
  /// present, otherwise returns null.
  ///
  /// Preferences are optional and may be empty.
  UserFitnessProfile? toUserFitnessProfile() {
    if (!hasRequiredProfileFields) {
      return null;
    }

    return UserFitnessProfile(
      goal: goal!,
      experience: experience!,
      workoutDuration: workoutDuration!,
      environment: environment!,
      equipment: Set.unmodifiable(equipment),
      preferences: Set.unmodifiable(preferences),
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

  /// Toggles a piece of equipment. Selecting [WorkoutEquipment.none] clears
  /// every other selection; selecting any other item removes `none`.
  void toggleEquipment(WorkoutEquipment item) {
    if (item == WorkoutEquipment.none) {
      state = state.copyWith(equipment: {WorkoutEquipment.none});
      return;
    }

    final updated = {...state.equipment}..remove(WorkoutEquipment.none);
    if (!updated.remove(item)) {
      updated.add(item);
    }
    state = state.copyWith(equipment: updated);
  }

  /// Toggles a workout preference on or off. Preferences are optional, so an
  /// empty selection is valid.
  void togglePreference(WorkoutPreference preference) {
    final updated = {...state.preferences};
    if (!updated.remove(preference)) {
      updated.add(preference);
    }
    state = state.copyWith(preferences: updated);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
