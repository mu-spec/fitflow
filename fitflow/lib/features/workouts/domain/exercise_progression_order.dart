import 'package:fitflow/features/workouts/domain/exercise.dart';

/// Shared deterministic order for existing progression metadata.
///
/// Progression rank is the primary family order. Exercise ID is only a stable
/// tie-breaker for malformed duplicate-rank metadata; it is not a capability
/// level or a mastery signal.
abstract final class ExerciseProgressionOrder {
  static List<Exercise> sort(Iterable<Exercise> exercises) {
    final ordered = exercises.toList();
    ordered.sort((a, b) {
      final byRank = a.progressionRank.compareTo(b.progressionRank);
      return byRank != 0 ? byRank : a.id.compareTo(b.id);
    });
    return List<Exercise>.unmodifiable(ordered);
  }
}
