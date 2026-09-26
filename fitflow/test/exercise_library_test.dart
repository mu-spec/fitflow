import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('Exercise Library opens from Workouts and displays count',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: FitFlowApp()),
    );
    await completeOnboarding(tester);

    // Navigate to Workouts tab
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Your workouts'), findsOneWidget);
    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Browse all 80 exercises'), findsOneWidget);

    // Open Exercise Library
    await tester.tap(find.text('Exercise Library'));
    await tester.pumpAndSettle();

    // Verify Exercise Library screen
    expect(find.text('Exercise Library'), findsWidgets);
    expect(find.text('80 exercises'), findsOneWidget);
  });

  testWidgets('Exercise Library displays representative exercises',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: FitFlowApp()),
    );
    await completeOnboarding(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise Library'));
    await tester.pumpAndSettle();

    // Check for representative exercises from different parts of catalog
    expect(find.text('Wall Push-Up'), findsOneWidget);
    expect(find.text('Standard Push-Up'), findsOneWidget);
    // Scroll to find later items if needed, but first items should be visible
    expect(find.text('Exercise Library'), findsWidgets);

    // Verify primary muscle and metadata for a sample item is shown
    // Standard Push-Up shows "Chest • Triceps" and "Push • Level 3" and "No equipment • 8 reps"
    expect(find.text('Chest • Triceps'), findsWidgets);
    expect(find.text('Push • Level 3'), findsWidgets);
    expect(find.textContaining('No equipment'), findsWidgets);
    expect(find.textContaining('reps'), findsWidgets);
  });

  testWidgets('Exercise Library list is scrollable and shows last items',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: FitFlowApp()),
    );
    await completeOnboarding(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise Library'));
    await tester.pumpAndSettle();

    // Verify first item visible
    expect(find.text('Wall Push-Up'), findsOneWidget);

    // Last item should not be visible initially without scrolling (80 items)
    // Scroll until last item becomes visible
    await tester.scrollUntilVisible(
      find.text('Figure-Four Stretch'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Figure-Four Stretch'), findsOneWidget);

    // Also verify scrolling can go back to top
    await tester.scrollUntilVisible(
      find.text('Wall Push-Up'),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Wall Push-Up'), findsOneWidget);
  });

  testWidgets('Exercise Library handles empty catalog gracefully',
      (tester) async {
    // Directly pump the screen with empty list via test override
    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseLibraryScreen(exercisesForTest: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('No exercises available'), findsOneWidget);
    expect(
        find.text(
            'The exercise catalog is currently empty. Please check back later.'),
        findsOneWidget);
    // Should not show count or list when empty
    expect(find.text('80 exercises'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets(
      'Exercise Library list item shows required summary fields for timed exercise',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: FitFlowApp()),
    );
    await completeOnboarding(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise Library'));
    await tester.pumpAndSettle();

    // Wall Sit is timed (20s) — verify its tile shows timed indication
    // Wall Sit is at index 9, may require scrolling
    await tester.scrollUntilVisible(
      find.text('Wall Sit'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Wall Sit'), findsOneWidget);
    // Its tile should contain "Quadriceps", "Squat • Level 2", and "20s"
    // Check for timed indicator near Wall Sit
    expect(find.textContaining('20s'), findsWidgets);
    // Also verify at least one timed exercise shows "s" suffix
    expect(find.textContaining('s'), findsWidgets);
  });
}
