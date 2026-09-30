import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';

/// FitFlow-owned, stable local-notification IDs. Only these IDs are ever
/// cancelled by the reminders feature (never `cancelAll`).
class WorkoutReminderIds {
  WorkoutReminderIds._();

  static const int _weekdayBase = 17000;

  /// Monday 17001 … Sunday 17007.
  static int forWeekday(int weekday) {
    assert(WorkoutReminderWeekday.isValid(weekday));
    return _weekdayBase + weekday;
  }

  static int? weekdayForId(int id) {
    final weekday = id - _weekdayBase;
    return WorkoutReminderWeekday.isValid(weekday) ? weekday : null;
  }

  /// Immediate test notification (never scheduled/repeated).
  static const int test = 17999;

  /// All seven weekly reminder IDs owned by this feature.
  static final List<int> allWeekly =
      List<int>.unmodifiable(WorkoutReminderWeekday.all.map(forWeekday));

  static bool isOwned(int id) => weekdayForId(id) != null || id == test;
}
