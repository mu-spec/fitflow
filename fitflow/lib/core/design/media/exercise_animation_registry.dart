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
  };

  static String? assetFor(String exerciseId) => assets[exerciseId];
}
