/// ISO weekday helpers (Monday = 1 … Sunday = 7, matching `DateTime`).
class WorkoutReminderWeekday {
  WorkoutReminderWeekday._();

  static const int monday = DateTime.monday;
  static const int sunday = DateTime.sunday;

  static const List<int> all = [1, 2, 3, 4, 5, 6, 7];

  static bool isValid(int weekday) => weekday >= monday && weekday <= sunday;

  static const List<String> _shortNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> _fullNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const List<String> _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static String shortName(int weekday) => _shortNames[weekday - 1];
  static String fullName(int weekday) => _fullNames[weekday - 1];
  static String letter(int weekday) => _letters[weekday - 1];

  /// Normalises any iterable of ints to a sorted, de-duplicated, valid set.
  static Set<int> normalise(Iterable<int> weekdays) {
    final sorted = weekdays.where(isValid).toSet().toList()..sort();
    return Set<int>.unmodifiable(sorted);
  }
}
