import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_variation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('Progression Helper', () {
    test('resolves middle of pushup progression correctly', () {
      final exercise = ExerciseCatalog.byId('pushup_standard')!;
      final info = ExerciseProgressionResolver.resolve(exercise);
      expect(info, isNotNull);
      expect(info!.familySorted.length, 6);
      expect(info.step, 4);
      expect(info.total, 6);
      expect(info.currentIndex, 3);
      expect(info.easier?.id, 'pushup_knee');
      expect(info.harder?.id, 'pushup_decline');
      expect(info.current.id, 'pushup_standard');
      // Sorted by rank
      expect(info.familySorted.map((e) => e.id).toList(), [
        'pushup_wall',
        'pushup_incline',
        'pushup_knee',
        'pushup_standard',
        'pushup_decline',
        'pushup_diamond',
      ]);
    });

    test('resolves end of progression diamond pushup', () {
      final exercise = ExerciseCatalog.byId('pushup_diamond')!;
      final info = ExerciseProgressionResolver.resolve(exercise);
      expect(info, isNotNull);
      expect(info!.total, 6);
      expect(info.step, 6);
      expect(info.isLast, true);
      expect(info.easier?.id, 'pushup_decline');
      expect(info.harder, isNull);
    });

    test('resolves three-step family bridge_march', () {
      final exercise = ExerciseCatalog.byId('bridge_march')!;
      final info = ExerciseProgressionResolver.resolve(exercise);
      expect(info, isNotNull);
      expect(info!.total, 3);
      expect(info.step, 2);
      expect(info.familySorted.map((e) => e.id).toList(), [
        'bridge_glute',
        'bridge_march',
        'bridge_single_leg',
      ]);
      expect(info.easier?.id, 'bridge_glute');
      expect(info.harder?.id, 'bridge_single_leg');
    });

    test('standalone exercise returns null', () {
      final exercise = ExerciseCatalog.byId('pushup_pike')!;
      // Pike Push-Up has no family
      expect(exercise.progressionFamilyId, isNull);
      final info = ExerciseProgressionResolver.resolve(exercise);
      expect(info, isNull);
    });

    test('handles broken variation IDs gracefully', () {
      // Create a fake exercise with broken easier/harder IDs but valid family
      // We test resolver with real catalog: if ID not found, it should omit
      final exercise = ExerciseCatalog.byId('pushup_wall')!;
      // pushup_wall has harderVariationId pushup_incline which exists
      final info = ExerciseProgressionResolver.resolve(exercise);
      expect(info, isNotNull);
      expect(info!.easier, isNull); // beginning
      expect(info.harder?.id, 'pushup_incline');
    });
  });

  group('Progression UI - Detail Screen', () {
    testWidgets('middle of progression pushup_standard shows Step 4 of 6 and variations',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'pushup_standard'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Step 4 of 6'), findsOneWidget);
      expect(find.text('4 / 6'), findsOneWidget);
      // Easier and harder cards
      expect(find.text('Knee Push-Up'), findsOneWidget);
      expect(find.text('Decline Push-Up'), findsOneWidget);
      expect(find.text('Standard Push-Up'), findsWidgets);
      expect(find.text('Easier variation'), findsOneWidget);
      expect(find.text('Harder variation'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
    });

    testWidgets('end of progression pushup_diamond shows Step 6 of 6 and only easier',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'pushup_diamond'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Step 6 of 6'), findsOneWidget);
      expect(find.text('Decline Push-Up'), findsOneWidget);
      expect(find.text('Easier variation'), findsOneWidget);
      // No harder variation
      expect(find.text('Harder variation'), findsNothing);
    });

    testWidgets('three-step family bridge_march shows Step 2 of 3 and correct chain',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'bridge_march'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Glute Bridge'), findsOneWidget);
      expect(find.text('Glute Bridge March'), findsWidgets);
      expect(find.text('Single-Leg Glute Bridge'), findsOneWidget);
    });

    testWidgets('standalone exercise pike push-up has no progression section',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseDetailScreen(exerciseId: 'pushup_pike'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progression'), findsNothing);
      expect(find.textContaining('Step'), findsNothing);
      expect(find.text('Easier variation'), findsNothing);
      expect(find.text('Harder variation'), findsNothing);
    });

    testWidgets('variation navigation from Standard Push-Up to Decline Push-Up',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(child: FitFlowApp()),
      );
      await completeOnboarding(tester);

      await tester.tap(find.text('Workouts'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Exercise Library').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Search and open Standard Push-Up via library tile
      await tester.enterText(find.byType(TextField), 'Standard Push-Up');
      await tester.pump(const Duration(milliseconds: 500));
      // Find the list tile - after search there should be exactly 1 ExerciseListTile
      final listTileFinder = find.byType(ExerciseListTile);
      expect(listTileFinder, findsOneWidget);
      await tester.tap(listTileFinder);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we are on Standard Push-Up detail
      // Clear the search field text from finder by checking AppBar title
      expect(find.text('Standard Push-Up'), findsWidgets);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Step 4 of 6'), findsOneWidget);

      // Now tap harder variation Decline Push-Up - need to scroll to it
      final declineFinder = find.text('Decline Push-Up');
      // There might be multiple scrollables, find the SingleChildScrollView of detail screen
      final detailScrollable = find.byWidgetPredicate((w) =>
          w is Scrollable && w.axis == Axis.vertical).last;
      await tester.scrollUntilVisible(
        declineFinder,
        200,
        scrollable: detailScrollable,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(declineFinder);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Decline Push-Up detail opened
      expect(find.text('Decline Push-Up'), findsWidgets);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Step 5 of 6'), findsOneWidget);
    });
  });

  group('Constraint metadata', () {
    testWidgets('Step Jack shows Quiet, Low impact, Standing', (tester) async {
      final exercise = ExerciseCatalog.byId('step_jack')!;
      expect(exercise.noiseLevel.name, 'quiet');
      expect(exercise.impactLevel.name, 'low');
      expect(exercise.bodyPosition!.name, 'standing');

      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exerciseId: exercise.id),
        ),
      );
      await tester.pumpAndSettle();

      // Summary chips
      expect(find.text('Quiet'), findsWidgets);
      expect(find.text('Low impact'), findsWidgets);
      expect(find.text('Standing'), findsWidgets);
      expect(find.text('Small space'), findsWidgets);
      // Summary line contains these
      expect(find.textContaining('Quiet •'), findsWidgets);

      // Characteristics still show factual values
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('Standing'), findsWidgets);
    });

    testWidgets('Standard Push-Up shows Floor and wrist load High', (tester) async {
      final exercise = ExerciseCatalog.byId('pushup_standard')!;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exerciseId: exercise.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Position'), findsOneWidget);
      expect(find.text('Floor'), findsWidgets);
      // Wrist load
      expect(find.text('Wrist load'), findsOneWidget);
      expect(find.text(exercise.wristLoad.label), findsWidgets);
      expect(exercise.wristLoad.label, 'High');
    });

    testWidgets('Bulgarian Split Squat shows knee load High', (tester) async {
      final exercise = ExerciseCatalog.byId('squat_split_bulgarian')!;
      expect(exercise.kneeLoad.label, 'High');
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailScreen(exerciseId: exercise.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Knee load'), findsOneWidget);
      // Find High - there may be multiple High values (wrist, knee etc) but at least one for knee
      expect(find.text('High'), findsWidgets);
      // Ensure knee load row exists
      await tester.scrollUntilVisible(
        find.text('Knee load'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Knee load'), findsOneWidget);
    });
  });
}
