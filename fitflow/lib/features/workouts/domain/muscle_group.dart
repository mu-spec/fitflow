/// Major muscle groups targeted by FitFlow exercises.
enum MuscleGroup {
  chest('Chest'),
  shoulders('Shoulders'),
  triceps('Triceps'),
  biceps('Biceps'),
  forearms('Forearms'),
  upperBack('Upper back'),
  lats('Lats'),
  lowerBack('Lower back'),
  abs('Abs'),
  obliques('Obliques'),
  glutes('Glutes'),
  quadriceps('Quadriceps'),
  hamstrings('Hamstrings'),
  calves('Calves'),
  hipFlexors('Hip flexors'),
  fullBody('Full body');

  const MuscleGroup(this.label);

  /// User-facing display label.
  final String label;
}
