import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseLibraryFilter search', () {
    test('search push finds Push-Up (case-insensitive)', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'push');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.any((e) => e.name.toLowerCase().contains('push')), isTrue);
    });
    test('search case-insensitive chest finds Chest', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'CHEST');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.any((e) => e.primaryMuscles.any((m) => m.label.toLowerCase().contains('chest')) || e.name.toLowerCase().contains('chest')), isTrue);
    });
    test('search glutes finds Glutes', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'glutes');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.any((e) => e.primaryMuscles.any((m) => m.label.toLowerCase().contains('glute'))), isTrue);
    });
    test('search chair finds Chair equipment', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'chair');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.any((e) => e.requiredEquipment.any((eq) => eq.label.toLowerCase().contains('chair'))), isTrue);
    });
    test('search whitespace-trimmed', () {
      const filter = ExerciseLibraryFilter(searchQuery: '  push  ');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.any((e) => e.name.toLowerCase().contains('push')), isTrue);
    });
  });

  group('ExerciseLibraryFilter category filters', () {
    test('movement pattern filter', () {
      const filter = ExerciseLibraryFilter(movementPatterns: {MovementPattern.push});
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.movementPattern == MovementPattern.push), isTrue);
      expect(result, isNotEmpty);
    });
    test('difficulty filter', () {
      const filter = ExerciseLibraryFilter(difficulties: {ExerciseDifficulty.level1});
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.difficulty == ExerciseDifficulty.level1), isTrue);
    });
    test('equipment filter', () {
      const filter = ExerciseLibraryFilter(equipment: {WorkoutEquipment.none});
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.requiredEquipment.contains(WorkoutEquipment.none) || e.requiredEquipment.isEmpty), isTrue);
    });
    test('position filter', () {
      const filter = ExerciseLibraryFilter(positions: {ExercisePosition.standing});
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.bodyPosition == ExercisePosition.standing), isTrue);
    });
  });

  group('Quick filters', () {
    test('No equipment', () {
      const filter = ExerciseLibraryFilter(noEquipment: true);
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.requiredEquipment.contains(WorkoutEquipment.none) || e.requiredEquipment.isEmpty), isTrue);
    });
    test('Standing only', () {
      const filter = ExerciseLibraryFilter(standingOnly: true);
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.bodyPosition == ExercisePosition.standing), isTrue);
    });
    test('Low impact', () {
      const filter = ExerciseLibraryFilter(lowImpact: true);
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.impactLevel == ImpactLevel.low), isTrue);
    });
    test('Quiet', () {
      const filter = ExerciseLibraryFilter(quiet: true);
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.noiseLevel == NoiseLevel.quiet), isTrue);
    });
  });

  group('Combined semantics', () {
    test('AND between categories, OR within', () {
      const filter = ExerciseLibraryFilter(
        movementPatterns: {MovementPattern.cardio, MovementPattern.push},
        standingOnly: true,
        quiet: true,
      );
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      for (final e in result) {
        expect(e.bodyPosition, ExercisePosition.standing);
        expect(e.noiseLevel, NoiseLevel.quiet);
        expect({MovementPattern.cardio, MovementPattern.push}.contains(e.movementPattern), isTrue);
      }
    });
    test('search AND filters', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'push', movementPatterns: {MovementPattern.push});
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.every((e) => e.movementPattern == MovementPattern.push && exerciseMatchesSearch(e, 'push')), isTrue);
    });
  });

  group('Result Count and No Results', () {
    test('filtered length live', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'push');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result.length, greaterThan(0));
      expect(result.length, lessThan(ExerciseCatalog.all.length));
    });
    test('No exercises found when filtered zero vs empty catalog', () {
      const filter = ExerciseLibraryFilter(searchQuery: 'zzzz_nonexistent');
      final result = applyExerciseLibraryFilter(ExerciseCatalog.all, filter);
      expect(result, isEmpty);
      final empty = applyExerciseLibraryFilter(const [], filter);
      expect(empty, isEmpty);
    });
  });
}
