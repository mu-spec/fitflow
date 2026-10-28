# Exercise demonstration integration

## Current coverage

This is a partial implementation of the requested approximately 80 exercise demonstrations. The catalog has 88 exercises. The existing exact-ID animation registry now covers **38** of them: nine existing animations plus **29 newly bundled Open Exercise Figures**. The other **50** exercises continue to use their existing photographs; they have not been assigned look-alike animations. Some remaining entries are static holds or stretches, for which a continuously moving loop can be misleading.

The new animations are available in the shared exercise image component used by the library, exercise details and workout player. The existing custom March in Place player pilot remains in use in the player; the newly registered march figure is used by other shared-media surfaces. Each new WebP is bundled with the app and plays offline. Workout prescriptions, reps and timers are not driven by the animations.

The implementation honors the existing reduced-motion, app-lifecycle, visibility, pause and photo-fallback behavior. A missing or disabled demonstration falls back to the registered photograph, and a missing photograph falls back to the existing neutral placeholder.

## New figure IDs

`squat_partial`, `dead_bug`, `bridge_glute`, `bridge_single_leg`, `jumping_jacks`, `squat_split_static`, `calf_raise`, `reverse_crunch`, `mountain_climbers`, `bridge_march`, `flutter_kicks`, `leg_raise`, `fast_feet`, `row_bent_over_dumbbell`, `squat_goblet_kettlebell`, `pushup_wall`, `squat_tempo`, `squat_pulse`, `bird_dog`, `donkey_kick`, `lunge_reverse`, `good_morning`, `hip_hinge`, `hip_hinge_single_leg`, `high_knees`, `standing_knee_raise`, `plank_reach`, `march_in_place`, and `mountain_climber_standing`.

## Remaining photograph-only IDs

`squat_chair`, `wall_sit`, `plank_knee`, `plank_forearm`, `plank_side`, `hollow_hold`, `row_doorway`, `row_towel`, `reverse_snow_angel`, `superman`, `prone_y_raise`, `squat_split_bulgarian`, `bicycle_crunch`, `heel_taps`, `cat_cow`, `childs_pose`, `hip_flexor_stretch`, `hamstring_stretch_standing`, `thoracic_rotation`, `fire_hydrant`, `pushup_close_grip`, `pushup_wide`, `shoulder_tap`, `plank_up_down`, `step_jack`, `butt_kicks`, `skater_step`, `squat_knee_drive`, `shadow_boxing`, `single_leg_stand`, `ankle_circles`, `arm_circles`, `world_greatest_stretch`, `pushup_diamond`, `pushup_down_dog`, `wall_shoulder_press`, `dip_chair`, `squat_sumo`, `lunge_curtsy`, `lunge_lateral`, `frog_pump`, `plank_side_knee`, `russian_twist`, `burpee_low_impact`, `figure_four_stretch`, `pull_apart_resistance_band`, `row_resistance_band`, `deadlift_kettlebell`, `dead_hang_pullup_bar`, and `scapular_pullup`.

## Form and rights

The figures were compared visually with the catalog descriptions, and some were adapted or authored using the upstream rig. **They have not been reviewed by a qualified exercise professional and should not be represented as professionally validated or guaranteed injury-safe.** A professional should review the animations and written instructions together before relying on them for coaching. Stylized figures cannot show every relevant form cue, grip, depth, joint angle or individual modification.

The new figures are derived from the CC0 Open Exercise Figures project; see `assets/animations/open_exercise_figures/NOTICE.md` and `LICENSE-CC0.txt` for the source, revision, adaptations and limitations. The pre-existing Vital animations are subject to their separate terms documented in `assets/animations/vital/NOTICE.md`; do not assume their individual media files are CC0. Reproduction instructions for the locally generated figures are in `tools/open_exercise_figures/README.md`.

## Run and verify

From the app directory, with Flutter and an Android SDK/device or emulator installed:

```sh
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/open_exercise_figures_test.dart test/exercise_animation_test.dart test/vital_exercise_animation_test.dart test/player_animation_pilot_test.dart
flutter run
```

The focused tests cover bundled animation codecs, shared media, fallbacks, reduced motion, representative timed and rep-based player behavior, pauses and lifecycle. They do not replace visual review on a physical device or expert form review. Some older screen tests use reduced motion so their UI transition checks do not wait indefinitely for a looping demonstration.

The project checkout intentionally omits the original `media_inbox/` directory (the app's already-optimized packaged media is present). It can be recovered separately from the selected GitHub branch if needed.
