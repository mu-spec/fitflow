import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/profile_summary_format.dart';
import 'package:fitflow/features/profile/presentation/workout_preferences_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  final editorVisible = find.text(
    'FitFlow uses these preferences when choosing exercises.',
  );
  final profileListVisible = find.text(
    'Your settings shape how FitFlow adapts future workouts.',
  );

  UserFitnessProfile seedWith(Set<WorkoutPreference> preferences) =>
      profileEditorSeed().copyWith(preferences: preferences);

  group('Workout preferences editor — loading', () {
    testWidgets('shows current preferences as selected', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutPreference.noJumping})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      expect(optionCardSelected(tester, 'No jumping'), isTrue);
      expect(optionCardSelected(tester, 'Low impact'), isFalse);
    });

    testWidgets('offers every preference value', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      expect(find.text('No jumping'), findsOneWidget);
      expect(find.text('Low impact'), findsOneWidget);
      expect(find.text('No floor exercises'), findsOneWidget);
      expect(find.text('Standing only'), findsOneWidget);
      expect(find.text('Avoid wrist-heavy exercises'), findsOneWidget);
      expect(find.text('Avoid deep knee bending'), findsOneWidget);
      expect(WorkoutPreference.values, hasLength(6));
    });

    testWidgets('uses no medical or diagnostic wording', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();

      for (final banned in [
        'injury',
        'pain',
        'rehab',
        'medical',
        'diagnos',
        'restriction',
      ]) {
        expect(allText.contains(banned), isFalse, reason: banned);
      }
    });
  });

  group('Workout preferences editor — selection', () {
    testWidgets('supports multi-select', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      await tapOption(tester, 'No jumping');
      await tapOption(tester, 'Standing only');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'No jumping'), isTrue);
      expect(optionCardSelected(tester, 'Standing only'), isTrue);
      expect(optionCardSelected(tester, 'Low impact'), isFalse);
    });

    testWidgets('tapping a selected preference deselects it', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutPreference.noJumping})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      await tapOption(tester, 'No jumping');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'No jumping'), isFalse);
    });
  });

  group('Workout preferences editor — save', () {
    testWidgets('Save changes only preferences, preserving everything else', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      await tapOption(tester, 'Low impact');
      await tapOption(tester, 'Avoid deep knee bending');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      expect(find.text('Workout preferences updated.'), findsOneWidget);
      expect(profileListVisible, findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final stored = UserFitnessProfileStorage(prefs).load()!;
      final seed = profileEditorSeed();

      expect(
        stored.preferences,
        {WorkoutPreference.lowImpact, WorkoutPreference.avoidDeepKneeBending},
      );
      expect(stored.goal, seed.goal);
      expect(stored.experience, seed.experience);
      expect(stored.workoutDuration, seed.workoutDuration);
      expect(stored.environment, seed.environment);
      expect(stored.equipment, seed.equipment);
    });

    testWidgets('an empty selection is valid and can be saved', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutPreference.noJumping})),
      );
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
      );

      await tapOption(tester, 'No jumping');
      await settleProfileFrames(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save changes'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      final prefs = await SharedPreferences.getInstance();
      final stored = UserFitnessProfileStorage(prefs).load()!;
      expect(stored.preferences, isEmpty);
      // Other fields untouched.
      expect(stored.equipment, {WorkoutEquipment.chair});
    });

    testWidgets('failed save keeps the old profile and stays on screen', (
      tester,
    ) async {
      final failing = ScriptedProfileController(
        seedWith(const {WorkoutPreference.noJumping}),
      )..saveResult = false;
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.workoutPreferences,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => failing),
        ],
      );

      await tapOption(tester, 'Low impact');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      expect(editorVisible, findsOneWidget);
      expect(
        find.text("Couldn't save your changes. Try again."),
        findsOneWidget,
      );
      expect(
        containerOf(tester)
            .read(userFitnessProfileProvider)
            .value!
            .preferences,
        {WorkoutPreference.noJumping},
      );
    });

    testWidgets('uses the exact success message', (tester) async {
      expect(
        WorkoutPreferencesEditorScreen.successMessage,
        'Workout preferences updated.',
      );
    });
  });

  group('Preferences summary formatting (deterministic)', () {
    test('empty selection uses the fallback copy', () {
      expect(formatPreferencesSummary(const {}), 'No special workout preferences');
    });

    test('selections list in enum declaration order', () {
      expect(
        formatPreferencesSummary(const {
          WorkoutPreference.standingOnly,
          WorkoutPreference.noJumping,
        }),
        'No jumping, Standing only',
      );
    });

    test('more than two selections collapse with +N', () {
      expect(
        formatPreferencesSummary(const {
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
          WorkoutPreference.noFloorExercises,
        }),
        'No jumping, Low impact +1',
      );
    });
  });
}
