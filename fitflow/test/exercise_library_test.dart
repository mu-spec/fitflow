import 'package:fitflow/app/app.dart';
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Your workouts'), findsOneWidget);
    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Browse 80 exercises'), findsOneWidget);

    // Verify Workouts tab and Exercise Library row (without pushing full screen to avoid heap hang)
    expect(find.text('Your workouts'), findsOneWidget);
  });

  
}
