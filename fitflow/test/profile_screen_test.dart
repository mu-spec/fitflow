import 'dart:async';

import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  UserFitnessProfile summaryProfile() => UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.someExperience,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: const {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.exerciseMat,
          WorkoutEquipment.chair,
          WorkoutEquipment.towel,
        },
        preferences: const {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.standingOnly,
        },
      );

  group('Profile screen — real summaries', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(summaryProfile()),
      );
    });

    testWidgets('old placeholder copy is gone', (tester) async {
      await pumpProfileApp(tester);

      expect(find.text('Your body and training goals.'), findsNothing);
      expect(find.text('Choose the equipment you train with.'), findsNothing);
      expect(find.text('Adjust how your workouts feel.'), findsNothing);
    });

    testWidgets('shows header and supporting copy', (tester) async {
      await pumpProfileApp(tester);

      expect(find.text('Your profile'), findsOneWidget);
      expect(
        find.text('Your settings shape how FitFlow adapts future workouts.'),
        findsOneWidget,
      );
    });

    testWidgets('Fitness Profile row shows the real summary', (tester) async {
      await pumpProfileApp(tester);

      expect(find.text('Fitness Profile'), findsOneWidget);
      expect(
        find.text('General fitness • Some experience\n20 minutes • Normal home'),
        findsOneWidget,
      );
    });

    testWidgets('Equipment row shows a deterministic summary', (tester) async {
      await pumpProfileApp(tester);

      // Four real items in enum declaration order: first two labels + "+2".
      expect(find.text('Exercise mat, Chair +2'), findsOneWidget);
    });

    testWidgets('Preferences row shows a deterministic summary', (tester) async {
      await pumpProfileApp(tester);

      expect(find.text('No jumping, Low impact +1'), findsOneWidget);
    });

    testWidgets('Equipment row shows None when only None is selected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(
          summaryProfile().copyWith(equipment: const {WorkoutEquipment.none}),
        ),
      );
      await pumpProfileApp(tester);

      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('Preferences row shows the empty fallback', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(summaryProfile().copyWith(preferences: const {})),
      );
      await pumpProfileApp(tester);

      expect(find.text('No special workout preferences'), findsOneWidget);
    });

    testWidgets('Settings entry remains and still opens Settings', (
      tester,
    ) async {
      await pumpProfileApp(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your app.'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await settleProfileFrames(tester);

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('tapping Fitness Profile opens its editor', (tester) async {
      await pumpProfileApp(tester);

      await tester.tap(find.text('Fitness Profile'));
      await settleProfileFrames(tester);

      expect(
        find.text('These settings shape future adaptive workouts.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Equipment opens its editor', (tester) async {
      await pumpProfileApp(tester);

      await tester.tap(find.text('Equipment'));
      await settleProfileFrames(tester);

      expect(
        find.text('Choose the equipment you currently have available.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Workout Preferences opens its editor', (tester) async {
      await pumpProfileApp(tester);

      await tester.tap(find.text('Workout Preferences'));
      await settleProfileFrames(tester);

      expect(
        find.text('FitFlow uses these preferences when choosing exercises.'),
        findsOneWidget,
      );
    });
  });

  group('Profile screen — missing profile states', () {
    testWidgets('loading shows a loading indicator', (tester) async {
      final pending = ScriptedProfileController(null)
        ..loadGate = Completer<UserFitnessProfile?>();
      await pumpProfileApp(
        tester,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => pending),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your profile…'), findsOneWidget);
    });

    testWidgets('error shows a factual retry UI and Retry recovers', (
      tester,
    ) async {
      final flaky = ScriptedProfileController(summaryProfile())
        ..loadFailures = 1;
      await pumpProfileApp(
        tester,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => flaky),
        ],
      );

      expect(find.text("Your profile couldn't be loaded."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await settleProfileFrames(tester);

      expect(find.text('Fitness Profile'), findsOneWidget);
      expect(find.text("Your profile couldn't be loaded."), findsNothing);
    });

    testWidgets('null profile shows setup prompt that opens onboarding', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        overrides: [
          userFitnessProfileProvider
              .overrideWith(() => ScriptedProfileController(null)),
        ],
      );

      expect(find.text('Fitness profile not set up'), findsOneWidget);

      await tester.tap(find.text('Set up profile'));
      await settleProfileFrames(tester);

      expect(find.text('Welcome to FitFlow'), findsOneWidget);
    });
  });

  group('Profile screen — layout safety', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(summaryProfile()),
      );
    });

    testWidgets('fits a 320px wide screen', (tester) async {
      await pumpProfileApp(tester, size: const Size(320, 640));

      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Fitness Profile'), findsOneWidget);
      expect(find.text('Exercise mat, Chair +2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a tablet/wide screen', (tester) async {
      await pumpProfileApp(tester, size: const Size(1280, 900));

      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits text scale 1.5', (tester) async {
      await pumpProfileApp(tester, textScale: 1.5);

      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Workout Preferences'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Routes', () {
    test('editor route constants are nested under /profile', () {
      expect(AppRoutes.fitnessProfile, '/profile/fitness-profile');
      expect(AppRoutes.equipment, '/profile/equipment');
      expect(
        AppRoutes.workoutPreferences,
        '/profile/workout-preferences',
      );
    });
  });
}
