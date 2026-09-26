import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = ExerciseCatalog.all;

  test('contains exactly the requested 60 exercises in stable order', () {
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
      'Doorway Row',
      'Towel Row',
      'Reverse Snow Angel',
      'Superman',
      'Prone Y Raise',
      'Reverse Lunge',
      'Forward Lunge',
      'Static Split Squat',
      'Bulgarian Split Squat',
      'Calf Raise',
      'Bird Dog',
      'Bicycle Crunch',
      'Heel Taps',
      'Reverse Crunch',
      'Mountain Climbers',
      'Cat-Cow',
      "Child's Pose",
      'Hip Flexor Stretch',
      'Standing Hamstring Stretch',
      'Thoracic Rotation',
      'Good Morning',
      'Hip Hinge',
      'Single-Leg Hip Hinge',
      'Donkey Kick',
      'Fire Hydrant',
      'Pike Push-Up',
      'Close-Grip Push-Up',
      'Wide Push-Up',
      'Shoulder Tap',
      'Plank Up-Down',
      'Step Jack',
      'Butt Kicks',
      'Skater Step',
      'Squat to Knee Drive',
      'Shadow Boxing',
      'Single-Leg Stand',
      'Standing Knee Raise',
      'Ankle Circles',
      'Arm Circles',
      "World's Greatest Stretch",
    ]);
    expect(all, hasLength(60));
  });

  test('IDs and normalized names are unique', () {
    expect(all.map((e) => e.id).toSet(), hasLength(60));
    expect(all.map((e) => e.name.trim().toLowerCase()).toSet(), hasLength(60));
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
      'lunge': [
        'squat_split_static',
        'lunge_reverse',
        'lunge_forward',
        'squat_split_bulgarian'
      ],
      'hinge': ['hip_hinge', 'good_morning', 'hip_hinge_single_leg'],
    };
    for (final family in families.entries) {
      final members = all
          .where((e) => e.progressionFamilyId == family.key)
          .toList()
        ..sort((a, b) => a.progressionRank.compareTo(b.progressionRank));
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

  test('new equipment and constraint metadata matches the described variants',
      () {
    final towel = ExerciseCatalog.byId('row_towel')!;
    expect(towel.requiredEquipment, {WorkoutEquipment.towel});
    expect(towel.bodyPosition, ExercisePosition.floor);
    final doorway = ExerciseCatalog.byId('row_doorway')!;
    expect(doorway.tags, contains('structural_doorway_required'));
    expect(
        doorway.instructions.join(' '), contains('never grip a moving door'));
    final split = ExerciseCatalog.byId('squat_split_bulgarian')!;
    expect(split.requiredEquipment, {WorkoutEquipment.bench});
    expect(split.kneeLoad, JointLoad.high);
    expect(split.tags, contains('balance_demand'));
    final climber = ExerciseCatalog.byId('mountain_climbers')!;
    expect(climber.bodyPosition, ExercisePosition.floor);
    expect(climber.wristLoad, JointLoad.high);
    expect(climber.impactLevel, ImpactLevel.moderate);
    expect(climber.noiseLevel, NoiseLevel.moderate);
    expect(climber.tags, contains('jumping'));
    for (final id in ['childs_pose', 'hamstring_stretch_standing']) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.impactLevel, ImpactLevel.low);
      expect(e.noiseLevel, NoiseLevel.quiet);
    }
    expect(ExerciseCatalog.byId('childs_pose')!.bodyPosition,
        ExercisePosition.floor);
    expect(ExerciseCatalog.byId('hamstring_stretch_standing')!.bodyPosition,
        ExercisePosition.standing);
  });

  test('new core and mobility entries are not forced into progressions', () {
    // Original 20 + hinge family are the only progressions; check that
    // post-30 entries except hinge family remain unlinked
    final hingeIds = {'hip_hinge', 'good_morning', 'hip_hinge_single_leg'};
    for (final e in all.skip(30)) {
      if (hingeIds.contains(e.id)) continue;
      expect(e.progressionFamilyId, isNull, reason: e.id);
      expect(e.easierVariationId, isNull, reason: e.id);
      expect(e.harderVariationId, isNull, reason: e.id);
    }
  });

  test('new hinge progression is correct if added', () {
    final hinge = ExerciseCatalog.byId('hip_hinge')!;
    final good = ExerciseCatalog.byId('good_morning')!;
    final single = ExerciseCatalog.byId('hip_hinge_single_leg')!;
    // Family and ranks
    expect(hinge.progressionFamilyId, 'hinge');
    expect(good.progressionFamilyId, 'hinge');
    expect(single.progressionFamilyId, 'hinge');
    expect(hinge.progressionRank, 1);
    expect(good.progressionRank, 2);
    expect(single.progressionRank, 3);
    // Easier/harder links
    expect(hinge.easierVariationId, isNull);
    expect(hinge.harderVariationId, 'good_morning');
    expect(good.easierVariationId, 'hip_hinge');
    expect(good.harderVariationId, 'hip_hinge_single_leg');
    expect(single.easierVariationId, 'good_morning');
    expect(single.harderVariationId, isNull);
    // Difficulty should support clean progression (level1 < level2 < level3)
    expect(hinge.difficulty.index < good.difficulty.index, isTrue);
    expect(good.difficulty.index < single.difficulty.index, isTrue);
  });

  test('low-impact alternatives such as Step Jack have correct constraint metadata',
      () {
    final stepJack = ExerciseCatalog.byId('step_jack')!;
    expect(stepJack.bodyPosition, ExercisePosition.standing);
    expect(stepJack.impactLevel, ImpactLevel.low);
    expect(stepJack.noiseLevel, NoiseLevel.quiet);
    expect(stepJack.tags, contains('no_jumping'));
    expect(stepJack.requiredEquipment, {WorkoutEquipment.none});
    // Step Jack should be quieter/more gentle than Jumping Jacks
    final jacks = ExerciseCatalog.byId('jumping_jacks')!;
    expect(stepJack.impactLevel.index < jacks.impactLevel.index, isTrue);
    expect(stepJack.noiseLevel.index < jacks.noiseLevel.index, isTrue);

    final shadow = ExerciseCatalog.byId('shadow_boxing')!;
    expect(shadow.bodyPosition, ExercisePosition.standing);
    expect(shadow.requiredEquipment, {WorkoutEquipment.none});
    expect(shadow.impactLevel, isIn([ImpactLevel.low, ImpactLevel.moderate]));
    expect(shadow.noiseLevel, NoiseLevel.quiet);
    expect(shadow.spaceRequirement, SpaceRequirement.small);

    final shoulderTap = ExerciseCatalog.byId('shoulder_tap')!;
    expect(shoulderTap.bodyPosition, ExercisePosition.floor);
    expect(shoulderTap.wristLoad, JointLoad.high);

    final upDown = ExerciseCatalog.byId('plank_up_down')!;
    expect(upDown.bodyPosition, ExercisePosition.floor);
    expect(upDown.wristLoad, JointLoad.high);
    // More demanding than forearm plank (level2)
    final forearm = ExerciseCatalog.byId('plank_forearm')!;
    expect(upDown.difficulty.index > forearm.difficulty.index, isTrue);

    final singleStand = ExerciseCatalog.byId('single_leg_stand')!;
    expect(singleStand.bodyPosition, ExercisePosition.standing);
    expect(singleStand.impactLevel, ImpactLevel.low);
    expect(singleStand.noiseLevel, NoiseLevel.quiet);
    expect(singleStand.tags, contains('balance'));

    final world = ExerciseCatalog.byId('world_greatest_stretch')!;
    expect(world.movementPattern, isNotNull);
    expect(world.spaceRequirement, SpaceRequirement.medium);
    // Requires more space than standing hamstring stretch (tiny)
    final hammy = ExerciseCatalog.byId('hamstring_stretch_standing')!;
    expect(world.spaceRequirement.index > hammy.spaceRequirement.index, isTrue);
  });

  test('original progression families remain valid', () {
    // Ensure original 5 families still have correct members and order
    const originalFamilies = {
      'pushup': 5,
      'squat': 4,
      'forearm_plank': 2,
      'glute_bridge': 2,
      'lunge': 4,
    };
    for (final entry in originalFamilies.entries) {
      final members =
          all.where((e) => e.progressionFamilyId == entry.key).toList();
      expect(members, hasLength(entry.value), reason: entry.key);
    }
    // No duplicate family contamination
    expect(
        all
            .where((e) => e.progressionFamilyId == 'pushup')
            .map((e) => e.id)
            .toSet(),
        containsAll([
          'pushup_wall',
          'pushup_incline',
          'pushup_knee',
          'pushup_standard',
          'pushup_decline'
        ]));
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
