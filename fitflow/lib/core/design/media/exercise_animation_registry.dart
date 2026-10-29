/// Exact movement mappings only; unregistered movements retain photographs.
///
/// Launch 25 — animated (5):
///   * `jumping_jacks` — original Jumping Jack animation, preserved byte-for-byte.
///   * `squat_bodyweight` — Danielflefil, Bodyweight Squats.gif, Wikimedia Commons,
///     CC BY-SA 4.0; resized to 360 × 360 looped GIF.
///   * `pushup_pike` — Danielflefil, Pike Push Ups.gif, Wikimedia Commons,
///     CC BY-SA 4.0; resized to 360 × 360 looped GIF.
///   * `lunge_forward` — Dinh Bui Xuan, "Free Lunge Animation", LottieFiles,
///     original dotLottie under the Lottie Simple License.
///   * `reverse_crunch` — Dinh Bui Xuan, "Free Reverse Crunches", LottieFiles,
///     original dotLottie under the Lottie Simple License.
///
/// All other exercises (20 still + 63 hidden for launch) use labeled still
/// photographs from ExerciseMediaRegistry. Illustrations never determine
/// prescriptions or the workout clock; animations pause when hidden, on pause,
/// on lifecycle suspend and under reduced motion.
abstract final class ExerciseAnimationRegistry {
  static const assets = <String, String>{
    // Original animation preserved byte-for-byte.
    'jumping_jacks': 'assets/animations/illustrated_athletes/jumping_jacks.json',

    // Reviewed real-person demonstrations (CC BY-SA 4.0; share-alike applies).
    'squat_bodyweight': 'assets/animations/real_people/squat_bodyweight.gif',
    'pushup_pike': 'assets/animations/real_people/pushup_pike.gif',

    // Reviewed Dinh Bui Xuan originals (Lottie Simple License).
    'lunge_forward': 'assets/animations/real_people/lunge_forward.lottie',
    'reverse_crunch': 'assets/animations/real_people/reverse_crunch.lottie',
  };

  static String? assetFor(String exerciseId) => assets[exerciseId];
}
