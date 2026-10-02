import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_restore_settings_entry.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appearance_persistence_test.dart' show ScriptedAppearanceStorage;
import 'helpers/profile_editor_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  late FakeWorkoutReminderNotificationService reminderService;

  setUp(() {
    ensureTimezones();
    SharedPreferences.setMockInitialValues({});
    reminderService = FakeWorkoutReminderNotificationService();
  });

  Future<GoRouter> pumpSettings(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = AppRouter.create(initialLocation: AppRoutes.settings);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...reminderOverrides(service: reminderService),
          ...overrides,
        ],
        child: _AppearanceDrivenApp(router: router, textScale: textScale),
      ),
    );
    await settleProfileFrames(tester);
    return router;
  }

  group('Settings information architecture', () {
    testWidgets('shows Appearance, reminders, Data sections and footer', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text('Settings'), findsOneWidget);

      // Appearance section.
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // M17 reminders section remains.
      expect(find.text('Workout reminders'), findsWidgets);

      // Data section with the M18 entry.
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('Backup & restore'), findsWidgets);
      expect(find.byKey(BackupRestoreSettingsEntry.tileKey), findsOneWidget);

      // Factual local-data footer.
      await tester.ensureVisible(find.text(SettingsScreen.localDataFooter));
      expect(find.text(SettingsScreen.localDataFooter), findsOneWidget);
      expect(
        find.text(
          'FitFlow works without an account. Your workout data is stored on '
          'this device unless you create a backup.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no account, cloud, or destructive settings exist', (
      tester,
    ) async {
      await pumpSettings(tester);

      // The local-data footer legitimately mentions "account"; strip it.
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase()
          .replaceAll(SettingsScreen.localDataFooter.toLowerCase(), '');
      for (final banned in [
        'sign in',
        'log in',
        'login',
        'register',
        'cloud',
        'sync',
        'reset app',
        'delete all',
        'delete everything',
        'clear history',
        'reset capability',
      ]) {
        expect(allText.contains(banned), isFalse, reason: banned);
      }
    });

    testWidgets('Backup & restore entry opens the M18 route', (tester) async {
      await pumpSettings(tester);

      final tile = find.byKey(BackupRestoreSettingsEntry.tileKey);
      await tester.ensureVisible(tile);
      await settleProfileFrames(tester, 3);
      await tester.tap(tile);
      await settleProfileFrames(tester);

      expect(find.byKey(BackupRestoreScreen.chooseFileButtonKey), findsOneWidget);
      expect(AppRoutes.backupRestore, '/profile/settings/backup-restore');
    });

    testWidgets('reminders section remains interactive', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Reminders are off.'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await settleProfileFrames(tester);

      expect(find.text('Workout reminders are scheduled.'), findsOneWidget);
    });
  });

  group('Settings appearance UX', () {
    testWidgets('successful selection becomes active', (tester) async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      await pumpSettings(tester);

      await tester.tap(find.text('Dark'));
      await settleProfileFrames(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('failed save keeps previous mode and shows honest copy', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      final failing = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
        result: false,
      );
      await pumpSettings(
        tester,
        overrides: [
          appearanceStorageFactoryProvider.overrideWithValue((prefs) => failing),
        ],
      );

      await tester.tap(find.text('Dark'));
      await settleProfileFrames(tester);

      // Exact failure copy, no internal exception text.
      expect(
        find.text(SettingsScreen.appearanceSaveFailedMessage),
        findsOneWidget,
      );
      expect(
        find.text("Couldn't save appearance. Try again."),
        findsOneWidget,
      );

      // Theme stays on the previously persisted mode.
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);

      // The stored value is unchanged.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppearanceStorage.appearanceKey),
        AppearanceMode.light.name,
      );
    });
  });

  group('Settings responsive layout', () {
    testWidgets('fits a 320px wide screen', (tester) async {
      await pumpSettings(tester, size: const Size(320, 640));

      expect(find.text('Appearance'), findsOneWidget);
      await tester.ensureVisible(find.text(SettingsScreen.localDataFooter));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a wide/tablet screen', (tester) async {
      await pumpSettings(tester, size: const Size(1280, 900));

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits landscape', (tester) async {
      await pumpSettings(tester, size: const Size(900, 390));

      expect(find.text('Appearance'), findsOneWidget);
      await tester.ensureVisible(find.text(SettingsScreen.localDataFooter));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits text scale 1.5', (tester) async {
      await pumpSettings(tester, textScale: 1.5);

      expect(find.text('Appearance'), findsOneWidget);
      await tester.ensureVisible(find.text(SettingsScreen.localDataFooter));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely in dark mode', (tester) async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'dark'},
      );
      await pumpSettings(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely in light mode', (tester) async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      await pumpSettings(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
      expect(find.text('Appearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Part 1 editors — layout safety', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(
        seedProfilePrefs(profileEditorSeed()),
      );
    });

    for (final (name, route) in [
      ('Fitness profile', AppRoutes.fitnessProfile),
      ('Equipment', AppRoutes.equipment),
      ('Workout preferences', AppRoutes.workoutPreferences),
    ]) {
      testWidgets('$name editor fits 320px width', (tester) async {
        final router = AppRouter.create(initialLocation: route);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: reminderOverrides(service: reminderService),
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await settleProfileFrames(tester);

        expect(find.text('Save changes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$name editor fits text scale 1.5', (tester) async {
        final router = AppRouter.create(initialLocation: route);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: reminderOverrides(service: reminderService),
            child: MaterialApp.router(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.5)),
                child: child!,
              ),
              routerConfig: router,
            ),
          ),
        );
        await settleProfileFrames(tester);

        expect(find.text('Save changes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Routing regression', () {
    test('all Part 1 + settings route constants remain correct', () {
      expect(AppRoutes.fitnessProfile, '/profile/fitness-profile');
      expect(AppRoutes.equipment, '/profile/equipment');
      expect(AppRoutes.workoutPreferences, '/profile/workout-preferences');
      expect(AppRoutes.settings, '/profile/settings');
      expect(AppRoutes.backupRestore, '/profile/settings/backup-restore');
    });
  });
}

/// Mirrors [FitFlowApp]'s theme wiring so tests observe the same
/// provider-driven theme switching the real app uses.
class _AppearanceDrivenApp extends ConsumerWidget {
  const _AppearanceDrivenApp({required this.router, required this.textScale});

  final GoRouter router;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceControllerProvider).value ??
        AppearanceMode.system;
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode.toThemeMode(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      routerConfig: router,
    );
  }
}
