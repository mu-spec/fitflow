import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Advances the fake clock past the splash delay so the app reaches
/// onboarding. Uses bounded pumps to avoid pumpAndSettle hanging on
/// persistent NavigationBar ticker.
Future<void> waitUntilOnboarding(WidgetTester tester) async {
  await tester.pump(AppConstants.splashDelay);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Selects a valid choice on steps that require one before continuing.
Future<void> selectChoiceIfRequired(WidgetTester tester, String pageId) async {
  switch (pageId) {
    case 'goal':
      await tester.tap(find.text('General fitness'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    case 'experience':
      await tester.tap(find.text('Completely new'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    case 'workout_time':
      await tester.tap(find.text('15 minutes'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    case 'environment':
      await tester.tap(find.text('Normal home'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    case 'equipment':
      await tester.tap(find.text('Chair'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Waits past the splash and taps through every onboarding step to Movement Check.
/// Uses bounded pumps instead of pumpAndSettle to avoid hanging on
/// NavigationBar animations.
Future<void> completeOnboarding(WidgetTester tester) async {
  await waitUntilOnboarding(tester);
  for (var i = 0; i < OnboardingPages.all.length - 1; i++) {
    await selectChoiceIfRequired(tester, OnboardingPages.all[i].id);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.tap(find.text('Get Started'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Completes onboarding then saves capability assessment to reach Home.
Future<void> completeOnboardingToHome(WidgetTester tester) async {
  await completeOnboarding(tester);
  // Now in Movement Check, scroll to and tap Save & Continue
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  final saveButton = find.text('Save & Continue');
  try {
    await tester.scrollUntilVisible(
      saveButton,
      300,
      maxScrolls: 30,
    );
  } catch (_) {
    // ignore if not found
  }
  await tester.pump(const Duration(milliseconds: 300));
  if (saveButton.evaluate().isNotEmpty) {
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }
}
