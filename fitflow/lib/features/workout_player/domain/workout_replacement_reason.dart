/// Factual reasons why a replacement exercise is suitable.
enum WorkoutReplacementReason {
  sameMovementFocus,
  sameDifficulty,
  easierVariation,
  fitsSetup,
  matchesPreferences,
  sameProgressionFamily,
  keepsWorkload,
}

extension WorkoutReplacementReasonLabel on WorkoutReplacementReason {
  String get label {
    switch (this) {
      case WorkoutReplacementReason.sameMovementFocus:
        return 'Same movement focus';
      case WorkoutReplacementReason.sameDifficulty:
        return 'Matches your current difficulty';
      case WorkoutReplacementReason.easierVariation:
        return 'Easier variation';
      case WorkoutReplacementReason.fitsSetup:
        return 'Fits your equipment and environment';
      case WorkoutReplacementReason.matchesPreferences:
        return 'Matches your workout preferences';
      case WorkoutReplacementReason.sameProgressionFamily:
        return 'Same exercise progression family';
      case WorkoutReplacementReason.keepsWorkload:
        return 'Keeps the same sets and workload';
    }
  }
}
