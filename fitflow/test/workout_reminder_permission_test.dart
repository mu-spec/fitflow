import 'package:fitflow/features/reminders/application/local_workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers/workout_reminder_test_helpers.dart';

/// Permission abstraction behaviour, without a real Android device.
void main() {
  ensureTimezones();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  WorkoutRemindersController make(FakeWorkoutReminderNotificationService s) {
    final c = WorkoutRemindersController(
        storage: ToggleReminderStorage().storage, service: s, clock: reminderTestNow);
    addTearDown(c.dispose);
    return c;
  }

  test('permission status semantics', () {
    expect(WorkoutReminderPermissionStatus.notRequired.allowsNotifications, isTrue);
    expect(WorkoutReminderPermissionStatus.granted.allowsNotifications, isTrue);
    expect(WorkoutReminderPermissionStatus.denied.allowsNotifications, isFalse);
    expect(WorkoutReminderPermissionStatus.unknown.allowsNotifications, isFalse);
  });

  test('Android < 13 / permission not required → enable schedules without a request', () async {
    final s = FakeWorkoutReminderNotificationService(
        permission: WorkoutReminderPermissionStatus.notRequired);
    final c = make(s);
    await c.initialize();
    expect(await c.enable(), isTrue);
    expect(s.permissionRequests, 0);
    expect(s.scheduled.length, 3);
    expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
  });

  test('Android 13+ granted after request → enabled', () async {
    final s = FakeWorkoutReminderNotificationService(
        permission: WorkoutReminderPermissionStatus.denied,
        requestResult: WorkoutReminderPermissionStatus.granted);
    final c = make(s);
    await c.initialize();
    expect(await c.enable(), isTrue);
    expect(s.permissionRequests, 1);
    expect(c.state.permission, WorkoutReminderPermissionStatus.granted);
  });

  test('Android 13+ denied → not enabled, nothing scheduled', () async {
    final s = FakeWorkoutReminderNotificationService(
        permission: WorkoutReminderPermissionStatus.denied,
        requestResult: WorkoutReminderPermissionStatus.denied);
    final c = make(s);
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(s.scheduled, isEmpty);
    expect(c.state.enabled, isFalse);
  });

  test('permission is never requested on load/refresh (only on enable)', () async {
    final s = FakeWorkoutReminderNotificationService(
        permission: WorkoutReminderPermissionStatus.denied);
    final c = make(s);
    await c.initialize();
    await c.refreshStatus();
    await c.onAppResumed();
    expect(s.permissionRequests, 0);
    expect(s.permissionQueries, greaterThan(0));
  });

  test('blocked after previously enabled → permissionBlocked, selection kept, no request', () async {
    final s = FakeWorkoutReminderNotificationService();
    final c = make(s);
    await c.initialize();
    await c.enable();
    s.permission = WorkoutReminderPermissionStatus.denied;
    await c.onAppResumed();
    expect(c.state.status, WorkoutReminderScheduleStatus.permissionBlocked);
    expect(c.state.preferences.weekdays, {1, 3, 5});
    expect(s.permissionRequests, 0);
    // Re-granted in Android Settings → back to scheduled without rescheduling.
    s.permission = WorkoutReminderPermissionStatus.granted;
    final calls = s.scheduleCalls;
    await c.onAppResumed();
    expect(c.state.status, WorkoutReminderScheduleStatus.scheduled);
    expect(s.scheduleCalls, calls);
  });

  test('open settings call is forwarded', () async {
    final s = FakeWorkoutReminderNotificationService();
    final c = make(s);
    await c.openNotificationSettings();
    expect(s.openSettingsCalls, 1);
  });

  test('unknown permission (backend unavailable) never enables', () async {
    final s = FakeWorkoutReminderNotificationService(
        permission: WorkoutReminderPermissionStatus.unknown, available: false);
    final c = make(s);
    await c.initialize();
    expect(await c.enable(), isFalse);
    expect(c.state.enabled, isFalse);
  });

  group('production service on a non-mobile host', () {
    test('is unavailable, non-throwing, and never claims permission or schedules', () async {
      final service = LocalWorkoutReminderNotificationService();
      expect(await service.initialize(), isFalse);
      expect(await service.permissionStatus(), WorkoutReminderPermissionStatus.unknown);
      expect(await service.requestPermission(), WorkoutReminderPermissionStatus.unknown);
      expect(await service.resolveLocalTimezone(), isNull);
      expect(await service.openNotificationSettings(), isFalse);
      expect(await service.pendingIds(), isNull);
      expect(await service.takeLaunchPayload(), isNull);
      expect(await service.cancel(17001), isFalse);
      expect(
          await service.showNow(id: 17999, title: 't', body: 'b'), isFalse);
      final when = tz.TZDateTime.now(tz.getLocation('Asia/Karachi'))
          .add(const Duration(days: 1));
      expect(
          await service.schedule(WorkoutReminderScheduleRequest(
              id: 17001, weekday: 1, scheduledAt: when, title: 't', body: 'b')),
          isFalse);
    });

    test('channel constants match the spec', () {
      expect(LocalWorkoutReminderNotificationService.channelId,
          'fitflow_workout_reminders_v1');
      expect(LocalWorkoutReminderNotificationService.channelName, 'Workout reminders');
      expect(LocalWorkoutReminderNotificationService.channelDescription,
          'Reminders for your FitFlow workout schedule.');
      expect(workoutReminderPayload, 'workout_reminder');
    });
  });

  test('provider wiring exposes the controller with default providers', () async {
    final service = FakeWorkoutReminderNotificationService();
    final container = ProviderContainerHolder.create(service);
    addTearDown(container.dispose);
    final controller = container.read(workoutRemindersControllerProvider.notifier);
    await controller.initialize();
    expect(container.read(workoutRemindersControllerProvider).isLoaded, isTrue);
  });
}
