# FitFlow Visual V2 — Step 5A Preview + active Player audit

- Date: 2026-10-13
- Branch: `main`
- Starting commit: `24d26f093d2448aa2939a63285a500afd653071c`

Scope: presentation of Workout Preview and the Player's **work phase**, including paused work. No Step 5B or Step 6.

## 1. Baseline findings and scope decisions

- Preview already generates the deterministic plan from the existing user/capability profiles and session mode. Its target, planned duration, equipment and ordered prescriptions are available; they must remain the source of truth.
- `WorkoutPlan` has no workout-title field. Preview therefore retains the existing localized `homeSession` context, “Adaptive Full Session,” and the existing fitness-goal label. No new workout identity is fabricated.
- The ordered sequence is Warm-up → Main → Cooldown. Each row already opens `AppRoutes.exerciseDetail(exercise.id)`. Replacement belongs to the existing Player picker, not a new Preview affordance.
- The sole `preview_start` action already pushes `AppRoutes.workoutPlayer`. The existing loading, error/retry, missing-profile, missing-capability and generator-null handling stays intact.
- Player uses a single execution engine for adaptive, custom and program sessions. The session view fixes its initial plan, mode and origin; viewport changes must not create another controller or session.
- Player position means **exercise position within the current section**, not a fabricated whole-workout index. Set progress uses the existing completed/total sets and `progressFraction`.
- `WorkoutPreviewExerciseRow` and `WorkoutPreviewSectionHeader` also serve Program Session Preview. V2 is an explicit opt-in, defaulting to `false`; the Program consumer is not edited.
- Player controls, progress header and session layout also serve non-work phases. V2 branches are gated by `phase == WorkoutPlayerPhase.work`. Ready, Rest, transition, section break and Completion retain their previous presentation branches.

## 2. Exact production working set

Paths are relative to the Flutter application directory, `fitflow/`.

| File | Presentation-only responsibility |
| --- | --- |
| `lib/core/design/widgets/fitflow_v2_workout_media.dart` | New shared static generic movement slot, painter and media-sizing helper. |
| `lib/features/workout_preview/presentation/workout_preview_screen.dart` | V2 page/header, explicitly opted-in sequence, one existing Start action. |
| `lib/features/workout_preview/presentation/widgets/workout_preview_summary_card.dart` | Real session context and metadata on the existing V2 hero surface. |
| `lib/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart` | Opt-in numbered native detail row; default branch unchanged. |
| `lib/features/workout_preview/presentation/widgets/workout_preview_section_header.dart` | Opt-in section hierarchy; default branch unchanged. |
| `lib/features/workout_player/presentation/workout_player_session_view.dart` | Work-only responsive layout, top/action styling and mounted overlay-label context. |
| `lib/features/workout_player/presentation/widgets/workout_player_exercise_center.dart` | Work-only identity/media/set/timer-or-reps focus surface. |
| `lib/features/workout_player/presentation/widgets/workout_player_progress_header.dart` | Work-only compact section/position and real set progress. |
| `lib/features/workout_player/presentation/widgets/workout_player_controls.dart` | Work-only target sizes and visual hierarchy; existing action branches/callbacks retained. |

Also created, without modifying existing tests or design records:

- `test/visual_v2_preview_player_test.dart`
- `docs/design/visual-v2-step-5a-preview-player-audit.md`
- `docs/design/visual-v2-step-5a-preview-player-validation.md`

No domain, controller, provider, persistence, generation, analytics, router or TTS implementation file is edited. No dependency declaration or lockfile is changed. No older backup file is restored.

## 3. Preview hierarchy and truthful data

1. Compact native navigation header with existing localized Preview title and back behavior.
2. Branded V2 hero: FITFLOW wordmark, existing goal/context and semantic session heading.
3. One neutral movement decoration, not an instructional exercise picture.
4. Existing effective/profile duration target, actual total exercise count and actual planned duration, explicitly kept as target vs planned values.
5. Required equipment from the real plan and existing Standard / temporary Low Energy / Comeback copy.
6. Existing details/replacement guidance and the three real section headers with their existing count/estimate values.
7. Compact numbered native rows in the original prescription order. Numbers are display indices derived from that order, not new domain identifiers.
8. Existing adaptive note, then the one dominant Start Workout action.

Rows render existing exercise names, sets × reps or sets × seconds, actual between-set rest when applicable, required equipment when applicable and an existing replacement label when supplied. No per-exercise art is added. Native `ListTile` navigation and focus remain in use.

The sole Start button retains key `preview_start`, the existing push callback and a minimum 56dp height. `SafeArea`, readable-width containment and compact-width padding remain. Normal-height layouts keep Start outside the content scroll; short layouts keep the whole content and the same single Start in one scroll. The existing `preview_scroll` key is retained in the pinned-button branch.

## 4. Active Player hierarchy

1. Compact native AppBar with the existing origin-specific title, native Back and the existing voice toggle/tooltip.
2. Existing phase announcement, real section and within-section exercise position.
3. Existing set progress as a compact progress bar and factual completed/total set text.
4. Work/Paused label with text and icon, followed by the real current exercise name as a semantic heading.
5. Existing replacement information, when present.
6. Central generic movement-media slot.
7. Actual set number and total sets for this exercise.
8. The existing countdown for timed work, or the existing rep prescription for rep work.
9. Existing equipment summary and the unchanged eligible controls.

The existing `WorkoutCountdown` formatter, responsive type-role choice and `PlayerTimerSemantics` remain in use. Countdown color is changed only by a local text theme on the hero, not by a global theme or timer replacement. Rep work displays the prescribed reps, never measured reps, automatic counting or a sensor result. M23 rep counting remains deferred.

### Control/condition preservation

| Existing condition | Existing action retained |
| --- | --- |
| Paused work | Resume. |
| Timed work | Pause Workout. |
| Rep work | Set Complete and Pause. |
| Replacement eligibility | Existing Replace Exercise picker, with its existing timed-work pause rule. |
| Ready or paused | Existing Exercise Details route. |
| Voice enabled/disabled | Existing `controller.toggleVoice()` and existing tooltip/icon state. |
| Active-session Back | Existing exit confirmation guard, cancel/confirm decisions and pop flow. |
| Rest / transition | Existing Pause and eligible Skip Rest / Skip Transition; no V2 redesign. |
| Section break | Existing Continue / Start Cooldown; no V2 redesign. |
| Completion | Existing completion view/actions/history/hook handling; no V2 redesign. |

No Next, Previous or Skip Work action is invented. The active primary target is at least 56dp high; secondary active controls, voice, replacement and Details retain at least 48dp targets.

Exit validation with real localization exposed an ancestor lookup through the retiring session element while the dismissing dialog rebuilt. The **same four existing localized labels** now resolve through the dialog builder's mounted `ctx`. No dialog content, action, guard, animation, result, navigation callback or workout state rule is changed. This is an overlay presentation-context correction, not an exit-flow redesign.

Session ownership, phase/exercise animation keys, lifecycle handlers, replacement selection, history guards, completion callbacks and their microtasks remain unchanged. The work layout receives the same phase/header/actions objects; no width-based session key is introduced.

## 5. Media implementation and Step 6 boundary

`FitFlowV2WorkoutMedia` is an original, generic FitFlow movement composition: two grounded rounded slabs, crossing paths and one restrained warm geometric accent. It uses the existing V2 art color roles on a quiet plate.

- Static, deterministic `CustomPainter`; no exercise-ID lookup, randomness, clock or animation.
- `ExcludeSemantics` covers the entire decoration, including optional future artwork.
- `RepaintBoundary` isolates the slot. `shouldRepaint` compares the five palette inputs and is false for equal inputs.
- Vector paths and flat geometry only; no network, stock imagery, raster exercise assets, photos, anatomy or charts.
- The same composition is used for every exercise. It is explicitly not a demonstration of that movement.
- Optional `artwork` is a widget slot for future work. No Step 6 exercise illustrations, lookup table or asset-loading system is implemented.
- No loops, parallax, animated gradients, continuous decorative painting, blur, shaders or additional decorative tickers.

No fabricated calories, difficulty scores, sensor measurements, muscle percentages, workout titles or duration claims are introduced.

## 6. Responsive, theme and accessibility decisions

### Layout

- Uses the existing `FitFlowMaxWidth` and native safe areas.
- Preview media is 80dp on sub-360dp viewports and 104dp otherwise. Work media is 112dp below 750dp viewport height and 152dp otherwise.
- **Both media slots reduce to 48dp** for short viewports (height <400dp) or large text (scaled 16sp >22sp). This detects text scaling; it does not clamp it.
- Active work uses side-by-side focus/actions only when the actual available width is at least 600dp and text is not enlarged.
- Large text stacks the focus and actions in one scroll. Short stacked layouts also use one scroll. Normal narrow layouts keep active actions outside the scrolling focus area.
- Art yields first. Exercise names, prescriptions, actual timing, actions and their semantics remain real, wrapping/reachable content.
- A fallback to the actual `View` dimensions supports contexts that supply an empty MediaQuery size; it never changes workout state.

### Light / Dark

Uses the existing semantic palette and opt-in `FitFlowVisualV2` roles: page, hero endpoints, on-hero/secondary text, support, tint and borders. Light and Dark are deliberately selected from those roles, not a screenshot inversion. Contrast tests check both hero endpoints and body/row/action pairs at a minimum 4.5:1 for their text.

### Accessibility and motion

- Real exercise names and Preview/section headings remain semantic headings.
- The phase announcement remains a live region that **omits the countdown**. Timer values remain separately exposed, not live regions.
- State is communicated by existing localized Work/Paused text and icons, never color alone.
- Native buttons, ListTiles, tooltips, routing, focus and keyboard activation are preserved.
- User text scaling is honored, including 2×; no `FittedBox`, text-scale clamp or forced scaling is introduced.
- Existing `SystemMotion` handles the inherited entry/chip animation. No new decorative motion is introduced, and reduced motion makes those entry/chip durations zero.

## 7. Evidence and limitations

The new focused tests exercise all five requested sizes in both themes at 1× and 2× for Preview, timed work and rep work, plus native actions, truthfulness, engine ownership, semantics, contrast, reduced motion and shared-widget scope. Exact commands and final counters are in the companion validation record.

This is widget/source validation, not an Android build, real TalkBack audit, rendered-font/device golden approval or Oppo A12 frame-time/memory benchmark. Optional local captures use the Flutter widget-test environment and are not production screenshots. The implementation is intentionally lightweight for the target device, but device performance is not claimed as measured.

**Stop boundary:** targeted validation only. No full-suite run, commit, push, Step 5B, Rest/Completion redesign or Step 6 work is authorized by this step.
