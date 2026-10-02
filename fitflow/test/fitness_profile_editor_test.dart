import 'dart:async';

import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/fitness_profile_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  /// Where the Profile tab lives after popping the editor.
  final profileListVisible = find.text(
    'Your settings shape how FitFlow adapts future workouts.',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(
      seedProfilePrefs(profileEditorSeed()),
    );
  });

  group('Fitness profile editor — draft loading', () {
    testWidgets('shows persisted values as selected', (tester) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      expect(optionCardSelected(tester, 'Build strength'), isTrue);
      expect(optionCardSelected(tester, 'Some experience'), isTrue);
      expect(optionCardSelected(tester, '20 minutes'), isTrue);
      expect(optionCardSelected(tester, 'Normal home'), isTrue);

      expect(optionCardSelected(tester, 'General fitness'), isFalse);
      expect(optionCardSelected(tester, '5 minutes'), isFalse);
    });

    testWidgets('offers every enum value in each section', (tester) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      for (final goal in FitnessGoal.values) {
        expect(find.text(goal.label), findsOneWidget, reason: goal.name);
      }
      for (final level in ExperienceLevel.values) {
        expect(find.text(level.label), findsOneWidget, reason: level.name);
        expect(find.text(level.helperText), findsOneWidget,
            reason: '${level.name} helper');
      }
      for (final duration in WorkoutDuration.values) {
        expect(find.text(duration.label), findsOneWidget,
            reason: duration.name);
      }
      for (final env in TrainingEnvironment.values) {
        expect(find.text(env.label), findsOneWidget, reason: env.name);
      }
    });

    testWidgets('does not edit equipment or preferences here', (tester) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      expect(find.text('Chair'), findsNothing);
      expect(find.text('No jumping'), findsNothing);
    });
  });

  group('Fitness profile editor — draft-then-save', () {
    testWidgets('selections update the draft only, never persistence', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );
      final prefs = await SharedPreferences.getInstance();
      final storedBefore =
          prefs.getString(UserFitnessProfileStorage.profileKey);

      await tapOption(tester, 'Build muscle');
      await tapOption(tester, 'Experienced');
      await tapOption(tester, '45 minutes');
      await tapOption(tester, 'Outdoor');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'Build muscle'), isTrue);
      expect(optionCardSelected(tester, 'Experienced'), isTrue);
      expect(optionCardSelected(tester, '45 minutes'), isTrue);
      expect(optionCardSelected(tester, 'Outdoor'), isTrue);

      // Nothing persisted, provider untouched.
      expect(
        prefs.getString(UserFitnessProfileStorage.profileKey),
        storedBefore,
      );
      final container = containerOf(tester);
      final profile = container.read(userFitnessProfileProvider).value!;
      expect(profile.goal, FitnessGoal.buildStrength);
      expect(profile.experience, ExperienceLevel.someExperience);
    });

    testWidgets('Save is disabled while the draft equals the persisted state', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save changes'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('successful save persists, updates provider, shows message', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      await tapOption(tester, 'Lose weight');
      await tapOption(tester, '5 minutes');
      await settleProfileFrames(tester);

      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      // Success message and navigation back to the Profile tab.
      expect(find.text('Fitness profile updated.'), findsOneWidget);
      expect(profileListVisible, findsOneWidget);

      // Persistence and provider reflect the new profile.
      final prefs = await SharedPreferences.getInstance();
      final stored = UserFitnessProfileStorage(prefs).load()!;
      expect(stored.goal, FitnessGoal.loseWeight);
      expect(stored.workoutDuration, WorkoutDuration.fiveMinutes);

      final container = containerOf(tester);
      final profile = container.read(userFitnessProfileProvider).value!;
      expect(profile.goal, FitnessGoal.loseWeight);
      expect(profile.workoutDuration, WorkoutDuration.fiveMinutes);

      // Untouched fields survive the save.
      expect(stored.experience, profileEditorSeed().experience);
      expect(stored.environment, profileEditorSeed().environment);
      expect(stored.equipment, profileEditorSeed().equipment);
      expect(stored.preferences, profileEditorSeed().preferences);
    });

    testWidgets('failed save stays on screen and keeps the old profile', (
      tester,
    ) async {
      final failing = ScriptedProfileController(profileEditorSeed())
        ..saveResult = false;
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => failing),
        ],
      );

      await tapOption(tester, 'Improve endurance');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      // Still on the editor with the failure message.
      expect(
        find.text('These settings shape future adaptive workouts.'),
        findsOneWidget,
      );
      expect(
        find.text("Couldn't save your changes. Try again."),
        findsOneWidget,
      );

      // Provider still exposes the OLD profile — never the unsaved draft.
      final container = containerOf(tester);
      final profile = container.read(userFitnessProfileProvider).value!;
      expect(profile.goal, FitnessGoal.buildStrength);
      expect(failing.profile!.goal, FitnessGoal.buildStrength);
    });
  });

  group('Fitness profile editor — save concurrency', () {
    testWidgets('duplicate Save presses cannot start a second write', (
      tester,
    ) async {
      final gated = ScriptedProfileController(profileEditorSeed())
        ..gate = Completer<bool>();
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => gated),
        ],
      );

      await tapOption(tester, 'Stay active');
      await settleProfileFrames(tester);

      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester, 3);

      // Save is in flight: busy indicator shown, button disabled.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save changes'),
      );
      expect(button.onPressed, isNull);

      // A second press while in flight must not start another write.
      await tester.tap(find.text('Save changes'), warnIfMissed: false);
      await settleProfileFrames(tester, 3);
      expect(gated.saveCalls, 1);

      gated.gate!.complete(true);
      await settleProfileFrames(tester);

      expect(gated.saveCalls, 1);
      expect(find.text('Fitness profile updated.'), findsOneWidget);
    });
  });

  group('Fitness profile editor — unsaved changes', () {
    testWidgets('back with changes shows the discard dialog', (tester) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      await tapOption(tester, 'Build muscle');
      await settleProfileFrames(tester);
      await tester.tap(find.byType(BackButton));
      await settleProfileFrames(tester);

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Your unsaved changes will be lost.'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('Keep editing returns to the editor with the draft intact', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      await tapOption(tester, 'Build muscle');
      await settleProfileFrames(tester);
      await tester.tap(find.byType(BackButton));
      await settleProfileFrames(tester);
      await tester.tap(find.text('Keep editing'));
      await settleProfileFrames(tester);

      expect(
        find.text('These settings shape future adaptive workouts.'),
        findsOneWidget,
      );
      expect(optionCardSelected(tester, 'Build muscle'), isTrue);
    });

    testWidgets('Discard leaves without saving', (tester) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );
      final prefs = await SharedPreferences.getInstance();
      final storedBefore =
          prefs.getString(UserFitnessProfileStorage.profileKey);

      await tapOption(tester, 'Build muscle');
      await settleProfileFrames(tester);
      await tester.tap(find.byType(BackButton));
      await settleProfileFrames(tester);
      await tester.tap(find.text('Discard'));
      await settleProfileFrames(tester);

      expect(profileListVisible, findsOneWidget);
      expect(find.text('Discard changes?'), findsNothing);
      expect(
        prefs.getString(UserFitnessProfileStorage.profileKey),
        storedBefore,
      );
    });

    testWidgets('back without changes pops without any dialog', (
      tester,
    ) async {
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.fitnessProfile,
      );

      await tester.tap(find.byType(BackButton));
      await settleProfileFrames(tester);

      expect(find.text('Discard changes?'), findsNothing);
      expect(profileListVisible, findsOneWidget);
    });
  });

  group('Fitness profile editor — success copy', () {
    testWidgets('uses the exact success message', (tester) async {
      expect(
        FitnessProfileEditorScreen.successMessage,
        'Fitness profile updated.',
      );
    });
  });
}
