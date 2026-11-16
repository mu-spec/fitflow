# Arm Circles and Step Jack review

Status: owner-approved and integrated on 14 November 2026. No APK built.
Twelve of 25 animations are approved and integrated. Thirteen adaptations
remain to refine and review.

## Character and movements

Both use the approved front-view head, torso and clothing contours, with
the original Jumping Jacks arm/hand artwork by Dinh Bui Xuan under the
bundled Lottie Simple License. The source's arm contours, shoulder position
and wrist connections are sampled together as each arm rises. Rotating only
the original down-pose artwork produced an angular shoulder junction; that
initial candidate was corrected before delivery.

Arm Circles: thirty-second loop; arms near shoulder height, original hands
attached at the wrists, modest circles increasing in size and reversing at
15 seconds. Front-view depth is represented with slight longitudinal
foreshortening, preserving limb width. It is a projected circle, rather than
a side-view depiction of the complete forward/backward depth. Feet stay fixed.

Step Jack: eight-second loop; one foot steps sideways and returns as both
arms sweep up and down, then the opposite side repeats. A small foot lift
occurs only during that foot's travel. The support foot stays grounded;
the moving foot lands flat at the outer endpoint. No jumping is authored.
Hands remain separated overhead rather than clapping or crossing.

## Verification

- Authoring asserts the approved torso contours remain identical.
- Hash checks confirm all installed animation/poster pairs are unchanged.
- Flutter rendered the complete loops at 12 fps (360 + 96 frames), including
  embedded shoe images. The rendering test passed.
- Inspected neutral, intermediate, overhead, left/right step and circular
  arm poses. This is visual/technical QA, not clinical validation.

Previews: `build/warmup-pair-review/arm_circles-review.gif` and
`build/warmup-pair-review/step_jack-review.gif`.
Authoring: `tools/squat_sample/build_warmup_review.py`.
Renderer: `tools/squat_sample/render_warmup_test.dart`.
Packaging: `tools/squat_sample/package_warmup_review.py`.

The standing-pair builder was given a main guard so its shared transformation
helpers can be imported without regenerating earlier reviewed candidates.

Movement references considered alongside the app's catalog instructions:
- https://eat-move-save.extension.illinois.edu/move/exercise/standingseated-arm-circles
- https://www.puregym.com/exercises/cardio/jumping-jack/step-jacks/

## Integration and shared demonstration pacing

The owner approved both previews and requested the push-up animation's speed
throughout the app. Published both JSON compositions and their 720px posters.
Motion data matches the approved previews; only names and approval metadata
changed. Backups and a pre-publish hash manifest are in
`build/warmup-pair-review/before-publish`. All other 23 asset/poster pairs were
unchanged. The batch generator now preserves these approved assets too.

The shared `ExerciseAnimation` widget now owns a separate visual animation
controller. The registry uses the untouched push-up's 67 frames at 25 fps:
2.68 seconds per full demonstration repetition. Alternating two-movement loops
take 5.36 seconds, and the twenty-circle arm sequence takes 53.6 seconds.
This normalizes average cadence while preserving authored easing and holds;
it does not make all limb velocities or individual phases identical. Plank
holds retain their source timing and remain held poses.

This is a presentation setting, not exercise tempo advice. Workout durations,
rep counts, rest periods, coach/music behavior and timers are unchanged. The
same playback policy covers the library, thumbnails, details, preview and
player. Pausing retains the current frame; backgrounding stops playback;
offscreen/reduced-motion removal disposes the visual ticker.

Validation: all 98 focused animation/player tests passed. Checks include all
25 offline assets, hero/thumbnail playback durations, measured progress for
single-rep, alternating and multi-circle sequences, pause/resume, background
behavior, reduced motion and player layouts. The reference push-up composition
is still byte-identical to its original. No APK built.

Integration script: `tools/squat_sample/publish_warmup_pair.py`.
