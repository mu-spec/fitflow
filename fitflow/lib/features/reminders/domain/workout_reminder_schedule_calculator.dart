import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:timezone/timezone.dart' as tz;

/// One planned weekly reminder occurrence.
class WorkoutReminderOccurrence {
  const WorkoutReminderOccurrence({
    required this.weekday,
    required this.notificationId,
    required this.scheduledAt,
  });

  final int weekday;
  final int notificationId;

  /// First fire time in the device's local IANA timezone; repeats weekly.
  final tz.TZDateTime scheduledAt;

  @override
  String toString() =>
      'WorkoutReminderOccurrence($weekday #$notificationId @ $scheduledAt)';
}

/// Pure, timezone-aware weekly schedule calculations.
class WorkoutReminderScheduleCalculator {
  WorkoutReminderScheduleCalculator._();

  /// Next occurrence of [weekday] at [time] strictly after [now] in
  /// [now.location]. If the weekday/time is now or already passed, the
  /// following week's occurrence is returned. Never returns the past.
  static tz.TZDateTime nextOccurrence({
    required tz.TZDateTime now,
    required int weekday,
    required WorkoutReminderTime time,
  }) {
    assert(WorkoutReminderWeekday.isValid(weekday));
    assert(time.isValid);
    final location = now.location;
    var daysAhead = (weekday - now.weekday) % 7;
    if (daysAhead < 0) daysAhead += 7;

    tz.TZDateTime candidate = _atLocalTime(
      location,
      now.year,
      now.month,
      now.day + daysAhead,
      time,
    );
    // Same-day but time already reached (or DST shifted it behind now).
    if (!candidate.isAfter(now)) {
      candidate = _atLocalTime(
        location,
        candidate.year,
        candidate.month,
        candidate.day + 7,
        time,
      );
    }
    return candidate;
  }

  /// Builds the wall-clock time for the given local date (DST aware because
  /// `TZDateTime` resolves the offset for that specific local instant).
  static tz.TZDateTime _atLocalTime(
    tz.Location location,
    int year,
    int month,
    int day,
    WorkoutReminderTime time,
  ) =>
      tz.TZDateTime(location, year, month, day, time.hour, time.minute);

  /// All planned occurrences for [preferences] (sorted by weekday), or an
  /// empty list when the preferences are not schedulable.
  static List<WorkoutReminderOccurrence> plan({
    required WorkoutReminderPreferences preferences,
    required tz.TZDateTime now,
  }) {
    if (!preferences.isSchedulable) return const [];
    final weekdays = preferences.weekdays.toList()..sort();
    return List<WorkoutReminderOccurrence>.unmodifiable(
      weekdays.map(
        (weekday) => WorkoutReminderOccurrence(
          weekday: weekday,
          notificationId: WorkoutReminderIds.forWeekday(weekday),
          scheduledAt:
              nextOccurrence(now: now, weekday: weekday, time: preferences.time),
        ),
      ),
    );
  }
}
