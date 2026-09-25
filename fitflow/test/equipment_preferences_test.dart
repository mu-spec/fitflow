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

  /// Advances through the steps before [pageId], selecting any required
  /// choices along the way.
  Future<void> advanceToStep(WidgetTester tester, String pageId) async {
    for (final page in OnboardingPages.all) {
      if (page.id == pageId) {
        return;
      }
      await selectChoiceIfRequired(tester, page.id);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
  }

  FilledButton continueButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );

  int selectedBoxCount(WidgetTester tester) =>
      find.byIcon(Icons.check_box).evaluate().length;

  group('Equipment step', () {
    testWidgets('Continue disabled with no selection', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'equipment');

      expect(find.text('What equipment do you have?'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNull);
    });

    testWidgets('multiple equipment items can be selected', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'equipment');

      await tester.tap(find.text('Exercise mat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbells'));
      await tester.pumpAndSettle();

      expect(selectedBoxCount(tester), 2);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('selecting None clears other equipment', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'equipment');

      await tester.tap(find.text('Exercise mat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dumbbells'));
      await tester.pumpAndSettle();
      expect(selectedBoxCount(tester), 2);

      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      expect(selectedBoxCount(tester), 1);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('selecting equipment after None removes None', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'equipment');

      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      expect(selectedBoxCount(tester), 1);

      await tester.tap(find.text('Exercise mat'));
      await tester.pumpAndSettle();

      expect(selectedBoxCount(tester), 1);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('equipment selections survive Back/Forward', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'equipment');

      await tester.tap(find.text('Exercise mat'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bench'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench'));
      await tester.pumpAndSettle();
      expect(selectedBoxCount(tester), 2);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text("Let's customize your workouts"), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('What equipment do you have?'), findsOneWidget);
      expect(selectedBoxCount(tester), 2);
    });
  });

  group('Preferences step', () {
    testWidgets('allows multiple selections', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'preferences');

      expect(find.text("Let's customize your workouts"), findsOneWidget);
      expect(
        find.text(
          'These preferences help FitFlow adapt workouts and are not '
          'medical advice.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('No jumping'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No floor exercises'));
      await tester.pumpAndSettle();

      expect(selectedBoxCount(tester), 2);
    });

    testWidgets('allows zero selections and Continue still works', (
      tester,
    ) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'preferences');

      expect(selectedBoxCount(tester), 0);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('preference selections survive Back/Forward', (tester) async {
      await launchOnboarding(tester);
      await advanceToStep(tester, 'preferences');

      await tester.tap(find.text('Low impact'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standing only'));
      await tester.pumpAndSettle();
      expect(selectedBoxCount(tester), 2);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text("You're ready"), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text("Let's customize your workouts"), findsOneWidget);
      expect(selectedBoxCount(tester), 2);
    });
  });
}
