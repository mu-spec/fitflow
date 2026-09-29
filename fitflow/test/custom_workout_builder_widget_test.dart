import 'package:fitflow/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('Builder shows all sections and Add exercise', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Create custom workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Create workout'), findsWidgets);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Cool-down'), findsOneWidget);
    expect(find.text('Add exercise'), findsNWidgets(3));
  });

  testWidgets('Builder has name field and duration chips', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Create custom workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Workout name'), findsOneWidget);
    expect(find.text('Target duration'), findsOneWidget);
  });

  testWidgets('Builder Save disabled when invalid', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Create custom workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Initially Save should be disabled (no name, no exercises)
    final saveButton = find.widgetWithText(FilledButton, 'Create workout');
    expect(saveButton, findsOneWidget);
    final button = tester.widget<FilledButton>(saveButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('Builder narrow width no overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Create custom workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Warm-up'), findsOneWidget);
  });

  testWidgets('Builder text scale 1.5 no overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const FitFlowApp(),
        ),
      ),
    );
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Create custom workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Warm-up'), findsOneWidget);
  });
}
