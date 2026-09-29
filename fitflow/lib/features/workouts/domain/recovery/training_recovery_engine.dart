import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/recovery/movement_recovery_status.dart';

/// Pure deterministic recovery calculator derived from completed workout history.
/// Uses effective MAIN prescriptions only, explicit now input, no I/O.
class TrainingRecoveryEngine {
  TrainingRecoveryEngine._();

  /// Derive recovery status for each trainable movement pattern.
  /// - history: list of completed workouts (any order, will be sorted internally)
  /// - now: explicit timestamp for deterministic calculations
  /// Returns list ordered: most recently trained first, never-trained after in canonical order.
  static List<MovementRecoveryStatus> calculate({
    required List<CompletedWorkout> history,
    required DateTime now,
  }) {
    // Defensive copy, inputs not mutated
    final historyCopy = List<CompletedWorkout>.from(history);

    // For each trainable pattern, compute stats
    final Map<MovementPattern, DateTime?> lastTrainedMap = {};
    final Map<MovementPattern, int> sessions7Map = {};
    final Map<MovementPattern, int> sets7Map = {};

    for (final pattern in CapabilityProfile.trainablePatterns) {
      lastTrainedMap[pattern] = null;
      sessions7Map[pattern] = 0;
      sets7Map[pattern] = 0;
    }

    // Sort history newest first for lastTrained detection (though we will compute max)
    historyCopy.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // For lastTrained: find most recent completedAt containing pattern in MAIN
    for (final pattern in CapabilityProfile.trainablePatterns) {
      DateTime? mostRecent;
      int sessionsIn7 = 0;
      int setsIn7 = 0;

      for (final workout in historyCopy) {
        final mainExercises = workout.main;
        final containsPattern = mainExercises.any((e) => e.movementPattern == pattern);

        if (containsPattern) {
          // Update most recent
          if (mostRecent == null || workout.completedAt.isAfter(mostRecent)) {
            mostRecent = workout.completedAt;
          }

          // Check if within last 7 days inclusive
          // Define inclusive boundary: completedAt >= sevenDaysAgo && completedAt <= now
          if (!workout.completedAt.isBefore(sevenDaysAgo) && !workout.completedAt.isAfter(now)) {
            sessionsIn7 += 1;
            // Sum sets for this pattern in this workout's Main
            int setsForPatternInWorkout = 0;
            for (final ex in mainExercises) {
              if (ex.movementPattern == pattern) {
                setsForPatternInWorkout += ex.sets;
              }
            }
            setsIn7 += setsForPatternInWorkout;
          }
        }
      }

      lastTrainedMap[pattern] = mostRecent;
      sessions7Map[pattern] = sessionsIn7;
      sets7Map[pattern] = setsIn7;
    }

    final List<MovementRecoveryStatus> trained = [];
    final List<MovementRecoveryStatus> neverTrained = [];

    for (final pattern in CapabilityProfile.trainablePatterns) {
      final last = lastTrainedMap[pattern];
      final sessions7 = sessions7Map[pattern]!;
      final sets7 = sets7Map[pattern]!;

      RecoveryCategory category;
      double? hoursSince;

      if (last == null) {
        category = RecoveryCategory.notTrainedRecently;
        hoursSince = null;
      } else {
        final diff = now.difference(last);
        hoursSince = diff.inMinutes / 60.0;
        if (diff < const Duration(hours: 24)) {
          category = RecoveryCategory.trainedRecently;
        } else if (diff < const Duration(hours: 48)) {
          category = RecoveryCategory.resting;
        } else {
          category = RecoveryCategory.wellRested;
        }
      }

      final status = MovementRecoveryStatus(
        movementPattern: pattern,
        lastTrained: last,
        category: category,
        sessionsLast7Days: sessions7,
        setsLast7Days: sets7,
        hoursSinceLastTrained: hoursSince,
      );

      if (last == null) {
        neverTrained.add(status);
      } else {
        trained.add(status);
      }
    }

    // Order: most recently trained first (by lastTrained descending)
    trained.sort((a, b) {
      final aTime = a.lastTrained!;
      final bTime = b.lastTrained!;
      return bTime.compareTo(aTime);
    });

    // Never-trained after in canonical trainablePatterns order – already in that order because we iterated canonical
    // But ensure canonical order: we iterated in canonical order, and neverTrained preserves that order
    return [...trained, ...neverTrained];
  }
}
