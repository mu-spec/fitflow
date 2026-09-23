import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  Future<void> launchOnboarding(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    await waitUntilOnboarding(tester);
  }

  testWidgets('first step shows the welcome content and progress', (
    tester,
  ) async {
    await launchOnboarding(tester);

    expect(find.text('Welcome to FitFlow'), findsOneWidget);
    expect(
      find.text(
        'Your workouts will adapt to your strength, time, space and equipment.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 of ${OnboardingPages.all.length}'), findsOneWidget);
  });

  testWidgets('Continue advances to the next step and updates progress', (
    tester,
  ) async {
    await launchOnboarding(tester);

    expect(find.text('1 of ${OnboardingPages.all.length}'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your main goal?'), findsOneWidget);
    expect(find.text('2 of ${OnboardingPages.all.length}'), findsOneWidget);
  });

  testWidgets('Back returns to the previous step and is disabled first', (
    tester,
  ) async {
    await launchOnboarding(tester);

    final firstBack = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Back'),
    );
    expect(firstBack.onPressed, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final secondBack = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Back'),
    );
    expect(secondBack.onPressed, isNotNull);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FitFlow'), findsOneWidget);
    expect(find.text('1 of ${OnboardingPages.all.length}'), findsOneWidget);
  });

  testWidgets('final step opens Home with Get Started', (tester) async {
    await launchOnboarding(tester);

    for (var i = 0; i < OnboardingPages.all.length - 1; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    expect(find.text("You're ready"), findsOneWidget);
    expect(
      find.text(
        '${OnboardingPages.all.length} of ${OnboardingPages.all.length}',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Your adaptive workout starts here'), findsOneWidget);
  });
}
