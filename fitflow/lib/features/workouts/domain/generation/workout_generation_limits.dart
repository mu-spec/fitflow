import 'package:fitflow/features/onboarding/data/workout_duration.dart';

/// Immutable exercise-count policy for V1 generator (5D-3).
///
/// Single source of truth for max exercises per section per duration.
class WorkoutGenerationLimits {
  final int warmupMax;
  final int mainMax;
  final int cooldownMax;

  const WorkoutGenerationLimits({
    required this.warmupMax,
    required this.mainMax,
    required this.cooldownMax,
  });

  // Exact V1 table per spec
  static const WorkoutGenerationLimits fiveMinutes =
      WorkoutGenerationLimits(warmupMax: 1, mainMax: 2, cooldownMax: 1);
  static const WorkoutGenerationLimits tenMinutes =
      WorkoutGenerationLimits(warmupMax: 1, mainMax: 3, cooldownMax: 1);
  static const WorkoutGenerationLimits fifteenMinutes =
      WorkoutGenerationLimits(warmupMax: 1, mainMax: 4, cooldownMax: 1);
  static const WorkoutGenerationLimits twentyMinutes =
      WorkoutGenerationLimits(warmupMax: 2, mainMax: 5, cooldownMax: 2);
  static const WorkoutGenerationLimits thirtyMinutes =
      WorkoutGenerationLimits(warmupMax: 2, mainMax: 6, cooldownMax: 2);
  static const WorkoutGenerationLimits fortyFiveMinutes =
      WorkoutGenerationLimits(warmupMax: 3, mainMax: 8, cooldownMax: 3);

  /// Returns limits for given [WorkoutDuration].
  static WorkoutGenerationLimits fromWorkoutDuration(
      WorkoutDuration duration) {
    switch (duration) {
      case WorkoutDuration.fiveMinutes:
        return fiveMinutes;
      case WorkoutDuration.tenMinutes:
        return tenMinutes;
      case WorkoutDuration.fifteenMinutes:
        return fifteenMinutes;
      case WorkoutDuration.twentyMinutes:
        return twentyMinutes;
      case WorkoutDuration.thirtyMinutes:
        return thirtyMinutes;
      case WorkoutDuration.fortyFiveMinutes:
        return fortyFiveMinutes;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutGenerationLimits &&
          warmupMax == other.warmupMax &&
          mainMax == other.mainMax &&
          cooldownMax == other.cooldownMax;

  @override
  int get hashCode =>
      Object.hash(warmupMax, mainMax, cooldownMax);

  @override
  String toString() =>
      'WorkoutGenerationLimits(warmup:$warmupMax, main:$mainMax, cooldown:$cooldownMax)';
}
