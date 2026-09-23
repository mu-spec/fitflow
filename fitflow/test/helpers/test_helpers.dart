import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Advances the fake clock past the splash delay so the app reaches
/// onboarding.
Future<void> waitUntilOnboarding(WidgetTester tester) async {
  await tester.pump(AppConstants.splashDelay + const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Selects a valid choice on steps that require one before continuing.
Future<void> selectChoiceIfRequired(WidgetTester tester, String pageId) async {
  switch (pageId) {
    case 'goal':
      await tester.tap(find.text('General fitness'));
      await tester.pumpAndSettle();
    case 'experience':
      await tester.tap(find.text('Completely new'));
      await tester.pumpAndSettle();
    case 'workout_time':
      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();
    case 'environment':
      await tester.tap(find.text('Normal home'));
      await tester.pumpAndSettle();
  }
}

/// Waits past the splash and taps through every onboarding step to Home.
Future<void> completeOnboarding(WidgetTester tester) async {
  await waitUntilOnboarding(tester);
  for (var i = 0; i < OnboardingPages.all.length - 1; i++) {
    await selectChoiceIfRequired(tester, OnboardingPages.all[i].id);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}
