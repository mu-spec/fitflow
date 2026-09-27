/// Section types for a workout (5C-1 domain only).
enum WorkoutSectionType {
  warmup('Warmup'),
  main('Main'),
  cooldown('Cooldown');

  const WorkoutSectionType(this.label);

  final String label;
}
