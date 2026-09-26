import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:flutter/foundation.dart';

/// Immutable filter model for the Exercise Library.
@immutable
class ExerciseLibraryFilter {
  const ExerciseLibraryFilter({
    this.searchQuery = '',
    this.movementPatterns = const {},
    this.difficulties = const {},
    this.equipment = const {},
    this.positions = const {},
    this.noEquipment = false,
    this.standingOnly = false,
    this.lowImpact = false,
    this.quiet = false,
  });

  final String searchQuery;
  final Set<MovementPattern> movementPatterns;
  final Set<ExerciseDifficulty> difficulties;
  final Set<WorkoutEquipment> equipment;
  final Set<ExercisePosition> positions;
  final bool noEquipment;
  final bool standingOnly;
  final bool lowImpact;
  final bool quiet;

  ExerciseLibraryFilter copyWith({
    String? searchQuery,
    Set<MovementPattern>? movementPatterns,
    Set<ExerciseDifficulty>? difficulties,
    Set<WorkoutEquipment>? equipment,
    Set<ExercisePosition>? positions,
    bool? noEquipment,
    bool? standingOnly,
    bool? lowImpact,
    bool? quiet,
  }) {
    return ExerciseLibraryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      movementPatterns: movementPatterns ?? this.movementPatterns,
      difficulties: difficulties ?? this.difficulties,
      equipment: equipment ?? this.equipment,
      positions: positions ?? this.positions,
      noEquipment: noEquipment ?? this.noEquipment,
      standingOnly: standingOnly ?? this.standingOnly,
      lowImpact: lowImpact ?? this.lowImpact,
      quiet: quiet ?? this.quiet,
    );
  }

  /// Number of active filter selections (excluding search text).
  int get activeFilterCount {
    var count = 0;
    count += movementPatterns.length;
    count += difficulties.length;
    count += equipment.length;
    count += positions.length;
    if (noEquipment) count++;
    if (standingOnly) count++;
    if (lowImpact) count++;
    if (quiet) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  bool get hasSearch => searchQuery.trim().isNotEmpty;

  /// Returns a copy with all filter selections cleared, preserving search.
  ExerciseLibraryFilter clearFilters() {
    return copyWith(
      movementPatterns: const {},
      difficulties: const {},
      equipment: const {},
      positions: const {},
      noEquipment: false,
      standingOnly: false,
      lowImpact: false,
      quiet: false,
    );
  }

  /// Returns a copy with everything cleared (filters + search).
  ExerciseLibraryFilter clearAll() {
    return const ExerciseLibraryFilter();
  }
}

/// Returns true if [exercise] matches [query] (case-insensitive, trimmed)
/// across name, primary/secondary muscle labels, movement pattern label,
/// equipment labels, and tags.
bool exerciseMatchesSearch(Exercise exercise, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return true;

  final searchable = <String>[];

  searchable.add(exercise.name.toLowerCase());

  for (final m in exercise.primaryMuscles) {
    searchable.add(m.label.toLowerCase());
  }
  for (final m in exercise.secondaryMuscles) {
    searchable.add(m.label.toLowerCase());
  }

  final movementLabel = exercise.movementPattern?.label.toLowerCase();
  if (movementLabel != null) {
    searchable.add(movementLabel);
  }

  // Equipment labels: include 'no equipment' phrase for none
  if (exercise.requiredEquipment.contains(WorkoutEquipment.none) ||
      exercise.requiredEquipment.isEmpty) {
    searchable.add('no equipment');
    searchable.add('none');
  }
  for (final e in exercise.requiredEquipment) {
    searchable.add(e.label.toLowerCase());
  }

  for (final tag in exercise.tags) {
    searchable.add(tag.toLowerCase());
  }

  // Check if any searchable field contains the query substring
  for (final field in searchable) {
    if (field.contains(trimmed)) return true;
  }
  return false;
}

/// Applies [filter] to [exercises] with AND-across-categories, OR-within-category semantics.
List<Exercise> applyExerciseLibraryFilter(
  List<Exercise> exercises,
  ExerciseLibraryFilter filter,
) {
  final query = filter.searchQuery.trim();

  return exercises.where((exercise) {
    // Search
    if (!exerciseMatchesSearch(exercise, query)) return false;

    // Movement Pattern: OR within
    if (filter.movementPatterns.isNotEmpty) {
      final pattern = exercise.movementPattern;
      if (pattern == null || !filter.movementPatterns.contains(pattern)) {
        return false;
      }
    }

    // Difficulty: OR within
    if (filter.difficulties.isNotEmpty) {
      if (!filter.difficulties.contains(exercise.difficulty)) return false;
    }

    // Equipment: OR within (any overlap)
    if (filter.equipment.isNotEmpty) {
      final required = exercise.requiredEquipment;
      // Empty equipment in model is considered as none, but validation ensures none is explicit
      final hasOverlap = required.any(filter.equipment.contains);
      // Also handle case where filter contains none and exercise is empty
      if (!hasOverlap) return false;
    }

    // Body Position: OR within
    if (filter.positions.isNotEmpty) {
      final pos = exercise.bodyPosition;
      if (pos == null || !filter.positions.contains(pos)) return false;
    }

    // Quick filters: each is an additional AND
    if (filter.noEquipment) {
      if (!exercise.requiredEquipment.contains(WorkoutEquipment.none)) {
        // Also treat empty as no equipment for safety
        if (exercise.requiredEquipment.isNotEmpty) return false;
      }
    }
    if (filter.standingOnly) {
      if (exercise.bodyPosition != ExercisePosition.standing) return false;
    }
    if (filter.lowImpact) {
      if (exercise.impactLevel != ImpactLevel.low) return false;
    }
    if (filter.quiet) {
      if (exercise.noiseLevel != NoiseLevel.quiet) return false;
    }

    return true;
  }).toList();
}
