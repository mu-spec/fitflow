/// A local wall-clock reminder time (hour 0–23, minute 0–59).
///
/// Stored as numbers only; formatting for display is done by the UI using
/// the device locale (never by this class).
class WorkoutReminderTime {
  const WorkoutReminderTime({required this.hour, required this.minute});

  /// Editable default suggested by the UI: 7:00 PM local time.
  static const WorkoutReminderTime suggested =
      WorkoutReminderTime(hour: 19, minute: 0);

  final int hour;
  final int minute;

  bool get isValid => hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

  /// Minutes since local midnight; handy for "has this time passed" checks.
  int get minutesOfDay => hour * 60 + minute;

  WorkoutReminderTime copyWith({int? hour, int? minute}) =>
      WorkoutReminderTime(hour: hour ?? this.hour, minute: minute ?? this.minute);

  @override
  bool operator ==(Object other) =>
      other is WorkoutReminderTime &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'WorkoutReminderTime($hour:$minute)';
}
