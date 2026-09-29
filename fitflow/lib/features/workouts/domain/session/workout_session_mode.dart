/// Temporary session-only workout mode – never persisted.
enum WorkoutSessionMode {
  standard,
  lowEnergy,
  comeback,
}

extension WorkoutSessionModeLabel on WorkoutSessionMode {
  String get label {
    switch (this) {
      case WorkoutSessionMode.standard:
        return 'Standard';
      case WorkoutSessionMode.lowEnergy:
        return 'Low Energy';
      case WorkoutSessionMode.comeback:
        return 'Comeback';
    }
  }

  String get description {
    switch (this) {
      case WorkoutSessionMode.standard:
        return 'Your normal adaptive workout.';
      case WorkoutSessionMode.lowEnergy:
        return 'A shorter, easier workout for today.';
      case WorkoutSessionMode.comeback:
        return 'A gentler return workout after time away.';
    }
  }

  String? get supportingNote {
    switch (this) {
      case WorkoutSessionMode.standard:
        return null;
      case WorkoutSessionMode.lowEnergy:
        return "This doesn't change your movement levels.";
      case WorkoutSessionMode.comeback:
        return "This doesn't change your movement levels.";
    }
  }
}
