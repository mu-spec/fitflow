import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitUntilOnboarding(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> selectChoiceIfRequired(WidgetTester tester, String pageId) async {
  switch (pageId) {
    case 'goal':
      await tester.tap(find.text('General fitness'));
      await tester.pump(const Duration(milliseconds: 300));
    case 'experience':
      await tester.tap(find.text('Completely new'));
      await tester.pump(const Duration(milliseconds: 300));
    case 'workout_time':
      await tester.tap(find.text('15 minutes'));
      await tester.pump(const Duration(milliseconds: 300));
    case 'environment':
      await tester.tap(find.text('Normal home'));
      await tester.pump(const Duration(milliseconds: 300));
    case 'equipment':
      await tester.tap(find.text('Chair'));
      await tester.pump(const Duration(milliseconds: 300));
  }
}

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
