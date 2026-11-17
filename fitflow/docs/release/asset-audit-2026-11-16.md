# Bundled asset audit — 16 November 2026

Question: the app was trimmed from 88 exercises to 25 active ones, so which bundled
assets can no longer be reached, and how much APK weight would removing them save?

Method (reproducible): `python3 tools/media/audit_bundled_assets.py`. It resolves every
`pubspec.yaml` asset entry to real files, then classifies each file by reconciling the
25 active catalog ids, `ExerciseAnimationRegistry`, `ExerciseMediaRegistry`,
`program_media_registry`, literal paths in `lib/`, and the files the credits screen reads.
Runtime reachability was checked separately: every consumer (`ExerciseLibraryScreen`,
`ExerciseSkillTreeResolver`, `ExerciseEligibilityEngine`, `ExerciseProgression`,
`CustomWorkoutPlanResolver`, `WorkoutGenerator`, replacement engine) filters
`exercise.active`, so **no UI path can render an inactive exercise**.

## Headline

Before / after the cleanup executed on 16 November 2026:

| | before | after |
| --- | --- | --- |
| Bundled by `pubspec.yaml` | 310 files / 66.8 MB | **124 files / 43.2 MB** |
| Reachable at runtime | 120 files / 46.8 MB | 119 files / 43.2 MB |
| Bundled but unreachable | **190 files / 20.0 MB** | 5 files / 0.02 MB (licence text only) |
| In repo but not bundled (no APK cost) | 41 files / 6.5 MB | 41 files / 6.5 MB |

Payload removed from the app: **26.8 MB** (20.0 MB of unreachable assets + the 5.8 MB
`club_diver.mp3` + the illustrated-athletes set).

## The unused 20 MB, by group

| group | files | size | why it is dead |
| --- | --- | --- | --- |
| `real_people/` motion | 6 | 7.51 MB | The registry moved to `launch25/*.json` on 10 Nov; only `NOTICE.md` + the two licence files are still read (by the credits screen). Contains `pushup_pike.gif` (4.6 MB), `squat_bodyweight.gif` (2.9 MB), two `.lottie` files and two poster WebPs. |
| Inactive-exercise stills | 126 | 6.32 MB | `ExerciseMediaRegistry` still declares hero + thumbnail for all 88 ids. 63 ids are `active: false` and unreachable, so 63 heroes (5.85 MB) + 63 thumbnails (0.77 MB) ship for nothing. |
| `illustrated_athletes/` | 54 | 6.12 MB | Superseded illustration set. No `lib/` reference at all — only the stale `test/illustrated_athletes_test.dart` (12 of the tree's pre-existing test failures). |
| `open_exercise_figures/` provenance | 2 | 0.01 MB | `NOTICE.md` + `LICENSE-CC0.txt` kept for provenance; nothing loads them. Negligible — keep for licensing evidence. |

The 63 inactive ids whose stills are dead weight:
`pushup_incline, pushup_decline, squat_tempo, wall_sit, plank_side, hollow_hold,
bridge_single_leg, high_knees, row_towel, superman, prone_y_raise, squat_split_static,
squat_split_bulgarian, bicycle_crunch, heel_taps, mountain_climbers, childs_pose,
hip_flexor_stretch, hamstring_stretch_standing, thoracic_rotation, good_morning,
hip_hinge_single_leg, donkey_kick, fire_hydrant, pushup_close_grip, pushup_wide,
shoulder_tap, plank_up_down, butt_kicks, skater_step, squat_knee_drive, shadow_boxing,
single_leg_stand, standing_knee_raise, ankle_circles, world_greatest_stretch,
pushup_diamond, pushup_down_dog, wall_shoulder_press, dip_chair, squat_sumo, squat_pulse,
lunge_curtsy, lunge_lateral, bridge_march, frog_pump, plank_reach, plank_side_knee,
russian_twist, leg_raise, flutter_kicks, burpee_low_impact, fast_feet,
mountain_climber_standing, figure_four_stretch, pull_apart_resistance_band,
row_resistance_band, squat_goblet_dumbbell, row_bent_over_dumbbell, deadlift_kettlebell,
squat_goblet_kettlebell, dead_hang_pullup_bar, scapular_pullup`

## Must not be deleted (licensing / tests / behaviour)

- `assets/animations/launch25/` — all 25 motions, 25 posters, `NOTICE.md` (read by
  Settings → Exercise artwork credits).
- `assets/animations/real_people/NOTICE.md`, `LICENSE-CC-BY-SA-4.0.txt`,
  `LICENSE-LOTTIE-SIMPLE.md` — credited in-app and referenced by `launch25/NOTICE.md`.
- `assets/animations/illustrated_athletes/NOTICE.md` — keep as prose provenance (5 KB),
  including if the media files go.
- `assets/animations/pushup.json` — `test/launch25_animation_test.dart` asserts
  `launch25/pushup_standard.json` is byte-identical to it. It is not bundled.
- `assets/audio/` (17 MB, both tracks referenced by `WorkoutMusic`), `assets/images/programs/`,
  `assets/images/editorial/`, `assets/images/branding/home_workout_icon.png`, the 25 active
  hero/thumbnail stills.

## Repository-only weight (does not change APK size)

41 files, 6.5 MB are in the repo but not bundled: `vital/` (1.3 MB), 29
`open_exercise_figures/*.webp` (3.6 MB, authoring sources), and the experiment Lotties at
`assets/animations/*.json` (`bodyweight_squat`, `cobra`, `knee_pushup`, `lunge`,
`pushup_decline`, `pushup_incline`, ~1.3 MB).
Bigger still: `media_inbox/` (~207 MB of raw source PNGs) is tracked in the repository. It
never reaches the APK, but `git rm -r media_inbox` would cut ~207 MB from the working tree
(history would still hold it until a `git filter-repo` rewrite).

## Phase plan

### Phase 1 — delete superseded motion (≈13.6 MB, zero code logic change)

1. `git rm -r assets/animations/illustrated_athletes` (keep `NOTICE.md` by re-adding it).
2. `git rm assets/animations/real_people/*.gif assets/animations/real_people/*.lottie assets/animations/real_people/*_poster.webp`.
3. `pubspec.yaml`: drop `- assets/animations/illustrated_athletes/` and
   `- assets/animations/real_people/`; add
   `- assets/animations/illustrated_athletes/NOTICE.md` and keep the three explicit
   `real_people` notice/licence lines (the two inside-directory duplicates can go).
4. `git rm test/illustrated_athletes_test.dart` — it asserts the deleted files (already
   failing before this change).
5. Verify: `flutter clean && flutter build apk --release --target-platform android-arm64`,
   compare APK size; `flutter test test/launch25_animation_test.dart
   test/exercise_animation_test.dart`.

### Phase 2 — drop stills for the 63 inactive ids (≈6.3 MB, small code change)

1. Trim `lib/core/design/media/exercise_media_registry.dart` from 88 to the 25 active
   entries.
2. `git rm` the 126 `assets/images/exercises/{thumb,hero}/<inactive-id>.webp` files.
3. Update `test/production_media_registry_test.dart` (currently asserts "all 88 canonical
   IDs are explicitly covered" and a release gate over every declared file) to the active
   set, and refresh the inventory in `docs/design/media/asset-handoff.md`.
4. Trade-off: reactivating one of those 63 exercises later means restoring its two WebPs
   from git history. `ExerciseMediaRegistry.lookup()` returns null for them in the
   meantime, which the image widget already handles by falling back.

### Phase 3 — repository hygiene (0 MB APK, ~215 MB repo)

`git rm -r media_inbox` (207 MB, artwork staging only), `vital/` (1.3 MB), the 29
`open_exercise_figures/*.webp` authoring renders (3.6 MB, keep `NOTICE.md` +
`LICENSE-CC0.txt`), the six unused experiment Lotties, plus the committed crash logs
(`hs_err_pid*.log`, `replay_pid*.log`, 2.3 MB) and `fitflow - Shortcut.lnk`.

### Not covered here, but the largest remaining lever

`assets/audio/` is 17 MB for two MP3s (`edm_detection.mp3` 11.7 MB, `club_diver.mp3`
5.8 MB). Both are used. Re-encoding to ~96–112 kbps would save roughly 10 MB without a
code change — but that is an audio-quality decision, not a cleanup.

## Honest notes

- Asset bytes are not APK bytes 1:1. Flutter stores bundled assets under
  `flutter_assets/`, and already-compressed `.webp`/`.png`/`.mp3` are typically stored
  uncompressed, so expect close to the numbers above — but measure the real delta with a
  before/after `flutter build apk` rather than trusting the estimate.
- Deleting `illustrated_athletes_test.dart` also removes 12 of the 105 pre-existing test
  failures in this tree; it does not mask any failure in shipping code.
- Nothing here changes workout generation, prescriptions, eligibility or the player.

## Executed 16 November 2026

Delivered Phases 1 and 2 plus the music trim (Phase 3 deliberately skipped: it changes no
APK byte).

| Removal | files | size |
| --- | --- | --- |
| `assets/animations/illustrated_athletes/` media (NOTICE.md kept, still bundled) | 53 | 6.1 MB |
| `assets/animations/real_people/` superseded motion (gifs, `.lottie`, posters) | 6 | 7.5 MB |
| `assets/images/exercises/{thumb,hero}/<inactive-id>.webp` | 126 | 6.3 MB |
| `assets/audio/club_diver.mp3` | 1 | 5.8 MB |
| **total** | **186** | **26.8 MB** |

Code and documentation changes:

- `pubspec.yaml`: the `illustrated_athletes/` and `real_people/` directory entries are gone
  (only `NOTICE.md`/licence files are still bundled for the in-app credits screen).
- `lib/core/design/media/exercise_media_registry.dart`: 88 → 25 entries.
- `lib/features/workout_player/application/workout_music.dart`: one bundled track
  (`EDM Detection Mode`); the picker stays list-driven, so adding a track later needs no
  playback change.
- `assets/audio/NOTICE.txt`: Club Diver credit removed, removal date recorded.
- `test/production_media_registry_test.dart`: asserts the 25 active ids are covered, that
  inactive ids resolve to no media (so the widget falls back instead of requesting a
  missing asset), and that the declared inventory is 55 files.
- `test/workout_music_test.dart`: the track-switch test now covers the single-track case.
- `test/illustrated_athletes_test.dart`: deleted (it asserted the removed files).
- `docs/design/media/asset-handoff.md`: dated note explaining the active-only inventory.

Verification on the cleaned tree:

- `flutter analyze lib` — no errors (13 pre-existing warnings, unchanged).
- `flutter test test/launch25_animation_test.dart test/exercise_animation_test.dart
  test/production_media_registry_test.dart test/production_media_image_test.dart
  test/workout_music_test.dart test/visual_v2_step6a_exercise_media_test.dart` →
  118 passed, 5 failed. All five are the pre-existing `production_media_image_test`
  failures (identical names before the cleanup).
- Per-file regression comparison against the pre-cleanup run (serial, `-j 1`):
  `visual_v2_step6b` 6→6, `visual_v2_step6c` 5→5, `visual_v2_step7b` 4→4,
  `push_up_icon` 2→2, `exercise_skill_tree_widget` 19→19, `visual_v2_step8a` 7→7,
  `pushup_lottie` 13→13, `visual_v2_preview_player` 44→44. **No file changed status**;
  deleting `illustrated_athletes_test.dart` removed 12 of the tree's 105 pre-existing
  failures.
- `tools/media/audit_bundled_assets.py` now reports 5 unreachable files (0.02 MB), all
  licence/provenance text that is intentionally bundled.

Not verified here: no Android SDK in this environment, so the before/after APK/AAB size
delta still has to be measured with a real `flutter build apk --release` on the developer
machine. Asset payload fell 26.8 MB; expect the APK to fall by roughly that, since Flutter
stores already-compressed `.webp`/`.png`/`.mp3` uncompressed.
