import 'package:fitflow/core/design/media/exercise_media_spec.dart';

/// Expected production assets; the registry is not proof of asset delivery.
/// Explicit ID allowlist, independent of names and exercise-domain metadata.
abstract final class ExerciseMediaRegistry {
  static const List<ExerciseMediaSpec> entries = [
    ExerciseMediaSpec(
      exerciseId: 'pushup_wall',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_wall.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_wall.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_incline',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_incline.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_incline.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_knee',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_knee.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_knee.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_standard',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_standard.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_standard.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_decline',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_decline.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_decline.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_chair',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_chair.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_chair.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_partial',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_partial.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_partial.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_bodyweight',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_bodyweight.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_bodyweight.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_tempo',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_tempo.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_tempo.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'wall_sit',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/wall_sit.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/wall_sit.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'dead_bug',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/dead_bug.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/dead_bug.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_knee',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_knee.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_knee.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_forearm',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_forearm.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_forearm.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_side',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_side.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_side.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'hollow_hold',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/hollow_hold.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/hollow_hold.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'bridge_glute',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/bridge_glute.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/bridge_glute.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'bridge_single_leg',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/bridge_single_leg.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/bridge_single_leg.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'march_in_place',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/march_in_place.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/march_in_place.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'high_knees',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/high_knees.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/high_knees.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'jumping_jacks',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/jumping_jacks.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/jumping_jacks.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'row_doorway',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/row_doorway.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/row_doorway.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'row_towel',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/row_towel.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/row_towel.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'reverse_snow_angel',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/reverse_snow_angel.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/reverse_snow_angel.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'superman',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/superman.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/superman.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'prone_y_raise',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/prone_y_raise.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/prone_y_raise.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'lunge_reverse',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/lunge_reverse.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/lunge_reverse.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'lunge_forward',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/lunge_forward.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/lunge_forward.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_split_static',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_split_static.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_split_static.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_split_bulgarian',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_split_bulgarian.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_split_bulgarian.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'calf_raise',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/calf_raise.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/calf_raise.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'bird_dog',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/bird_dog.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/bird_dog.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'bicycle_crunch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/bicycle_crunch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/bicycle_crunch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'heel_taps',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/heel_taps.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/heel_taps.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'reverse_crunch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/reverse_crunch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/reverse_crunch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'mountain_climbers',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/mountain_climbers.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/mountain_climbers.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'cat_cow',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/cat_cow.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/cat_cow.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'childs_pose',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/childs_pose.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/childs_pose.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'hip_flexor_stretch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/hip_flexor_stretch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/hip_flexor_stretch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'hamstring_stretch_standing',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/hamstring_stretch_standing.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/hamstring_stretch_standing.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'thoracic_rotation',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/thoracic_rotation.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/thoracic_rotation.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'good_morning',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/good_morning.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/good_morning.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'hip_hinge',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/hip_hinge.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/hip_hinge.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'hip_hinge_single_leg',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/hip_hinge_single_leg.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/hip_hinge_single_leg.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'donkey_kick',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/donkey_kick.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/donkey_kick.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'fire_hydrant',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/fire_hydrant.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/fire_hydrant.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_pike',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_pike.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_pike.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_close_grip',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_close_grip.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_close_grip.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_wide',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_wide.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_wide.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'shoulder_tap',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/shoulder_tap.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/shoulder_tap.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_up_down',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_up_down.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_up_down.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'step_jack',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/step_jack.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/step_jack.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'butt_kicks',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/butt_kicks.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/butt_kicks.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'skater_step',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/skater_step.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/skater_step.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_knee_drive',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_knee_drive.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_knee_drive.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'shadow_boxing',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/shadow_boxing.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/shadow_boxing.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'single_leg_stand',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/single_leg_stand.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/single_leg_stand.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'standing_knee_raise',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/standing_knee_raise.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/standing_knee_raise.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'ankle_circles',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/ankle_circles.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/ankle_circles.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'arm_circles',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/arm_circles.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/arm_circles.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'world_greatest_stretch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/world_greatest_stretch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/world_greatest_stretch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_diamond',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_diamond.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_diamond.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pushup_down_dog',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pushup_down_dog.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pushup_down_dog.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'wall_shoulder_press',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/wall_shoulder_press.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/wall_shoulder_press.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'dip_chair',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/dip_chair.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/dip_chair.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_sumo',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_sumo.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_sumo.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_pulse',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_pulse.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_pulse.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'lunge_curtsy',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/lunge_curtsy.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/lunge_curtsy.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'lunge_lateral',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/lunge_lateral.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/lunge_lateral.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'bridge_march',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/bridge_march.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/bridge_march.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'frog_pump',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/frog_pump.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/frog_pump.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_reach',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_reach.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_reach.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'plank_side_knee',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/plank_side_knee.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/plank_side_knee.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'russian_twist',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/russian_twist.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/russian_twist.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'leg_raise',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/leg_raise.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/leg_raise.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'flutter_kicks',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/flutter_kicks.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/flutter_kicks.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'burpee_low_impact',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/burpee_low_impact.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/burpee_low_impact.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'fast_feet',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/fast_feet.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/fast_feet.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'mountain_climber_standing',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/mountain_climber_standing.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/mountain_climber_standing.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'cobra_stretch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/cobra_stretch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/cobra_stretch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'figure_four_stretch',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/figure_four_stretch.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/figure_four_stretch.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'pull_apart_resistance_band',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/pull_apart_resistance_band.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/pull_apart_resistance_band.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'row_resistance_band',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/row_resistance_band.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/row_resistance_band.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_goblet_dumbbell',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_goblet_dumbbell.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_goblet_dumbbell.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'row_bent_over_dumbbell',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/row_bent_over_dumbbell.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/row_bent_over_dumbbell.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'deadlift_kettlebell',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/deadlift_kettlebell.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/deadlift_kettlebell.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'squat_goblet_kettlebell',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/squat_goblet_kettlebell.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/squat_goblet_kettlebell.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'dead_hang_pullup_bar',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/dead_hang_pullup_bar.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/dead_hang_pullup_bar.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ExerciseMediaSpec(
      exerciseId: 'scapular_pullup',
      thumbnail: FitFlowMediaAsset(
        path: 'assets/images/exercises/thumb/scapular_pullup.webp',
        pixelWidth: 256,
        pixelHeight: 256,
      ),
      hero: FitFlowMediaAsset(
        path: 'assets/images/exercises/hero/scapular_pullup.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
  ];

  static final Map<String, ExerciseMediaSpec> _byId = Map.unmodifiable({
    for (final entry in entries) entry.exerciseId: entry,
  });

  /// Exact, case-sensitive ID lookup. Unknown IDs never borrow another photo.
  static ExerciseMediaSpec? lookup(String exerciseId) => _byId[exerciseId];
}
