import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = ExerciseCatalog.all;

  test('contains exactly the requested 20 exercises in stable order', () {
    expect(all.map((e) => e.name).toList(), [
      'Wall Push-Up',
      'Incline Push-Up',
      'Knee Push-Up',
      'Standard Push-Up',
      'Decline Push-Up',
      'Chair Sit-to-Stand',
      'Partial Squat',
      'Bodyweight Squat',
      'Tempo Squat',
      'Wall Sit',
      'Dead Bug',
      'Knee Plank',
      'Forearm Plank',
      'Side Plank',
      'Hollow Hold',
      'Glute Bridge',
      'Single-Leg Glute Bridge',
      'March in Place',
      'High Knees',
      'Jumping Jacks',
    ]);
    expect(all, hasLength(20));
  });

  test('IDs and normalized names are unique', () {
    expect(all.map((e) => e.id).toSet(), hasLength(20));
    expect(all.map((e) => e.name.trim().toLowerCase()).toSet(), hasLength(20));
  });

  test('every definition validates and contains meaningful metadata', () {
    for (final e in all) {
      expect(e.validate(), isEmpty, reason: e.id);
      expect(e.shortDescription, isNotEmpty);
      expect(e.primaryMuscles, isNotEmpty);
      expect(e.secondaryMuscles, isNotEmpty);
      expect(e.primaryMuscles.intersection(e.secondaryMuscles), isEmpty);
      expect(e.movementPattern, isNotNull);
      expect(e.bodyPosition, isNotNull);
      expect(e.instructions.length, greaterThanOrEqualTo(3));
      expect(e.commonMistakes.length, greaterThanOrEqualTo(2));
      expect(e.breathingGuidance, isNotEmpty);
      expect(e.tags, isNotEmpty);
      expect(e.defaultRest, greaterThan(Duration.zero));
      expect(e.active, isTrue);
      expect(e.assetPath, isNull); // No fabricated asset references.
      if (e.exerciseType == ExerciseType.reps) {
        expect(e.defaultDuration, isNull);
      } else {
        expect(e.defaultReps, isNull);
      }
    }
  });

  test('equipment uses valid values with none exclusive', () {
    for (final e in all) {
      expect(e.requiredEquipment, isNotEmpty);
      expect(WorkoutEquipment.values, containsAll(e.requiredEquipment));
      if (e.requiredEquipment.contains(WorkoutEquipment.none)) {
        expect(e.requiredEquipment, {WorkoutEquipment.none});
      }
    }
    expect(ExerciseCatalog.byId('pushup_incline')!.requiredEquipment,
        {WorkoutEquipment.bench});
    expect(ExerciseCatalog.byId('pushup_decline')!.requiredEquipment,
        {WorkoutEquipment.bench});
    expect(ExerciseCatalog.byId('squat_chair')!.requiredEquipment,
        {WorkoutEquipment.chair});
  });

  test('progressions have valid reciprocal links and adjacent ranks', () {
    for (final e in all) {
      for (final id in [e.easierVariationId, e.harderVariationId]) {
        if (id != null) {
          expect(id, isNot(e.id));
          expect(ExerciseCatalog.byId(id), isNotNull);
          expect(ExerciseCatalog.byId(id)!.progressionFamilyId,
              e.progressionFamilyId);
        }
      }
      if (e.easierVariationId != null) {
        final easier = ExerciseCatalog.byId(e.easierVariationId!)!;
        expect(easier.progressionRank, e.progressionRank - 1);
        expect(easier.harderVariationId, e.id);
      }
      if (e.harderVariationId != null) {
        final harder = ExerciseCatalog.byId(e.harderVariationId!)!;
        expect(harder.progressionRank, e.progressionRank + 1);
        expect(harder.easierVariationId, e.id);
      }
      if (e.progressionFamilyId == null) {
        expect(e.progressionRank, 0);
        expect(e.easierVariationId, isNull);
        expect(e.harderVariationId, isNull);
      }
    }
  });

  test('families contain exactly the intended ordered chains', () {
    const families = {
      'pushup': [
        'pushup_wall',
        'pushup_incline',
        'pushup_knee',
        'pushup_standard',
        'pushup_decline'
      ],
      'squat': [
        'squat_chair',
        'squat_partial',
        'squat_bodyweight',
        'squat_tempo'
      ],
      'forearm_plank': ['plank_knee', 'plank_forearm'],
      'glute_bridge': ['bridge_glute', 'bridge_single_leg'],
    };
    for (final family in families.entries) {
      final members =
          all.where((e) => e.progressionFamilyId == family.key).toList();
      expect(members.map((e) => e.id).toList(), family.value);
      expect(members.map((e) => e.progressionRank).toList(),
          List.generate(members.length, (i) => i + 1));
      expect(members.first.easierVariationId, isNull);
      expect(members.last.harderVariationId, isNull);
    }
  });

  test('constraint metadata distinguishes jumping, standing and wrist load',
      () {
    for (final id in ['jumping_jacks', 'high_knees']) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.impactLevel, ImpactLevel.high);
      expect(e.noiseLevel, NoiseLevel.loud);
      expect(e.bodyPosition, ExercisePosition.standing);
      expect(e.tags, contains('jumping'));
    }
    final march = ExerciseCatalog.byId('march_in_place')!;
    expect(march.impactLevel, ImpactLevel.low);
    expect(march.noiseLevel, NoiseLevel.quiet);
    expect(march.bodyPosition, ExercisePosition.standing);
    final plank = ExerciseCatalog.byId('plank_forearm')!;
    expect(plank.bodyPosition, ExercisePosition.floor);
    expect(plank.impactLevel, ImpactLevel.low);
    expect(plank.noiseLevel, NoiseLevel.quiet);
    expect(plank.wristLoad, JointLoad.none);
    expect(ExerciseCatalog.byId('pushup_standard')!.wristLoad, JointLoad.high);
    expect(ExerciseCatalog.byId('plank_knee')!.bodyPosition,
        ExercisePosition.floor);
  });

  test('catalog and model collections cannot be mutated', () {
    expect(() => all.clear(), throwsUnsupportedError);
    expect(() => all.first.instructions.clear(), throwsUnsupportedError);
    expect(() => all.first.tags.clear(), throwsUnsupportedError);
    expect(() => all.first.primaryMuscles.clear(), throwsUnsupportedError);
    expect(() => all.first.requiredEquipment.clear(), throwsUnsupportedError);
  });

  test('lookup returns the existing definition or null', () {
    for (final e in all) {
      expect(ExerciseCatalog.byId(e.id), same(e));
    }
    expect(ExerciseCatalog.byId('unknown'), isNull);
  });
}
