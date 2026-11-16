# Wall Push-Up and Knee Push-Up review

Status: both previews approved and integrated on 14 November 2026, including
the fuller knee-leg revision. Fourteen of 25 exercises are now approved and
integrated. No APK built.

Both candidates reuse Military Push Ups artwork by Dinh Bui Xuan under the
bundled Lottie Simple License. The head, torso, arms, hands, shoes and clothing
retain the original contours. The knee variant now uses continuous thigh/calf
paths to avoid the blocky overlap of rotated straight-leg shapes. The source
file and installed catalog remain unchanged.

- Knee Push-Up: knees and palms stay stationary; lower legs are raised behind
  the knees. The torso moves as a unit, with elbows bending back. Corrected
  the far knee so its position no longer follows the torso rotation. Following
  the latest review, rounded the supported knee and inner crease while keeping
  its lower contour fixed on the mat throughout the repetition.
  The subsequent revision restores a fuller leg silhouette: about 38 source
  units across the thigh, broader calves, and a gradual taper into the shoes.
  The bottom of the knee stays at the same supported height.
- Wall Push-Up: fixed palms against the wall and planted feet; elbows bend
  as the body leans toward the wall. Adjusted shoe orientation to a standing
  position and preserved perspective separation between near and far limbs.
  Following the latest review, attached the far shorts panel to the same pelvis
  transform as the near panel, removing the projecting rectangular flap.
- Both previews run one repetition in 2.68 seconds, matching the approved
  push-up's average playback cadence. Each has a fixed full-body camera.

## Required checks only

The builder verifies unchanged source paths except the explicitly revised knee
skin contours, zero drift in authored support landmarks, and unchanged hashes
for all installed JSON/poster pairs.
The targeted Flutter test `tools/squat_sample/render_press_test.dart` passed,
rendering 40 frames per candidate through a complete loop plus 720px posters.
Start, middle, bottom and return poses were visually inspected. These are
technical/visual checks, not clinical validation of exercise form.

The revised pair also passed this targeted render. The broad app test suite
was not rerun for this preview batch.
For the fuller-leg revision, only the knee was rendered using
`--dart-define=PRESS_PREVIEW=pushup_knee` (40 frames plus the poster).
The approved wall JSON hash remained
`6E3E04424DF5A769CE572162F29E99C01E1C84B76A3AFB59A36196313F8DE5F2`.

Artifacts:
- `build/press-pair-review/pushup_knee-revised.gif`
- `build/press-pair-review/pushup_knee-fuller-legs.gif` (latest review copy)
- `build/press-pair-review/pushup_wall-revised.gif`
- `build/press-pair-review/verification.json`

Authoring: `tools/squat_sample/build_press_review.py`.
Packaging: `tools/squat_sample/package_press_review.py`.

Movement references considered alongside the app's catalog instructions:
- https://www.mayoclinic.org/healthy-lifestyle/fitness/multimedia/modified-pushup/vid-20084674
- https://www.nhs.uk/live-well/exercise/strength-exercises/

Publication used `tools/squat_sample/publish_press_pair.py`. Both installed JSON
files retain the exact reviewed motion data, and posters are byte-identical to
the reviewed renders. Backups are in `build/press-pair-review/before-publish`.
Hash checks confirmed that all other 23 JSON/poster pairs were unchanged.
The three tests in `test/launch25_animation_test.dart` passed after integration:
asset/poster loading, unchanged original push-up, and pause/reduced-motion use.

Next review batch: Knee Plank and Forearm Plank. Eleven refinements remain,
including those two previews.
