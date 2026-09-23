import 'package:fitflow/app/app.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FitFlow opens on the splash screen, then moves to Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);

    await tester.pump(AppConstants.splashDelay + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your adaptive workout starts here'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between the four tabs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    await tester.pump(AppConstants.splashDelay + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your adaptive workout starts here'), findsOneWidget);

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Training Time'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Your adaptive workout starts here'), findsOneWidget);
  });
}
