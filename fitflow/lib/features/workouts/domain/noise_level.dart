/// How much noise an exercise typically produces.
enum NoiseLevel {
  quiet('Quiet'),
  moderate('Moderate'),
  loud('Loud');

  const NoiseLevel(this.label);

  /// User-facing display label.
  final String label;
}
