import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/equipment_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/profile_summary_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  final editorVisible = find.text(
    'Choose the equipment you currently have available.',
  );
  final profileListVisible = find.text(
    'Your settings shape how FitFlow adapts future workouts.',
  );

  UserFitnessProfile seedWith(Set<WorkoutEquipment> equipment) =>
      profileEditorSeed().copyWith(equipment: equipment);

  group('Equipment editor — loading', () {
    testWidgets('shows current equipment as selected', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.chair})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      expect(optionCardSelected(tester, 'Chair'), isTrue);
      expect(optionCardSelected(tester, 'Dumbbells'), isFalse);
      expect(optionCardSelected(tester, 'None'), isFalse);
    });

    testWidgets('offers every equipment value', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.none})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      for (final item in WorkoutEquipment.values) {
        expect(find.text(item.label), findsOneWidget, reason: item.name);
      }
    });
  });

  group('Equipment editor — selection semantics', () {
    testWidgets('selecting None clears all real equipment', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(
          seedWith(const {
            WorkoutEquipment.dumbbells,
            WorkoutEquipment.exerciseMat,
          }),
        ),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tapOption(tester, 'None');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'None'), isTrue);
      expect(optionCardSelected(tester, 'Dumbbells'), isFalse);
      expect(optionCardSelected(tester, 'Exercise mat'), isFalse);
    });

    testWidgets('selecting real equipment removes None', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.none})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tapOption(tester, 'Dumbbells');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'Dumbbells'), isTrue);
      expect(optionCardSelected(tester, 'None'), isFalse);
    });

    testWidgets('deselecting the final real item falls back to None', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.chair})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tapOption(tester, 'Chair');
      await settleProfileFrames(tester);

      // Never empty: None is automatically selected instead.
      expect(optionCardSelected(tester, 'Chair'), isFalse);
      expect(optionCardSelected(tester, 'None'), isTrue);
    });

    testWidgets('multiple real items can be combined', (tester) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.chair})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tapOption(tester, 'Pull-up bar');
      await settleProfileFrames(tester);

      expect(optionCardSelected(tester, 'Chair'), isTrue);
      expect(optionCardSelected(tester, 'Pull-up bar'), isTrue);
      expect(optionCardSelected(tester, 'None'), isFalse);
    });
  });

  group('Equipment editor — save', () {
    testWidgets('Save changes only equipment, preserving everything else', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.chair})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      await tapOption(tester, 'Dumbbells');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      expect(find.text('Equipment updated.'), findsOneWidget);
      expect(profileListVisible, findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      final stored = UserFitnessProfileStorage(prefs).load()!;
      final seed = profileEditorSeed();

      expect(
        stored.equipment,
        {WorkoutEquipment.chair, WorkoutEquipment.dumbbells},
      );
      expect(stored.goal, seed.goal);
      expect(stored.experience, seed.experience);
      expect(stored.workoutDuration, seed.workoutDuration);
      expect(stored.environment, seed.environment);
      expect(stored.preferences, seed.preferences);

      final container = containerOf(tester);
      expect(
        container.read(userFitnessProfileProvider).value!.equipment,
        {WorkoutEquipment.chair, WorkoutEquipment.dumbbells},
      );
    });

    testWidgets('an empty equipment set can never be persisted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(seedWith(const {WorkoutEquipment.chair})),
      );
      await pumpProfileApp(tester, initialLocation: AppRoutes.equipment);

      // Deselect the only real item -> automatic None.
      await tapOption(tester, 'Chair');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      final prefs = await SharedPreferences.getInstance();
      final stored = UserFitnessProfileStorage(prefs).load()!;
      expect(stored.equipment, isNotEmpty);
      expect(stored.equipment, {WorkoutEquipment.none});
    });

    testWidgets('failed save keeps the old profile and stays on screen', (
      tester,
    ) async {
      final failing = ScriptedProfileController(
        seedWith(const {WorkoutEquipment.chair}),
      )..saveResult = false;
      await pumpProfileApp(
        tester,
        initialLocation: AppRoutes.equipment,
        overrides: [
          userFitnessProfileProvider.overrideWith(() => failing),
        ],
      );

      await tapOption(tester, 'Kettlebell');
      await settleProfileFrames(tester);
      await tester.tap(find.text('Save changes'));
      await settleProfileFrames(tester);

      expect(editorVisible, findsOneWidget);
      expect(
        find.text("Couldn't save your changes. Try again."),
        findsOneWidget,
      );
      expect(
        containerOf(tester).read(userFitnessProfileProvider).value!.equipment,
        {WorkoutEquipment.chair},
      );
    });

    testWidgets('uses the exact success message', (tester) async {
      expect(EquipmentEditorScreen.successMessage, 'Equipment updated.');
    });
  });

  group('Equipment summary formatting (deterministic)', () {
    test('empty and None-only selections read as None', () {
      expect(formatEquipmentSummary(const {}), 'None');
      expect(
        formatEquipmentSummary(const {WorkoutEquipment.none}),
        'None',
      );
    });

    test('single and double selections list labels in enum order', () {
      expect(
        formatEquipmentSummary(const {WorkoutEquipment.towel}),
        'Towel',
      );
      expect(
        formatEquipmentSummary(const {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.exerciseMat,
        }),
        'Exercise mat, Dumbbells',
      );
    });

    test('more than two selections collapse with +N', () {
      expect(
        formatEquipmentSummary(const {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.exerciseMat,
          WorkoutEquipment.chair,
          WorkoutEquipment.towel,
        }),
        // Enum declaration order, never Set/hash order.
        'Exercise mat, Chair +2',
      );
    });

    test('None is never mixed into a real-item list', () {
      expect(
        formatEquipmentSummary(const {
          WorkoutEquipment.none,
          WorkoutEquipment.bench,
        }),
        'Bench',
      );
    });

    test('every enum value renders a stable summary', () {
      for (final item in WorkoutEquipment.values) {
        final summary = formatEquipmentSummary({item});
        expect(summary, item == WorkoutEquipment.none ? 'None' : item.label);
      }
    });
  });
}
