import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_restore_transaction.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_preview_card.dart';
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

import 'helpers/backup_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  late FakeBackupFileService files;
  late FakeWorkoutReminderNotificationService reminders;

  setUp(() {
    ensureTimezones();
    SharedPreferences.setMockInitialValues({'unrelated': 'keep'});
    files = FakeBackupFileService();
    reminders = FakeWorkoutReminderNotificationService();
  });

  List<Override> overrides({BackupRestoreTransactionFactory? tx}) => [
        backupFileServiceProvider.overrideWithValue(files),
        backupClockProvider.overrideWithValue(() => backupTestNow),
        if (tx != null)
          backupRestoreTransactionFactoryProvider.overrideWithValue(tx),
        ...reminderOverrides(service: reminders),
      ];

  Future<void> settle(WidgetTester tester, [int frames = 4]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps the real router positioned on the Backup & restore route.
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
    String initial = AppRoutes.backupRestore,
    BackupRestoreTransactionFactory? tx,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = AppRouter.create(initialLocation: initial);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...overrides(tx: tx),
        appRouterProvider.overrideWithValue(router),
      ],
      child: MaterialApp.router(
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: widget!,
        ),
        routerConfig: router,
      ),
    ));
    await settle(tester);
    return router;
  }

  Future<void> seedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await BackupRestoreTransaction(prefs: prefs)
        .run(fullBackupData().copyWith(appearance: AppearanceMode.light));
  }

  Future<void> pickValidAndPreview(WidgetTester tester) async {
    files.pickResult = BackupPickResult.picked(fullBackupBytes());
    await tester
        .ensureVisible(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
    await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
    await settle(tester);
    expect(find.byType(BackupPreviewCard), findsOneWidget);
  }

  group('Settings entry & routing', () {
    test('route constant nests under settings', () {
      expect(AppRoutes.backupRestore, '/profile/settings/backup-restore');
      expect(AppRoutes.backupRestore.startsWith(AppRoutes.settings), isTrue);
    });

    testWidgets('Settings shows the entry and navigates to the dedicated route',
        (tester) async {
      final router = await pumpApp(tester, initial: AppRoutes.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.dragUntilVisible(
        find.byKey(BackupRestoreSettingsEntry.tileKey),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      expect(find.text(BackupCopy.settingsTitle), findsWidgets);
      expect(find.text(BackupCopy.settingsSubtitle), findsOneWidget);
      // The heavy workflow is NOT inline on Settings.
      expect(find.text(BackupCopy.createDescription), findsNothing);
      expect(find.byType(BackupRestoreScreen), findsNothing);

      await tester.tap(find.byKey(BackupRestoreSettingsEntry.tileKey));
      await settle(tester);
      expect(router.state.uri.path, AppRoutes.backupRestore);
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'direct navigation renders the screen; back returns to Settings',
        (tester) async {
      final router = await pumpApp(tester);
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.backupRestore);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(router.state.uri.path, AppRoutes.settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Screen copy', () {
    testWidgets(
        'shows the required, honest copy and no cloud/encryption claims',
        (tester) async {
      await pumpApp(tester);
      for (final text in [
        BackupCopy.storageNote,
        BackupCopy.createTitle,
        BackupCopy.createDescription,
        BackupCopy.restoreTitle,
        BackupCopy.restoreDescription,
        BackupCopy.privacyNote,
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(
          find.text(
              'Your backup is stored wherever you choose. FitFlow does not upload it to a FitFlow server.'),
          findsOneWidget);
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final banned in [
        'cloud',
        'encrypt',
        'sync',
        'automatic',
        'drive',
        'password'
      ]) {
        expect(allText.contains(banned), isFalse,
            reason: 'no "$banned" claims');
      }
    });
  });

  group('Create backup', () {
    testWidgets('saved → "Backup saved." snackbar', (tester) async {
      await seedDevice();
      await pumpApp(tester);
      await tester.tap(find.byKey(BackupRestoreScreen.createButtonKey));
      await settle(tester);
      expect(find.text(BackupCopy.backupSaved), findsOneWidget);
      expect(files.saveCalls, 1);
      expect(BackupCodec.decode(files.lastSavedBytes!).isSuccess, isTrue);
    });

    testWidgets('cancelled → no snackbar, no error', (tester) async {
      files.saveOutcome = BackupSaveOutcome.cancelled;
      await pumpApp(tester);
      await tester.tap(find.byKey(BackupRestoreScreen.createButtonKey));
      await settle(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Restore flow', () {
    testWidgets('picker cancel → nothing happens', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
      await settle(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(BackupPreviewCard), findsNothing);
    });

    testWidgets('invalid file → concise error, no preview, no writes',
        (tester) async {
      await seedDevice();
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(AppearanceStorage.appearanceKey);
      files.pickResult = BackupPickResult.picked(bytesOf({'nope': 1}));
      await pumpApp(tester);
      await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
      await settle(tester);
      expect(find.text(BackupCopy.notFitFlowBackup), findsOneWidget);
      expect(find.byType(BackupPreviewCard), findsNothing);
      expect(prefs.getString(AppearanceStorage.appearanceKey), before);
    });

    testWidgets('too large → dedicated message', (tester) async {
      files.pickResult = const BackupPickResult.tooLarge();
      await pumpApp(tester);
      await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
      await settle(tester);
      expect(find.text(BackupCopy.fileTooLarge), findsOneWidget);
    });

    testWidgets('valid file → preview with counts', (tester) async {
      await pumpApp(tester);
      await pickValidAndPreview(tester);
      expect(find.text(BackupCopy.previewTitle), findsOneWidget);
      expect(find.text(BackupCopy.previewHistory), findsOneWidget);
      expect(find.text(BackupCopy.previewCustom), findsOneWidget);
      expect(find.text(BackupCopy.previewProgramsStarted), findsOneWidget);
      expect(find.text(BackupCopy.previewProgramSessions), findsOneWidget);
      expect(find.text(BackupCopy.previewReminders), findsOneWidget);
      expect(find.text(BackupCopy.on), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text(BackupCopy.included), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget); // saved workouts
      expect(find.text('2 patterns'), findsOneWidget);
      // Not labelled as a lifetime total.
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      expect(allText.contains('lifetime'), isFalse);
      expect(allText.contains('total workouts'), isFalse);

      await tester
          .ensureVisible(find.byKey(BackupPreviewCard.discardButtonKey));
      await tester.tap(find.byKey(BackupPreviewCard.discardButtonKey));
      await settle(tester);
      expect(find.byType(BackupPreviewCard), findsNothing);
    });

    testWidgets('confirmation dialog has exact copy; Cancel writes nothing',
        (tester) async {
      await seedDevice();
      final prefs = await SharedPreferences.getInstance();
      await pumpApp(tester);
      await pickValidAndPreview(tester);
      await tester
          .ensureVisible(find.byKey(BackupPreviewCard.restoreButtonKey));
      await tester.tap(find.byKey(BackupPreviewCard.restoreButtonKey));
      await settle(tester);
      expect(find.text(BackupCopy.confirmTitle), findsOneWidget);
      expect(find.text('Restore FitFlow backup?'), findsOneWidget);
      expect(find.text(BackupCopy.confirmBody), findsOneWidget);
      expect(find.text(BackupCopy.confirmNoMerge), findsOneWidget);
      expect(
          find.widgetWithText(TextButton, BackupCopy.cancel), findsOneWidget);
      expect(find.widgetWithText(FilledButton, BackupCopy.restore),
          findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, BackupCopy.cancel));
      await settle(tester);
      expect(find.text(BackupCopy.confirmTitle), findsNothing);
      expect(find.byType(BackupPreviewCard), findsOneWidget,
          reason: 'preview kept');
      expect(prefs.getString(AppearanceStorage.appearanceKey), 'light');
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
    });

    testWidgets(
        'Restore → data replaced, theme applied, routed through splash to Home',
        (tester) async {
      await seedDevice();
      final prefs = await SharedPreferences.getInstance();
      final router = await pumpApp(tester);
      await pickValidAndPreview(tester);
      await tester
          .ensureVisible(find.byKey(BackupPreviewCard.restoreButtonKey));
      await tester.tap(find.byKey(BackupPreviewCard.restoreButtonKey));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, BackupCopy.restore));
      await settle(tester);

      expect(prefs.getString(AppearanceStorage.appearanceKey), 'dark');
      expect(prefs.getString('unrelated'), 'keep');
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      expect(container.read(appearanceControllerProvider).value,
          AppearanceMode.dark);

      // Left the backup screen via the start gate, not forced Home.
      expect(router.state.uri.path, AppRoutes.splash);
      await tester.pump(AppConstants.splashDelay);
      await settle(tester, 8);
      expect(router.state.uri.path, AppRoutes.home);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Restoring an empty backup routes to onboarding',
        (tester) async {
      await seedDevice();
      final router = await pumpApp(tester);
      files.pickResult = BackupPickResult.picked(
          BackupCodec.encode(envelopeOf(emptyBackupData())));
      await tester
          .ensureVisible(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
      await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
      await settle(tester);
      expect(find.text(BackupCopy.notIncluded), findsNWidgets(2));
      await tester
          .ensureVisible(find.byKey(BackupPreviewCard.restoreButtonKey));
      await tester.tap(find.byKey(BackupPreviewCard.restoreButtonKey));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, BackupCopy.restore));
      await settle(tester);
      await tester.pump(AppConstants.splashDelay);
      await settle(tester, 8);
      expect(router.state.uri.path, AppRoutes.onboarding);
    });

    testWidgets('write failure → "previous data was kept", stays on screen',
        (tester) async {
      await seedDevice();
      final prefs = await SharedPreferences.getInstance();
      var failed = false;
      final router = await pumpApp(
        tester,
        tx: (p) => BackupRestoreTransaction(
          prefs: p,
          setString: (k, v) async {
            if (k == AppearanceStorage.appearanceKey && !failed) {
              failed = true;
              return false;
            }
            return p.setString(k, v);
          },
        ),
      );
      await pickValidAndPreview(tester);
      await tester
          .ensureVisible(find.byKey(BackupPreviewCard.restoreButtonKey));
      await tester.tap(find.byKey(BackupPreviewCard.restoreButtonKey));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, BackupCopy.restore));
      await settle(tester);
      expect(find.text(BackupCopy.restoreFailedRolledBack), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.backupRestore);
      expect(prefs.getString(AppearanceStorage.appearanceKey), 'light');
      expect(find.byType(BackupPreviewCard), findsOneWidget);
    });
  });

  group('Layout', () {
    for (final config in [
      (
        name: 'narrow 320px',
        size: const Size(320, 640),
        scale: 1.0,
        dark: false
      ),
      (name: 'tablet', size: const Size(800, 1280), scale: 1.0, dark: false),
      (
        name: 'text scale 1.5',
        size: const Size(390, 844),
        scale: 1.5,
        dark: false
      ),
      (name: 'dark theme', size: const Size(390, 844), scale: 1.0, dark: true),
    ]) {
      testWidgets('${config.name}: screen + preview render without overflow',
          (tester) async {
        await pumpApp(
          tester,
          size: config.size,
          textScale: config.scale,
          brightness: config.dark ? Brightness.dark : Brightness.light,
        );
        expect(find.byType(BackupRestoreScreen), findsOneWidget);
        await pickValidAndPreview(tester);
        await tester
            .ensureVisible(find.byKey(BackupPreviewCard.restoreButtonKey));
        await tester.tap(find.byKey(BackupPreviewCard.restoreButtonKey));
        await settle(tester);
        expect(find.text(BackupCopy.confirmTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${config.name}: Settings entry renders', (tester) async {
        await pumpApp(
          tester,
          size: config.size,
          textScale: config.scale,
          brightness: config.dark ? Brightness.dark : Brightness.light,
          initial: AppRoutes.settings,
        );
        await tester.dragUntilVisible(
          find.byKey(BackupRestoreSettingsEntry.tileKey),
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        expect(find.text(BackupCopy.settingsSubtitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
