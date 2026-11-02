import '../domain/exercise.dart';
import '../domain/muscle_group.dart';

/// Browsing groups use catalog muscle metadata, never name matching.
/// Primary targets keep stabilizer muscles from crowding unrelated categories.
enum ExerciseBodyFocus {
  all('All', {}),
  abs('Abs', {MuscleGroup.abs, MuscleGroup.obliques}),
  chest('Chest', {MuscleGroup.chest}),
  arms('Arms', {MuscleGroup.biceps, MuscleGroup.triceps, MuscleGroup.forearms}),
  legs('Legs', {
    MuscleGroup.quadriceps,
    MuscleGroup.hamstrings,
    MuscleGroup.calves,
    MuscleGroup.glutes,
    MuscleGroup.hipFlexors
  }),
  shoulders('Shoulders', {MuscleGroup.shoulders}),
  back(
      'Back', {MuscleGroup.upperBack, MuscleGroup.lowerBack, MuscleGroup.lats}),
  fullBody('Full body', {MuscleGroup.fullBody});

  const ExerciseBodyFocus(this.label, this.muscles);
  final String label;
  final Set<MuscleGroup> muscles;

  bool matches(Exercise exercise) =>
      this == all || exercise.primaryMuscles.any(muscles.contains);
}
