/// The body position an exercise is performed in.
enum ExercisePosition {
  standing('Standing'),
  floor('Floor'),
  seated('Seated'),
  kneeling('Kneeling'),
  hanging('Hanging');

  const ExercisePosition(this.label);

  /// User-facing display label.
  final String label;
}
