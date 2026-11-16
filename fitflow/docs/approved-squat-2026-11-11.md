# Approved Bodyweight Squat — 11 November 2026

The owner approved the front-facing squat movement, then requested a corrected
arm position. The final approved version holds both hands in front of the chest
with bent elbows. The leg and hip movement is unchanged from the accepted sample.

## Integration

- Replaced only `assets/animations/launch25/squat_bodyweight.json` and its poster.
- Uses the original Jumping Jacks head and torso vectors; limbs are locally
  reposed, with front-view thigh foreshortening and a revised shorts seam.
- The shared registry serves the asset to exercise details, thumbnails, preview,
  skill paths and the workout player. The 720px poster matches the new character.
- The other 24 animation compositions and posters are byte-identical to their
  pre-publish versions. The five original approved motions remain untouched.
- The batch authoring script preserves this published squat instead of recreating
  the rejected side-view candidate.

## Source and review

- Authoring: `tools/squat_sample/build_front_sample.py`.
- Review rendering: `tools/squat_sample/render_front_test.dart`.
- Approved preview: `build/front-squat-review/squat-arms-comparison-v2.gif`.
- Pre-publish backup and hashes: `build/front-squat-review/before-publish`.
- Attribution is retained in the asset metadata and launch catalog notice.

## Validation

Rendered 24 points in the loop, including decoded shoe artwork. Checked standing,
midway and bottom poses visually. The existing 94 focused animation/player tests
passed, covering asset loading, hero/thumbnail rendering, reduced-motion posters,
pause/resume and layout behavior. This is visual acceptance by the app owner;
these checks do not constitute a professional exercise-form assessment.
