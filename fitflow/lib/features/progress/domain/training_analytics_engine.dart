import 'dart:convert';

import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Pure deterministic analytics engine derived entirely from real completed history.
/// No I/O, no Riverpod, no DateTime.now() inside pure calculations.
/// Future-dated workouts ignored, duplicate IDs counted once.
/// Duplicate rule:
/// 1. later completedAt wins
/// 2. equal completedAt → lexicographically greater canonical JSON snapshot wins
/// This guarantees order-independence: reversing input list yields identical analytics.
class TrainingAnalyticsEngine {
  const TrainingAnalyticsEngine._();

  static Duration _plannedDurationFor(CompletedWorkout w) {
    if (w.estimatedDuration != null) return w.estimatedDuration!;
    if (w.targetDuration != null) return w.targetDuration!;
    return Duration.zero;
  }

  static int _mainSetsFor(CompletedWorkout w) {
    int sum = 0;
    for (final ex in w.main) {
      sum += ex.sets;
    }
    return sum;
  }

  static bool _isInCurrentPeriod(DateTime completedAt, DateTime now) {
    final start = now.subtract(const Duration(days: 7));
    // [now-7d, now] inclusive
    return !completedAt.isBefore(start) && !completedAt.isAfter(now);
  }

  static bool _isInPreviousPeriod(DateTime completedAt, DateTime now) {
    final startPrev = now.subtract(const Duration(days: 14));
    final endPrev = now.subtract(const Duration(days: 7));
    // [now-14d, now-7d)
    return !completedAt.isBefore(startPrev) && completedAt.isBefore(endPrev);
  }

  static bool _isInLast28Days(DateTime completedAt, DateTime now) {
    final start = now.subtract(const Duration(days: 28));
    // [now-28d, now] inclusive start
    return !completedAt.isBefore(start) && !completedAt.isAfter(now);
  }

  static bool _isInBucket(DateTime completedAt, DateTime bucketStart, DateTime bucketEnd, bool isLast) {
    if (isLast) {
      return !completedAt.isBefore(bucketStart) && !completedAt.isAfter(bucketEnd);
    } else {
      return !completedAt.isBefore(bucketStart) && completedAt.isBefore(bucketEnd);
    }
  }

  static String _canonicalFingerprint(CompletedWorkout w) {
    try {
      // toJson emits stable field structure and ordered exercise lists
      return jsonEncode(w.toJson());
    } catch (_) {
      // Fallback to id + completedAt + counts if json fails (should not happen)
      return '${w.id}|${w.completedAt.toIso8601String()}|${w.totalSetCount}|${w.totalExerciseCount}';
    }
  }

  static TrainingAnalytics calculate({
    required List<CompletedWorkout> history,
    required DateTime now,
  }) {
    // Defensive copy, do not mutate input
    final historyCopy = List<CompletedWorkout>.from(history);

    // Deduplicate by ID, retain most recent completedAt,
    // equal completedAt → lexicographically greater canonical snapshot wins (order-independent)
    final Map<String, CompletedWorkout> dedupedMap = {};
    final Map<String, String> fingerprintMap = {};

    for (final workout in historyCopy) {
      // Future check: ignore if after now
      if (workout.completedAt.isAfter(now)) continue;

      final existing = dedupedMap[workout.id];
      if (existing == null) {
        dedupedMap[workout.id] = workout;
        fingerprintMap[workout.id] = _canonicalFingerprint(workout);
      } else {
        if (workout.completedAt.isAfter(existing.completedAt)) {
          dedupedMap[workout.id] = workout;
          fingerprintMap[workout.id] = _canonicalFingerprint(workout);
        } else if (workout.completedAt.isAtSameMomentAs(existing.completedAt)) {
          final newFp = _canonicalFingerprint(workout);
          final oldFp = fingerprintMap[workout.id]!;
          // Lexicographically greater wins – deterministic, independent of input position
          if (newFp.compareTo(oldFp) > 0) {
            dedupedMap[workout.id] = workout;
            fingerprintMap[workout.id] = newFp;
          }
        }
        // else older timestamp → keep existing
      }
    }

    final validWorkouts = dedupedMap.values.toList();
    // Sort newest first for recent workouts and for deterministic output
    // For equal completedAt, use fingerprint as secondary sort to ensure deterministic ordering
    validWorkouts.sort((a, b) {
      final timeCmp = b.completedAt.compareTo(a.completedAt);
      if (timeCmp != 0) return timeCmp;
      return _canonicalFingerprint(b).compareTo(_canonicalFingerprint(a));
    });

    final savedCount = validWorkouts.length;

    if (savedCount == 0) {
      return TrainingAnalytics.empty(now);
    }

    // Current 7 days
    int currentWorkouts = 0;
    int currentSets = 0;
    Duration currentPlanned = Duration.zero;

    // Previous 7 days
    int prevWorkouts = 0;
    int prevSets = 0;
    Duration prevPlanned = Duration.zero;

    // Last 28 days
    int last28Workouts = 0;
    int last28Sets = 0;
    Duration last28Planned = Duration.zero;

    // For movement analytics we need list of workouts in last 28 days
    final List<CompletedWorkout> last28List = [];

    for (final w in validWorkouts) {
      final planned = _plannedDurationFor(w);
      final mainSets = _mainSetsFor(w);

      if (_isInCurrentPeriod(w.completedAt, now)) {
        currentWorkouts += 1;
        currentSets += mainSets;
        currentPlanned += planned;
      }
      if (_isInPreviousPeriod(w.completedAt, now)) {
        prevWorkouts += 1;
        prevSets += mainSets;
        prevPlanned += planned;
      }
      if (_isInLast28Days(w.completedAt, now)) {
        last28Workouts += 1;
        last28Sets += mainSets;
        last28Planned += planned;
        last28List.add(w);
      }
    }

    // Eight 7-day trend buckets
    final List<TrainingTrendBucket> buckets = [];
    for (int i = 0; i < 8; i++) {
      final start = now.subtract(Duration(days: (8 - i) * 7));
      final end = now.subtract(Duration(days: (7 - i) * 7));
      final isLast = i == 7;

      int bWorkouts = 0;
      int bSets = 0;
      Duration bPlanned = Duration.zero;

      for (final w in validWorkouts) {
        if (_isInBucket(w.completedAt, start, end, isLast)) {
          bWorkouts += 1;
          bSets += _mainSetsFor(w);
          bPlanned += _plannedDurationFor(w);
        }
      }

      buckets.add(TrainingTrendBucket(
        index: i,
        start: start,
        end: end,
        workoutCount: bWorkouts,
        mainSetCount: bSets,
        plannedDuration: bPlanned,
      ));
    }

    // Active weeks: number of latest four 7-day buckets containing at least one workout
    int activeWeeks = 0;
    for (int i = 4; i < 8; i++) {
      if (buckets[i].workoutCount > 0) activeWeeks += 1;
    }

    // Movement analytics for last 28 days
    final Map<MovementPattern, int> movementSessions = {};
    final Map<MovementPattern, int> movementSets = {};
    final Map<MovementPattern, DateTime?> movementLast = {};

    for (final pattern in CapabilityProfile.trainablePatterns) {
      movementSessions[pattern] = 0;
      movementSets[pattern] = 0;
      movementLast[pattern] = null;
    }

    for (final workout in last28List) {
      final Set<MovementPattern> patternsInWorkout = {};
      final Map<MovementPattern, int> setsInWorkout = {};

      for (final ex in workout.main) {
        final mp = ex.movementPattern;
        if (mp == null) continue;
        if (!CapabilityProfile.trainablePatterns.contains(mp)) continue;

        setsInWorkout[mp] = (setsInWorkout[mp] ?? 0) + ex.sets;
        patternsInWorkout.add(mp);
      }

      for (final mp in patternsInWorkout) {
        movementSessions[mp] = (movementSessions[mp] ?? 0) + 1;
        final currentLast = movementLast[mp];
        if (currentLast == null || workout.completedAt.isAfter(currentLast)) {
          movementLast[mp] = workout.completedAt;
        }
      }
      for (final entry in setsInWorkout.entries) {
        movementSets[entry.key] = (movementSets[entry.key] ?? 0) + entry.value;
      }
    }

    final List<MovementTrainingAnalytics> movementAnalytics = [];
    for (final pattern in CapabilityProfile.trainablePatterns) {
      movementAnalytics.add(MovementTrainingAnalytics(
        movementPattern: pattern,
        sessions: movementSessions[pattern] ?? 0,
        mainSets: movementSets[pattern] ?? 0,
        lastTrained: movementLast[pattern],
      ));
    }

    movementAnalytics.sort((a, b) {
      if (b.mainSets != a.mainSets) return b.mainSets.compareTo(a.mainSets);
      if (b.sessions != a.sessions) return b.sessions.compareTo(a.sessions);
      final aIdx = CapabilityProfile.trainablePatterns.indexOf(a.movementPattern);
      final bIdx = CapabilityProfile.trainablePatterns.indexOf(b.movementPattern);
      return aIdx.compareTo(bIdx);
    });

    return TrainingAnalytics(
      now: now,
      savedWorkoutsCount: savedCount,
      validWorkouts: validWorkouts,
      currentPeriod: TrainingPeriodSummary(
        workoutCount: currentWorkouts,
        mainSets: currentSets,
        plannedDuration: currentPlanned,
      ),
      previousPeriod: TrainingPeriodSummary(
        workoutCount: prevWorkouts,
        mainSets: prevSets,
        plannedDuration: prevPlanned,
      ),
      last28Days: TrainingPeriodSummary(
        workoutCount: last28Workouts,
        mainSets: last28Sets,
        plannedDuration: last28Planned,
      ),
      activeWeeksCount: activeWeeks,
      trendBuckets: buckets,
      movementAnalytics: movementAnalytics,
    );
  }
}
