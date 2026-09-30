import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:flutter/foundation.dart';

/// The reminder USER intent that a backup carries: enabled, weekdays, time.
///
/// Deliberately excludes `lastScheduledTimezoneId` (device scheduling
/// metadata), OS permission state and any notification IDs.
@immutable
class BackupReminderPreferences {
  BackupReminderPreferences({
    required this.enabled,
    required Iterable<int> weekdays,
    required this.time,
  }) : weekdays = WorkoutReminderWeekday.normalise(weekdays);

  factory BackupReminderPreferences.fromPreferences(
      WorkoutReminderPreferences p) {
    return BackupReminderPreferences(
      enabled: p.enabled,
      weekdays: p.weekdays,
      time: p.time,
    );
  }

  /// Mirrors [WorkoutReminderPreferences.defaults] (disabled, no days).
  static final BackupReminderPreferences defaults =
      BackupReminderPreferences.fromPreferences(
          WorkoutReminderPreferences.defaults);

  final bool enabled;

  /// Sorted, de-duplicated ISO weekdays (unmodifiable).
  final Set<int> weekdays;
  final WorkoutReminderTime time;

  bool get isValid => time.isValid && (!enabled || weekdays.isNotEmpty);

  /// Runtime preferences with NO timezone id, so M17 reconciliation resolves
  /// the current device timezone after a restore.
  WorkoutReminderPreferences toPreferences() => WorkoutReminderPreferences(
        enabled: enabled,
        weekdays: weekdays,
        time: time,
      );

  @override
  bool operator ==(Object other) =>
      other is BackupReminderPreferences &&
      other.enabled == enabled &&
      other.time == time &&
      setEquals(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(enabled, time, Object.hashAll(weekdays));
}
