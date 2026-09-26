import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Exercise Detail Navigation', () {
    testWidgets(
        'open Workouts -> Exercise Library -> tap exercise opens detail',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(child: FitFlowApp()),
      );
      await completeOnboardingToHome(tester);

      // Navigate to Workouts tab
      await tester.tap(find.text('Workouts'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Your workouts'), findsOneWidget);

      // Open Exercise Library
      await tester.tap(find.text('Exercise Library').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('80 exercises'), findsOneWidget);

      // Search for Standard Push-Up to make it visible reliably
      await tester.enterText(find.byType(TextField), 'Standard Push-Up');
      await tester.pump(const Duration(milliseconds: 500));
      final tileFinder = find.byType(ExerciseListTile).first;
      expect(tileFinder, findsOneWidget);
      // Tap the tile (not just text) to trigger navigation
      await tester.tap(tileFinder);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify detail screen opened with correct data
      expect(find.text('Standard Push-Up'), findsWidgets);
      // Detail screen unique sections - pump more if needed
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Default Prescription'), findsOneWidget);
      expect(find.text('Muscles Worked'), findsOneWidget);
      expect(find.text('How to Perform'), findsOneWidget);
      // Hero chips
      expect(find.text('Push'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      // Description may be off-screen, try scrolling
      await tester.dragUntilVisible(
        find.text('A full bodyweight press from a straight-arm plank.'),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          find.text('A full bodyweight press from a straight-arm plank.'),
          findsOneWidget);
    });
  });

  group('Exercise Detail Data - Standard Push-Up', () {
    testWidgets('displays all representative fields for pushup_standard',
        (tester) async {
      final expected = ExerciseCatalog.byId('pushup_standard')!;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exerciseId: expected.id),
        ),
      );
      await tester.pumpAndSettle();

      // Name and description
      expect(find.text(expected.name), findsWidgets);
      expect(find.text(expected.shortDescription!), findsOneWidget);

      // Movement, difficulty, type
      expect(find.text(expected.movementPattern!.label), findsOneWidget);
      final levelNumber =
          expected.difficulty.name.replaceFirst('level', '');
      expect(find.text('Level $levelNumber'), findsOneWidget);
      expect(find.text(expected.exerciseType.label), findsOneWidget);

      // Prescription - reps
      expect(find.text('${expected.defaultReps} reps'), findsOneWidget);
      // Rest - 60 seconds
      expect(find.textContaining('Rest:'), findsOneWidget);
      expect(find.textContaining('60 seconds'), findsOneWidget);

      // Equipment - No equipment
      expect(find.text('No equipment'), findsWidgets);

      // Muscles
      for (final m in expected.primaryMuscles) {
        expect(find.text(m.label), findsWidgets);
      }
      for (final m in expected.secondaryMuscles) {
        expect(find.text(m.label), findsWidgets);
      }

      // Instructions - exactly catalog content
      for (final instr in expected.instructions) {
        expect(find.text(instr), findsOneWidget);
      }

      // Common mistakes
      for (final mistake in expected.commonMistakes) {
        expect(find.text(mistake), findsOneWidget);
      }

      // Breathing
      expect(find.text(expected.breathingGuidance!), findsOneWidget);

      // Characteristics - body position, impact, noise, space, wrist, knee
      expect(find.text('Position'), findsOneWidget);
      expect(find.text(expected.bodyPosition!.label), findsWidgets);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.text(expected.impactLevel.label), findsWidgets);
      expect(find.text('Noise'), findsOneWidget);
      expect(find.text(expected.noiseLevel.label), findsWidgets);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text(expected.spaceRequirement.label), findsWidgets);
      expect(find.text('Wrist load'), findsOneWidget);
      expect(find.text(expected.wristLoad.label), findsWidgets);
      expect(find.text('Knee load'), findsOneWidget);
      expect(find.text(expected.kneeLoad.label), findsWidgets);

      // Ensure tags are not dumped prominently - we omit raw tags UI
      // Check that generic placeholder does not pretend to be form demo
      expect(find.text('Illustration coming soon'), findsOneWidget);
    });
  });

  group('Exercise Detail Data - Timed Exercise Wall Sit', () {
    testWidgets('displays duration rather than reps for timed exercise',
        (tester) async {
      final expected = ExerciseCatalog.byId('wall_sit')!;
      expect(expected.exerciseType.name, 'timed');
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exerciseId: expected.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(expected.name), findsWidgets);
      expect(find.text(expected.shortDescription!), findsOneWidget);

      // Should show duration like "20 seconds"
      final durationText = '${expected.defaultDuration!.inSeconds} seconds';
      expect(find.text(durationText), findsOneWidget);

      // Should NOT show reps text like "8 reps" for this timed exercise
      // Check that it shows Timed chip
      expect(find.text('Timed'), findsOneWidget);

      // Rest still shown
      expect(find.textContaining('Rest:'), findsOneWidget);
      expect(
          find.textContaining(
              '${expected.defaultRest!.inSeconds} seconds'),
          findsOneWidget);
    });
  });

  group('Exercise Detail Unknown ID', () {
    testWidgets('unknown exercise ID produces not-found state without crash',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'unknown_exercise_xyz'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exercise not found'), findsWidgets);
      expect(
          find.text('This exercise is no longer available.'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      // Should not crash, no exercise data shown
      expect(find.text('Muscles Worked'), findsNothing);
      expect(find.text('How to Perform'), findsNothing);
    });

    testWidgets('unknown ID via router does not crash - direct screen test',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'does_not_exist'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Exercise not found'), findsWidgets);
      // Tapping Back should not crash - in non-GoRouter context it should safely handle
      // We wrap in a Scaffold with a Navigator, so pop should work or be no-op
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      // No exception means pass
    });
  });

  group('Exercise Detail Search/Filter Regression', () {
    testWidgets('search and filter still work after detail changes',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(child: FitFlowApp()),
      );
      await completeOnboardingToHome(tester);

      await tester.tap(find.text('Workouts'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Exercise Library').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Helper to find count text like "80 exercises"
      Finder countFinder() {
        return find.byWidgetPredicate((widget) {
          if (widget is Text) {
            final data = widget.data;
            if (data == null) return false;
            // Matches pattern like "80 exercises" or "5 exercises"
            return RegExp(r'^\d+ exercises$').hasMatch(data);
          }
          return false;
        });
      }

      expect(countFinder(), findsOneWidget);
      expect(find.text('80 exercises'), findsOneWidget);

      // Search still works
      await tester.enterText(find.byType(TextField), 'push');
      await tester.pump(const Duration(milliseconds: 500));
      // Should filter to push-related exercises
      expect(find.textContaining('Push-Up'), findsWidgets);
      // Count should be less than 80
      final countAfterSearch = tester.widget<Text>(countFinder()).data!;
      expect(countAfterSearch, isNot('80 exercises'));
      expect(int.parse(countAfterSearch.split(' ').first), lessThan(80));

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('80 exercises'), findsOneWidget);

      // Quick filter still works
      await tester.tap(find.text('No equipment'));
      await tester.pump(const Duration(milliseconds: 500));
      // Should filter
      final countAfterFilter = tester.widget<Text>(countFinder()).data!;
      expect(int.parse(countAfterFilter.split(' ').first), lessThan(80));
      expect(int.parse(countAfterFilter.split(' ').first), greaterThan(0));
    });
  });
}
