# The last three exercises — how the other 22 are built, and how yours get added

Read-through date: 2026-11-16. Scope: `lib/core/design/media/`, `lib/features/workouts/`,
`tools/`, `assets/animations/launch25/`, `test/`. No app file was modified for this note.

## 1. What "25 animated exercises" actually means

| Layer | File | Fact |
| --- | --- | --- |
| Catalog | `lib/features/workouts/data/exercise_catalog.dart` | 88 `Exercise` definitions, exactly **25** with `active: true` |
| Motion registry | `lib/core/design/media/exercise_animation_registry.dart` | `assets` map: all 25 ids → `assets/animations/launch25/<id>.json`; `repetitionsPerLoop`; `referenceRepetition = 2680 ms`; `posterFor(id)` → `launch25/<id>_poster.png` |
| Still registry | `lib/core/design/media/exercise_media_registry.dart` | hero (960×720) + thumb (256×256) WebP for every id — used only when no motion is registered, and as the reduced-motion/`heroFallback` still |
| Bundling | `pubspec.yaml` | whole `assets/animations/launch25/` directory is bundled, so a new file needs no pubspec edit |

`test/launch25_animation_test.dart` enforces that the registry keys equal the 25 active ids
and that every motion file parses with a non-zero duration and has a poster > 1000 bytes.
So: **an exercise becomes "animated" by one registry entry plus two files** (motion + poster).
Nothing in the workout engine, prescriptions or player depends on the media beyond display.

## 2. Runtime path — what happens when any exercise is drawn

```
ExerciseDetailScreen / WorkoutPlayerExerciseCenter / ExerciseListTile / preview rows /
history rows / custom builder / replacement picker / capability assessment
        └── FitFlowExerciseImage.hero(...) | .thumbnail(...)            (the only entry point)
              ├── exerciseId == 'pushup_standard' → PushUpIcon          (special case)
              ├── ExerciseAnimationRegistry.assetFor(id) != null → ExerciseAnimation
              └── else → FitFlowMediaImage (still WebP)
```

`ExerciseAnimation` (`exercise_animation.dart`) is the shared player, and it owns **display
only**:

- Lottie via `_PacedExerciseLottie`; `.gif` / `.webp` via `Image.asset` with a frameBuilder.
- Its own `AnimationController`; duration is overwritten with
  `ExerciseAnimationRegistry.playbackDuration(id, sourceDuration)` =
  `2680 ms × repetitionsPerLoop[id]`. The composition's own timing is deliberately
  *not* respected — every exercise loops at the shared push-up cadence. Planks use `0`,
  which means "keep the source duration" (isometric hold).
- Off-screen (inside a `RenderAbstractViewport`) → the animation widget is dropped and its
  ticker disposed; on-screen pause keeps the exact frame.
- App backgrounded → `animate: false`. `MediaQuery.disableAnimations` (reduced motion) →
  the poster PNG is shown instead of the Lottie.
- Decode/parse failure → poster, then the still WebP.
- Fixed presentation: `SizedBox` + `ClipRRect(FitFlowRadius.mediumBorder)` +
  `ColoredBox(FitFlowTheme.subtleSurface)` + `BoxFit.contain`, so any canvas aspect
  letterboxes instead of cropping.
- It never touches the workout clock, reps, sets, prescriptions or selection.

## 3. How the 22 approved animations were made

Two families:

**A. Five supplied originals, preserved byte-for-byte** — `pushup_standard` (Military Push
Ups), `jumping_jacks`, `lunge_forward` (Lunges), `reverse_crunch` (Reverse Crunches),
`cobra_stretch` (Cobras). `test/launch25_animation_test.dart` asserts
`launch25/pushup_standard.json == animations/pushup.json` byte-identical.

**B. Twenty locally authored adaptations** of the same licensed orange-shirt character
(Dinh Bui Xuan, Lottie Simple License):
`tools/orange_character/build_character.py` retargets the original 23 source layers to new
poses (rigid per-bone segments, IK for fixed contacts, rounded shorts masks, spine path
bend for Cat-Cow, mat/wall/doorway support shapes, camera). Pose timelines come from the
Open Exercise Figures solver rigs (MIT-0) in `tools/illustrated_athletes/rigs/` and
`tools/open_exercise_figures/`.

Each approved batch followed the same five-step publish contract:

1. `tools/squat_sample/build_<batch>_review.py` → `build/<batch>-review/*.json`
   (`meta.review_only = true`), asserted that **no installed asset changed**.
2. `tools/squat_sample/render_<batch>_test.dart` → 40 review frames at 420 px plus a
   720×720 poster at frame 10, rendered by the app's own Lottie renderer.
3. `tools/squat_sample/package_<batch>_review.py` → review GIF + 4-pose contact sheet for
   the owner.
4. Owner approval.
5. `tools/squat_sample/publish_<batch>.py` → validates the candidate, backs up the replaced
   pair with a SHA-256 manifest, flips `meta` to `review_only: false` + `approved: <date>` +
   `approved_review_sha256`, writes exactly two files, and asserts every other pair is
   unchanged.

Current state (`python3 tools/media/verify_launch25.py`): 19 exercises are 720×720, ~29.85 fps,
carry an approval date, and follow the 2.68 s cadence (or 5.36 s for two-sided loops,
53.6 s for the 20-circle Arm Circles).

## 4. Why these three are the odd ones out

`dead_bug`, `cat_cow` and `reverse_snow_angel` are the last outputs of
`tools/orange_character/build_launch25.py`, which bypasses the retarget rig and feeds hand
written joint coordinates straight in (`Direct.pose_joints`). Consequences:

| | dead_bug | cat_cow | reverse_snow_angel |
| --- | --- | --- | --- |
| fps / frames / length | 17 / 68 / 4.0 s | 16.2 / 81 / 5.0 s | 16.2 / 81 / 5.0 s |
| poster | 360×360 | 360×360 | 360×360 |
| pacing (`reps`) | 2 (5.36 s) | 1 (2.68 s) | 1 (2.68 s) |
| approach | flat torso, both legs held vertical, single-plane arm reach | original shirt **path is bent** between fixed hip/shoulder; head height animated only | oblique "top-down" projection with per-side y offsets; full-bleed cyan mat |
| visible problem | reads as a lying figure with lifted legs, not a controlled anti-extension reach; limbs overlap the shorts | barely any spinal shape change; no pelvis/head counter-rotation; silhouette is a straight box | arms sweep *behind* the torso, legs stack, the cyan square dominates the tile |

All three also carry the old `meta` (`source`/`license`/`adaptation` only — no `approved`
key), and `docs/final-three-review-2026-11-16.md` records them as **review candidates, not
published**: "Remaining review candidates: Dead Bug, Cat-Cow, Reverse Snow Angel … These
three have NOT replaced installed assets yet."

That is exactly the gap your supplied animations fill.

## 5. Integration contract for the three files you send

Per exercise, in this order:

1. **Inspect** — I open the file, read fps / frames / canvas / layer count, and render 24
   review frames + a 720×720 poster with the app's renderer
   (`tools/review/render_lottie_test.dart`), then look at them before publishing.
2. **Stage** — `python3 tools/media/ingest_launch25.py --id <id> --source <file> --reps <n> --dry-run`
   normalises metadata (`nm`, `meta.source/license/approved/source_sha256`), and writes only
   into `build/<id>-ingest/`.
3. **Publish** — same command without `--dry-run`: backs up the old pair, writes
   `assets/animations/launch25/<id>.json` + `<id>_poster.png`, deletes a superseded
   `.gif/.webp` if the type changed, and asserts **only those two files changed**.
4. **Registry** — set/keep `assets['<id>']` and set
   `repetitionsPerLoop['<id>']` to the number of full repetitions in the supplied loop
   (1 → 2.68 s, 2 → 5.36 s for an alternating both-sides loop, 0 → keep source duration for
   an isometric hold).
5. **Prove** —
   `python3 tools/media/verify_launch25.py` (structure) then
   `flutter test test/launch25_animation_test.dart test/exercise_animation_test.dart`
   (registry contract, per-id Lottie load, hero + thumbnail render, reduced-motion still,
   player pause, shared cadence). Baseline on this tree: all green.
6. **Document** — update `assets/animations/launch25/NOTICE.md` and
   `docs/launch25-animation-review.md` with source, licence, credit and date, and note the
   approval in `docs/final-three-review-2026-11-16.md`.
7. **You review** — I show the new poster, a frame sheet and (optionally) a looping GIF of
   the real render at phone size before anything is called approved.

## 6. Best input, and what I need to know

- **Preferred:** Lottie `.json` (or dotLottie `.lottie`, auto-extracted), 720×720 canvas,
  transparent background, mat/floor included only if the other 22 have it, loop start/end
  matching so the repeat seam is invisible, and a frame around 10/80 that reads as the
  teaching pose.
- **Also fine:** animated `.gif` or `.webp` — the runtime already supports them
  (`_animation()` branches on the extension); I render the poster with Pillow and update the
  registry path. Video (`.mp4/.mov`) needs a GIF/WebP/Lottie export first; there is no video
  player in the app.
- **Tell me, or I will propose and you confirm:** how many full repetitions one loop
  contains (this sets `repetitionsPerLoop`, i.e. whether it plays at 2.68 s or 5.36 s per
  loop), whether it alternates sides, and the credit/licence line for `NOTICE.md`
  (owner-supplied is fine — the existing three have no outside licence).

## 6b. Status: published 16 November 2026

The three owner-supplied GIFs turned out to be the review packaging of the in-repo
vector candidates: 40 frames at 420x482 (420 px art + 62 px header), 5360 ms for Dead
Bug and 2680 ms for the other two. Rebuilding with
`tools/squat_sample/build_final_three_review.py` and rendering with the app's Lottie
engine reproduced them at a mean absolute error of 0.02 (GIF palette noise only), so the
720x720 vectors were published rather than the 420 px rasters:

- `assets/animations/launch25/{dead_bug,cat_cow,reverse_snow_angel}.json` — 29.85 fps,
  160 / 80 / 80 frames, `meta.review_only = false`, `meta.approved = 2026-11-16`,
  `meta.approved_review_sha256` recorded.
- `assets/animations/launch25/*_poster.png` — 720x720, rendered at 25 % of each loop
  (the frame the owner reviewed).
- `repetitionsPerLoop` needed no change (2 / 1 / 1) because the published source
  durations are exactly 5.36 s / 2.68 s / 2.68 s — the loops play at true speed.
- Validation: `tools/media/verify_launch25.py` clean except the five preserved original
  compositions; `launch25_animation_test.dart` and `exercise_animation_test.dart` green;
  A/B of every media-adjacent widget suite before vs after the swap is identical
  (99 passed / 105 failed both ways — the failures are pre-existing stale tests on this
  tree, none in these files, none naming these three exercises).

## 7. Tooling added today (repo-safe, no app behaviour touched)

| File | Purpose |
| --- | --- |
| `tools/media/verify_launch25.py` | read-only cross-check: catalog ↔ registry ↔ files ↔ pubspec, prints the 25-row table of fps/frames/pacing/poster/approval and flags structural errors |
| `tools/review/render_lottie_test.dart` | renders any `.json`'s review frames + 720×720 poster using the same `lottie` package as the app, driven by `--dart-define` |
| `tools/media/ingest_launch25.py` | validate → normalise → poster → backup → publish two files → assert no collateral change; `--dry-run` stages into `build/` |

Toolchain used for the checks: Flutter 3.47.8 / Dart 3.13.7 (the version the repo's own
release notes cite), `flutter pub get` OK, `flutter test test/launch25_animation_test.dart`
→ 3/3 passing on the unchanged tree.
