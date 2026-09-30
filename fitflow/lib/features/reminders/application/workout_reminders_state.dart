import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';

/// One-shot outcomes the UI may surface (as calm, factual copy).
enum WorkoutReminderMessage {
  permissionNeeded,
  selectAtLeastOneDay,
  scheduleFailed,
  saveFailed,
  testSent,
  testFailed,
  settingsUnavailable,
}

/// Immutable controller state for local workout reminders.
class WorkoutRemindersState {
  WorkoutRemindersState({
    required this.preferences,
    this.permission = WorkoutReminderPermissionStatus.unknown,
    this.isLoaded = false,
    this.isBusy = false,
    this.lastScheduleFailed = false,
    this.message,
    this.messageId = 0,
  });

  factory WorkoutRemindersState.initial() =>
      WorkoutRemindersState(preferences: WorkoutReminderPreferences.defaults);

  final WorkoutReminderPreferences preferences;

  /// Live OS permission (refreshed, never persisted).
  final WorkoutReminderPermissionStatus permission;
  final bool isLoaded;
  final bool isBusy;

  /// Last scheduling/reconciliation attempt failed while enabled.
  final bool lastScheduleFailed;

  /// Pending one-shot message (cleared by the UI after showing it).
  final WorkoutReminderMessage? message;

  /// Increments with every new message so identical messages re-trigger.
  final int messageId;

  bool get enabled => preferences.enabled;

  /// Truthful user-facing status.
  WorkoutReminderScheduleStatus get status {
    if (!preferences.enabled) {
      // A failed rollback may have left an owned reminder pending; never
      // claim a clean OFF state until reconciliation repairs it.
      return lastScheduleFailed
          ? WorkoutReminderScheduleStatus.scheduleError
          : WorkoutReminderScheduleStatus.off;
    }
    if (permission == WorkoutReminderPermissionStatus.denied) {
      return WorkoutReminderScheduleStatus.permissionBlocked;
    }
    if (lastScheduleFailed ||
        permission == WorkoutReminderPermissionStatus.unknown) {
      return WorkoutReminderScheduleStatus.scheduleError;
    }
    return WorkoutReminderScheduleStatus.scheduled;
  }

  bool get canSendTest => permission.allowsNotifications && !isBusy;

  WorkoutRemindersState copyWith({
    WorkoutReminderPreferences? preferences,
    WorkoutReminderPermissionStatus? permission,
    bool? isLoaded,
    bool? isBusy,
    bool? lastScheduleFailed,
    WorkoutReminderMessage? message,
    bool clearMessage = false,
  }) {
    final newMessage = clearMessage ? null : (message ?? this.message);
    return WorkoutRemindersState(
      preferences: preferences ?? this.preferences,
      permission: permission ?? this.permission,
      isLoaded: isLoaded ?? this.isLoaded,
      isBusy: isBusy ?? this.isBusy,
      lastScheduleFailed: lastScheduleFailed ?? this.lastScheduleFailed,
      message: newMessage,
      messageId: message != null ? messageId + 1 : messageId,
    );
  }
}
