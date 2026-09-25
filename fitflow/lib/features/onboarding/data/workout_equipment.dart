/// Stable internal values for equipment the user has available.
enum WorkoutEquipment {
  none('None'),
  exerciseMat('Exercise mat'),
  chair('Chair'),
  resistanceBands('Resistance bands'),
  dumbbells('Dumbbells'),
  kettlebell('Kettlebell'),
  pullUpBar('Pull-up bar'),
  bench('Bench');

  const WorkoutEquipment(this.label);

  /// User-facing display label.
  final String label;
}
