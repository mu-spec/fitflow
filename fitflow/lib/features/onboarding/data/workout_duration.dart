/// Stable internal values for the user's typical workout time.
enum WorkoutDuration {
  fiveMinutes(5, '5 minutes'),
  tenMinutes(10, '10 minutes'),
  fifteenMinutes(15, '15 minutes'),
  twentyMinutes(20, '20 minutes'),
  thirtyMinutes(30, '30 minutes'),
  fortyFiveMinutes(45, '45 minutes');

  const WorkoutDuration(this.minutes, this.label);

  /// Typical duration in minutes.
  final int minutes;

  /// User-facing display label.
  final String label;
}
