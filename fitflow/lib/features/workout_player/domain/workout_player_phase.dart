/// Core player phases for Part 1.
enum WorkoutPlayerPhase {
  /// Initial state before workout starts, shows first warm-up exercise.
  ready,

  /// Active work for current set (reps or timed).
  work,

  /// Rest between sets of same prescription.
  rest,

  /// Transition between different exercises in same section (15 sec).
  transition,

  /// Manual untimed break between sections (Warm-up complete, Main complete).
  sectionBreak,

  /// Workout fully completed.
  completed,
}

extension WorkoutPlayerPhaseX on WorkoutPlayerPhase {
  String get label {
    switch (this) {
      case WorkoutPlayerPhase.ready:
        return 'Ready';
      case WorkoutPlayerPhase.work:
        return 'Work';
      case WorkoutPlayerPhase.rest:
        return 'Rest';
      case WorkoutPlayerPhase.transition:
        return 'Transition';
      case WorkoutPlayerPhase.sectionBreak:
        return 'Section Break';
      case WorkoutPlayerPhase.completed:
        return 'Completed';
    }
  }
}
