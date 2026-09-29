import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

@immutable
class TrainingPeriodSummary {
  const TrainingPeriodSummary({
    required this.workoutCount,
    required this.mainSets,
    required this.plannedDuration,
  });

  final int workoutCount;
  final int mainSets;
  final Duration plannedDuration;

  static const zero = TrainingPeriodSummary(
    workoutCount: 0,
    mainSets: 0,
    plannedDuration: Duration.zero,
  );

  @override
  bool operator ==(Object other) =>
      other is TrainingPeriodSummary &&
      workoutCount == other.workoutCount &&
      mainSets == other.mainSets &&
      plannedDuration == other.plannedDuration;

  @override
  int get hashCode => Object.hash(workoutCount, mainSets, plannedDuration);

  @override
  String toString() =>
      'TrainingPeriodSummary(workouts:$workoutCount sets:$mainSets planned:${plannedDuration.inSeconds}s)';
}

@immutable
class TrainingTrendBucket {
  const TrainingTrendBucket({
    required this.index,
    required this.start,
    required this.end,
    required this.workoutCount,
    required this.mainSetCount,
    required this.plannedDuration,
  });

  /// 0 = oldest, 7 = current
  final int index;
  final DateTime start;
  final DateTime end;
  final int workoutCount;
  final int mainSetCount;
  final Duration plannedDuration;

  bool get isCurrent => index == 7;

  @override
  bool operator ==(Object other) =>
      other is TrainingTrendBucket &&
      index == other.index &&
      start == other.start &&
      end == other.end &&
      workoutCount == other.workoutCount &&
      mainSetCount == other.mainSetCount &&
      plannedDuration == other.plannedDuration;

  @override
  int get hashCode => Object.hash(index, start, end, workoutCount, mainSetCount, plannedDuration);
}

@immutable
class MovementTrainingAnalytics {
  const MovementTrainingAnalytics({
    required this.movementPattern,
    required this.sessions,
    required this.mainSets,
    this.lastTrained,
  });

  final MovementPattern movementPattern;
  final int sessions;
  final int mainSets;
  final DateTime? lastTrained;

  @override
  bool operator ==(Object other) =>
      other is MovementTrainingAnalytics &&
      movementPattern == other.movementPattern &&
      sessions == other.sessions &&
      mainSets == other.mainSets &&
      lastTrained == other.lastTrained;

  @override
  int get hashCode => Object.hash(movementPattern, sessions, mainSets, lastTrained);
}

@immutable
class TrainingAnalytics {
  const TrainingAnalytics({
    required this.now,
    required this.savedWorkoutsCount,
    required this.validWorkouts,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.last28Days,
    required this.activeWeeksCount,
    required this.trendBuckets,
    required this.movementAnalytics,
  });

  final DateTime now;
  final int savedWorkoutsCount;
  /// Valid workouts at/before now, deduplicated, sorted newest first
  final List<CompletedWorkout> validWorkouts;

  final TrainingPeriodSummary currentPeriod;
  final TrainingPeriodSummary previousPeriod;
  final TrainingPeriodSummary last28Days;
  final int activeWeeksCount;
  final List<TrainingTrendBucket> trendBuckets;
  final List<MovementTrainingAnalytics> movementAnalytics;

  int get workoutDelta => currentPeriod.workoutCount - previousPeriod.workoutCount;
  int get mainSetsDelta => currentPeriod.mainSets - previousPeriod.mainSets;
  Duration get plannedDurationDelta => currentPeriod.plannedDuration - previousPeriod.plannedDuration;

  bool get isEmpty => savedWorkoutsCount == 0;

  static TrainingAnalytics empty(DateTime now) {
    // For empty history, still provide 10 trainable patterns with zero data for UI consistency
    final movementAnalytics = CapabilityProfile.trainablePatterns
        .map((p) => MovementTrainingAnalytics(
              movementPattern: p,
              sessions: 0,
              mainSets: 0,
              lastTrained: null,
            ))
        .toList();
    return TrainingAnalytics(
      now: now,
      savedWorkoutsCount: 0,
      validWorkouts: const [],
      currentPeriod: TrainingPeriodSummary.zero,
      previousPeriod: TrainingPeriodSummary.zero,
      last28Days: TrainingPeriodSummary.zero,
      activeWeeksCount: 0,
      trendBuckets: List.generate(
        8,
        (i) => TrainingTrendBucket(
          index: i,
          start: now.subtract(Duration(days: (8 - i) * 7)),
          end: now.subtract(Duration(days: (7 - i) * 7)),
          workoutCount: 0,
          mainSetCount: 0,
          plannedDuration: Duration.zero,
        ),
      ),
      movementAnalytics: movementAnalytics,
    );
  }
}

@immutable
class CompletedWorkoutSummary {
  const CompletedWorkoutSummary({
    required this.id,
    required this.completedAt,
    required this.plannedDuration,
    required this.mainSets,
  });

  final String id;
  final DateTime completedAt;
  final Duration plannedDuration;
  final int mainSets;
}
