/// Stable internal values for workout preferences. These are user
/// preferences, not medical diagnoses.
enum WorkoutPreference {
  noJumping('No jumping'),
  lowImpact('Low impact'),
  noFloorExercises('No floor exercises'),
  standingOnly('Standing only'),
  avoidWristHeavy('Avoid wrist-heavy exercises'),
  avoidDeepKneeBending('Avoid deep knee bending');

  const WorkoutPreference(this.label);

  /// User-facing display label.
  final String label;
}
