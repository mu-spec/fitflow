/// How an exercise's default output is measured.
enum ExerciseType {
  reps('Reps'),
  timed('Timed');

  const ExerciseType(this.label);

  /// User-facing display label.
  final String label;
}
