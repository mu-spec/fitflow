/// Broad movement categories used to classify exercises.
enum MovementPattern {
  push('Push'),
  pull('Pull'),
  squat('Squat'),
  lunge('Lunge'),
  hinge('Hinge'),
  core('Core'),
  glute('Glute'),
  cardio('Cardio'),
  mobility('Mobility'),
  balance('Balance'),
  warmup('Warmup'),
  cooldown('Cooldown');

  const MovementPattern(this.label);

  /// User-facing display label.
  final String label;
}
