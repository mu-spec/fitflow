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
  ];

  static final Map<String, ExerciseMediaSpec> _byId = Map.unmodifiable({
    for (final entry in entries) entry.exerciseId: entry,
  });

  /// Exact, case-sensitive ID lookup. Unknown IDs never borrow another photo.
  static ExerciseMediaSpec? lookup(String exerciseId) => _byId[exerciseId];
}
