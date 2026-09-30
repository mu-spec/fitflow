import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_state.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/workout_reminder_test_helpers.dart';

/// M17 stabilization: cancellation results are part of reminder truthfulness.
void main() {
  ensureTimezones();
  late FakeWorkoutReminderNotificationService service;
  late ToggleReminderStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = FakeWorkoutReminderNotificationService();
    storage = ToggleReminderStorage();
  });

  WorkoutRemindersController make() {
    final c = WorkoutRemindersController(
      storage: storage.storage,
      service: service,
      clock: reminderTestNow,
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<WorkoutReminderPreferences> stored() =>
      const WorkoutReminderStorage().load();

  /// Enabled Mon/Wed/Fri with a clean schedule.
  Future<WorkoutRemindersController> enabledMonWedFri() async {
    final c = make();
    await c.initialize();
    expect(await c.enable(), isTrue);
    expect(service.scheduledIds, {17001, 17003, 17005});
    service.cancelled.clear();
    return c;
  }

  group('disable requires successful cancellation', () {
    test('1. all cancels succeed → disable works and persists OFF', () async {
      final c = await enabledMonWedFri();
      expect(await c.disable(), isTrue);
      expect(service.scheduled, isEmpty);
      expect(c.state.status, WorkoutReminderScheduleStatus.off);
      expect((await stored()).enabled, isFalse);
    });

    test('2. cancellation failure → disable returns false', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      expect(await c.disable(), isFalse);
    });

    test('3. cancellation failure → persisted preference remains enabled', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.disable();
      final s = await stored();
      expect(s.enabled, isTrue);
      expect(s.weekdays, {1, 3, 5});
      expect(s.lastScheduledTimezoneId, 'Asia/Karachi');
    });

    test('4. cancellation failure → controller remains enabled', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.disable();
      expect(c.state.enabled, isTrue);
      expect(c.state.preferences.weekdays, {1, 3, 5});
      expect(c.state.isBusy, isFalse);
    });

    test('5. cancellation failure → previous schedule restored best-effort', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.disable();
      // Mon/Wed were cancelled, then re-created; Fri never left the OS.
      expect(service.scheduledIds, {17001, 17003, 17005});
      expect(service.cancelled.where((id) => id == 17005), isNotEmpty);
      expect(service.cancelled.every(WorkoutReminderIds.isWeeklyOwned), isTrue);
    });

    test('6. no false OFF status; truthful update failure reported', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.disable();
      expect(c.state.status, isNot(WorkoutReminderScheduleStatus.off));
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled,
          reason: 'previous schedule fully restored');
      expect(c.state.message, WorkoutReminderMessage.saveFailed);
    });

    test('6b. cancellation failure + restore failure → schedule-error status', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      service.failIds = {17001}; // restoring Monday fails too
      expect(await c.disable(), isFalse);
      expect(c.state.enabled, isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);
      expect((await stored()).enabled, isTrue);
    });
  });

  group('editing an enabled schedule requires obsolete IDs to cancel', () {
    test('7. obsolete IDs cancel successfully → new selection persists', () async {
      final c = await enabledMonWedFri();
      expect(await c.setWeekdays(const [2, 3]), isTrue);
      expect(service.scheduledIds, {17002, 17003});
      expect((await stored()).weekdays, {2, 3});
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    });

    test('8. obsolete cancellation failure → update returns false', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005}; // Friday refuses to cancel
      expect(await c.setWeekdays(const [2, 3]), isFalse);
      expect(c.state.message, WorkoutReminderMessage.scheduleFailed);
    });

    test('9. obsolete cancellation failure → old preference remains persisted', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.setWeekdays(const [2, 3]);
      final s = await stored();
      expect(s.enabled, isTrue);
      expect(s.weekdays, {1, 3, 5}, reason: 'never Tue/Wed persisted with Fri pending');
      expect(c.state.preferences.weekdays, {1, 3, 5});
    });

    test('10. previous selected schedule restored', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.setWeekdays(const [2, 3]);
      expect(service.scheduledIds, {17001, 17003, 17005});
      expect(service.scheduled.containsKey(17002), isFalse,
          reason: 'newly added Tuesday rolled back');
    });

    test('11. no false new schedule state', () async {
      final c = await enabledMonWedFri();
      service.failCancelIds = {17005};
      await c.setWeekdays(const [2, 3]);
      expect(c.state.enabled, isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled,
          reason: 'previous Mon/Wed/Fri schedule is intact and truthful');
      expect(c.state.isBusy, isFalse);
      // Persisted and pending sets agree exactly.
      final expected = (await stored()).weekdays.map(WorkoutReminderIds.forWeekday).toSet();
      expect(service.scheduledIds, expected);
    });
  });

  group('reconciliation compares the exact owned weekly set', () {
    test('12. all expected IDs present, no extras → no reschedule, no cancels', () async {
      final c = await enabledMonWedFri();
      final calls = service.scheduleCalls;
      await c.onAppResumed();
      await c.refreshStatus();
      expect(service.scheduleCalls, calls);
      expect(service.cancelled, isEmpty);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    });

    test('13. expected ID missing → reschedule', () async {
      final c = await enabledMonWedFri();
      service.scheduled.remove(17003);
      final calls = service.scheduleCalls;
      await c.onAppResumed();
      expect(service.scheduleCalls, calls + 3);
      expect(service.scheduledIds, {17001, 17003, 17005});
    });

    test('14. extra owned weekly ID present → reconciliation cancels it', () async {
      final c = await enabledMonWedFri();
      service.injectPending(17007); // stale Sunday reminder
      final calls = service.scheduleCalls;
      await c.onAppResumed();
      expect(service.cancelled, [17007]);
      expect(service.scheduledIds, {17001, 17003, 17005});
      expect(service.scheduleCalls, calls, reason: 'extras alone need no reschedule');
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    });

    test('15. test notification 17999 / unrelated IDs never count as a mismatch', () async {
      final c = await enabledMonWedFri();
      service.injectPending(WorkoutReminderIds.test);
      service.injectPending(42); // some future, non-reminder notification
      final calls = service.scheduleCalls;
      await c.onAppResumed();
      expect(service.scheduleCalls, calls);
      expect(service.cancelled, isEmpty, reason: 'never cancels unowned IDs');
      expect(service.scheduled.containsKey(WorkoutReminderIds.test), isTrue);
      expect(service.scheduled.containsKey(42), isTrue);
    });

    test('16. after reconciliation exact owned weekly set == expected set', () async {
      final c = await enabledMonWedFri();
      service.injectPending(17002); // extra
      service.injectPending(17006); // extra
      service.scheduled.remove(17001); // missing
      service.injectPending(42); // unrelated, must survive
      await c.onAppResumed();
      final owned = service.scheduledIds.where(WorkoutReminderIds.isWeeklyOwned).toSet();
      expect(owned, {17001, 17003, 17005});
      expect(service.scheduled.containsKey(42), isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    });

    test('16b. extra owned ID that fails to cancel → truthful schedule error', () async {
      final c = await enabledMonWedFri();
      service.injectPending(17007);
      service.failCancelIds = {17007};
      await c.onAppResumed();
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);
      service.failCancelIds = {};
      await c.onAppResumed();
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
      expect(service.scheduledIds, {17001, 17003, 17005});
    });
  });

  group('rollback reports cancellation results', () {
    test('17. newly-added ID cancellation failure makes rollback incomplete', () async {
      final c = await enabledMonWedFri();
      service.failIds = {17006}; // Saturday cannot be scheduled
      service.failCancelIds = {17002}; // and the new Tuesday cannot be cancelled
      expect(await c.setWeekdays(const [1, 2, 3, 5, 6]), isFalse);
      expect((await stored()).weekdays, {1, 3, 5});
      expect(c.state.preferences.weekdays, {1, 3, 5});
      expect(service.scheduled.containsKey(17002), isTrue, reason: 'stray Tuesday');
    });

    test('18. controller exposes truthful schedule-error state', () async {
      final c = await enabledMonWedFri();
      service.failIds = {17006};
      service.failCancelIds = {17002};
      await c.setWeekdays(const [1, 2, 3, 5, 6]);
      expect(c.state.lastScheduleFailed, isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);
      expect(c.state.message, WorkoutReminderMessage.scheduleFailed);
    });

    test('18b. enable rollback with stray ID does not claim a clean OFF state', () async {
      final c = make();
      await c.initialize();
      service.failIds = {17005};
      service.failCancelIds = {17001};
      expect(await c.enable(), isFalse);
      expect(c.state.enabled, isFalse);
      expect((await stored()).enabled, isFalse);
      expect(service.scheduled.containsKey(17001), isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);
      expect(c.state.status, isNot(WorkoutReminderScheduleStatus.off));
    });

    test('19. subsequent successful resume/reconcile repairs extra owned IDs', () async {
      final c = await enabledMonWedFri();
      service.failIds = {17006};
      service.failCancelIds = {17002};
      await c.setWeekdays(const [1, 2, 3, 5, 6]);
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);

      service.failIds = {};
      service.failCancelIds = {};
      await c.onAppResumed();
      expect(service.scheduledIds, {17001, 17003, 17005});
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
      expect((await stored()).weekdays, {1, 3, 5});
    });

    test('19b. disabled state: stray owned weekly ID is cleaned on resume; test ID kept', () async {
      final c = make();
      await c.initialize();
      service.failIds = {17005};
      service.failCancelIds = {17001};
      await c.enable();
      expect(c.state.status, WorkoutReminderScheduleStatus.scheduleError);
      service.injectPending(WorkoutReminderIds.test);

      service.failIds = {};
      service.failCancelIds = {};
      await c.onAppResumed();
      expect(service.scheduledIds.where(WorkoutReminderIds.isWeeklyOwned), isEmpty);
      expect(service.scheduled.containsKey(WorkoutReminderIds.test), isTrue);
      expect(c.state.status, WorkoutReminderScheduleStatus.off);
      expect(service.permissionRequests, 0, reason: 'resume never prompts');
    });
  });

  test('isWeeklyOwned covers exactly 17001–17007', () {
    for (final id in WorkoutReminderIds.allWeekly) {
      expect(WorkoutReminderIds.isWeeklyOwned(id), isTrue);
    }
    expect(WorkoutReminderIds.isWeeklyOwned(WorkoutReminderIds.test), isFalse);
    expect(WorkoutReminderIds.isWeeklyOwned(17000), isFalse);
    expect(WorkoutReminderIds.isWeeklyOwned(17008), isFalse);
    expect(WorkoutReminderIds.isOwned(WorkoutReminderIds.test), isTrue);
  });
}
