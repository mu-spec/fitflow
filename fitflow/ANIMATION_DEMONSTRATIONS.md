# Temporary exercise media: GIF plus still references

The project is using the user's chosen temporary approach while they consider a
paid exercise pack later. **This is not an 88-GIF library.**

## Current default selection

| FitFlow exercise | Media in app | Status |
| --- | --- | --- |
| Bodyweight Squat (`squat_bodyweight`) | Offline real-person GIF, 360 × 360, 68 frames | The user approved the visual style. This is a prototype, not a professional form or likeness/publicity-rights clearance. |
| Jumping Jacks (`jumping_jacks`) | The existing illustrated Lottie JSON | Preserved byte-for-byte; not replaced by a GIF. |
| Other **86** exercise IDs | Existing exercise-specific still references | A visible **Still image** badge identifies a hero still in exercise detail and the workout player. It is not a moving demonstration. |

The stills and their individual poses have not all been professionally reviewed.
Users should read the app's existing exercise instructions; no still by itself
shows a complete movement. Camera angle, grip, equipment, range and form still
need qualified review before publication. Old candidate animations remain as
source material, but none of the rejected candidates are selected in the
runtime registry.

## How it works

- `ExerciseAnimationRegistry` maps exact catalog IDs to local media; there is no
  name-based guessing. It currently selects only the squat GIF and the original
  Jumping Jacks Lottie.
- The existing shared `FitFlowExerciseImage` is used throughout the app,
  including detail screens, the player, library, workout preview, and history.
  GIF and animated WebP assets use Flutter's built-in image decoder. Lottie is
  retained for Jumping Jacks. No network service is required.
- Animated images pause with the workout player and on backgrounding. Reduced
  motion uses stills. Missing or corrupt motion assets fall back to a labeled
  still; Bodyweight Squat uses a still of the same person. Media never owns or
  changes workout time, reps, sets, prescriptions or exercise selection.
- The badge sits inside the existing image bounds so it does not move workout
  controls. Thumbnails are not overlaid with text; the large exercise reference
  is labeled where it is used to understand the movement.
- Older animations are retained in the repository for provenance; their
  inclusion in the asset bundle does **not** mean they are selected in the app.

## Credits and release checks

The Bodyweight Squats GIF is an adaptation of the work credited to Danielflefil,
licensed CC BY-SA 4.0. The source, changes, license and full license text are
bundled in `assets/animations/real_people/`, and **Settings → Exercise artwork
credits** displays the notice offline. Copyright licensing is not the same as
confirmation of the depicted person's likeness/publicity rights. Confirm those
rights and obtain qualified technique review before public or commercial release.
Do not describe the user's approval of the look as professional certification.

## Adding a future paid GIF or WebP pack

1. Confirm that the purchase terms permit bundled, offline in-app use and
   distribution on the intended platforms. Preserve any required notices.
2. Review each motion against the exact FitFlow ID, instructions, equipment,
   framing and complete movement. Do not match solely by title.
3. Add each approved local `.gif`, animated `.webp` or `.json` Lottie to a
   bundled asset directory and add the exact ID and path to
   `ExerciseAnimationRegistry.assets`. Add a matching still to
   `ExerciseAnimationRegistry.posters` when available.
4. Update credits and run the focused media, fallback, player and accessibility
   tests. Check the actual result on Android/iOS devices before release.

There is currently no generic video-player implementation or automatic paid-pack
importer; a future MP4 pack would need an appropriate player and license review.
