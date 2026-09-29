import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';

/// Pure deterministic helper to suggest Comeback based on history.
/// Suggests when most recent workout is >=14 days ago.
class ComebackSuggestionPolicy {
  const ComebackSuggestionPolicy._();

  /// Returns true if Comeback should be suggested.
  /// Inputs: history (any order), explicit now.
  /// Rules:
  /// - history contains at least one completed workout
  /// - most recent valid completed workout is at or before now (future ignored)
  /// - time since latest >=14 days
  /// Boundary: exactly 14 days → true, <14 → false, no history → false
  static bool shouldSuggestComeback({
    required List<CompletedWorkout> history,
    required DateTime now,
  }) {
    if (history.isEmpty) return false;

    // Defensive copy
    final copy = List<CompletedWorkout>.from(history);

    // Filter out future-dated records (completedAt > now)
    final valid = copy.where((w) => !w.completedAt.isAfter(now)).toList();
    if (valid.isEmpty) return false;

    // Find most recent
    valid.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final mostRecent = valid.first;

    final diff = now.difference(mostRecent.completedAt);
    return diff >= const Duration(days: 14);
  }
}
