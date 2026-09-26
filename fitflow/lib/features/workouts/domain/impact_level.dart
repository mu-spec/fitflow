/// Impact intensity of an exercise (e.g. for jump-less workouts).
enum ImpactLevel {
  low('Low'),
  moderate('Moderate'),
  high('High');

  const ImpactLevel(this.label);

  /// User-facing display label.
  final String label;
}
