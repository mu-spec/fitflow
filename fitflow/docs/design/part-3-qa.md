# Part 3 — implementation boundaries and physical QA

## Implementation boundaries

- Canonical parent: `4db32544c315408e97ea50db69bca0bf35e4cff1`.
- Source changes are confined to workout Preview/Player presentation and localized
  copy. No controller, generator, replacement engine, domain, storage, TTS service,
  timer, route definition, theme, appearance setting or program-progress code changes.
- Preview shows session type/goal, effective target, real estimated time/count/setup
  and one mode line. Section budgets remain exact widget data, no longer competing
  with the estimate. Flat native detail rows expose the existing exercise route.
- **No new preview-editing session**: baseline has no preview replacement provider or
  handoff. Copy points to replacement of the current exercise in the existing Player
  ready/first-set phases. Adding arbitrary pre-session replacement would be a separate
  functionality task. Replaced context is rendered only when actual context is supplied;
  the Player uses its existing original/effective exercise fields.
- Shared preview rows/section headings also improve Program session previews. Program
  screens/resolvers/origin callbacks and the custom-workout editor/hub remain untouched.
- Player freezes plan/mode/origin exactly as before. A presentation-only GlobalKey
  preserves the phase subtree and one-shot Done control across layout changes. The
  controller remains above responsive layout and animation, never keyed by screen size.
- Pause/Resume moves to reachable bottom controls; rest and transition retain existing
  Skip actions. No invented Previous or skip-work action. Details are available in ready
  or paused states, so viewing details does not introduce a new auto-pause/resume policy.
- Replacement uses the same pause/get-options/replace-current calls. Only presentation
  reason priority changes, not candidate order. Typed equipment formatting fixes the old
  UI predicate that could show No equipment for an equipment-requiring alternative.
- Phase entry uses a single 200ms token fade keyed only by exercise/phase, never seconds.
  Native control feedback and a 120ms phase-color transition communicate selection/pause.
  Reduced motion sets authored motion to zero. No outgoing active controls are retained.
- Countdown semantics remain non-live. The separate localized live announcement still
  omits seconds. Native buttons retain tap/focus actions. No font-scale clamping.
- Completion uses the canonical success/accomplishment color role, actual counts and
  clearly labeled target/estimated duration; no elapsed-time claim or invented score.
  Done is primary; Tune is secondary under the same origin/mode eligibility conditions.
- Tuning still evaluates/applies the same evidence and levels. Human-readable level
  labels reuse Part 2's adapter; decision copy maps actual decision enums in presentation.
  The entire sheet can scroll at large text/short height, including actions/errors.
- No extra packages, images, blur, shaders, continuous decoration or per-tick animation.
  The existing one-second view updates are retained; no speculative repaint layers.

## Automated coverage

The Part 3 suite adds 20 tests. A 12-case matrix covers Preview and every Player phase
at 320×700, 390×844, 430×900, 600×800, 900×800 and 900×320, in Light/Dark at 2× text.
Other tests exercise real candidate selection, equipment/reason truthfulness, original
context, timer/pause/workload/session preservation, non-repeated speech, native actions,
non-live countdown, details/start routes, no alternatives and history/completion once.
The existing program, custom, progression, lifecycle, timer, voice, replacement and
M22 suites remain the functional regression authority. Physical performance is not
inferred from passing widget tests.

## Oppo A12 checklist (later, on a separate test installation)

No APK/AAB is built by this change. Back up wanted data before clearing app storage.
Record Android version, commit, font/display scale, theme and orientation.

1. **Preview readability:** identify the session, target, estimate, count, mode and
   start action in a few seconds. Scan Warm-up/Main/Cooldown. Tap a row for details,
   then return; confirm the plan is unchanged.
2. **Replacement UI:** in Player setup/first set, open Replace. Verify current name,
   preserved workload, equipment and factual reasons. Expand Why this fits. Check
   No suitable alternatives is understandable and dismissible when appropriate.
3. **Start:** Preview Start opens the same ready phase. Begin starts exactly once.
4. **Timer:** observe timed work at arm's length; no clipped or bouncing numerals.
5. **Pause/Resume:** pause timed work, reps, rest and transition. Wait; countdown must
   stay frozen. Resume must be obvious and continue the same session.
6. **Rest:** verify Rest identity, countdown, upcoming exercise/set and Skip rest.
7. **Next exercise:** verify short transition, next workload and Skip transition;
   section Continue/Start cooldown keep existing behavior.
8. **Active replacement:** open during the first timed set. Verify existing automatic
   pause; cancel retains remaining time. Select an alternative: same session/workload,
   original context retained and timer follows existing replacement reset semantics.
9. **Exit dialog:** Android Back during work/rest/pause asks for confirmation. Continue
   workout preserves the session. Exit workout leaves without implying partial history.
10. **Full completion:** finish every phase. Verify actual counts, planned durations,
    restrained success feedback, Done/Tune hierarchy and repeat-tap protection.
11. **History:** return and verify exactly one completed record, including replacements.
12. **Program origin:** launch a program session and finish. Confirm program context,
    exactly-once program progress and return to the correct program on Done/Tune.
13. **Low Energy/Comeback:** verify truthful temporary status and existing target/mode
    behavior; no movement-level change or Tune action when not eligible.
14. **TTS:** mute/unmute, pause/resume, change exercise and complete. No repeated speech
    caused by fades/rotation; enable TalkBack to check no every-second live announcements.
15. **Dark mode:** verify work/rest/pause/completion/replacement contrast and selected
    state in Light, Dark and System appearance.
16. **Landscape / large text:** rotate during work and completion; increase system text
    to 2× where available. Exercise identity, timer and controls must wrap/scroll safely
    without reset. Check one-shot Done still works across orientation changes.
17. **Stutter / clipping:** inspect timer ticks, phase entry, sheet drag and scrolling.
    Enable reduced animations and verify immediate transitions. Note dropped frames,
    delayed controls, clipped labels or awkward one-handed reach for later profiling.

Stop here. Programs, Workouts hub, Exercise Library, Progress, Profile and Settings
redesigns remain future work.
