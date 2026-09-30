import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';

/// Why an enabled schedule is not valid.
enum WorkoutReminderValidationIssue { noWeekdays, invalidTime }

/// Immutable user preferences for local workout reminders.
///
/// [enabled] is the user's intent stored in FitFlow. Whether Android actually
/// allows notifications is queried from the OS and never persisted here.
class WorkoutReminderPreferences {
  WorkoutReminderPreferences({
    required this.enabled,
    required Iterable<int> weekdays,
    required this.time,
    this.lastScheduledTimezoneId,
  }) : weekdays = WorkoutReminderWeekday.normalise(weekdays);

  /// Reminders are OFF by default; the suggested days/time are editable
  /// defaults only and schedule nothing until the user enables reminders.
  static final WorkoutReminderPreferences defaults = WorkoutReminderPreferences(
    enabled: false,
    weekdays: const {DateTime.monday, DateTime.wednesday, DateTime.friday},
    time: WorkoutReminderTime.suggested,
  );

  final bool enabled;

  /// Sorted, de-duplicated, unmodifiable ISO weekdays.
  final Set<int> weekdays;
  final WorkoutReminderTime time;

  /// IANA timezone ID used for the last successful schedule (null if never).
  final String? lastScheduledTimezoneId;

  WorkoutReminderValidationIssue? get validationIssue {
    if (weekdays.isEmpty) return WorkoutReminderValidationIssue.noWeekdays;
    if (!time.isValid) return WorkoutReminderValidationIssue.invalidTime;
    return null;
  }

  /// True when the selection could be scheduled (≥1 weekday, valid time).
  bool get isSchedulable => validationIssue == null;

  /// An enabled state with zero weekdays or an invalid time is never valid.
  bool get isValid => !enabled || isSchedulable;

  bool get isEveryDay => weekdays.length == 7;

  WorkoutReminderPreferences copyWith({
    bool? enabled,
    Iterable<int>? weekdays,
    WorkoutReminderTime? time,
    String? lastScheduledTimezoneId,
    bool clearTimezoneId = false,
  }) {
    return WorkoutReminderPreferences(
      enabled: enabled ?? this.enabled,
      weekdays: weekdays ?? this.weekdays,
      time: time ?? this.time,
      lastScheduledTimezoneId: clearTimezoneId
          ? null
          : (lastScheduledTimezoneId ?? this.lastScheduledTimezoneId),
    );
  }

  /// Same schedule (days + time), ignoring enabled flag and timezone.
  bool sameSchedule(WorkoutReminderPreferences other) =>
      other.time == time &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  bool operator ==(Object other) =>
      other is WorkoutReminderPreferences &&
      other.enabled == enabled &&
      other.time == time &&
      other.lastScheduledTimezoneId == lastScheduledTimezoneId &&
      sameSchedule(other);

  @override
  int get hashCode => Object.hash(
      enabled, time, lastScheduledTimezoneId, Object.hashAll(weekdays));

  @override
  String toString() =>
      'WorkoutReminderPreferences(enabled: $enabled, weekdays: $weekdays, '
      'time: $time, tz: $lastScheduledTimezoneId)';
}
