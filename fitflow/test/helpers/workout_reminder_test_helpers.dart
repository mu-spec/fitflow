import 'dart:async';

import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _tzReady = false;

/// Initialises the timezone database once for the test isolate.
void ensureTimezones() {
  if (_tzReady) return;
  tzdata.initializeTimeZones();
  _tzReady = true;
}

/// Configurable in-memory notification backend.
class FakeWorkoutReminderNotificationService
    implements WorkoutReminderNotificationService {
  FakeWorkoutReminderNotificationService({
    this.permission = WorkoutReminderPermissionStatus.granted,
    WorkoutReminderPermissionStatus? requestResult,
    this.timezoneId = 'Asia/Karachi',
    this.available = true,
  }) : requestResult = requestResult ?? permission;

  bool available;
  WorkoutReminderPermissionStatus permission;
  WorkoutReminderPermissionStatus requestResult;
  String? timezoneId;
  bool scheduleSucceeds = true;
  bool cancelSucceeds = true;
  bool showSucceeds = true;
  bool openSettingsSucceeds = true;
  List<int>? pendingOverride;
  String? launchPayload;

  /// Fail scheduling only for these IDs (simulates partial failure).
  Set<int> failIds = {};

  /// Fail cancellation only for these IDs (the reminder stays pending).
  Set<int> failCancelIds = {};

  int initializeCalls = 0;
  int permissionQueries = 0;
  int permissionRequests = 0;
  int openSettingsCalls = 0;
  int timezoneResolutions = 0;
  int scheduleCalls = 0;
  final Map<int, WorkoutReminderScheduleRequest> scheduled = {};
  final List<int> cancelled = [];
  final List<({int id, String title, String body, String? payload})> shown = [];
  final StreamController<String?> taps = StreamController<String?>.broadcast();

  Set<int> get scheduledIds => scheduled.keys.toSet();

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return available;
  }

  @override
  Future<String?> resolveLocalTimezone() async {
    timezoneResolutions++;
    if (timezoneId == null) return null;
    ensureTimezones();
    tz.setLocalLocation(tz.getLocation(timezoneId!));
    return timezoneId;
  }

  @override
  Future<WorkoutReminderPermissionStatus> permissionStatus() async {
    permissionQueries++;
    return permission;
  }

  @override
  Future<WorkoutReminderPermissionStatus> requestPermission() async {
    permissionRequests++;
    permission = requestResult;
    return requestResult;
  }

  @override
  Future<bool> openNotificationSettings() async {
    openSettingsCalls++;
    return openSettingsSucceeds;
  }

  @override
  Future<bool> schedule(WorkoutReminderScheduleRequest request) async {
    scheduleCalls++;
    if (!scheduleSucceeds || failIds.contains(request.id)) return false;
    scheduled[request.id] = request;
    return true;
  }

  @override
  Future<bool> cancel(int id) async {
    cancelled.add(id);
    if (!cancelSucceeds || failCancelIds.contains(id)) return false;
    scheduled.remove(id);
    return true;
  }

  /// Simulates a reminder left pending in the OS (e.g. a stale weekly ID or
  /// an unrelated notification) without going through the controller.
  void injectPending(int id) {
    ensureTimezones();
    scheduled[id] = WorkoutReminderScheduleRequest(
      id: id,
      weekday: WorkoutReminderIds.weekdayForId(id) ?? 1,
      scheduledAt: tz.TZDateTime.now(tz.getLocation('Asia/Karachi')),
      title: 'stale',
      body: 'stale',
    );
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!showSucceeds) return false;
    shown.add((id: id, title: title, body: body, payload: payload));
    return true;
  }

  @override
  Future<List<int>?> pendingIds() async =>
      pendingOverride ?? scheduled.keys.toList();

  @override
  Future<String?> takeLaunchPayload() async {
    final p = launchPayload;
    launchPayload = null;
    return p;
  }

  @override
  Stream<String?> get tapPayloads => taps.stream;
}

/// Storage whose writes can be toggled / made to throw.
class ToggleReminderStorage {
  bool allowWrites = true;
  bool throwOnWrite = false;
  int writes = 0;

  WorkoutReminderStorage get storage => WorkoutReminderStorage(
        writeString: (prefs, key, value) async {
          writes++;
          if (throwOnWrite) throw StateError('disk full');
          if (!allowWrites) return false;
          return prefs.setString(key, value);
        },
      );
}

/// Fixed clock: Wednesday 2026-09-30 12:00 local (Asia/Karachi).
DateTime reminderTestNow() => DateTime.utc(2026, 9, 30, 7); // 12:00 PKT

List<Override> reminderOverrides({
  required FakeWorkoutReminderNotificationService service,
  WorkoutReminderStorage? storage,
  DateTime Function()? clock,
}) =>
    [
      workoutReminderNotificationServiceProvider.overrideWithValue(service),
      if (storage != null) workoutReminderStorageProvider.overrideWithValue(storage),
      workoutReminderClockProvider.overrideWithValue(clock ?? reminderTestNow),
    ];

Future<String?> storedReminderJson() async =>
    (await SharedPreferences.getInstance()).getString(WorkoutReminderStorage.key);

/// Small helper to build a container with the reminder overrides.
class ProviderContainerHolder {
  ProviderContainerHolder._();
  static ProviderContainer create(FakeWorkoutReminderNotificationService service) =>
      ProviderContainer(overrides: reminderOverrides(service: service));
}
