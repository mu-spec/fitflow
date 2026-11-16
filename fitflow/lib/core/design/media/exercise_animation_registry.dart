/// Launch catalog of exercise-specific vector demonstrations.
/// The five reference motions are preserved; adapted motion sources live in
/// tools/orange_character and tools/squat_sample. Playback never drives the
/// workout timer. The squat variants, march, calf raise, arm circles and step
/// jack use approved front-view artwork. Wall/knee push-ups and both planks use
/// approved adaptations of the original Military Push Ups character.
abstract final class ExerciseAnimationRegistry {
  static const assets = <String, String>{
    'pushup_wall': 'assets/animations/launch25/pushup_wall.json',
    'pushup_knee': 'assets/animations/launch25/pushup_knee.json',
    'pushup_standard': 'assets/animations/launch25/pushup_standard.json',
    'squat_chair': 'assets/animations/launch25/squat_chair.json',
    'squat_partial': 'assets/animations/launch25/squat_partial.json',
    'squat_bodyweight': 'assets/animations/launch25/squat_bodyweight.json',
    'dead_bug': 'assets/animations/launch25/dead_bug.json',
    'plank_knee': 'assets/animations/launch25/plank_knee.json',
    'plank_forearm': 'assets/animations/launch25/plank_forearm.json',
    'bridge_glute': 'assets/animations/launch25/bridge_glute.json',
    'march_in_place': 'assets/animations/launch25/march_in_place.json',
    'jumping_jacks': 'assets/animations/launch25/jumping_jacks.json',
    'row_doorway': 'assets/animations/launch25/row_doorway.json',
    'reverse_snow_angel': 'assets/animations/launch25/reverse_snow_angel.json',
    'lunge_reverse': 'assets/animations/launch25/lunge_reverse.json',
    'lunge_forward': 'assets/animations/launch25/lunge_forward.json',
    'calf_raise': 'assets/animations/launch25/calf_raise.json',
    'bird_dog': 'assets/animations/launch25/bird_dog.json',
    'reverse_crunch': 'assets/animations/launch25/reverse_crunch.json',
    'cat_cow': 'assets/animations/launch25/cat_cow.json',
    'hip_hinge': 'assets/animations/launch25/hip_hinge.json',
    'pushup_pike': 'assets/animations/launch25/pushup_pike.json',
    'step_jack': 'assets/animations/launch25/step_jack.json',
    'arm_circles': 'assets/animations/launch25/arm_circles.json',
    'cobra_stretch': 'assets/animations/launch25/cobra_stretch.json',
  };
  static String? assetFor(String id) => assets[id];

  /// Approved Military Push Ups: frames 2..69 at 25 fps, one full repetition.
  /// These are display timings only, never workout prescriptions or timers.
  static const referenceRepetition = Duration(milliseconds: 2680);
  static const repetitionsPerLoop = <String, int>{
    'pushup_wall': 1,
    'pushup_knee': 1,
    'pushup_standard': 1,
    'squat_chair': 1,
    'squat_partial': 1,
    'squat_bodyweight': 1,
    'dead_bug': 2,
    'plank_knee': 0,
    'plank_forearm': 0,
    'bridge_glute': 1,
    'march_in_place': 2,
    'jumping_jacks': 1,
    'row_doorway': 1,
    'reverse_snow_angel': 1,
    'lunge_reverse': 2,
    'lunge_forward': 2,
    'calf_raise': 1,
    'bird_dog': 2,
    'reverse_crunch': 1,
    'cat_cow': 1,
    'hip_hinge': 1,
    'pushup_pike': 1,
    'step_jack': 2,
    // Ten forward circles followed by ten backward circles in the approved art.
    'arm_circles': 20,
    'cobra_stretch': 1,
  };

  static Duration playbackDuration(String id, Duration sourceDuration) {
    final repetitions = repetitionsPerLoop[id];
    if (repetitions == null || repetitions == 0) return sourceDuration;
    return referenceRepetition * repetitions;
  }

  static String? posterFor(String id) => assets.containsKey(id)
      ? 'assets/animations/launch25/${id}_poster.png'
      : null;
}
