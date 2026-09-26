import 'package:fitflow/app/app.dart';
import 'package:fitflow/core/widgets/placeholder_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('Exercise Library opens from Workouts and displays count and search',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: FitFlowApp()),
    );
    await completeOnboarding(tester);

    // Navigate to Workouts tab (bounded pumps to avoid NavigationBar ticker hang)
    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Your workouts'), findsOneWidget);
    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Browse 80 exercises'), findsOneWidget);

    // Open Exercise Library via tapping the row - must succeed if route is registered
    await tester.tap(find.byType(PlaceholderRow).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify ExerciseLibraryScreen opened
    expect(find.text('Exercise Library'), findsWidgets);

    // Verify live result count shows 80 exercises
    expect(find.text('80 exercises'), findsOneWidget);

    // Verify Search field appears with placeholder 'Search exercises'
    expect(find.byType(TextField), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.decoration?.hintText, 'Search exercises');
  });
}
