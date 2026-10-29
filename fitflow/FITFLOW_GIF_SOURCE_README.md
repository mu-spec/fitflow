# FitFlow Home Workout — animated-exercise source bundle

Rebuilt after snapshot regression. This is the working tree of
`/home/user/fitflow/fitflow` (branch `arena-workouts-redesign`) with the
reviewed, zero-budget animated media implemented. It is NOT a release; it is
a source bundle for the next paid-pack replacement.

## What changed (this reconstruction)

- `lib/core/design/media/exercise_animation_registry.dart` — reduced to five
  exact, reviewed movement mappings only:
  - `jumping_jacks` → `assets/animations/illustrated_athletes/jumping_jacks.json`
    (original animation, preserved byte-for-byte; SHA-256
    e975bde0a30d9e1abd5127e145592901420c7d18a3a528ebaa55272df2ebcee7)
  - `squat_bodyweight` → `assets/animations/real_people/squat_bodyweight.gif`
    (Danielflefil, Bodyweight Squats.gif, Wikimedia Commons, CC BY-SA 4.0;
    resized 1080×1080 → 360×360 looped GIF; 68 frames)
  - `pushup_pike` → `assets/animations/real_people/pushup_pike.gif`
    (Danielflefil, Pike Push Ups.gif, Wikimedia Commons, CC BY-SA 4.0;
    resized 1080×1080 → 360×360 looped GIF; 77 frames)
  - `lunge_forward` → `assets/animations/real_people/lunge_forward.lottie`
    (Dinh Bui Xuan, "Free Lunge Animation", LottieFiles, original dotLottie,
    Lottie Simple License; 150 frames at 25 fps, matches the catalog's Forward
    Lunge instructions: step forward, bend both knees, return, alternate)
  - `reverse_crunch` → `assets/animations/real_people/reverse_crunch.lottie`
    (Dinh Bui Xuan, "Free Reverse Crunches", LottieFiles, original dotLottie,
    Lottie Simple License; 50 frames at 25 fps, matches the catalog's Reverse
    Crunch instructions)
  - Every other exercise keeps its labeled still photograph
    (ExerciseMediaRegistry: hero + thumbnail WebPs).

- `lib/core/design/media/exercise_animation.dart` — `.gif` assets now decode
  as animated image streams with the same pause / lifecycle / reduced-motion
  gating as Lottie; on decode failure the registered still poster shows.

- `pubspec.yaml` — removed replaced Vital/explicit illustration asset lines;
  `assets/animations/real_people/` glob bundles the new GIFs and dotLotties.

- `assets/animations/real_people/NOTICE.md` + `LICENSE-LOTTIE-SIMPLE.md` +
  existing `LICENSE-CC-BY-SA-4.0.txt` — attribution, share-alike and
  likeness/form disclaimers for Danielflefil and Dinh Bui Xuan media.

- `lib/features/settings/presentation/exercise_artwork_credits_screen.dart` —
  now bundles both the illustrated-athletes and real-people notices.

- Tests rebuilt: `test/exercise_animation_test.dart` (registry contract, GIF
  decode, Lottie decode, render + reduced motion, player pause), rewritten
  `test/push_up_icon_test.dart` (standard push-up is a still now), updated
  `test/production_media_image_test.dart`; removed obsolete pilot tests
  (player_animation_pilot, vital_exercise_animation, pushup_lottie,
  open_exercise_figures, illustrated_athletes) that asserted the rejected
  slim-motion baseline.

## Coverage (honest)

Animated: 5 of 88 catalog exercises (jumping_jacks, squat_bodyweight,
pushup_pike, lunge_forward, reverse_crunch). Labeled stills: the remaining 83.
No complete free, same-person library was found; this bundle does not inflate
coverage with unreviewed clips.

## Rights and limitations (read before release)

- CC BY-SA 4.0 media (squat, pike): keep creator credit, license link,
  change notices and share-alike. Visual approval is not expert form
  approval; performer likeness clearance is unverified.
- Lottie Simple License media (lunge, reverse crunch): attribution strongly
  encouraged; derivatives must carry the same terms; no competing-service
  compilation. Likeness clearance unverified.
- Do not imply professional form certification. Have a qualified fitness
  professional review demonstrated form before public/commercial release.
- Original Jumping Jacks must stay byte-identical; do not substitute.

## Verification (this tree)

- `flutter pub get` — OK (Flutter 3.47.8, disk-backed caches)
- `flutter analyze --no-pub lib` — No issues found
- Focused widget tests: 44 passing (exercise_animation, push_up_icon,
  production_media_registry, production_media_image, visual_v2_step6a), plus
  player/library/settings batches pass. No device/APK/release build tested.

## Later paid-pack replacement

Registry keys are exercise-ID stable (`assets` map by ID), so a paid pack can
be swapped in by changing `exercise_animation_registry.dart` entries and
pubspec assets without touching prescriptions, the workout clock or UI.
