import 'package:fitflow/features/reminders/application/local_workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_state.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_calculator.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/presentation/workout_reminder_copy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

final workoutReminderStorageProvider = Provider<WorkoutReminderStorage>(
  (ref) => const WorkoutReminderStorage(),
);

final workoutReminderNotificationServiceProvider =
    Provider<WorkoutReminderNotificationService>(
  (ref) => LocalWorkoutReminderNotificationService(),
);

/// Wall-clock source (UTC or local `DateTime`); converted to the resolved
/// timezone before scheduling. Overridable in tests.
final workoutReminderClockProvider =
    Provider<DateTime Function()>((ref) => () => DateTime.now());

final workoutRemindersControllerProvider =
    StateNotifierProvider<WorkoutRemindersController, WorkoutRemindersState>(
  (ref) => WorkoutRemindersController(
    storage: ref.watch(workoutReminderStorageProvider),
    service: ref.watch(workoutReminderNotificationServiceProvider),
    clock: ref.watch(workoutReminderClockProvider),
  ),
);

/// Owns preference persistence, permission refresh, weekly scheduling,
/// test notifications and timezone reconciliation. Widgets only call
/// methods here; nothing platform-specific lives in the UI.
class WorkoutRemindersController extends StateNotifier<WorkoutRemindersState> {
  WorkoutRemindersController({
    required WorkoutReminderStorage storage,
    required WorkoutReminderNotificationService service,
    required DateTime Function() clock,
  })  : _storage = storage,
        _service = service,
        _clock = clock,
        super(WorkoutRemindersState.initial());

  final WorkoutReminderStorage _storage;
  final WorkoutReminderNotificationService _service;
  final DateTime Function() _clock;

  Future<void>? _initializing;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Loads preferences and, if reminders are enabled, reconciles permission,
  /// timezone and pending schedule. Safe to call repeatedly; runs once.
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    try {
      final prefs = await _storage.load();
      if (!mounted) return;
      state = state.copyWith(preferences: prefs, isLoaded: true);
      await _service.initialize();
      await _refreshPermission();
      await _reconcile();
    } catch (_) {
      // Notifications are never fatal.
      if (mounted) state = state.copyWith(isLoaded: true);
    }
  }

  /// Settings opened / app resumed: refresh the real OS permission and
  /// reconcile only when the timezone changed or the pending schedule is
  /// inconsistent. Never recreates identical notifications needlessly.
  Future<void> refreshStatus() async {
    await initialize();
    if (!mounted) return;
    await _refreshPermission();
    await _reconcile();
  }

  Future<void> onAppResumed() => refreshStatus();

  void clearMessage() {
    if (state.message != null) state = state.copyWith(clearMessage: true);
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<bool> setWeekdays(Iterable<int> weekdays) =>
      _updatePreferences(state.preferences.copyWith(weekdays: weekdays));

  Future<bool> toggleWeekday(int weekday) {
    final current = state.preferences.weekdays;
    final next = current.contains(weekday)
        ? current.where((d) => d != weekday)
        : [...current, weekday];
    return setWeekdays(next);
  }

  Future<bool> setTime(WorkoutReminderTime time) {
    if (!time.isValid) return Future.value(false);
    return _updatePreferences(state.preferences.copyWith(time: time));
  }

  /// Enable flow (§21): validate → permission → timezone → schedule →
  /// persist. Any failure leaves preferences disabled and reports truthfully.
  Future<bool> enable() async {
    if (state.isBusy) return false;
    final desired = state.preferences.copyWith(enabled: true);
    if (!desired.isSchedulable) {
      _emit(WorkoutReminderMessage.selectAtLeastOneDay);
      return false;
    }
    state = state.copyWith(isBusy: true);
    try {
      await _service.initialize();
      var permission = await _service.permissionStatus();
      if (!permission.allowsNotifications) {
        permission = await _service.requestPermission();
      }
      if (!mounted) return false;
      state = state.copyWith(permission: permission);
      if (!permission.allowsNotifications) {
        _emit(WorkoutReminderMessage.permissionNeeded);
        return false;
      }
      return await _applySchedule(desired);
    } finally {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Disable flow (§22): cancel the seven owned IDs, persist enabled=false.
  /// `enabled=false` is persisted only once every cancellation is known to
  /// have succeeded. If any cancellation or persistence fails, the previous
  /// enabled state stays the source of truth and its schedule is restored
  /// (best effort) so UI, storage and OS schedule never disagree.
  Future<bool> disable() async {
    if (state.isBusy) return false;
    final previous = state.preferences;
    state = state.copyWith(isBusy: true);
    try {
      var allCancelled = true;
      for (final id in WorkoutReminderIds.allWeekly) {
        if (!await _service.cancel(id)) allCancelled = false;
      }
      if (!allCancelled) {
        // Some reminders may still be pending: no fake OFF state.
        final restored = await _restoreSchedule(previous);
        if (!mounted) return false;
        state = state.copyWith(lastScheduleFailed: !restored);
        _emit(WorkoutReminderMessage.saveFailed);
        return false;
      }
      final next = previous.copyWith(enabled: false, clearTimezoneId: true);
      final saved = await _storage.save(next);
      if (!mounted) return false;
      if (!saved) {
        final restored = await _restoreSchedule(previous);
        if (!mounted) return false;
        state = state.copyWith(lastScheduleFailed: !restored);
        _emit(WorkoutReminderMessage.saveFailed);
        return false;
      }
      state = state.copyWith(preferences: next, lastScheduleFailed: false);
      return true;
    } finally {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  Future<bool> setEnabled(bool value) => value ? enable() : disable();

  /// Immediate one-off test notification (ID 17999). Never touches
  /// preferences or the weekly schedule.
  Future<bool> sendTestNotification() async {
    await _service.initialize();
    final permission = await _service.permissionStatus();
    if (!mounted) return false;
    state = state.copyWith(permission: permission);
    if (!permission.allowsNotifications) {
      _emit(WorkoutReminderMessage.permissionNeeded);
      return false;
    }
    final ok = await _service.showNow(
      id: WorkoutReminderIds.test,
      title: WorkoutReminderCopy.testTitle,
      body: WorkoutReminderCopy.testBody,
      payload: workoutReminderPayload,
    );
    if (!mounted) return false;
    _emit(ok ? WorkoutReminderMessage.testSent : WorkoutReminderMessage.testFailed);
    return ok;
  }

  Future<bool> openNotificationSettings() async {
    final ok = await _service.openNotificationSettings();
    if (!ok && mounted) _emit(WorkoutReminderMessage.settingsUnavailable);
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _emit(WorkoutReminderMessage message) {
    if (mounted) state = state.copyWith(message: message);
  }

  Future<void> _refreshPermission() async {
    final permission = await _service.permissionStatus();
    if (mounted) state = state.copyWith(permission: permission);
  }

  /// Days/time edits. Disabled → persist only. Enabled → atomic reschedule.
  Future<bool> _updatePreferences(WorkoutReminderPreferences next) async {
    if (state.isBusy) return false;
    if (next.sameSchedule(state.preferences)) return true;
    if (!next.enabled) {
      final saved = await _storage.save(next);
      if (!mounted) return false;
      if (!saved) {
        _emit(WorkoutReminderMessage.saveFailed);
        return false;
      }
      state = state.copyWith(preferences: next);
      return true;
    }
    if (!next.isSchedulable) {
      _emit(WorkoutReminderMessage.selectAtLeastOneDay);
      return false;
    }
    state = state.copyWith(isBusy: true);
    try {
      return await _applySchedule(next);
    } finally {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  /// Schedules [desired] (enabled) in the current device timezone, cancels
  /// obsolete owned IDs, then persists. On failure the previous persisted
  /// preferences and previous schedule are restored where possible.
  Future<bool> _applySchedule(WorkoutReminderPreferences desired) async {
    final previous = state.preferences;

    final tzId = await _service.resolveLocalTimezone();
    tz.Location? location;
    if (tzId != null) {
      try {
        location = tz.getLocation(tzId);
      } catch (_) {
        location = null;
      }
    }
    if (location == null) {
      // Never schedule against UTC by accident. Nothing was touched, so a
      // previously valid schedule still stands.
      _emit(WorkoutReminderMessage.scheduleFailed);
      return false;
    }

    final now = tz.TZDateTime.from(_clock(), location);
    final plan = WorkoutReminderScheduleCalculator.plan(
        preferences: desired, now: now);
    final previousIds = previous.enabled
        ? previous.weekdays.map(WorkoutReminderIds.forWeekday).toSet()
        : <int>{};
    final scheduledNow = <int>{};
    var ok = true;
    for (final occurrence in plan) {
      final success = await _service.schedule(WorkoutReminderScheduleRequest(
        id: occurrence.notificationId,
        weekday: occurrence.weekday,
        scheduledAt: occurrence.scheduledAt,
        title: WorkoutReminderCopy.notificationTitle,
        body: WorkoutReminderCopy.notificationBody,
      ));
      if (!success) {
        ok = false;
        break;
      }
      scheduledNow.add(occurrence.notificationId);
    }
    if (!ok) {
      await _rollbackAndReport(
          previous, previousIds, scheduledNow, WorkoutReminderMessage.scheduleFailed);
      return false;
    }

    // Obsolete owned IDs (days no longer selected) must be gone before the
    // new preference becomes the persisted truth.
    var obsoleteCancelled = true;
    for (final id in previousIds.difference(scheduledNow)) {
      if (!await _service.cancel(id)) obsoleteCancelled = false;
    }
    if (!obsoleteCancelled) {
      await _rollbackAndReport(
          previous, previousIds, scheduledNow, WorkoutReminderMessage.scheduleFailed);
      return false;
    }

    final toPersist = desired.copyWith(lastScheduledTimezoneId: tzId);
    final saved = await _storage.save(toPersist);
    if (!saved) {
      await _rollbackAndReport(
          previous, previousIds, scheduledNow, WorkoutReminderMessage.saveFailed);
      return false;
    }
    if (mounted) {
      state = state.copyWith(preferences: toPersist, lastScheduleFailed: false);
    }
    return true;
  }

  /// Rolls back to [previous] and exposes the outcome truthfully: the
  /// schedule-error flag is set whenever the previous schedule could not be
  /// fully restored (including a stray newly-created reminder that failed to
  /// cancel), regardless of whether [previous] was enabled.
  Future<void> _rollbackAndReport(
    WorkoutReminderPreferences previous,
    Set<int> previousIds,
    Set<int> scheduledNow,
    WorkoutReminderMessage message,
  ) async {
    final restored = await _rollback(previous, previousIds, scheduledNow);
    if (!mounted) return;
    state = state.copyWith(lastScheduleFailed: !restored);
    _emit(message);
  }

  /// Best-effort restoration of the previous state: drop newly created IDs
  /// that the previous schedule did not own, then re-create the previous
  /// schedule if it was enabled. Returns true only when every such
  /// cancellation succeeded AND the previous schedule is fully in place.
  Future<bool> _rollback(
    WorkoutReminderPreferences previous,
    Set<int> previousIds,
    Set<int> scheduledNow,
  ) async {
    var newCancelled = true;
    for (final id in scheduledNow.difference(previousIds)) {
      if (!await _service.cancel(id)) newCancelled = false;
    }
    final restored = await _restoreSchedule(previous);
    return newCancelled && restored;
  }

  Future<bool> _restoreSchedule(WorkoutReminderPreferences previous) async {
    if (!previous.enabled || !previous.isSchedulable) return true;
    final tzId = previous.lastScheduledTimezoneId ??
        await _service.resolveLocalTimezone();
    if (tzId == null) return false;
    tz.Location location;
    try {
      location = tz.getLocation(tzId);
    } catch (_) {
      return false;
    }
    final now = tz.TZDateTime.from(_clock(), location);
    var allOk = true;
    for (final occurrence in WorkoutReminderScheduleCalculator.plan(
        preferences: previous, now: now)) {
      final ok = await _service.schedule(WorkoutReminderScheduleRequest(
        id: occurrence.notificationId,
        weekday: occurrence.weekday,
        scheduledAt: occurrence.scheduledAt,
        title: WorkoutReminderCopy.notificationTitle,
        body: WorkoutReminderCopy.notificationBody,
      ));
      allOk = allOk && ok;
    }
    return allOk;
  }

  /// Pending-schedule / timezone reconciliation (§36).
  ///
  /// Enabled: compares the exact set of pending FitFlow weekly IDs
  /// (17001–17007, filtered through [WorkoutReminderIds.isWeeklyOwned]) with
  /// the IDs the selected weekdays require. Extra owned IDs are cancelled,
  /// and a reschedule happens only when the timezone changed or an expected
  /// ID is missing. Unrelated IDs (including the 17999 test notification) are
  /// ignored and never cancelled.
  ///
  /// Disabled: any stray owned weekly ID (e.g. after an incomplete rollback)
  /// is cancelled so the OS matches the persisted OFF state.
  Future<void> _reconcile() async {
    final prefs = state.preferences;
    if (!prefs.enabled) {
      await _reconcileDisabled();
      return;
    }
    if (!prefs.isSchedulable) return;
    if (state.permission == WorkoutReminderPermissionStatus.denied) {
      // Blocked by Android: keep the user's schedule; status shows blocked.
      return;
    }
    final tzId = await _service.resolveLocalTimezone();
    if (!mounted) return;
    if (tzId == null) {
      state = state.copyWith(lastScheduleFailed: true);
      return;
    }
    final expected = prefs.weekdays.map(WorkoutReminderIds.forWeekday).toSet();
    final pending = await _service.pendingIds();
    if (!mounted) return;
    final pendingOwned =
        pending?.where(WorkoutReminderIds.isWeeklyOwned).toSet();

    var extrasCancelled = true;
    var missing = false;
    if (pendingOwned != null) {
      for (final id in pendingOwned.difference(expected)) {
        if (!await _service.cancel(id)) extrasCancelled = false;
      }
      missing = !expected.every(pendingOwned.contains);
    }
    if (!mounted) return;

    final needsReschedule = tzId != prefs.lastScheduledTimezoneId || missing;
    if (needsReschedule) {
      final ok = await _applySchedule(prefs);
      if (ok && !extrasCancelled && mounted) {
        state = state.copyWith(lastScheduleFailed: true);
      }
      return;
    }
    if (state.lastScheduleFailed != !extrasCancelled) {
      state = state.copyWith(lastScheduleFailed: !extrasCancelled);
    }
  }

  Future<void> _reconcileDisabled() async {
    final pending = await _service.pendingIds();
    if (!mounted || pending == null) return;
    final stray = pending.where(WorkoutReminderIds.isWeeklyOwned).toSet();
    var allCancelled = true;
    for (final id in stray) {
      if (!await _service.cancel(id)) allCancelled = false;
    }
    if (!mounted) return;
    if (state.lastScheduleFailed != !allCancelled) {
      state = state.copyWith(lastScheduleFailed: !allCancelled);
    }
  }
}
