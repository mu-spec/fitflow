import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = ExerciseCatalog.all;

  test('contains exactly the requested 80 exercises in stable order', () {
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
      'Diamond Push-Up',
      'Push-Up to Downward Dog',
      'Wall Shoulder Press',
      'Triceps Dip on Chair',
      'Sumo Squat',
      'Squat Pulse',
      'Curtsy Lunge',
      'Lateral Lunge',
      'Glute Bridge March',
      'Frog Pump',
      'Plank Reach',
      'Side Plank Knee Down',
      'Russian Twist',
      'Leg Raise',
      'Flutter Kicks',
      'Low-Impact Burpee',
      'Fast Feet',
      'Standing Mountain Climber',
      'Cobra Stretch',
      'Figure-Four Stretch',
    ]);
    expect(all, hasLength(80));
  });

  test('IDs and normalized names are unique', () {
    expect(all.map((e) => e.id).toSet(), hasLength(80));
    expect(all.map((e) => e.name.trim().toLowerCase()).toSet(), hasLength(80));
  });

  test('every definition validates and contains meaningful metadata', () {
    for (final e in all) {
      expect(e.validate(), isEmpty, reason: e.id);
      expect(e.shortDescription, isNotEmpty, reason: e.id);
      expect(e.shortDescription!.length, greaterThan(10), reason: e.id);
      expect(e.primaryMuscles, isNotEmpty, reason: e.id);
      expect(e.secondaryMuscles, isNotEmpty, reason: e.id);
      expect(e.primaryMuscles.intersection(e.secondaryMuscles), isEmpty,
          reason: e.id);
      expect(e.movementPattern, isNotNull, reason: e.id);
      expect(e.bodyPosition, isNotNull, reason: e.id);
      expect(e.instructions.length, greaterThanOrEqualTo(3), reason: e.id);
      for (final line in e.instructions) {
        expect(line.trim().length, greaterThan(10), reason: e.id);
      }
      expect(e.commonMistakes.length, greaterThanOrEqualTo(2), reason: e.id);
      for (final m in e.commonMistakes) {
        expect(m.trim().length, greaterThan(10), reason: e.id);
      }
      expect(e.breathingGuidance, isNotEmpty, reason: e.id);
      expect(e.breathingGuidance!.length, greaterThan(10), reason: e.id);
      expect(e.tags, isNotEmpty, reason: e.id);
      for (final t in e.tags) {
        expect(t.trim(), isNotEmpty, reason: e.id);
        expect(t.toLowerCase(), equals(t), reason: e.id);
      }
      expect(e.defaultRest, greaterThan(Duration.zero), reason: e.id);
      expect(e.active, isTrue, reason: e.id);
      expect(e.assetPath, isNull, reason: e.id); // No fabricated assets.
      expect(e.name.toLowerCase(), isNot(contains('placeholder')),
          reason: e.id);
      expect(e.shortDescription!.toLowerCase(), isNot(contains('placeholder')),
          reason: e.id);
      if (e.exerciseType == ExerciseType.reps) {
        expect(e.defaultDuration, isNull, reason: e.id);
        expect(e.defaultReps, isNotNull, reason: e.id);
        expect(e.defaultReps, greaterThan(0), reason: e.id);
      } else {
        expect(e.defaultReps, isNull, reason: e.id);
        expect(e.defaultDuration, isNotNull, reason: e.id);
        expect(e.defaultDuration, greaterThan(Duration.zero), reason: e.id);
      }
    }
  });

  test('equipment uses valid values with none exclusive', () {
    for (final e in all) {
      expect(e.requiredEquipment, isNotEmpty, reason: e.id);
      expect(WorkoutEquipment.values, containsAll(e.requiredEquipment),
          reason: e.id);
      if (e.requiredEquipment.contains(WorkoutEquipment.none)) {
        expect(e.requiredEquipment, {WorkoutEquipment.none}, reason: e.id);
      }
    }
    expect(ExerciseCatalog.byId('pushup_incline')!.requiredEquipment,
        {WorkoutEquipment.bench});
    expect(ExerciseCatalog.byId('pushup_decline')!.requiredEquipment,
        {WorkoutEquipment.bench});
    expect(ExerciseCatalog.byId('squat_chair')!.requiredEquipment,
        {WorkoutEquipment.chair});
    expect(ExerciseCatalog.byId('dip_chair')!.requiredEquipment,
        {WorkoutEquipment.chair});
  });

  test('progressions have valid reciprocal links and adjacent ranks', () {
    for (final e in all) {
      for (final id in [e.easierVariationId, e.harderVariationId]) {
        if (id != null) {
          expect(id, isNot(e.id), reason: e.id);
          expect(ExerciseCatalog.byId(id), isNotNull, reason: e.id);
          expect(ExerciseCatalog.byId(id)!.progressionFamilyId,
              e.progressionFamilyId,
              reason: e.id);
        }
      }
      if (e.easierVariationId != null) {
        final easier = ExerciseCatalog.byId(e.easierVariationId!)!;
        expect(easier.progressionRank, e.progressionRank - 1, reason: e.id);
        expect(easier.harderVariationId, e.id, reason: e.id);
      }
      if (e.harderVariationId != null) {
        final harder = ExerciseCatalog.byId(e.harderVariationId!)!;
        expect(harder.progressionRank, e.progressionRank + 1, reason: e.id);
        expect(harder.easierVariationId, e.id, reason: e.id);
      }
      if (e.progressionFamilyId == null) {
        expect(e.progressionRank, 0, reason: e.id);
        expect(e.easierVariationId, isNull, reason: e.id);
        expect(e.harderVariationId, isNull, reason: e.id);
      } else {
        expect(e.progressionRank, greaterThan(0), reason: e.id);
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
        'pushup_decline',
        'pushup_diamond'
      ],
      'squat': [
        'squat_chair',
        'squat_partial',
        'squat_bodyweight',
        'squat_tempo'
      ],
      'forearm_plank': ['plank_knee', 'plank_forearm'],
      'glute_bridge': ['bridge_glute', 'bridge_march', 'bridge_single_leg'],
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
      expect(members.map((e) => e.id).toList(), family.value,
          reason: family.key);
      expect(members.map((e) => e.progressionRank).toList(),
          List.generate(members.length, (i) => i + 1),
          reason: family.key);
      expect(members.first.easierVariationId, isNull, reason: family.key);
      expect(members.last.harderVariationId, isNull, reason: family.key);
    }
  });

  test('constraint metadata distinguishes jumping, standing and wrist load',
      () {
    for (final id in ['jumping_jacks', 'high_knees']) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.impactLevel, ImpactLevel.high, reason: id);
      expect(e.noiseLevel, NoiseLevel.loud, reason: id);
      expect(e.bodyPosition, ExercisePosition.standing, reason: id);
      expect(e.tags, contains('jumping'), reason: id);
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
      expect(e.impactLevel, ImpactLevel.low, reason: id);
      expect(e.noiseLevel, NoiseLevel.quiet, reason: id);
    }
    expect(ExerciseCatalog.byId('childs_pose')!.bodyPosition,
        ExercisePosition.floor);
    expect(ExerciseCatalog.byId('hamstring_stretch_standing')!.bodyPosition,
        ExercisePosition.standing);
  });

  test('core and mobility entries are not forced into progressions except hinge/pushup/glute', () {
    final allowedFamilies = {'pushup', 'squat', 'forearm_plank', 'glute_bridge', 'lunge', 'hinge'};
    for (final e in all) {
      if (e.progressionFamilyId == null) {
        expect(e.progressionRank, 0, reason: e.id);
      } else {
        expect(allowedFamilies, contains(e.progressionFamilyId), reason: e.id);
      }
    }
    // Specifically, new 3B-4 core/mobility should remain unlinked except allowed families
    final newCoreMobilityIds = [
      'plank_reach',
      'plank_side_knee',
      'russian_twist',
      'leg_raise',
      'flutter_kicks',
      'cobra_stretch',
      'figure_four_stretch',
    ];
    for (final id in newCoreMobilityIds) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.progressionFamilyId, isNull, reason: id);
    }
  });

  test('new hinge progression is correct if added', () {
    final hinge = ExerciseCatalog.byId('hip_hinge')!;
    final good = ExerciseCatalog.byId('good_morning')!;
    final single = ExerciseCatalog.byId('hip_hinge_single_leg')!;
    expect(hinge.progressionFamilyId, 'hinge');
    expect(good.progressionFamilyId, 'hinge');
    expect(single.progressionFamilyId, 'hinge');
    expect(hinge.progressionRank, 1);
    expect(good.progressionRank, 2);
    expect(single.progressionRank, 3);
    expect(hinge.easierVariationId, isNull);
    expect(hinge.harderVariationId, 'good_morning');
    expect(good.easierVariationId, 'hip_hinge');
    expect(good.harderVariationId, 'hip_hinge_single_leg');
    expect(single.easierVariationId, 'good_morning');
    expect(single.harderVariationId, isNull);
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
    final hammy = ExerciseCatalog.byId('hamstring_stretch_standing')!;
    expect(world.spaceRequirement.index > hammy.spaceRequirement.index, isTrue);
  });

  test('Diamond Push-Up progression if added', () {
    final diamond = ExerciseCatalog.byId('pushup_diamond')!;
    expect(diamond.progressionFamilyId, 'pushup');
    expect(diamond.progressionRank, 6);
    expect(diamond.easierVariationId, 'pushup_decline');
    expect(diamond.harderVariationId, isNull);
    final decline = ExerciseCatalog.byId('pushup_decline')!;
    expect(decline.harderVariationId, 'pushup_diamond');
    expect(decline.progressionRank, 5);
    // Not forced for Pike/Wide/Close
    for (final id in ['pushup_pike', 'pushup_close_grip', 'pushup_wide']) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.progressionFamilyId, isNull, reason: id);
    }
  });

  test('Glute Bridge progression update if added', () {
    final bridge = ExerciseCatalog.byId('bridge_glute')!;
    final march = ExerciseCatalog.byId('bridge_march')!;
    final single = ExerciseCatalog.byId('bridge_single_leg')!;
    expect(bridge.progressionFamilyId, 'glute_bridge');
    expect(march.progressionFamilyId, 'glute_bridge');
    expect(single.progressionFamilyId, 'glute_bridge');
    expect(bridge.progressionRank, 1);
    expect(march.progressionRank, 2);
    expect(single.progressionRank, 3);
    expect(bridge.easierVariationId, isNull);
    expect(bridge.harderVariationId, 'bridge_march');
    expect(march.easierVariationId, 'bridge_glute');
    expect(march.harderVariationId, 'bridge_single_leg');
    expect(single.easierVariationId, 'bridge_march');
    expect(single.harderVariationId, isNull);
    expect(bridge.difficulty.index < march.difficulty.index, isTrue);
    expect(march.difficulty.index < single.difficulty.index, isTrue);
  });

  test('hard-constraint audit: quiet/no-jumping candidates', () {
    for (final id in [
      'step_jack',
      'march_in_place',
      'shadow_boxing',
      'mountain_climber_standing'
    ]) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.noiseLevel, NoiseLevel.quiet, reason: id);
      expect(e.impactLevel, isIn([ImpactLevel.low, ImpactLevel.moderate]),
          reason: id);
      // Standing mountain climber must be standing with no wrist load
      if (id == 'mountain_climber_standing') {
        expect(e.bodyPosition, ExercisePosition.standing, reason: id);
        expect(e.wristLoad, JointLoad.none, reason: id);
        expect(e.tags, contains('no_floor'), reason: id);
      }
    }
    // Ensure these quiet candidates are indeed low impact
    expect(ExerciseCatalog.byId('step_jack')!.impactLevel, ImpactLevel.low);
    expect(
        ExerciseCatalog.byId('mountain_climber_standing')!.impactLevel,
        ImpactLevel.low);
  });

  test('hard-constraint audit: floor exercises not appearing as standing', () {
    for (final id in [
      'plank_forearm',
      'plank_knee',
      'plank_side',
      'pushup_standard',
      'pushup_diamond',
      'dead_bug',
      'bridge_glute',
      'mountain_climbers',
      'plank_up_down',
      'plank_reach'
    ]) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.bodyPosition, isNot(ExercisePosition.standing), reason: id);
      expect(e.bodyPosition, ExercisePosition.floor, reason: id);
    }
  });

  test('hard-constraint audit: wrist-heavy exercises have meaningful wrist load',
      () {
    for (final id in [
      'pushup_standard',
      'pushup_diamond',
      'pushup_pike',
      'pushup_wide',
      'shoulder_tap',
      'plank_up_down',
      'dip_chair',
      'mountain_climbers',
      'plank_reach'
    ]) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.wristLoad.index >= JointLoad.moderate.index, isTrue,
          reason: id);
    }
    // Chair dip specifically requires chair and significant wrist/shoulder
    final dip = ExerciseCatalog.byId('dip_chair')!;
    expect(dip.requiredEquipment, {WorkoutEquipment.chair});
    expect(dip.wristLoad, JointLoad.high);
    expect(dip.primaryMuscles, contains(MuscleGroup.triceps));
  });

  test('hard-constraint audit: knee-heavy exercises not negligible', () {
    for (final id in [
      'lunge_forward',
      'squat_split_bulgarian',
      'lunge_lateral',
      'lunge_curtsy',
      'squat_sumo',
      'squat_pulse'
    ]) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.kneeLoad.index >= JointLoad.moderate.index, isTrue,
          reason: id);
      expect(e.kneeLoad, isNot(JointLoad.none), reason: id);
      expect(e.kneeLoad, isNot(JointLoad.low), reason: id);
    }
    expect(ExerciseCatalog.byId('squat_split_bulgarian')!.kneeLoad,
        JointLoad.high);
  });

  test('hard-constraint audit: low-impact burpee and standing mountain climber',
      () {
    final burpee = ExerciseCatalog.byId('burpee_low_impact')!;
    expect(burpee.impactLevel, isNot(ImpactLevel.high), reason: 'burpee');
    expect(burpee.tags, contains('no_jumping'), reason: 'burpee');
    expect(burpee.spaceRequirement, SpaceRequirement.medium, reason: 'burpee');
    expect(burpee.wristLoad.index >= JointLoad.moderate.index, isTrue,
        reason: 'burpee');
    final standing = ExerciseCatalog.byId('mountain_climber_standing')!;
    expect(standing.bodyPosition, ExercisePosition.standing);
    expect(standing.impactLevel, ImpactLevel.low);
    expect(standing.noiseLevel, NoiseLevel.quiet);
    expect(standing.wristLoad, JointLoad.none);
  });

  test('hard-constraint audit: lateral/curtsy lunge space and knee', () {
    for (final id in ['lunge_lateral', 'lunge_curtsy']) {
      final e = ExerciseCatalog.byId(id)!;
      expect(e.spaceRequirement, SpaceRequirement.medium, reason: id);
      expect(e.kneeLoad.index >= JointLoad.moderate.index, isTrue, reason: id);
      expect(e.tags, contains('balance_demand'), reason: id);
    }
    final fig = ExerciseCatalog.byId('figure_four_stretch')!;
    expect(fig.impactLevel, ImpactLevel.low);
    expect(fig.noiseLevel, NoiseLevel.quiet);
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
