import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_state.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  ensureTimezones();
  late FakeWorkoutReminderNotificationService service;
  late ToggleReminderStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = FakeWorkoutReminderNotificationService();
    storage = ToggleReminderStorage();
  });

  WorkoutRemindersController make({DateTime Function()? clock}) {
    final c = WorkoutRemindersController(
      storage: storage.storage,
      service: service,
      clock: clock ?? reminderTestNow,
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<WorkoutReminderPreferences> stored() =>
      const WorkoutReminderStorage().load();

  test('default disabled: nothing scheduled, status off', () async {
    final c = make();
    await c.initialize();
    expect(c.state.isLoaded, isTrue);
    expect(c.state.enabled, isFalse);
    expect(c.state.status, WorkoutReminderScheduleStatus.off);
    expect(service.scheduled, isEmpty);
    expect(service.permissionRequests, 0, reason: 'never requested on load');
    expect(c.state.preferences.weekdays, {1, 3, 5});
  });

  test('enabling requests permission only when not already granted', () async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.requestResult = WorkoutReminderPermissionStatus.granted;
    final c = make();
    await c.initialize();
    expect(service.permissionRequests, 0);
    expect(await c.enable(), isTrue);
    expect(service.permissionRequests, 1);
    expect(c.state.permission, WorkoutReminderPermissionStatus.granted);
  });

  test('permission granted → schedules selected weekdays, persists, status scheduled', () async {
    final c = make();
    await c.initialize();
    expect(await c.enable(), isTrue);
    expect(service.permissionRequests, 0, reason: 'already granted');
    expect(service.scheduledIds, {17001, 17003, 17005});
    for (final r in service.scheduled.values) {
      expect(r.title, 'FitFlow workout reminder');
      expect(r.body, 'Your workout reminder is ready when you are.');
      expect(r.payload, workoutReminderPayload);
      expect(r.scheduledAt.location.name, 'Asia/Karachi');
      expect(r.scheduledAt.hour, 19);
      expect(r.scheduledAt.weekday, r.weekday);
      expect(r.scheduledAt.isAfter(reminderTestNow()), isTrue);
    }
    expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    final s = await stored();
    expect(s.enabled, isTrue);
    expect(s.lastScheduledTimezoneId, 'Asia/Karachi');
  });

  test('permission denied → unscheduled, not enabled, truthful message', () async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.requestResult = WorkoutReminderPermissionStatus.denied;
    final c = make();
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(service.scheduled, isEmpty);
    expect(c.state.enabled, isFalse);
    expect(c.state.status, WorkoutReminderScheduleStatus.off);
    expect(c.state.message, WorkoutReminderMessage.permissionNeeded);
    expect((await stored()).enabled, isFalse);
    // Selected days/time remain available.
    expect(c.state.preferences.weekdays, {1, 3, 5});
  });

  test('enable with zero weekdays fails validation before any permission request', () async {
    final c = make();
    await c.initialize();
    expect(await c.setWeekdays(const []), isTrue);
    expect(await c.enable(), isFalse);
    expect(c.state.message, WorkoutReminderMessage.selectAtLeastOneDay);
    expect(service.permissionRequests, 0);
    expect(service.scheduled, isEmpty);
  });

  test('disable cancels only the seven owned IDs and persists enabled=false', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    service.cancelled.clear();
    expect(await c.disable(), isTrue);
    expect(service.cancelled.toSet(), WorkoutReminderIds.allWeekly.toSet());
    expect(service.cancelled.every(WorkoutReminderIds.isOwned), isTrue);
    expect(service.scheduled, isEmpty);
    expect(c.state.status, WorkoutReminderScheduleStatus.off);
    final s = await stored();
    expect(s.enabled, isFalse);
    expect(s.weekdays, {1, 3, 5}, reason: 'schedule selection preserved');
  });

  test('changing days while enabled reschedules atomically and cancels obsolete IDs', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    service.cancelled.clear();
    expect(await c.setWeekdays(const [2, 3]), isTrue);
    expect(service.scheduledIds, {17002, 17003});
    expect(service.cancelled.toSet(), {17001, 17005});
    expect((await stored()).weekdays, {2, 3});
    expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
  });

  test('toggling the last day off while enabled is rejected (never enabled with zero days)', () async {
    final c = make();
    await c.initialize();
    await c.setWeekdays(const [4]);
    await c.enable();
    expect(await c.toggleWeekday(4), isFalse);
    expect(c.state.message, WorkoutReminderMessage.selectAtLeastOneDay);
    expect(c.state.preferences.weekdays, {4});
    expect(service.scheduledIds, {17004});
  });

  test('changing time while enabled reschedules with the new time', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    expect(await c.setTime(const WorkoutReminderTime(hour: 6, minute: 30)), isTrue);
    expect(service.scheduledIds, {17001, 17003, 17005});
    for (final r in service.scheduled.values) {
      expect(r.scheduledAt.hour, 6);
      expect(r.scheduledAt.minute, 30);
    }
    expect((await stored()).time, const WorkoutReminderTime(hour: 6, minute: 30));
    expect(await c.setTime(const WorkoutReminderTime(hour: 30, minute: 0)), isFalse);
  });

  test('scheduling failure preserves previous state and previous schedule', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    final before = c.state.preferences;
    service.failIds = {17002};
    expect(await c.setWeekdays(const [1, 2]), isFalse);
    expect(c.state.preferences, before);
    expect((await stored()), before);
    expect(service.scheduledIds, {17001, 17003, 17005}, reason: 'previous schedule restored');
    expect(c.state.message, WorkoutReminderMessage.scheduleFailed);
    expect(c.state.status, WorkoutReminderScheduleStatus.scheduled,
        reason: 'previous valid schedule still stands');
  });

  test('enable: scheduling failure → not enabled, new IDs cancelled', () async {
    service.scheduleSucceeds = false;
    final c = make();
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(c.state.enabled, isFalse);
    expect(service.scheduled, isEmpty);
    expect((await stored()).enabled, isFalse);
    expect(c.state.message, WorkoutReminderMessage.scheduleFailed);
  });

  test('persistence failure after scheduling → newly scheduled reminders cancelled, no success claim', () async {
    storage.allowWrites = false;
    final c = make();
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(c.state.enabled, isFalse);
    expect(service.scheduled, isEmpty);
    expect(service.cancelled.toSet(), {17001, 17003, 17005});
    expect(c.state.message, WorkoutReminderMessage.saveFailed);
    expect(await storedReminderJson(), isNull);
  });

  test('disable: persistence failure → previous schedule restored, failure reported', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    storage.allowWrites = false;
    expect(await c.disable(), isFalse);
    expect(c.state.enabled, isTrue);
    expect(service.scheduledIds, {17001, 17003, 17005});
    expect((await stored()).enabled, isTrue);
    expect(c.state.message, WorkoutReminderMessage.saveFailed);
  });

  test('timezone unresolved → no schedule, no UTC fallback, error status', () async {
    service.timezoneId = null;
    final c = make();
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(service.scheduled, isEmpty);
    expect(c.state.enabled, isFalse);
    expect(c.state.message, WorkoutReminderMessage.scheduleFailed);
  });

  test('permission revoked externally is reflected on refresh; schedule kept', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    service.permission = WorkoutReminderPermissionStatus.denied;
    await c.refreshStatus();
    expect(c.state.status, WorkoutReminderScheduleStatus.permissionBlocked);
    expect(c.state.enabled, isTrue);
    expect(c.state.preferences.weekdays, {1, 3, 5}, reason: 'not erased');
    expect((await stored()).enabled, isTrue);
  });

  test('timezone change on resume causes reschedule in the new zone', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    final callsBefore = service.scheduleCalls;
    service.timezoneId = 'Europe/Berlin';
    await c.onAppResumed();
    expect(service.scheduleCalls, callsBefore + 3);
    for (final r in service.scheduled.values) {
      expect(r.scheduledAt.location.name, 'Europe/Berlin');
      expect(r.scheduledAt.hour, 19);
    }
    expect((await stored()).lastScheduledTimezoneId, 'Europe/Berlin');
  });

  test('same timezone + consistent pending schedule → no unnecessary reschedule', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    final callsBefore = service.scheduleCalls;
    await c.onAppResumed();
    await c.refreshStatus();
    await c.onAppResumed();
    expect(service.scheduleCalls, callsBefore);
  });

  test('inconsistent pending schedule (missing ID) → reconciled once', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    service.scheduled.remove(17003); // e.g. cleared by the OS
    final callsBefore = service.scheduleCalls;
    await c.onAppResumed();
    expect(service.scheduleCalls, callsBefore + 3);
    expect(service.scheduledIds, {17001, 17003, 17005});
  });

  test('startup with enabled stored preference reconciles when timezone differs', () async {
    await const WorkoutReminderStorage().save(WorkoutReminderPreferences(
      enabled: true,
      weekdays: const [6],
      time: const WorkoutReminderTime(hour: 9, minute: 0),
      lastScheduledTimezoneId: 'America/New_York',
    ));
    final c = make();
    await c.initialize();
    expect(service.scheduledIds, {17006});
    expect(service.scheduled[17006]!.scheduledAt.location.name, 'Asia/Karachi');
    expect((await stored()).lastScheduledTimezoneId, 'Asia/Karachi');
  });

  test('test notification uses ID 17999, calm copy, and never mutates preferences or schedule', () async {
    final c = make();
    await c.initialize();
    await c.enable();
    final prefsBefore = c.state.preferences;
    final scheduleBefore = Map.of(service.scheduled);
    expect(await c.sendTestNotification(), isTrue);
    expect(service.shown.single.id, 17999);
    expect(service.shown.single.title, 'FitFlow test reminder');
    expect(service.shown.single.body, 'Notifications are working.');
    expect(c.state.preferences, prefsBefore);
    expect(service.scheduled, scheduleBefore);
    expect(await stored(), prefsBefore);
    expect(c.state.message, WorkoutReminderMessage.testSent);
  });

  test('test notification with permission denied does not send', () async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    final c = make();
    await c.initialize();
    expect(await c.sendTestNotification(), isFalse);
    expect(service.shown, isEmpty);
    expect(c.state.message, WorkoutReminderMessage.permissionNeeded);
  });

  test('editing while disabled persists without scheduling', () async {
    final c = make();
    await c.initialize();
    expect(await c.setWeekdays(const [7]), isTrue);
    expect(await c.setTime(const WorkoutReminderTime(hour: 8, minute: 15)), isTrue);
    expect(service.scheduled, isEmpty);
    expect(service.permissionRequests, 0);
    final s = await stored();
    expect(s.weekdays, {7});
    expect(s.time, const WorkoutReminderTime(hour: 8, minute: 15));
  });

  test('max seven reminders, one per weekday, even when enabling every day', () async {
    final c = make();
    await c.initialize();
    await c.setWeekdays(const [1, 2, 3, 4, 5, 6, 7]);
    await c.enable();
    expect(service.scheduled.length, 7);
    expect(service.scheduledIds, WorkoutReminderIds.allWeekly.toSet());
  });

  test('open notification settings delegates to the backend', () async {
    final c = make();
    expect(await c.openNotificationSettings(), isTrue);
    expect(service.openSettingsCalls, 1);
    service.openSettingsSucceeds = false;
    expect(await c.openNotificationSettings(), isFalse);
    expect(c.state.message, WorkoutReminderMessage.settingsUnavailable);
  });

  test('clearMessage clears the one-shot message', () async {
    service.permission = WorkoutReminderPermissionStatus.denied;
    service.requestResult = WorkoutReminderPermissionStatus.denied;
    final c = make();
    await c.initialize();
    await c.enable();
    expect(c.state.message, isNotNull);
    c.clearMessage();
    expect(c.state.message, isNull);
  });
}
