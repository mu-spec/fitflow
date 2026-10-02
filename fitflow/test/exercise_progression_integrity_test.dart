import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// Progression family integrity (Milestone 20 Part 1, spec §29).
///
/// Families are discovered dynamically from the catalog so new families are
/// covered automatically; the original major families are additionally pinned
/// as explicit regressions.
void main() {
  final catalog = ExerciseCatalog.all;
  final byId = {for (final e in catalog) e.id: e};

  Map<String, List<Exercise>> discoverFamilies() {
    final families = <String, List<Exercise>>{};
    for (final e in catalog) {
      final familyId = e.progressionFamilyId;
      if (familyId != null) {
        families.putIfAbsent(familyId, () => []).add(e);
      }
    }
    return families;
  }

  group('every progression family', () {
    test('has positive unique ranks and a deterministic order', () {
      final families = discoverFamilies();
      expect(families, isNotEmpty);
      families.forEach((familyId, members) {
        final ranks = members.map((m) => m.progressionRank).toList();
        expect(ranks.every((r) => r > 0), isTrue, reason: familyId);
        expect(ranks.toSet(), hasLength(ranks.length), reason: familyId);

        final once = ExerciseProgressionOrder.sort(members);
        final twice = ExerciseProgressionOrder.sort(members.reversed);
        expect(
          once.map((e) => e.id).toList(),
          twice.map((e) => e.id).toList(),
          reason: 'family $familyId must sort deterministically',
        );
      });
    });

    test('keeps a single movement pattern per family', () {
      discoverFamilies().forEach((familyId, members) {
        final patterns = members.map((m) => m.movementPattern).toSet();
        expect(patterns, hasLength(1), reason: familyId);
      });
    });

    test('never gets easier along the ladder', () {
      discoverFamilies().forEach((familyId, members) {
        final sorted = ExerciseProgressionOrder.sort(members);
        for (var i = 1; i < sorted.length; i++) {
          expect(
            sorted[i].difficulty.index >= sorted[i - 1].difficulty.index,
            isTrue,
            reason:
                '$familyId: ${sorted[i].id} must not be easier than '
                '${sorted[i - 1].id}',
          );
        }
      });
    });

    test('links resolve, stay in family, follow rank direction, and are '
        'reciprocal', () {
      for (final e in catalog) {
        final easierId = e.easierVariationId;
        final harderId = e.harderVariationId;
        if (easierId == null && harderId == null) {
          continue;
        }
        expect(e.progressionFamilyId, isNotNull,
            reason: '${e.id} has links but no family');

        if (easierId != null) {
          expect(easierId, isNot(e.id), reason: e.id);
          final target = byId[easierId];
          expect(target, isNotNull, reason: e.id);
          expect(target!.active, isTrue, reason: e.id);
          expect(target.progressionFamilyId, e.progressionFamilyId,
              reason: e.id);
          expect(target.progressionRank, lessThan(e.progressionRank),
              reason: e.id);
          expect(target.harderVariationId, e.id,
              reason: '${e.id} easier link must be reciprocal');
        }
        if (harderId != null) {
          expect(harderId, isNot(e.id), reason: e.id);
          final target = byId[harderId];
          expect(target, isNotNull, reason: e.id);
          expect(target!.active, isTrue, reason: e.id);
          expect(target.progressionFamilyId, e.progressionFamilyId,
              reason: e.id);
          expect(target.progressionRank, greaterThan(e.progressionRank),
              reason: e.id);
          expect(target.easierVariationId, e.id,
              reason: '${e.id} harder link must be reciprocal');
        }
      }
    });

    test('has no easier/harder cycles', () {
      for (final e in catalog) {
        final seenHarder = <String>{e.id};
        var cursor = e.harderVariationId;
        while (cursor != null) {
          expect(seenHarder.add(cursor), isTrue,
              reason: 'harder cycle from ${e.id} revisits $cursor');
          cursor = byId[cursor]?.harderVariationId;
        }
        final seenEasier = <String>{e.id};
        cursor = e.easierVariationId;
        while (cursor != null) {
          expect(seenEasier.add(cursor), isTrue,
              reason: 'easier cycle from ${e.id} revisits $cursor');
          cursor = byId[cursor]?.easierVariationId;
        }
      }
    });
  });

  group('original major families remain intact', () {
    List<String> familyOrder(String familyId) => ExerciseProgressionOrder.sort(
          catalog.where(
            (e) => e.active && e.progressionFamilyId == familyId,
          ),
        )
            .map((e) => e.id)
            .toList();

    test('pushup ladder', () {
      expect(familyOrder('pushup'), [
        'pushup_wall',
        'pushup_incline',
        'pushup_knee',
        'pushup_standard',
        'pushup_decline',
        'pushup_diamond',
      ]);
    });

    test('squat ladder', () {
      expect(familyOrder('squat'), [
        'squat_chair',
        'squat_partial',
        'squat_bodyweight',
        'squat_tempo',
      ]);
    });

    test('forearm plank ladder', () {
      expect(familyOrder('forearm_plank'), [
        'plank_knee',
        'plank_forearm',
      ]);
    });

    test('glute bridge ladder', () {
      expect(familyOrder('glute_bridge'), [
        'bridge_glute',
        'bridge_march',
        'bridge_single_leg',
      ]);
    });

    test('lunge ladder', () {
      expect(familyOrder('lunge'), [
        'squat_split_static',
        'lunge_reverse',
        'lunge_forward',
        'squat_split_bulgarian',
      ]);
    });

    test('hinge ladder', () {
      expect(familyOrder('hinge'), [
        'hip_hinge',
        'good_morning',
        'hip_hinge_single_leg',
      ]);
    });
  });

  group('resolver integration', () {
    test('mid-ladder exercise exposes consistent progression info', () {
      final standard = ExerciseCatalog.byId('pushup_standard')!;
      final info = ExerciseProgressionResolver.resolve(standard);
      expect(info, isNotNull);
      expect(info!.step, 4);
      expect(info.total, 6);
      expect(info.easier?.id, 'pushup_knee');
      expect(info.harder?.id, 'pushup_decline');
      expect(info.isFirst, isFalse);
      expect(info.isLast, isFalse);
    });

    test('standalone exercises still resolve to no progression', () {
      final wallSit = ExerciseCatalog.byId('wall_sit')!;
      expect(ExerciseProgressionResolver.resolve(wallSit), isNull);
    });
  });
}
