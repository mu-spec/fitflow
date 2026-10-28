/// Exact movement mappings only; unregistered movements retain photographs.
/// Military Push Ups.json is byte-identical to the existing pushup.json.
/// Step-Up and Jump Squat have no catalog entries and are deferred.
abstract final class ExerciseAnimationRegistry {
  static const assets = <String, String>{
    'squat_bodyweight': 'assets/animations/bodyweight_squat.json',
    'pushup_incline': 'assets/animations/pushup_incline.json',
    'pushup_decline': 'assets/animations/pushup_decline.json',
    'pushup_knee': 'assets/animations/knee_pushup.json',
    'pushup_standard': 'assets/animations/pushup.json',
    'cobra_stretch': 'assets/animations/cobra.json',
    'lunge_forward': 'assets/animations/lunge.json',
    'pushup_pike': 'assets/animations/vital/pushup_pike.webp',
    'squat_goblet_dumbbell':
        'assets/animations/vital/squat_goblet_dumbbell.webp',

    // CC0 Open Exercise Figures and locally authored/adapted figures rendered
    // with its rig. Exact IDs only; other movements retain photographs.
    'pushup_wall': 'assets/animations/open_exercise_figures/pushup_wall.webp',
    'squat_tempo': 'assets/animations/open_exercise_figures/squat_tempo.webp',
    'squat_pulse': 'assets/animations/open_exercise_figures/squat_pulse.webp',
    'bird_dog': 'assets/animations/open_exercise_figures/bird_dog.webp',
    'donkey_kick': 'assets/animations/open_exercise_figures/donkey_kick.webp',
    'lunge_reverse':
        'assets/animations/open_exercise_figures/lunge_reverse.webp',
    'good_morning': 'assets/animations/open_exercise_figures/good_morning.webp',
    'hip_hinge': 'assets/animations/open_exercise_figures/hip_hinge.webp',
    'hip_hinge_single_leg':
        'assets/animations/open_exercise_figures/hip_hinge_single_leg.webp',
    'high_knees': 'assets/animations/open_exercise_figures/high_knees.webp',
    'standing_knee_raise':
        'assets/animations/open_exercise_figures/standing_knee_raise.webp',
    'plank_reach': 'assets/animations/open_exercise_figures/plank_reach.webp',
    'march_in_place':
        'assets/animations/open_exercise_figures/march_in_place.webp',
    'mountain_climber_standing':
        'assets/animations/open_exercise_figures/mountain_climber_standing.webp',
    'squat_partial':
        'assets/animations/open_exercise_figures/squat_partial.webp',
    'dead_bug': 'assets/animations/open_exercise_figures/dead_bug.webp',
    'bridge_glute': 'assets/animations/open_exercise_figures/bridge_glute.webp',
    'bridge_single_leg':
        'assets/animations/open_exercise_figures/bridge_single_leg.webp',
    'jumping_jacks':
        'assets/animations/open_exercise_figures/jumping_jacks.webp',
    'squat_split_static':
        'assets/animations/open_exercise_figures/squat_split_static.webp',
    'calf_raise': 'assets/animations/open_exercise_figures/calf_raise.webp',
    'reverse_crunch':
        'assets/animations/open_exercise_figures/reverse_crunch.webp',
    'mountain_climbers':
        'assets/animations/open_exercise_figures/mountain_climbers.webp',
    'bridge_march': 'assets/animations/open_exercise_figures/bridge_march.webp',
    'flutter_kicks':
        'assets/animations/open_exercise_figures/flutter_kicks.webp',
    'leg_raise': 'assets/animations/open_exercise_figures/leg_raise.webp',
    'fast_feet': 'assets/animations/open_exercise_figures/fast_feet.webp',
    'row_bent_over_dumbbell':
        'assets/animations/open_exercise_figures/row_bent_over_dumbbell.webp',
    'squat_goblet_kettlebell':
        'assets/animations/open_exercise_figures/squat_goblet_kettlebell.webp',
  };

  static String? assetFor(String exerciseId) => assets[exerciseId];
}
