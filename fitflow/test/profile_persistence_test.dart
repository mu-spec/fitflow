import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  const profile = UserFitnessProfile(
    goal: FitnessGoal.buildStrength,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.outdoor,
    equipment: {
      WorkoutEquipment.exerciseMat,
      WorkoutEquipment.resistanceBands,
      WorkoutEquipment.dumbbells,
    },
    preferences: {
      WorkoutPreference.lowImpact,
      WorkoutPreference.noJumping,
    },
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    await waitUntilOnboarding(tester);
  }

  group('UserFitnessProfileStorage', () {
    test('round-trips a profile with all fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = UserFitnessProfileStorage(prefs);

      expect(await storage.save(profile), isTrue);
      final restored = storage.load();

      expect(restored, isNotNull);
      expect(restored?.goal, FitnessGoal.buildStrength);
      expect(restored?.experience, ExperienceLevel.regularTraining);
      expect(restored?.workoutDuration, WorkoutDuration.twentyMinutes);
      expect(restored?.environment, TrainingEnvironment.outdoor);
      expect(restored?.equipment, profile.equipment);
      expect(restored?.preferences, profile.preferences);
    });

    test('empty preferences restore correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = UserFitnessProfileStorage(prefs);

      const noPreferences = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.thirtyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.chair},
      );
      await storage.save(noPreferences);

      final restored = storage.load();
      expect(restored?.preferences, isEmpty);
    });

    test('multiple equipment selections restore correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = UserFitnessProfileStorage(prefs);

      await storage.save(profile);
      final restored = storage.load();

      expect(
        restored?.equipment,
        WorkoutEquipment.values
            .where(profile.equipment.contains)
            .toSet(),
      );
      expect(restored?.equipment, hasLength(3));
    });

    test('clear removes the stored profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = UserFitnessProfileStorage(prefs);

      await storage.save(profile);
      expect(storage.load(), isNotNull);

      await storage.clear();
      expect(storage.load(), isNull);
    });

    test('returns null for missing, malformed, or invalid data', () async {
      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey: '{not valid json',
      });
      var prefs = await SharedPreferences.getInstance();
      expect(UserFitnessProfileStorage(prefs).load(), isNull);

      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey: 'null',
      });
      prefs = await SharedPreferences.getInstance();
      expect(UserFitnessProfileStorage(prefs).load(), isNull);

      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey: '{"goal":"nope"}',
      });
      prefs = await SharedPreferences.getInstance();
      expect(UserFitnessProfileStorage(prefs).load(), isNull);

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      expect(UserFitnessProfileStorage(prefs).load(), isNull);
    });
  });

  group('Startup and onboarding flow', () {
    testWidgets('first launch with no saved profile shows onboarding', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);

      expect(find.text('Welcome to FitFlow'), findsOneWidget);
    });

    testWidgets('completing onboarding saves the profile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      await completeOnboarding(tester);

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final saved = UserFitnessProfileStorage(prefs).load();
      expect(saved, isNotNull);
      expect(saved?.goal, FitnessGoal.generalFitness);
      expect(saved?.equipment, isNotEmpty);
    });

    testWidgets('restart with a saved profile goes straight to Home', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(profile);
      await pumpApp(tester);

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);
      expect(find.text('Welcome to FitFlow'), findsNothing);
    });

    testWidgets('malformed profile data falls back to onboarding', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey: '{broken json!',
      });
      await pumpApp(tester);

      expect(find.text('Welcome to FitFlow'), findsOneWidget);
    });

    testWidgets('stored profile is exposed through the provider', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(profile);
      await pumpApp(tester);

      final context = tester.element(find.byType(Scaffold).first);
      final container = ProviderScope.containerOf(context);
      final loaded = container.read(userFitnessProfileProvider).value;

      expect(loaded, isNotNull);
      expect(loaded?.goal, FitnessGoal.buildStrength);
      expect(loaded?.experience, ExperienceLevel.regularTraining);
    });
  });
}
