import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('AppearanceController', () {
    test('defaults to system and persists changes locally', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial =
          await container.read(appearanceControllerProvider.future);
      expect(initial, AppearanceMode.system);

      await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.dark);
      expect(container.read(appearanceControllerProvider).value,
          AppearanceMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.dark);
    });

    test('loads a persisted mode on startup', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial =
          await container.read(appearanceControllerProvider.future);
      expect(initial, AppearanceMode.light);
    });

    test('falls back to system for unknown persisted values', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'neon'},
      );
      final prefs = await SharedPreferences.getInstance();
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.system);
    });
  });

  group('Settings screen', () {
    Future<void> launchOnProfileTab(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await completeOnboarding(tester);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the Profile tab with appearance options', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await launchOnProfileTab(tester);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('updates the theme immediately when a mode is selected', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await launchOnProfileTab(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(_materialApp(tester).themeMode, ThemeMode.dark);
      expect(_brightness(tester), Brightness.dark);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(_materialApp(tester).themeMode, ThemeMode.light);
      expect(_brightness(tester), Brightness.light);

      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();
      expect(_materialApp(tester).themeMode, ThemeMode.system);
    });

    testWidgets('restores the selected mode on app restart', (tester) async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'dark'},
      );
      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await waitUntilOnboarding(tester);

      expect(_materialApp(tester).themeMode, ThemeMode.dark);
      expect(_brightness(tester), Brightness.dark);
    });
  });
}

MaterialApp _materialApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
