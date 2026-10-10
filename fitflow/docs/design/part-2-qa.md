# Part 2 — implementation notes and Oppo A12 QA

## Scope and architecture

Built directly on canonical `f638ac1`. No second token system, theme, palette,
font package, image asset, navigation architecture or route was added.

### Onboarding

- Same eight step IDs/order and controller fields; same required-choice gates,
  exclusive None equipment rule, optional preferences, and Back state retention.
- Welcome has one integrated value proposition, not a carousel or extra route.
- Each choice step has short contextual guidance and single/multi-select wording.
- Readable 640dp cap; 16dp inset below 360dp, existing 24dp screen inset otherwise.
- Progress and actions keep their positions while only question content fades in.
  In short windows, actions move into the scroll area instead of squeezing content.
- Canonical selectable tiles for single choices; native checkbox tiles for multiple
  choices. Semantic merging retains native tap/focus actions and selected states.
  The legacy OnboardingOptionCard is retained byte-for-byte for Profile editors;
  the new OnboardingChoice is a feature-only composition of Part 1 controls.
- Save-in-flight feedback blocks duplicate taps and reports failure without leaving
  the ready step. The same controller saves the same profile before assessment.

### Movement Check

- Same ten movements, experience-seeded answers, five choices, stable option keys,
  per-movement update function, timestamps and capability-save path.
- User-facing choice titles replace L1–L5; rank values never appear in labels or
  tooltips. Existing English titles/descriptions/examples are localized in ARB
  through a presentation-only adapter; domain/catalog files are untouched.
- Compact question surfaces, wrapping native ChoiceChips, named suggestions and a
  human-readable summary. Save is pinned when there is room and scrollable in short
  landscape. Defaults are described as suggestions, not newly measured abilities.
- Successful save retains `go(Home)` and shows a short non-blocking confirmation;
  Home content enters with the existing motion tokens. No extra route, tap or delay.

### Home

- Same provider gates and generator/context calls. Existing M12 mode controller,
  effective durations, history-driven comeback policy and callbacks are unchanged.
- One hero groups the plan title, effective target duration, actual exercise count,
  estimated planned time, factual adaptation line, View workout CTA and mode.
- Section counts remain available but visually secondary. The actual main-movement
  focus remains below the hero without another card.
- Real profile facts and the longer adaptation explanation are under Built for you;
  stored preferred duration is labeled Usual time so it cannot masquerade as today's
  effective duration. Nothing fabricated or removed from the profile snapshot.
- Existing exercise-library shortcut remains secondary. No new analytics, readiness,
  streak, calorie or AI claims. No fake progress during loading.
- Shared loading/error/empty treatments. Local-data error copy no longer blames a
  network connection. Missing-profile recovery callbacks are unchanged; no-plan
  adds a direct shortcut to the existing Profile route for the suggested adjustment.

### Navigation, motion, accessibility

- Same four destinations, same `goBranch` and same-tab reset behavior.
- Canonical bar/rail uses the same 840dp breakpoint and short-window rail scrolling.
  Labels wrap; compact bar has more room at large text. Keeping the body under the
  same Row/Expanded structure preserves widget state when resizing bar ↔ rail.
- Existing Part 1 120ms/200ms/320ms motion helpers govern entry, mode feedback,
  selection and route presentation. No extra controllers, bounce, blur or artwork.
- Native accessibility actions, selected states, practical 48dp controls, localized
  labels, live progress/error feedback and reduced-motion behavior are covered by
  tests. No text-scaling clamps or fixed-height text containers.
- Light and Dark both use the canonical palette/ThemeExtension and semantic surfaces;
  feature code adds no raw color palette or theme overrides.

## Physical-device QA checklist — Oppo A12

**Preparation:** use a separately built debug/test installation. This change does
not build or include an APK/AAB. Back up wanted app data before clearing storage.

1. **Fresh start:** clear app data and launch. Verify Welcome; progress begins at
   1 of 8, Back is disabled, and Continue is reachable without visual jumping.
2. **Each step:** try Continue without a required answer. Select options, go Back,
   and return. Verify selection persists. Select two equipment items, then None,
   then another item; verify exclusivity. Leave preferences empty and continue.
3. **Movement Check:** review all ten movements. Verify human choice names, readable
   explanations and obvious selected chips. Change Push, Squat and Core independently.
   Save once; confirm arrival on Home with no extra completion tap. Restart and
   confirm first-run setup is not repeated.
4. **Home first load:** confirm the workout, target minutes, exercise count, active
   mode and View workout action are immediately identifiable. Expand Built for you
   and compare actual profile facts. View workout must open the existing preview.
5. **Modes:** select Standard, Low Energy and Comeback. Verify target duration follows
   existing mode behavior, the temporary note appears appropriately, the sheet closes,
   and stored movement levels/profile settings are not changed by mode selection.
6. **Navigation:** switch all four tabs. Open a nested page, switch away and back,
   then reselect the active tab. Verify existing branch restoration/reselect behavior.
   Rotate to landscape and check all navigation destinations stay reachable.
7. **Dark mode:** use the existing appearance setting, then revisit Home and onboarding
   in a fresh test-data run. Check selected options, disabled controls, target time,
   surfaces and action text for contrast; confirm System mode still follows Android.
8. **Large text / TalkBack:** use the largest practical system font/display sizes.
   Verify wraps rather than clipping and actions remain scroll-reachable. With
   TalkBack, check option labels/selection, actual tap activation, progress, Home CTA
   and mode choices. Keyboard focus can be checked with an external keyboard.
9. **Motion:** inspect step changes, choice feedback, mode changes, completion and
   Home entry for stutter or long delays. Enable Android reduced animations (where
   available); verify feedback remains meaningful without decorative movement.
10. **Recovery / safety:** where test hooks allow, exercise profile load/save failure,
    missing profile/capability and an ungenerable restrictive setup. Verify honest
    localized messages, usable retry/recovery actions, and no raw exception text.

Record Android version, app commit, font/display scale, theme, orientation and any
clipping/stutter. Physical-device performance and TalkBack results are **not claimed**
by the sandbox widget tests. Workout Preview/Player and all other feature redesigns
remain out of scope until instructed.
