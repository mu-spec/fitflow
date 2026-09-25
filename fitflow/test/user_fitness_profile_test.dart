import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  OnboardingState completedState({
    FitnessGoal? goal,
    ExperienceLevel? experience,
    WorkoutDuration? workoutDuration,
    TrainingEnvironment? environment,
    Set<WorkoutEquipment>? equipment,
    Set<WorkoutPreference>? preferences,
  }) {
    return OnboardingState(
      goal: goal ?? FitnessGoal.generalFitness,
      experience: experience ?? ExperienceLevel.completelyNew,
      workoutDuration: workoutDuration ?? WorkoutDuration.thirtyMinutes,
      environment: environment ?? TrainingEnvironment.normalHome,
      equipment: equipment ??
          const {WorkoutEquipment.exerciseMat, WorkoutEquipment.chair},
      preferences: preferences ??
          const {WorkoutPreference.noJumping, WorkoutPreference.lowImpact},
    );
  }

  group('OnboardingState.toUserFitnessProfile', () {
    test('completed state creates a valid profile', () {
      final profile = completedState().toUserFitnessProfile();

      expect(profile, isNotNull);
      expect(profile, isA<UserFitnessProfile>());
    });

    test('profile contains correct goal', () {
      final profile = completedState(
        goal: FitnessGoal.buildStrength,
      ).toUserFitnessProfile();

      expect(profile?.goal, FitnessGoal.buildStrength);
    });

    test('profile contains correct experience', () {
      final profile = completedState(
        experience: ExperienceLevel.regularTraining,
      ).toUserFitnessProfile();

      expect(profile?.experience, ExperienceLevel.regularTraining);
    });

    test('profile contains correct workout duration', () {
      final profile = completedState(
        workoutDuration: WorkoutDuration.fifteenMinutes,
      ).toUserFitnessProfile();

      expect(profile?.workoutDuration, WorkoutDuration.fifteenMinutes);
    });

    test('profile contains correct environment', () {
      final profile = completedState(
        environment: TrainingEnvironment.largeRoom,
      ).toUserFitnessProfile();

      expect(profile?.environment, TrainingEnvironment.largeRoom);
    });

    test('equipment is preserved', () {
      const equipment = {
        WorkoutEquipment.dumbbells,
        WorkoutEquipment.resistanceBands,
      };
      final profile =
          completedState(equipment: equipment).toUserFitnessProfile();

      expect(profile?.equipment, equipment);
    });

    test('preferences are preserved', () {
      const preferences = {
        WorkoutPreference.standingOnly,
        WorkoutPreference.noFloorExercises,
      };
      final profile =
          completedState(preferences: preferences).toUserFitnessProfile();

      expect(profile?.preferences, preferences);
    });

    test('empty preferences create a valid profile', () {
      final profile =
          completedState(preferences: const {}).toUserFitnessProfile();

      expect(profile, isNotNull);
      expect(profile?.preferences, isEmpty);
    });

    test('incomplete state cannot create a profile', () {
      const incomplete = OnboardingState();

      expect(incomplete.toUserFitnessProfile(), isNull);
    });

    test('missing equipment cannot create a profile', () {
      final profile =
          completedState(equipment: const {}).toUserFitnessProfile();

      expect(profile, isNull);
    });

    test('missing goal cannot create a profile', () {
      const incomplete = OnboardingState(
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.thirtyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.chair},
      );

      expect(incomplete.toUserFitnessProfile(), isNull);
    });
  });

  group('UserFitnessProfileController', () {
    test('starts null and accepts a profile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(userFitnessProfileProvider), isNull);

      final profile = completedState().toUserFitnessProfile();
      container
          .read(userFitnessProfileProvider.notifier)
          .setProfile(profile!);

      expect(container.read(userFitnessProfileProvider), same(profile));
    });
  });

  group('Get Started wiring', () {
    testWidgets('creates the in-memory profile before opening Home', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await completeOnboarding(tester);

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);

      final context = tester.element(find.byType(Scaffold).first);
      final container = ProviderScope.containerOf(context);
      final profile = container.read(userFitnessProfileProvider);

      expect(profile, isNotNull);
      expect(profile?.goal, FitnessGoal.generalFitness);
      expect(profile?.experience, ExperienceLevel.completelyNew);
      expect(profile?.workoutDuration, WorkoutDuration.fifteenMinutes);
      expect(profile?.environment, TrainingEnvironment.normalHome);
      expect(profile?.equipment, isNotEmpty);
    });
  });
}
