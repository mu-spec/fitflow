import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/backup/presentation/backup_copy.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_preview_card.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_restore_settings_entry.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/presentation/privacy_policy_screen.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/settings/presentation/widgets/utility_presentation.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  testWidgets(
      'Settings preserves its existing hierarchy, values, and destinations',
      (tester) async {
    final files = FakeBackupFileService();
    final reminders = FakeWorkoutReminderNotificationService();
    final router = await _pumpSettingsV2App(
      tester,
      files: files,
      reminders: reminders,
      initialLocation: AppRoutes.settings,
      reducedMotion: true,
      initialPreferences: {
        AppearanceStorage.appearanceKey: AppearanceMode.light.name,
      },
    );

    final semantics = tester.ensureSemantics();
    try {
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Settings')).flagsCollection.isHeader,
        isTrue,
      );
      for (final label in ['Preferences', 'Appearance', 'Data', 'About']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(UtilityDisclosure), findsNWidgets(2));
      expect(find.byType(FitFlowV2InfoSurface), findsNothing);
      expect(find.text(BackupCopy.settingsTitle), findsOneWidget);
      expect(find.text(BackupCopy.settingsSubtitle), findsNothing);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('How Home Workout handles information on this device.'),
          findsNothing);
      expect(find.text(SettingsScreen.localDataFooter), findsOneWidget);

      await _ensureVisibleAndTap(tester, 'Appearance');
      for (final option in ['System default', 'Light', 'Dark']) {
        expect(find.widgetWithText(RadioListTile<AppearanceMode>, option),
            findsOneWidget,
            reason: option);
      }
      final lightRadio = find.widgetWithText(
        RadioListTile<AppearanceMode>,
        'Light',
      );
      expect(tester.widget<RadioListTile<AppearanceMode>>(lightRadio).selected,
          isTrue);
      expect(
        tester.getSize(lightRadio).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.text('Dark'));
      await _settle(tester);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );

      // About remains the existing factual Privacy Policy destination.
      await tester
          .ensureVisible(find.byKey(SettingsScreen.privacyPolicyTileKey));
      await tester.tap(find.byKey(SettingsScreen.privacyPolicyTileKey));
      await _settle(tester);
      expect(router.state.uri.path, AppRoutes.privacyPolicy);
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(PrivacyPolicyScreen))).brightness,
        Brightness.dark,
      );
      expect(find.text(PrivacyPolicyScreen.title), findsOneWidget);
      expect(PrivacyPolicyScreen.sections, hasLength(9));
      for (final section in PrivacyPolicyScreen.sections) {
        expect(find.text(section.heading), findsOneWidget,
            reason: section.heading);
      }
      expect(
        find.text(
            'This page describes how Home Workout handles information in this version of the app.'),
        findsOneWidget,
      );
      expect(find.text('About Home Workout'), findsNothing);

      router.go(AppRoutes.settings);
      await _settle(tester);
      final entry = find.byKey(BackupRestoreSettingsEntry.tileKey);
      await tester.ensureVisible(entry);
      final entryData = tester.getSemantics(entry).getSemanticsData();
      expect(entryData.hasAction(SemanticsAction.tap), isTrue);
      expect(entryData.hasAction(SemanticsAction.focus), isTrue);
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      final inkWell =
          find.descendant(of: entry, matching: find.byType(InkWell));
      final gesture = find.descendant(
        of: inkWell,
        matching: find.byType(GestureDetector),
      );
      final targetFocus = Focus.of(tester.element(gesture), scopeOk: false);
      var focusedEntry = false;
      for (var index = 0; index < 32; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (identical(FocusManager.instance.primaryFocus, targetFocus)) {
          focusedEntry = true;
          break;
        }
      }
      expect(focusedEntry, isTrue,
          reason: 'Tab traversal should reach Backup & restore');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(router.state.uri.path, AppRoutes.backupRestore);
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(BackupRestoreScreen))).brightness,
        Brightness.dark,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'appearance and reminder controls keep their saved state and semantics',
      (tester) async {
    final files = FakeBackupFileService();
    final reminders = FakeWorkoutReminderNotificationService();
    await _pumpSettingsV2App(
      tester,
      files: files,
      reminders: reminders,
      initialLocation: AppRoutes.settings,
      reducedMotion: true,
      initialPreferences: {
        AppearanceStorage.appearanceKey: AppearanceMode.dark.name,
        WorkoutReminderStorage.key: WorkoutReminderStorage.encode(
          WorkoutReminderPreferences(
            enabled: false,
            weekdays: const {1, 3, 5},
            time: const WorkoutReminderTime(hour: 19, minute: 0),
            lastScheduledTimezoneId: 'Asia/Karachi',
          ),
        ),
      },
    );

    final semantics = tester.ensureSemantics();
    try {
      final appearanceDisclosure = find.byType(UtilityDisclosure).first;
      final appearanceTile = tester.widget<ExpansionTile>(
        find.descendant(
          of: appearanceDisclosure,
          matching: find.byType(ExpansionTile),
        ),
      );
      expect(appearanceTile.expansionAnimationStyle?.duration, Duration.zero);
      await _ensureVisibleAndTap(tester, 'Appearance');
      final darkRadio = find.widgetWithText(
        RadioListTile<AppearanceMode>,
        'Dark',
      );
      expect(tester.widget<RadioListTile<AppearanceMode>>(darkRadio).selected,
          isTrue);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );

      await tester.tap(find.text('Light'));
      await _settle(tester);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceStorage.appearanceKey), 'light');
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light,
      );

      await _ensureVisibleAndTap(tester, 'Workout reminders');
      expect(find.text('Reminders are off.'), findsOneWidget);
      expect(find.text('Mon, Wed, Fri • 7:00 PM'), findsOneWidget);
      final switchFinder = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      expect(tester.getSize(switchFinder).height, greaterThanOrEqualTo(48));
      final switchSemantics = tester.getSemantics(switchFinder);
      expect(switchSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue);
      expect(
          switchSemantics.getSemanticsData().hasAction(SemanticsAction.focus),
          isTrue);

      for (final day in [1, 2, 3, 4, 5, 6, 7]) {
        final chip = find.byKey(ValueKey<String>('reminder_weekday_$day'));
        expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      }
      final monday = find.byKey(const ValueKey<String>('reminder_weekday_1'));
      final mondaySemantics = tester.getSemantics(monday);
      expect(mondaySemantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(mondaySemantics.getSemanticsData().label, contains('Monday'));

      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await _settle(tester);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      expect(find.text('Workout reminders are scheduled.'), findsOneWidget);
      expect(reminders.scheduledIds, {17001, 17003, 17005});
      final stored = jsonDecode(
        (await SharedPreferences.getInstance())
            .getString(WorkoutReminderStorage.key)!,
      ) as Map<String, dynamic>;
      expect(stored['enabled'], isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'backup export, preview, and destructive confirmation keep existing behavior',
      (tester) async {
    final files = FakeBackupFileService();
    final reminders = FakeWorkoutReminderNotificationService();
    final router = await _pumpSettingsV2App(
      tester,
      files: files,
      reminders: reminders,
      initialLocation: AppRoutes.backupRestore,
      size: const Size(320, 700),
      textScale: 2,
      initialPreferences: {
        AppearanceStorage.appearanceKey: AppearanceMode.light.name,
      },
    );

    final semantics = tester.ensureSemantics();
    try {
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
      expect(find.text(BackupCopy.storageNote), findsOneWidget);
      expect(find.text(BackupCopy.createTitle), findsOneWidget);
      expect(find.text(BackupCopy.createDescription), findsOneWidget);
      expect(find.text(BackupCopy.restoreTitle), findsOneWidget);
      expect(find.text(BackupCopy.restoreDescription), findsOneWidget);
      expect(find.text(BackupCopy.privacyNote), findsOneWidget);
      final create = find.byKey(BackupRestoreScreen.createButtonKey);
      final choose = find.byKey(BackupRestoreScreen.chooseFileButtonKey);
      expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(choose).height, greaterThanOrEqualTo(48));

      await tester.ensureVisible(create);
      await tester.tap(create);
      await _settle(tester);
      expect(files.saveCalls, 1);
      expect(find.text(BackupCopy.backupSaved), findsOneWidget);

      files.pickResult = BackupPickResult.picked(fullBackupBytes());
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await _settle(tester);
      final preview = find.byType(BackupPreviewCard);
      expect(preview, findsOneWidget);
      for (final label in [
        BackupCopy.previewTitle,
        BackupCopy.previewCreated,
        BackupCopy.previewProfile,
        BackupCopy.previewCapability,
        BackupCopy.previewEvidence,
        BackupCopy.previewHistory,
        BackupCopy.previewCustom,
        BackupCopy.previewProgramsStarted,
        BackupCopy.previewProgramSessions,
        BackupCopy.previewReminders,
        BackupCopy.previewAppearance,
        BackupCopy.confirmBody,
        BackupCopy.confirmNoMerge,
      ]) {
        expect(
          find.descendant(of: preview, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.text('Dark'), findsOneWidget);
      final previewRestore = find.byKey(BackupPreviewCard.restoreButtonKey);
      expect(tester.getSize(previewRestore).height, greaterThanOrEqualTo(48));
      expect(
        tester
            .getSemantics(previewRestore)
            .getSemanticsData()
            .hasAction(SemanticsAction.focus),
        isTrue,
      );

      await tester.ensureVisible(previewRestore);
      await tester.tap(previewRestore);
      await _settle(tester);
      expect(find.text(BackupCopy.confirmTitle), findsOneWidget);
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining(BackupCopy.confirmBody),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining(BackupCopy.confirmNoMerge),
        ),
        findsOneWidget,
      );
      final restoreConfirm =
          find.widgetWithText(TextButton, BackupCopy.restore);
      final cancel = find.widgetWithText(TextButton, BackupCopy.cancel);
      expect(restoreConfirm, findsOneWidget);
      expect(cancel, findsOneWidget);
      expect(tester.getSize(restoreConfirm).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
      expect(files.pickCalls, 1);

      await tester.tap(cancel);
      await _settle(tester);
      expect(find.text(BackupCopy.confirmTitle), findsNothing);
      expect(find.byType(BackupPreviewCard), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.backupRestore);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Settings, reminders, backup, and Privacy Policy fit the viewport matrix',
      (tester) async {
    const viewports = <({Size size, double scale})>[
      (size: Size(320, 700), scale: 1),
      (size: Size(390, 844), scale: 1),
      (size: Size(600, 900), scale: 1),
      (size: Size(840, 1000), scale: 1),
      (size: Size(900, 320), scale: 1),
      (size: Size(320, 700), scale: 2),
    ];

    for (final viewport in viewports) {
      final files = FakeBackupFileService();
      final reminders = FakeWorkoutReminderNotificationService();
      final router = await _pumpSettingsV2App(
        tester,
        files: files,
        reminders: reminders,
        initialLocation: AppRoutes.settings,
        size: viewport.size,
        textScale: viewport.scale,
        manageRouter: false,
        initialPreferences: {
          AppearanceStorage.appearanceKey: AppearanceMode.light.name,
        },
      );
      try {
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        final settingsBody = find.byType(SingleChildScrollView).first;
        expect(
          tester.getSize(settingsBody).width,
          lessThanOrEqualTo(FitFlowLayout.maxReadableWidth),
        );
        await _ensureVisibleAndTap(tester, 'Workout reminders');
        await _expectReachable(
          tester,
          find.text('Send test notification'),
          viewport.size,
          reason: 'Reminder action should be reachable at $viewport',
        );
        expect(tester.takeException(), isNull, reason: 'Settings $viewport');

        router.go(AppRoutes.backupRestore);
        await _settle(tester);
        expect(find.byType(BackupRestoreScreen), findsOneWidget);
        await _expectReachable(
          tester,
          find.byKey(BackupRestoreScreen.chooseFileButtonKey),
          viewport.size,
          reason: 'Restore action should be reachable at $viewport',
        );
        expect(tester.takeException(), isNull, reason: 'Backup $viewport');

        if (viewport.size.width == 900) {
          files.pickResult = BackupPickResult.picked(fullBackupBytes());
          final choose = find.byKey(BackupRestoreScreen.chooseFileButtonKey);
          await tester.ensureVisible(choose);
          await tester.tap(choose);
          await _settle(tester);
          final previewRestore = find.byKey(BackupPreviewCard.restoreButtonKey);
          await tester.ensureVisible(previewRestore);
          await tester.tap(previewRestore);
          await _settle(tester);
          expect(find.byType(AlertDialog), findsOneWidget);
          final cancel = find.widgetWithText(TextButton, BackupCopy.cancel);
          expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
          await _expectReachable(
            tester,
            cancel,
            viewport.size,
            reason: 'Restore cancel action should be reachable in landscape',
          );
          await tester.tap(cancel);
          await _settle(tester);
          expect(find.byType(BackupPreviewCard), findsOneWidget);
        }

        router.go(AppRoutes.privacyPolicy);
        await _settle(tester);
        expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
        await _expectReachable(
          tester,
          find.text('Not medical advice'),
          viewport.size,
          reason: 'Privacy content should scroll at $viewport',
        );
        expect(tester.takeException(), isNull, reason: 'Privacy $viewport');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    }
  });
}

Future<GoRouter> _pumpSettingsV2App(
  WidgetTester tester, {
  required FakeBackupFileService files,
  required FakeWorkoutReminderNotificationService reminders,
  required String initialLocation,
  Map<String, Object> initialPreferences = const {},
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reducedMotion = false,
  bool manageRouter = true,
}) async {
  ensureTimezones();
  SharedPreferences.setMockInitialValues(initialPreferences);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = AppRouter.create(initialLocation: initialLocation);
  if (manageRouter) addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupFileServiceProvider.overrideWithValue(files),
        backupClockProvider.overrideWithValue(() => backupTestNow),
        ...reminderOverrides(service: reminders),
      ],
      child: _AppearanceDrivenApp(
        router: router,
        textScale: textScale,
        reducedMotion: reducedMotion,
      ),
    ),
  );
  await _settle(tester);
  return router;
}

class _AppearanceDrivenApp extends ConsumerWidget {
  const _AppearanceDrivenApp({
    required this.router,
    required this.textScale,
    required this.reducedMotion,
  });

  final GoRouter router;
  final double textScale;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceControllerProvider).valueOrNull ??
        AppearanceMode.system;
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode.toThemeMode(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: SystemMotionTheme(child: child ?? const SizedBox.shrink()),
      ),
      routerConfig: router,
    );
  }
}

Future<void> _ensureVisibleAndTap(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _expectReachable(
  WidgetTester tester,
  Finder target,
  Size viewport, {
  required String reason,
}) async {
  await tester.ensureVisible(target);
  expect(
    tester.getRect(target).overlaps(Offset.zero & viewport),
    isTrue,
    reason: reason,
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var index = 0; index < frames; index++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
