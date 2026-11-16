# Exercise animation rollout — 10 November 2026

## Changes
- All 25 active exercise IDs use offline Lottie demonstrations in the shared exercise image component, including library/detail, preview, player and skill-path surfaces.
- Preserved the existing Jumping Jacks, Forward Lunge and Reverse Crunch motion compositions. Added the supplied Military Push Ups and Cobras compositions. The other 20 demonstrations adapt the orange-shirt character with individual exercise poses. Planks show held positions rather than invented repetitions.
- Matching still posters appear for reduced motion and unloaded/inactive artwork. Player animation pause/resume and background gating remain separate from the workout clock.
- Profile offers **Review setup questions**, seeded from saved answers. Draft edits do not alter saved profile or history. Fresh-start routing still goes to onboarding; installations retaining/restoring a valid profile go Home.
- Programs entry has a rounded **Explore →** button.
- Replaced the former music with offline **EDM Detection Mode (128 BPM)** and **Club Diver (140 BPM)** by Kevin MacLeod, CC BY 4.0. Old audio assets removed. Pause/resume, interruptions, disposal and speech ducking remain tested.

## Validation
- 133 animation/startup/responsive tests passed in `build/launch25-validation.txt`.
- Onboarding, splash routing and music tests passed in the earlier combined run; obsolete immediate-start timing tests were subsequently updated to respect the already-requested brand presentation.
- Setup draft preservation test and final animation renders passed in `build/final-render-review.txt`.
- Rendered four poses per exercise, inspected contact sheets and corrected squat knee direction, Step Jack leg direction, Bird Dog support transitions and floor/head positioning. Static samples do not replace continuous physical-device review.
- Authoring scripts: `tools/orange_character/build_launch25.py`, `build_character.py`; rendering test: `render_review_test.dart`. Candidate files are built in `.dart_tool/orange_character`, reviewed, then explicitly copied into `assets/animations/launch25`.
- Attribution and adaptation terms are bundled in `assets/animations/launch25/NOTICE.md` and `assets/audio/NOTICE.txt`.

## Remaining device verification
Check continuous motion and frame rate on the target phone, and listen to both tracks. Exercise form has not been independently reviewed by a trainer. Audio interruption, Bluetooth disconnect and long-session looping have automated coverage but still need physical-device verification. The full older repository suite is not claimed green; unrelated legacy redesign expectations remain documented in the previous review.

Final focused analyzer: no issues (11 source/test files). Final debug APK build succeeded; all 25 JSON files, 25 posters and both MP3s were byte-verified against packaged assets.
