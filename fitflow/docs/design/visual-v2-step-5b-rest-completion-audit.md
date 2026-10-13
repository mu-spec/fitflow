# Visual V2 Step 5B — Rest + Completion audit

- Date: 2026-10-13
- Branch/baseline: `main`, `24d26f093d2448aa2939a63285a500afd653071c`
- Scope: presentation only. Step 5A preserved; no Step 6, commit or push.

## Production changes — exactly two files

1. `lib/features/workout_player/presentation/widgets/workout_player_rest_view.dart`
2. `lib/features/workout_player/presentation/widgets/workout_player_completed_view.dart`

No shared primitive, active Player/Preview file, session layout, controller, domain, storage, provider, feedback sheet, router, localization, global theme or dependency file is changed for Step 5B. All 12 Step 5A production/test/document files retain their pre-Step-5B SHA-256 hashes.

## Rest findings and treatment

The existing Rest state is **between sets of the current effective exercise**. It supplies the real remaining duration, current prescription and next set number. It does not identify a separately resolved next exercise. The redesign must not invent one.

Hierarchy:

1. Existing compact AppBar/section/position/progress context, unchanged.
2. Existing Rest/Paused status, with text and icon.
3. Dominant existing countdown on a calm V2 tonal recovery surface.
4. Separate upcoming-set card: existing next-set label, real current exercise name and actual workload.
5. Existing controls in the unchanged session/control widgets.

The rounded ring/oval frame is a static outline, **not a progress/recovery measurement**. Its decoration uses `ExcludeSemantics` independently of the timer. `WorkoutCountdown`, its formatter and `PlayerTimerSemantics` remain unchanged. A local text theme selects an existing type role that fits the actual value and width; it does not alter time or clamp user scaling. The frame's minimum height reduces from 216dp to 128dp for short viewports or large text.

Pause/Resume, Skip Rest, eligible paused Details, Back/exit and voice actions keep their original conditions/callbacks. Reaching zero still begins the next set; completing the final set then reaches the existing transition. No next/previous/skip-work action or exercise artwork is added.

## Completion findings and treatment

The supplied plan has no workout-name field or measured elapsed-duration field. Identity uses the existing localized origin-specific workout context; no name is fabricated. Completion retains the existing completion/finished messages.

Hierarchy:

1. Existing native workout context and completion announcement, unchanged.
2. V2 hero with a small static, semantics-excluded check mark and real origin context.
3. Canonical exercise count and completed/total sets on wrapping factual surfaces.
4. Existing **target** and **estimated** duration rows, explicitly not elapsed time.
5. Existing temporary/custom/program note and local-history copy.
6. Existing guarded Done and eligible Tune Next Workout actions.

The mark reduces from 64dp to 40dp for short viewports or large text. Fact tiles switch between two columns and a stack using available width and existing text scaling. Done has a 56dp minimum height; Tune retains at least 48dp.

## Behavior and persistence safety

- `_openTuneSheet`, `_handleDone`, Tune eligibility and the `_OnceDoneButton` press guard retain their original logic.
- The feedback sheet/options, selection, Skip/Apply behavior, capability/evidence transaction and destination rules are untouched.
- History and completion callbacks remain in the unchanged session view with their existing one-shot/retry guards. No side effect is moved into a hero, fact tile, decoration or rendering helper.
- Adaptive temporary-mode protection/reset, custom protection/fallback and program origin/note/destination/Home-mode independence remain intact.
- No calories, XP, score, heart rate, readiness/recovery/breathing metrics, ranking, streak, fat-burn claim or fabricated percentage is displayed.

## Theme, accessibility, responsiveness and cost

Existing V2 semantic colors provide deliberate Light/Dark support/tonal/hero treatments. Text contrast tests cover ordinary/tonal surfaces and both hero endpoints at 4.5:1 or better.

Real status, exercise identity, completion heading and native button/focus semantics are preserved. Rest countdown stays non-live; ticking does not alter the existing phase announcement. Completion retains its existing live announcement. Decoration never hides factual text or timer semantics.

Both views are validated at 320×700, 390×844, 600×900, 840×1000 and 900×320, in both themes at 1× and 2× text. The existing session scroll/safe-area layouts suffice; Completion also provides a scroll when directly embedded in a bounded parent. No Step 5A compatibility edit is needed. No scaling clamp, `FittedBox` or new session key is introduced.

No new animation is added. The inherited one-time phase entrance/chip motion still respects `SystemMotion`; reduced-motion tests verify zero durations and no continuous frame. Geometry uses ordinary decoration and a native icon, with no new painter, dependency, image asset, network fetch, blur, shadow stack, particles, confetti or animated gradient.

This is widget/source validation, not a physical Oppo A12 benchmark or real TalkBack/device-font screenshot approval. Exact test results and commands are in the companion validation document.
