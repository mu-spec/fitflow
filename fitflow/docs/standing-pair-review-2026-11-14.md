# March in Place and Calf Raise review

Status: owner approved and integrated on 14 November 2026. No APK built.
The user confirmed the previously integrated Partial Squat and Chair Sit-to-Stand
animations work correctly on their device. With this pair integrated, ten of
25 are approved/integrated; 15 adaptations still await refinement and review.

## Artwork and motion

- Preserve the approved front-view head/torso artwork from the squat, originally
  adapted from Jumping Jacks by Dinh Bui Xuan (Lottie Simple License).
- Reuse the original limb contours and embedded shoe artwork.
- March: four-second loop, alternating comfortable knee lifts with opposite bent
  arm movement. At least one foot remains grounded in the authored poses.
- Calf raise: five-second loop, relaxed arms, heel rise, brief hold, slow lowering.
  This front-view projection makes heel height less apparent than a side view;
  toe contact is represented by an anchored shoe projection.
- Normalize source layer time stretch so movement occupies the complete loop.
- Separate animated position axes to avoid zero-length spatial paths at holds
  in Flutter's Lottie renderer. Place the floor shadow behind the shoes.

## Validation and review files

The builder verifies unchanged approved torso shapes and unchanged production
JSON/poster hashes. The Flutter rendering test passed for both complete loops,
exporting 48 marching frames and 60 calf-raise frames at 12 fps. Representative
poses were visually inspected for character continuity and hand/foot placement.
This is an animation review, not clinical validation of exercise technique.

- `build/standing-pair-review/march_in_place-review.gif`
- `build/standing-pair-review/calf_raise-review.gif`
- `build/standing-pair-review/march_in_place-poses.png`
- `build/standing-pair-review/calf_raise-poses.png`

Authoring: `tools/squat_sample/build_standing_review.py`.
Rendering: `tools/squat_sample/render_standing_test.dart`.
Packaging: `tools/squat_sample/package_standing_review.py`.

The owner approved the corrected hand positions and authorized integration.

## Hand-position review

The user approved the character appearance and requested a hand-position check.
Marching previously brought both hands close together at the abdomen during
the neutral phase. Adjusted the elbow/wrist trajectory outward so each hand
stays on its own side, with relaxed fingers aligned with the forearm and the
opposite arm advancing as a knee lifts. Added per-pose assertions for hand
clearance from the centre line and wrists below the shoulders. Kept the
approved character artwork unchanged.

Calf-raise arms remain relaxed alongside the thighs throughout the rise,
hold and lowering phases. This depicts the app's unassisted, no-equipment
variant, rather than a supported rehabilitation variant.

Re-rendered both complete loops successfully and visually inspected the
neutral, left/right lift, raised-heel and lowering poses. App assets remain
unchanged; no APK built.

Reference: NHS warm-up guidance describes rhythmic marching arm movement,
bent elbows and relaxed hands:
https://www.nhs.uk/live-well/exercise/how-to-warm-up-before-exercising/
AAOS describes chair/wall support for its supported heel-raise variant:
https://www.orthoinfo.org/recovery/foot-and-ankle-conditioning-program/

## Integration

Published both reviewed compositions and their 720px posters to
`assets/animations/launch25`. The existing shared registry serves the new
assets in exercise details, library thumbnails, workout previews, the player
and skill paths. Only names and approval metadata differ from the reviewed
JSON; the motion and artwork are identical. Hash checks confirmed that the
other 23 animation/poster pairs were unchanged. Backups and the pre-publish
manifest are in `build/standing-pair-review/before-publish`.

Updated `tools/orange_character/build_launch25.py` to preserve both approved
assets instead of regenerating their superseded versions. Updated attribution.
All 94 focused animation/player tests passed, including pause, reduced motion,
offline asset loading, hero/thumbnail rendering and player layout checks.
No APK was built. Integration script: `tools/squat_sample/publish_standing_pair.py`.
