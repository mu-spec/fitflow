import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';

/// Lightweight progression context resolved from existing catalog metadata.
///
/// No hardcoding, no DB, no persistence.
class ExerciseProgressionInfo {
  const ExerciseProgressionInfo({
    required this.current,
    required this.familySorted,
    required this.currentIndex,
    this.easier,
    this.harder,
  });

  /// The exercise currently being viewed.
  final Exercise current;

  /// All active exercises sharing the same family ID, sorted by progressionRank.
  final List<Exercise> familySorted;

  /// 0-based index of current inside [familySorted].
  final int currentIndex;

  /// Easier variation resolved via [Exercise.easierVariationId], if any and resolvable.
  final Exercise? easier;

  /// Harder variation resolved via [Exercise.harderVariationId], if any and resolvable.
  final Exercise? harder;

  int get total => familySorted.length;

  /// 1-based step for UI, e.g. 4 of 6.
  int get step => currentIndex + 1;

  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == total - 1;
}

abstract final class ExerciseProgressionResolver {
  /// Resolves progression info from catalog metadata.
  ///
  /// Returns null when exercise has no progression metadata:
  /// - progressionFamilyId == null
  /// - easierVariationId == null
  /// - harderVariationId == null
  /// In that case UI should omit the Progression section.
  static ExerciseProgressionInfo? resolve(Exercise exercise) {
    final familyId = exercise.progressionFamilyId;
    final easierId = exercise.easierVariationId;
    final harderId = exercise.harderVariationId;

    // Standalone: no family and no easier/harder links
    if (familyId == null && easierId == null && harderId == null) {
      return null;
    }

    // If no familyId, we cannot build ordered family, so treat as no progression
    // (catalog guarantees standalone exercises have no family)
    if (familyId == null) {
      return null;
    }

    // Resolve family sorted by rank
    final family = ExerciseCatalog.all
        .where((e) => e.active && e.progressionFamilyId == familyId)
        .toList()
      ..sort((a, b) => a.progressionRank.compareTo(b.progressionRank));

    if (family.isEmpty) {
      return null;
    }

    final currentIndex = family.indexWhere((e) => e.id == exercise.id);
    // If current not found in its own family (should not happen), omit
    if (currentIndex == -1) {
      return null;
    }

    // Resolve easier/harder gracefully, omitting broken refs
    Exercise? easier;
    Exercise? harder;

    if (easierId != null) {
      final resolved = ExerciseCatalog.byId(easierId);
      if (resolved != null && resolved.active) {
        easier = resolved;
      }
    }

    if (harderId != null) {
      final resolved = ExerciseCatalog.byId(harderId);
      if (resolved != null && resolved.active) {
        harder = resolved;
      }
    }

    return ExerciseProgressionInfo(
      current: exercise,
      familySorted: List.unmodifiable(family),
      currentIndex: currentIndex,
      easier: easier,
      harder: harder,
    );
  }
}
