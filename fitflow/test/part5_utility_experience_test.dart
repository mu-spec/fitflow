import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate, CheckedState;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:fitflow/features/backup/application/backup_file_service.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_preview_card.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appearance_persistence_test.dart' show ScriptedAppearanceStorage;
import 'helpers/backup_test_helpers.dart';
import 'helpers/profile_editor_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

Future<GoRouter> pumpUtility(
  WidgetTester tester,
  String route, {
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool reduced = true,
  double keyboard = 0,
  List<Override> overrides = const [],
  FakeBackupFileService? files,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final router = AppRouter.create(initialLocation: route);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...reminderOverrides(service: FakeWorkoutReminderNotificationService()),
      backupFileServiceProvider
          .overrideWithValue(files ?? FakeBackupFileService()),
      ...overrides,
    ],
    child: MaterialApp.router(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
              viewInsets: EdgeInsets.only(bottom: keyboard)),
          child: child!),
      routerConfig: router,
    ),
  ));
  await settleProfileFrames(tester);
  return router;
}

Future<void> openUtility(WidgetTester tester, String title) async {
  final target = find.text(title).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ensureTimezones();
    SharedPreferences.setMockInitialValues({
      ...seedProfilePrefs(backupProfile()),
      CapabilityProfileStorage.profileKey:
          jsonEncode(backupCapabilityProfile().toJson()),
      AppearanceStorage.appearanceKey: 'light',
    });
  });

  testWidgets(
      'settings groups only actual utilities and reveals persisted appearance',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpUtility(tester, AppRoutes.settings);
    for (final title in [
      'Preferences',
      'Data',
      'About',
      'Appearance',
      'Workout reminders',
      'Privacy Policy',
      'Backup & restore'
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Current: Light'), findsOneWidget);
    expect(find.byType(RadioListTile<AppearanceMode>), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.textContaining('Voice coaching'), findsNothing);
    await openUtility(tester, 'Appearance');
    final radios = tester.widgetList<RadioListTile<AppearanceMode>>(
        find.byType(RadioListTile<AppearanceMode>));
    expect(radios.length, 3);
    expect(radios.singleWhere((r) => r.value == AppearanceMode.light).selected,
        isTrue);
  });

  testWidgets(
      'appearance exposes native checked and tap semantics; slow failure retains old mode',
      (tester) async {
    addTearDown(tester.view.reset);
    final storage = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
        result: false,
        gate: Completer<bool>());
    await pumpUtility(tester, AppRoutes.settings, overrides: [
      appearanceStorageFactoryProvider.overrideWithValue((_) => storage),
    ]);
    await openUtility(tester, 'Appearance');
    final handle = tester.ensureSemantics();
    try {
      final light = tester.getSemantics(
          find.widgetWithText(RadioListTile<AppearanceMode>, 'Light'));
      expect(light.getSemanticsData().flagsCollection.isChecked,
          CheckedState.isTrue);
      expect(light.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(
          tester
              .widget<RadioListTile<AppearanceMode>>(
                  find.widgetWithText(RadioListTile<AppearanceMode>, 'Light'))
              .selected,
          isTrue);
      await tester.tap(find.text('System default'));
      await tester.pump();
      expect(storage.saveCalls, 1);
      storage.gate!.complete(false);
      await settleProfileFrames(tester);
      expect(find.text("Couldn't save appearance. Try again."), findsOneWidget);
      expect(find.text('Current: Light'), findsOneWidget);
      expect(
          (await SharedPreferences.getInstance())
              .getString(AppearanceStorage.appearanceKey),
          'light');
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
      'movement summary shows all ten persisted values with human levels, no assessment redirect',
      (tester) async {
    addTearDown(tester.view.reset);
    final router = await pumpUtility(tester, AppRoutes.profile);
    await openUtility(tester, 'Movement levels');
    for (final label in [
      'Just starting',
      'Basic',
      'Solid',
      'Strong',
      'Advanced'
    ]) {
      expect(find.text(label), findsNWidgets(2));
    }
    expect(find.textContaining(RegExp(r'^L[1-5]$|^level[1-5]$')), findsNothing);
    expect(router.state.uri.path, AppRoutes.profile);
    expect(find.textContaining('not a health score'), findsOneWidget);
    expect(find.text('Exercise mat'), findsNothing);
    expect(find.text('Chair, Resistance bands'), findsOneWidget);
  });

  testWidgets(
      'fitness editor current-value disclosures use canonical selectable controls',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpUtility(tester, AppRoutes.fitnessProfile);
    expect(find.text('Selected: Build strength'), findsOneWidget);
    expect(find.byType(FitFlowSelectableTile), findsNothing);
    await openUtility(tester, 'Goal');
    expect(find.widgetWithText(FitFlowSelectableTile, 'Build strength'),
        findsOneWidget);
    final handle = tester.ensureSemantics();
    try {
      final selected = tester
          .getSemantics(
              find.widgetWithText(FitFlowSelectableTile, 'Build strength'))
          .getSemanticsData();
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(selected.hasAction(SemanticsAction.tap), isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
      'Cancel uses existing unsaved confirmation and Keep editing retains draft',
      (tester) async {
    addTearDown(tester.view.reset);
    final router = await pumpUtility(tester, AppRoutes.equipment);
    await tapOption(tester, 'Dumbbells');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(optionCardSelected(tester, 'Dumbbells'), isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.profile);
    expect(find.text('Chair, Resistance bands'), findsOneWidget);
  });

  testWidgets(
      'disabled reminder edits serialize slow writes without requesting permission',
      (tester) async {
    addTearDown(tester.view.reset);
    final gate = Completer<bool>();
    var writes = 0;
    final storage =
        WorkoutReminderStorage(writeString: (prefs, key, value) async {
      writes++;
      await gate.future;
      return prefs.setString(key, value);
    });
    final service = FakeWorkoutReminderNotificationService();
    await pumpUtility(tester, AppRoutes.settings,
        overrides: reminderOverrides(service: service, storage: storage));
    await openUtility(tester, 'Workout reminders');
    final chip = find.byKey(const ValueKey('reminder_weekday_2'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(tester.widget<FilterChip>(chip).onSelected, isNull);
    await tester.tap(chip);
    await tester.pump();
    expect(writes, 1);
    gate.complete(true);
    await settleProfileFrames(tester);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(service.permissionRequests, 0);
    expect(service.scheduleCalls, 0);
  });

  testWidgets(
      'weekday native semantics retain full name, selection and tap action',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpUtility(tester, AppRoutes.settings);
    await openUtility(tester, 'Workout reminders');
    final chip = find.byKey(const ValueKey('reminder_weekday_1'));
    await tester.ensureVisible(chip);
    final handle = tester.ensureSemantics();
    try {
      final node = tester
          .getSemantics(find.bySemanticsLabel('Monday'))
          .getSemanticsData();
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('native time picker cancellation is quiet and does not write',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpUtility(tester, AppRoutes.settings);
    await openUtility(tester, 'Workout reminders');
    final before = await storedReminderJson();
    await openUtility(tester, 'Reminder time');
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(await storedReminderJson(), before);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
      'backup preview explains replacement; cancel preview does not open a picker',
      (tester) async {
    addTearDown(tester.view.reset);
    final files = FakeBackupFileService()
      ..pickResult = BackupPickResult.picked(fullBackupBytes());
    await pumpUtility(tester, AppRoutes.backupRestore, files: files);
    await tester
        .ensureVisible(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
    await tester.tap(find.byKey(BackupRestoreScreen.chooseFileButtonKey));
    await settleProfileFrames(tester);
    expect(find.text('Movement progress'), findsOneWidget);
    expect(find.text('Progression evidence'), findsNothing);
    expect(find.text('This restore does not merge the two sets of data.'),
        findsOneWidget);
    await tester.ensureVisible(find.byKey(BackupPreviewCard.discardButtonKey));
    await tester.tap(find.byKey(BackupPreviewCard.discardButtonKey));
    await settleProfileFrames(tester);
    expect(find.byType(BackupPreviewCard), findsNothing);
    expect(files.pickCalls, 1);
  });

  testWidgets(
      'reduced-motion disclosures are immediate and keyboard-inset save actions stay above keyboard',
      (tester) async {
    addTearDown(tester.view.reset);
    await pumpUtility(tester, AppRoutes.fitnessProfile,
        keyboard: 280, scale: 2);
    final tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile).first);
    expect(tile.expansionAnimationStyle!.duration, Duration.zero);
    final save = find.widgetWithText(FilledButton, 'Save changes');
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(844 - 280));
    expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(find.text('Goal'));
    await tester.pump();
    await tester.tap(find.text('Goal'));
    await tester.pump();
    expect(find.widgetWithText(FitFlowSelectableTile, 'General fitness'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final route in [
    AppRoutes.fitnessProfile,
    AppRoutes.equipment,
    AppRoutes.workoutPreferences
  ]) {
    testWidgets('editor load failure has sanitized Retry: $route',
        (tester) async {
      addTearDown(tester.view.reset);
      final profile = ScriptedProfileController(backupProfile())
        ..loadFailures = 1;
      await pumpUtility(tester, route,
          overrides: [userFitnessProfileProvider.overrideWith(() => profile)]);
      expect(find.text("Your profile couldn't be loaded."), findsOneWidget);
      expect(find.textContaining('simulated profile'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(profile.loadCalls, 2);
      expect(find.text("Your profile couldn't be loaded."), findsNothing);
      expect(find.text('Save changes'), findsOneWidget);
    });
  }

  testWidgets('missing editor profile has the existing setup recovery',
      (tester) async {
    addTearDown(tester.view.reset);
    final router = await pumpUtility(tester, AppRoutes.equipment, overrides: [
      userFitnessProfileProvider
          .overrideWith(() => ScriptedProfileController(null)),
    ]);
    expect(find.text('Fitness profile not set up'), findsOneWidget);
    await tester.tap(find.text('Set up profile'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.onboarding);
  });

  testWidgets(
      'reminders do not claim Off or expose defaults before storage loads',
      (tester) async {
    addTearDown(tester.view.reset);
    final gate = Completer<SharedPreferences>();
    await pumpUtility(tester, AppRoutes.settings,
        overrides: reminderOverrides(
            service: FakeWorkoutReminderNotificationService(),
            storage: WorkoutReminderStorage(getPrefs: () => gate.future)));
    await openUtility(tester, 'Workout reminders');
    expect(find.text('Loading reminders…'), findsWidgets);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Reminders are off.'), findsNothing);
    gate.complete(await SharedPreferences.getInstance());
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Reminders are off.'), findsOneWidget);
  });

  const screens = [
    AppRoutes.profile,
    AppRoutes.fitnessProfile,
    AppRoutes.equipment,
    AppRoutes.workoutPreferences,
    AppRoutes.settings,
    AppRoutes.backupRestore,
    AppRoutes.privacyPolicy
  ];
  const sizes = [
    Size(320, 760),
    Size(390, 844),
    Size(430, 900),
    Size(600, 900),
    Size(840, 1000),
    Size(1024, 768),
    Size(844, 390)
  ];
  for (final brightness in Brightness.values) {
    for (final size in sizes) {
      testWidgets(
          'utility routes ${size.width}x${size.height} $brightness 2x expanded layout',
          (tester) async {
        addTearDown(tester.view.reset);
        for (final route in screens) {
          await pumpUtility(tester, route,
              size: size, scale: 2, brightness: brightness);
          if (route == AppRoutes.profile) {
            await openUtility(tester, 'Movement levels');
          }
          if (route == AppRoutes.fitnessProfile) {
            await openUtility(tester, 'Goal');
          }
          if (route == AppRoutes.settings) {
            await openUtility(tester, 'Appearance');
            await openUtility(tester, 'Workout reminders');
          }
          final scroll = find.byType(SingleChildScrollView).first;
          await tester.drag(scroll, const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
        }
      });
    }
  }
}
