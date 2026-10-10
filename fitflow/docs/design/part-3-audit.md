# Part 3 pre-implementation audit

Baseline verified against remote main: `4db32544c315408e97ea50db69bca0bf35e4cff1`.
Working tree was clean before this audit. Part 1/2 are canonical.

## Preview

The adaptive preview repeats temporary mode in its summary and a separate banner.
Four equally weighted summary metrics, section budgets, movement labels, internal
body-position/difficulty enums, workload/rest badges and individual cards make the
plan resemble a diagnostic list. Start is only at the bottom of the whole plan.
Section headings already have real counts/estimates and must keep using those data.

Important baseline distinction: adaptive preview rows are currently **not tappable**
and there is **no preview replacement state/provider**. Replacement exists in the
shared Player's ready/work phases, with ready explicitly preceding Begin workout.
Do not invent a second replacement controller or silently change generation/route
handoff. Expose the existing exercise-detail route from rows; explain that exercise
adjustment is available in workout setup before beginning. Replaced metadata is
shown where the existing session actually owns it, not fabricated in preview.
Program session previews reuse the section/row widgets; retain their origin/resolver,
route and session identifiers. Do not redesign program browsing/detail screens or
custom workout editing under the guise of preview work.

## Player

The same set appears in the top progress header and current exercise view (twice for
reps). Overall completed/total sets competes with current set. Ready repeats total
sets and progress. Replacement metadata repeats above and inside the hero. Large
movement illustrations, movement labels and multiple pause labels compete with the
actual timer/reps. Pause uses error styling despite being an ordinary state.
Pause is both an app-bar icon and, for timed work only, a bottom control. Paused reps
and rest lack an obvious bottom Resume. No Previous/skip-work controller action is
exposed by the existing UI: do not invent either. Keep existing completeSet,
skipRest, skipTransition, continueSection, pause and resume calls unchanged.

Session ownership is correctly frozen in initState. Lifecycle pausing, completion
microtasks, history/session-ID guards, program callback and Done dispatch must not
be refactored. The voice action calls toggleVoice directly; motion must not trigger
speech, start another session, or key/recreate WorkoutPlayerSessionView/controllers.

## Replacement

The existing controller supplies deterministic options and factual reason enums.
The sheet shows every reason equally, exposes internal difficulty ranks, duplicates
metadata, and has a faulty presentation-only equipment predicate that can label
required equipment as 'No equipment'. It also uses dynamic prescriptions.
Use typed prescription data and localized equipment labels. Prioritize workload,
setup/difficulty reasons; disclose remaining actual reasons without inventing any.
Keep no-alternative feedback calm. Preserve the exact pause-before-picker and
replaceCurrentExercise calls and do not change engine eligibility or workload.

## Rest, transition, completion and tuning

Rest and transition reuse a large generic countdown layout. Differentiate work,
rest/next and paused with text/icon plus existing semantic phase colors. Upcoming
workload belongs below the countdown. Exercise/phase entry can fade briefly; do not
animate every timer tick, pause via animation, or defer state changes.

Completion is a large icon, motivational line, stacked statistics card and two
competing actions. Data are actual plan counts, completed sets and **planned**
durations, not elapsed measurement. Keep that distinction. Done should be primary,
Tune secondary when currently eligible. Preserve one-shot Done and origin dispatch.
The tuning sheet has working evidence/persistence logic; its tall fixed header and
footer, individual cards and internal rank presentation need compact wrapping
presentation, not changes to feedback/evaluation/apply logic.

## Accessibility, responsive, motion and tests

M22 deliberately exposes countdowns on focus, not as live regions; preserve this.
Phase announcement text omits seconds and should remain stable on timer ticks.
Current player caps at a hard-coded width and scrolls all content in short windows.
Use canonical bounds and a wider focus/control arrangement when helpful, with
scroll-safe fallback at 2x. Avoid AnimatedSwitcher retaining live outgoing controls.
Use existing SystemMotion/FitFlowMotion and implicit entry only keyed by meaningful
phase/exercise changes. No new palette, package, asset or decorative loop.

Relevant existing suites cover preview/modes, replacement matching/controller/UI,
player execution/lifecycle/timers/voice/profile stability, history, completion
callback, custom/program origins and M22 targets/semantics/large text. Preserve
functional assertions; narrowly update presentation expectations and add a Part 3
responsive/phase/native-action/replacement/completion suite. Run analyze, targeted,
full tests and whitespace validation. No APK/AAB or physical-device claims.
