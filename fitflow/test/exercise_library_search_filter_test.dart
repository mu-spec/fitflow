import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Milestone 20 Part 2: Exercise Library search & filter regression over the
/// corrected catalog. Preserves current architecture — no fuzzy search, no
/// new packages.
void main() {
  final catalog = ExerciseCatalog.all;

  List<String> ids(List<Exercise> exercises) =>
      exercises.map((e) => e.id).toList();

  group('representative searches', () {
    test('"push" finds push-up family content', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'push'),
      );
      expect(results, isNotEmpty);
      expect(ids(results), contains('pushup_standard'));
    });

    test('"squat" finds squat family content', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'squat'),
      );
      expect(results, isNotEmpty);
      expect(ids(results), contains('squat_bodyweight'));
    });

    test('"plank" finds plank variations', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'plank'),
      );
      expect(results, isNotEmpty);
      expect(ids(results), contains('plank_forearm'));
    });

    test('"mobility" finds mobility content via pattern label', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'mobility'),
      );
      expect(results, isNotEmpty);
      for (final exercise in results) {
        final haystack = [
          exercise.name,
          exercise.movementPattern?.label ?? '',
          ...exercise.tags,
        ].join(' ').toLowerCase();
        expect(haystack, contains('mobility'), reason: exercise.id);
      }
    });

    test('"dumbbell" returns zero rows truthfully (catalog has none) and '
        'equipment search itself works', () {
      // The catalog truthfully contains no dumbbell exercises.
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'dumbbell'),
      );
      expect(results, isEmpty);

      // The search mechanism itself covers equipment labels: a synthetic
      // dumbbell exercise would be findable without any enhancement.
      final synthetic = Exercise(
        id: 'synthetic_dumbbell_row',
        name: 'Synthetic Dumbbell Row',
        difficulty: ExerciseDifficulty.level2,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.low,
        kneeLoad: JointLoad.none,
        requiredEquipment: const {WorkoutEquipment.dumbbells},
        exerciseType: ExerciseType.reps,
        defaultReps: 8,
        defaultRest: const Duration(seconds: 30),
        active: true,
      );
      expect(exerciseMatchesSearch(synthetic, 'dumbbell'), isTrue);
    });
  });

  group('determinism', () {
    test('same query twice yields identical ordered results', () {
      final filter = const ExerciseLibraryFilter(searchQuery: 'plank');
      expect(
        ids(applyExerciseLibraryFilter(catalog, filter)),
        ids(applyExerciseLibraryFilter(catalog, filter)),
      );
    });

    test('results preserve catalog order', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(searchQuery: 'e'),
      );
      final catalogOrder = {for (var i = 0; i < catalog.length; i++) catalog[i].id: i};
      final indexes = results.map((e) => catalogOrder[e.id]!).toList();
      final sorted = List<int>.of(indexes)..sort();
      expect(indexes, sorted);
    });
  });

  group('quick filters honor corrected Part 1 metadata', () {
    test('no equipment returns only equipment-free exercises', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(noEquipment: true),
      );
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expect(exercise.requiredEquipment, {WorkoutEquipment.none},
            reason: exercise.id);
      }
    });

    test('standing only returns only standing exercises', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(standingOnly: true),
      );
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expect(exercise.bodyPosition, ExercisePosition.standing,
            reason: exercise.id);
      }
      // Part 1 correction: dip_chair is seated, never standing.
      expect(ids(results), isNot(contains('dip_chair')));
    });

    test('low impact returns only low-impact exercises', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(lowImpact: true),
      );
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expect(exercise.impactLevel, ImpactLevel.low, reason: exercise.id);
      }
    });

    test('quiet returns only quiet exercises', () {
      final results = applyExerciseLibraryFilter(
        catalog,
        const ExerciseLibraryFilter(quiet: true),
      );
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expect(exercise.noiseLevel, NoiseLevel.quiet, reason: exercise.id);
      }
    });
  });

  group('combined filters never violate their own predicates', () {
    void expectMatchesFilter(Exercise exercise, ExerciseLibraryFilter filter) {
      if (filter.movementPatterns.isNotEmpty) {
        expect(filter.movementPatterns, contains(exercise.movementPattern),
            reason: exercise.id);
      }
      if (filter.difficulties.isNotEmpty) {
        expect(filter.difficulties, contains(exercise.difficulty),
            reason: exercise.id);
      }
      if (filter.noEquipment) {
        expect(exercise.requiredEquipment, {WorkoutEquipment.none},
            reason: exercise.id);
      }
      if (filter.standingOnly) {
        expect(exercise.bodyPosition, ExercisePosition.standing,
            reason: exercise.id);
      }
      if (filter.lowImpact) {
        expect(exercise.impactLevel, ImpactLevel.low, reason: exercise.id);
      }
      if (filter.quiet) {
        expect(exercise.noiseLevel, NoiseLevel.quiet, reason: exercise.id);
      }
    }

    test('movement + equipment', () {
      const filter = ExerciseLibraryFilter(
        movementPatterns: {MovementPattern.push},
        equipment: {WorkoutEquipment.bench},
      );
      final results = applyExerciseLibraryFilter(catalog, filter);
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expect(exercise.movementPattern, MovementPattern.push);
        expect(exercise.requiredEquipment, contains(WorkoutEquipment.bench),
            reason: exercise.id);
      }
    });

    test('difficulty + quiet', () {
      const filter = ExerciseLibraryFilter(
        difficulties: {ExerciseDifficulty.level1},
        quiet: true,
      );
      final results = applyExerciseLibraryFilter(catalog, filter);
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expectMatchesFilter(exercise, filter);
      }
    });

    test('standing + no equipment', () {
      const filter = ExerciseLibraryFilter(
        standingOnly: true,
        noEquipment: true,
      );
      final results = applyExerciseLibraryFilter(catalog, filter);
      expect(results, isNotEmpty);
      for (final exercise in results) {
        expectMatchesFilter(exercise, filter);
      }
    });

    test('full-sheet combination stays self-consistent', () {
      const filter = ExerciseLibraryFilter(
        searchQuery: 'squat',
        movementPatterns: {MovementPattern.squat, MovementPattern.lunge},
        difficulties: {ExerciseDifficulty.level1, ExerciseDifficulty.level2},
        lowImpact: true,
        quiet: true,
      );
      final results = applyExerciseLibraryFilter(catalog, filter);
      for (final exercise in results) {
        expectMatchesFilter(exercise, filter);
        expect(exerciseMatchesSearch(exercise, 'squat'), isTrue,
            reason: exercise.id);
      }
    });
  });
}
