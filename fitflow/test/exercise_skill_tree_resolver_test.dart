import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

void main() {
  ExerciseSkillTreeCatalog resolve(Iterable<Exercise> exercises) {
    return ExerciseSkillTreeResolver.resolve(
      exercises: exercises,
      userProfile: skillTreeUserProfile(),
      capabilityProfile: skillTreeCapabilityProfile(),
    );
  }

  group('ExerciseSkillTreeResolver family discovery', () {
    test('existing catalog families resolve without metadata defects', () {
      final catalog = ExerciseSkillTreeResolver.resolve(
        exercises: ExerciseCatalog.all,
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(),
      );

      expect(
        catalog.trees.map((tree) => tree.familyId).toSet(),
        {
          'pushup',
          'squat',
          'forearm_plank',
          'glute_bridge',
          'lunge',
          'hinge',
        },
      );
      expect(catalog.diagnostics, isEmpty);
    });
    test('discovers future progression families dynamically', () {
      final catalog = resolve([
        ...skillTreeLadder(familyId: 'future_push_chain'),
        ...skillTreeLadder(
          familyId: 'future_squat_path',
          pattern: MovementPattern.squat,
        ).map(
          (exercise) => skillTreeExercise(
            id: exercise.id.replaceFirst('a_easy', 'c_low').replaceFirst(
                  'b_hard',
                  'd_high',
                ),
            familyId: exercise.progressionFamilyId,
            rank: exercise.progressionRank,
            difficulty: exercise.difficulty,
            movementPattern: exercise.movementPattern,
          ),
        ),
      ]);

      expect(catalog.trees.map((tree) => tree.familyId), [
        'future_push_chain',
        'future_squat_path',
      ]);
      expect(catalog.treeForFamilyId('future_push_chain'), isNotNull);
      expect(catalog.treeForFamilyId('future_squat_path')?.movementPattern,
          MovementPattern.squat);
    });

    test('standalone exercises do not create a tree', () {
      final catalog = resolve([
        skillTreeExercise(id: 'standalone_1', familyId: null),
        skillTreeExercise(id: 'standalone_2', familyId: null, rank: 2),
      ]);

      expect(catalog.trees, isEmpty);
    });

    test('a family requires at least two valid active nodes', () {
      final catalog = resolve([
        skillTreeExercise(id: 'only_node', familyId: 'small_family'),
      ]);

      expect(catalog.trees, isEmpty);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
              ExerciseSkillTreeDiagnosticCode.insufficientValidExercises,
        ),
        isTrue,
      );
    });

    test('inactive exercises are excluded from family nodes', () {
      final catalog = resolve([
        ...skillTreeLadder(familyId: 'active_only'),
        skillTreeExercise(
          id: 'inactive',
          familyId: 'active_only',
          rank: 3,
          active: false,
        ),
      ]);

      expect(catalog.treeForFamilyId('active_only')?.nodeCount, 2);
      expect(
        catalog
            .treeForFamilyId('active_only')!
            .nodes
            .any((node) => node.exercise.id == 'inactive'),
        isFalse,
      );
    });

    test('invalid Exercise data is excluded but diagnosed', () {
      final catalog = resolve([
        ...skillTreeLadder(familyId: 'valid_remainder'),
        skillTreeExercise(
          id: 'invalid_reps',
          familyId: 'valid_remainder',
          rank: 3,
          defaultReps: null,
        ),
      ]);

      expect(catalog.treeForFamilyId('valid_remainder')?.nodeCount, 2);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code == ExerciseSkillTreeDiagnosticCode.invalidExercise &&
              item.exerciseId == 'invalid_reps',
        ),
        isTrue,
      );
    });

    test('nodes sort by progression rank', () {
      final catalog = resolve(skillTreeLadder().reversed);

      expect(
        catalog.trees.single.nodes.map((node) => node.exercise.id),
        ['a_easy', 'b_hard'],
      );
      expect(catalog.trees.single.nodes.map((node) => node.progressionRank),
          [1, 2]);
      expect(catalog.trees.single.nodes.map((node) => node.position), [1, 2]);
    });

    test('equal ranks use exercise ID as a stable secondary order', () {
      final catalog = resolve([
        skillTreeExercise(id: 'z_node', familyId: 'tied', rank: 4),
        skillTreeExercise(id: 'a_node', familyId: 'tied', rank: 4),
      ]);

      expect(
          catalog
              .treeForFamilyId('tied')
              ?.nodes
              .map((node) => node.exercise.id),
          ['a_node', 'z_node']);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
              ExerciseSkillTreeDiagnosticCode.duplicateProgressionRank,
        ),
        isTrue,
      );
    });

    test('catalog input order does not affect trees or diagnostics', () {
      final exercises = [
        ...skillTreeLadder(familyId: 'alpha'),
        skillTreeExercise(id: 'rank_tie_z', familyId: 'beta', rank: 1),
        skillTreeExercise(id: 'rank_tie_a', familyId: 'beta', rank: 1),
      ];
      final forward = resolve(exercises);
      final reversed = resolve(exercises.reversed);

      expect(
        reversed.trees.map((tree) => tree.familyId).toList(),
        forward.trees.map((tree) => tree.familyId).toList(),
      );
      expect(reversed.diagnostics, forward.diagnostics);
      for (var index = 0; index < forward.trees.length; index++) {
        expect(
          reversed.trees[index].nodes.map((node) => node.exercise.id),
          forward.trees[index].nodes.map((node) => node.exercise.id),
        );
      }
    });

    test('all exposed tree collections are unmodifiable', () {
      final catalog = resolve(skillTreeLadder());
      final tree = catalog.trees.single;
      final node = tree.nodes.first;

      expect(() => catalog.trees.add(tree), throwsUnsupportedError);
      expect(
          () => catalog.diagnostics.add(
                const ExerciseSkillTreeDiagnostic(
                  code: ExerciseSkillTreeDiagnosticCode.emptyFamilyId,
                ),
              ),
          throwsUnsupportedError);
      expect(() => tree.nodes.add(node), throwsUnsupportedError);
      expect(
          () => tree.diagnostics.add(
                const ExerciseSkillTreeDiagnostic(
                  code: ExerciseSkillTreeDiagnosticCode.emptyFamilyId,
                ),
              ),
          throwsUnsupportedError);
      expect(() => node.setupExclusionReasons.clear(), throwsUnsupportedError);
      expect(
          () => node.setupIssueLabels.add('changed'), throwsUnsupportedError);
    });

    test('family movement pattern is derived from exercises', () {
      final catalog = resolve(
        skillTreeLadder(
            familyId: 'derived_squat', pattern: MovementPattern.squat),
      );

      expect(catalog.trees.single.movementPattern, MovementPattern.squat);
    });

    test('non-trainable movement patterns cannot form a family tree', () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'warmup_one',
          familyId: 'warmup_family',
          rank: 1,
          movementPattern: MovementPattern.warmup,
        ),
        skillTreeExercise(
          id: 'warmup_two',
          familyId: 'warmup_family',
          rank: 2,
          movementPattern: MovementPattern.warmup,
        ),
      ]);

      expect(catalog.treeForFamilyId('warmup_family'), isNull);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
              ExerciseSkillTreeDiagnosticCode.nonTrainableMovementPattern,
        ),
        isTrue,
      );
    });

    test('mixed movement patterns exclude the family and retain a diagnostic',
        () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'push_node',
          familyId: 'mixed',
          rank: 1,
          movementPattern: MovementPattern.push,
        ),
        skillTreeExercise(
          id: 'squat_node',
          familyId: 'mixed',
          rank: 2,
          movementPattern: MovementPattern.squat,
        ),
      ]);

      expect(catalog.treeForFamilyId('mixed'), isNull);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.familyId == 'mixed' &&
              item.code ==
                  ExerciseSkillTreeDiagnosticCode.mixedMovementPatterns,
        ),
        isTrue,
      );
    });

    test('duplicate exercise IDs are diagnosed and excluded conservatively',
        () {
      final catalog = resolve([
        skillTreeExercise(
            id: 'duplicate', familyId: 'duplicate_family', rank: 1),
        skillTreeExercise(
            id: 'duplicate', familyId: 'duplicate_family', rank: 2),
        skillTreeExercise(id: 'third', familyId: 'duplicate_family', rank: 3),
      ]);

      expect(catalog.treeForFamilyId('duplicate_family'), isNull);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode.duplicateExerciseId &&
              item.exerciseId == 'duplicate',
        ),
        isTrue,
      );
    });

    test('non-positive family rank is excluded and diagnosed', () {
      final catalog = resolve([
        skillTreeExercise(id: 'zero_rank', familyId: 'ranked', rank: 0),
        skillTreeExercise(id: 'valid_one', familyId: 'ranked', rank: 2),
        skillTreeExercise(id: 'valid_two', familyId: 'ranked', rank: 3),
      ]);

      expect(catalog.treeForFamilyId('ranked')?.nodeCount, 2);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode.nonPositiveProgressionRank &&
              item.exerciseId == 'zero_rank',
        ),
        isTrue,
      );
    });

    test('missing easier variation target is reported without fabricating it',
        () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'first',
          familyId: 'missing_easier',
          rank: 1,
          harderId: 'second',
        ),
        skillTreeExercise(
          id: 'second',
          familyId: 'missing_easier',
          rank: 2,
          easierId: 'not_in_catalog',
        ),
      ]);

      expect(catalog.treeForFamilyId('missing_easier')?.nodeCount, 2);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode
                      .missingEasierVariationTarget &&
              item.relatedExerciseId == 'not_in_catalog',
        ),
        isTrue,
      );
      expect(catalog.treeForFamilyId('missing_easier')!.nodes.last.exercise.id,
          'second');
    });

    test('missing harder variation target is reported without substitution',
        () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'first',
          familyId: 'missing_harder',
          rank: 1,
          harderId: 'not_in_catalog',
        ),
        skillTreeExercise(
          id: 'second',
          familyId: 'missing_harder',
          rank: 2,
          easierId: 'first',
        ),
      ]);

      expect(catalog.treeForFamilyId('missing_harder')?.nodeCount, 2);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode
                      .missingHarderVariationTarget &&
              item.relatedExerciseId == 'not_in_catalog',
        ),
        isTrue,
      );
    });

    test('cross-family variation links are diagnosed', () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'first',
          familyId: 'inside',
          rank: 1,
          harderId: 'external',
        ),
        skillTreeExercise(
          id: 'second',
          familyId: 'inside',
          rank: 2,
          easierId: 'first',
        ),
        skillTreeExercise(id: 'external', familyId: 'outside', rank: 1),
      ]);

      expect(catalog.treeForFamilyId('inside'), isNotNull);
      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode
                      .harderVariationFromAnotherFamily &&
              item.exerciseId == 'first',
        ),
        isTrue,
      );
    });

    test('self-referential variation links are diagnosed', () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'self',
          familyId: 'self_link',
          rank: 1,
          harderId: 'self',
        ),
        skillTreeExercise(
          id: 'next',
          familyId: 'self_link',
          rank: 2,
          easierId: 'self',
        ),
      ]);

      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode
                      .selfReferenceHarderVariation &&
              item.exerciseId == 'self',
        ),
        isTrue,
      );
    });

    test('inconsistent immediate neighbor links are reported', () {
      final catalog = resolve([
        skillTreeExercise(
          id: 'first',
          familyId: 'wrong_neighbor',
          rank: 1,
          harderId: 'second',
        ),
        skillTreeExercise(
          id: 'second',
          familyId: 'wrong_neighbor',
          rank: 2,
          // The immediate easier link is intentionally absent.
        ),
      ]);

      expect(
        catalog.diagnostics.any(
          (item) =>
              item.code ==
                  ExerciseSkillTreeDiagnosticCode
                      .inconsistentEasierNeighborLink &&
              item.exerciseId == 'second',
        ),
        isTrue,
      );
    });

    test('family title formatter has a generic future-ID fallback', () {
      expect(
          formatExerciseSkillTreeFamilyName('forearm_plank'), 'Forearm Plank');
      expect(formatExerciseSkillTreeFamilyName('glute_bridge'), 'Glute Bridge');
      expect(formatExerciseSkillTreeFamilyName('pushup'), 'Push-Up');
      expect(
        formatExerciseSkillTreeFamilyName('future_balance_flow'),
        'Future Balance Flow',
      );
    });

    test('a blank family ID is ignored and diagnosed', () {
      final catalog = resolve([
        skillTreeExercise(id: 'blank', familyId: '   '),
        skillTreeExercise(id: 'other', familyId: '   ', rank: 2),
      ]);

      expect(catalog.trees, isEmpty);
      expect(
        catalog.diagnostics.any((item) =>
            item.code == ExerciseSkillTreeDiagnosticCode.emptyFamilyId),
        isTrue,
      );
    });
  });
}
