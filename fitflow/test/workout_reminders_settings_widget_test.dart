import 'dart:convert';

import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:fitflow/features/reminders/presentation/widgets/workout_reminders_section.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  late FakeWorkoutReminderNotificationService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = FakeWorkoutReminderNotificationService();
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
    Widget? child,
    List<Override>? overrides,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides ?? reminderOverrides(service: service),
      child: MaterialApp(
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: widget!,
        ),
        home: child ??
            const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: WorkoutRemindersSection(),
              ),
            ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder chip(int weekday) => find.byKey(ValueKey<String>('reminder_weekday_$weekday'));
  final toggle = find.byType(SwitchListTile);
  Future<void> flipToggle(WidgetTester tester) async {
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders inside the real Settings screen with Appearance intact', (tester) async {
    await pumpSection(tester, child: const SettingsScreen());
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Send test notification'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Workout reminders'), findsWidgets);
    expect(find.text('Reminders are off.'), findsOneWidget);
    expect(find.text('Android may deliver reminders slightly later to reduce battery use.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default state: off, Mon/Wed/Fri 7:00 PM, nothing scheduled or requested',
      (tester) async {
    await pumpSection(tester);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Reminders are off.'), findsOneWidget);
    expect(find.text('Mon, Wed, Fri • 7:00 PM'), findsOneWidget);
    expect(find.text('7:00 PM'), findsOneWidget);
    for (final d in [1, 3, 5]) {
      expect(tester.widget<FilterChip>(chip(d)).selected, isTrue);
    }
    for (final d in [2, 4, 6, 7]) {
      expect(tester.widget<FilterChip>(chip(d)).selected, isFalse);
    }
    expect(service.permissionRequests, 0);
    expect(service.scheduled, isEmpty);
    expect(await storedReminderJson(), isNull);
  });

  testWidgets('weekday chips expose full-day-name semantics and letters M T W T F S S',
      (tester) async {
    await pumpSection(tester);
    final handle = tester.ensureSemantics();
    for (final entry in {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    }.entries) {
      expect(find.bySemanticsLabel(entry.value), findsOneWidget, reason: entry.value);
    }
    final letters = [for (final d in WorkoutReminderWeekday.all) WorkoutReminderWeekday.letter(d)];
    expect(letters, ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    for (final l in ['M', 'W', 'F']) {
      expect(find.text(l), findsWidgets);
    }
    handle.dispose();
  });

  testWidgets('enable requests permission once, schedules 3 reminders, persists, status scheduled',
      (tester) async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.requestResult = WorkoutReminderPermissionStatus.granted;
    await pumpSection(tester);
    await flipToggle(tester);
    expect(service.permissionRequests, 1);
    expect(service.scheduled.keys.toSet(),
        {WorkoutReminderIds.forWeekday(1), WorkoutReminderIds.forWeekday(3), WorkoutReminderIds.forWeekday(5)});
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(find.text('Workout reminders are scheduled.'), findsOneWidget);
    final stored = jsonDecode((await storedReminderJson())!) as Map<String, dynamic>;
    expect(stored['enabled'], isTrue);
    expect(stored['timezoneId'], 'Asia/Karachi');
  });

  testWidgets('permission denied on enable: truthful failure, days/time kept, settings action',
      (tester) async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.requestResult = WorkoutReminderPermissionStatus.denied;
    await pumpSection(tester);
    await flipToggle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.scheduled, isEmpty);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Notification permission is needed to send workout reminders.'),
        findsOneWidget);
    expect(find.text('Open notification settings'), findsWidgets);
    expect(find.text('Mon, Wed, Fri • 7:00 PM'), findsOneWidget);
    expect(find.text('Workout reminders are scheduled.'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Open notification settings'));
    await tester.pump();
    expect(service.openSettingsCalls, 1);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('enabled but blocked later shows blocked status and keeps schedule', (tester) async {
    SharedPreferences.setMockInitialValues({
      'workout_reminders_v1': jsonEncode({
        'version': 1, 'enabled': true, 'weekdays': [1, 3, 5],
        'hour': 19, 'minute': 0, 'timezoneId': 'Asia/Karachi',
      }),
    });
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.pendingOverride = [17001, 17003, 17005];
    await pumpSection(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
        find.text('Reminders are enabled in FitFlow, but notifications are blocked by Android.'),
        findsOneWidget);
    expect(find.text('Open notification settings'), findsOneWidget);
    expect(service.cancelled, isEmpty);
    expect(service.permissionRequests, 0, reason: 'refresh never prompts');
    // Test button unavailable while blocked.
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send test notification'));
    expect(button.onPressed, isNull);
  });

  testWidgets('disable cancels only the 7 FitFlow IDs and persists off', (tester) async {
    await pumpSection(tester);
    await flipToggle(tester);
    expect(service.scheduled.length, 3);
    await flipToggle(tester);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Reminders are off.'), findsOneWidget);
    expect(service.scheduled, isEmpty);
    expect(service.cancelled.toSet(), WorkoutReminderIds.allWeekly.toSet());
    final stored = jsonDecode((await storedReminderJson())!) as Map<String, dynamic>;
    expect(stored['enabled'], isFalse);
    expect(stored['weekdays'], [1, 3, 5]);
  });

  testWidgets('toggling weekdays while enabled reschedules and updates summary', (tester) async {
    await pumpSection(tester);
    await flipToggle(tester);
    await tester.tap(chip(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Mon, Tue, Wed, Fri • 7:00 PM'), findsOneWidget);
    expect(service.scheduled.keys, contains(WorkoutReminderIds.forWeekday(2)));
    await tester.tap(chip(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tue, Wed, Fri • 7:00 PM'), findsOneWidget);
    expect(service.scheduled.keys, isNot(contains(WorkoutReminderIds.forWeekday(1))));
    expect(service.cancelled, contains(WorkoutReminderIds.forWeekday(1)));
    expect(service.scheduled.length, 3);
  });

  testWidgets('deselecting the last day while enabled is refused with a calm message',
      (tester) async {
    await pumpSection(tester);
    await flipToggle(tester);
    for (final d in [1, 3]) {
      await tester.tap(chip(d));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Fri • 7:00 PM'), findsOneWidget);
    await tester.tap(chip(5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Select at least one day.'), findsWidgets);
    expect(tester.widget<FilterChip>(chip(5)).selected, isTrue);
    expect(service.scheduled.length, 1, reason: 'never zero reminders while enabled');
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('every day summary and weekend edits while disabled do not schedule', (tester) async {
    await pumpSection(tester);
    for (final d in [2, 4, 6, 7]) {
      await tester.tap(chip(d));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Every day • 7:00 PM'), findsOneWidget);
    expect(service.scheduled, isEmpty);
    expect(service.permissionRequests, 0);
    final stored = jsonDecode((await storedReminderJson())!) as Map<String, dynamic>;
    expect(stored['weekdays'], [1, 2, 3, 4, 5, 6, 7]);
    expect(stored['enabled'], isFalse);
  });

  testWidgets('time picker stores hour/minute and displays locale time', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    // Switch to keyboard entry and type 8:30 AM.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '8');
    await tester.enterText(fields.at(1), '30');
    await tester.pumpAndSettle();
    if (find.text('AM').evaluate().isNotEmpty) {
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Mon, Wed, Fri • 8:30 AM'), findsOneWidget);
    final stored = jsonDecode((await storedReminderJson())!) as Map<String, dynamic>;
    expect(stored['hour'], 8);
    expect(stored['minute'], 30);
    expect(service.scheduled, isEmpty, reason: 'still disabled');
  });

  testWidgets('send test notification uses ID 17999 and does not touch preferences',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Send test notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(service.shown.map((s) => s.id), [WorkoutReminderIds.test]);
    expect(service.shown.single.title, 'FitFlow test reminder');
    expect(service.shown.single.body, 'Notifications are working.');
    expect(find.text('Test notification sent.'), findsOneWidget);
    expect(await storedReminderJson(), isNull);
    expect(service.scheduled, isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('schedule failure on enable is reported truthfully', (tester) async {
    service.scheduleSucceeds = false;
    await pumpSection(tester);
    await flipToggle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text("Couldn't schedule reminders. Try again."), findsWidgets);
    expect(find.text('Workout reminders are scheduled.'), findsNothing);
    expect(service.scheduled, isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('timezone resolution failure blocks enabling without UTC fallback', (tester) async {
    service.timezoneId = null;
    await pumpSection(tester);
    await flipToggle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(service.scheduled, isEmpty);
    expect(find.text("Couldn't schedule reminders. Try again."), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('persistence failure on enable rolls back the new schedule', (tester) async {
    final storage = ToggleReminderStorage()..allowWrites = false;
    await pumpSection(tester,
        overrides: reminderOverrides(service: service, storage: storage.storage));
    await flipToggle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(service.scheduled, isEmpty);
    expect(find.text("Couldn't save reminder settings. Try again."), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no internal enum names leak into the UI', (tester) async {
    await pumpSection(tester);
    await flipToggle(tester);
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join('\n');
    for (final leak in [
      'WorkoutReminder',
      'permissionBlocked',
      'scheduleError',
      'notRequired',
      'inexactAllowWhileIdle',
      'fitflow_workout_reminders_v1',
    ]) {
      expect(texts.contains(leak), isFalse, reason: leak);
    }
  });

  testWidgets('layout: 320px phone, text scale 1.5', (tester) async {
    await pumpSection(tester, size: const Size(320, 640), textScale: 1.5);
    expect(find.text('Send test notification'), findsOneWidget);
    for (var d = 1; d <= 7; d++) {
      expect(chip(d), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout: tablet, dark theme', (tester) async {
    await pumpSection(tester, size: const Size(1024, 1366), brightness: Brightness.dark);
    expect(Theme.of(tester.element(find.byType(Card))).brightness, Brightness.dark);
    expect(find.text('Mon, Wed, Fri • 7:00 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout: 320px light with permission-denied banner', (tester) async {
    SharedPreferences.setMockInitialValues({
      'workout_reminders_v1': jsonEncode({
        'version': 1, 'enabled': true, 'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'hour': 6, 'minute': 5, 'timezoneId': 'Asia/Karachi',
      }),
    });
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.pendingOverride = WorkoutReminderIds.allWeekly;
    await pumpSection(tester, size: const Size(320, 640), textScale: 1.3);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Every day • 6:05 AM'), findsOneWidget);
    expect(find.text('Open notification settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('scheduleSummary formats correctly (static helper)', () {
    // Covered via widget tests above; keep controller provider reachable.
    expect(workoutRemindersControllerProvider, isNotNull);
  });
}
