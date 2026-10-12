# Visual V2 / Step 3 — Workouts audit before implementation

Baseline: published `8f2277e9ee4753bd072f589d2873b549995d1904`, verified against GitHub `mu-spec/fitflow` main and the entire clean source tree. Steps 1 (Home) and 2 (Onboarding / Movement Check) are canonical. This is a new visual direction for the Workouts landing screen only, not a functionality pass.

## Scope inspected

- Production `WorkoutsScreen` (`lib/features/workouts/presentation/workouts_screen.dart`): flat Material/transparent page, `TrainingHeading` title + intro sentence, inline Programs `Card`+`ListTile`+chevron, `ActiveProgramCard`, `TrainingHeading("Custom workouts")` + empty/populated custom states, `TrainingHeading("Explore")` + two plain `ListTile` rows separated by a `Divider`, trailing adaptive-workout note + `TextButton("Go to Home")`.
- Programs entry / active-program continuation (`lib/features/programs/presentation/widgets/workouts_program_cards.dart`): `ActiveProgramCard` is a standard `Card` tinted `primaryContainer` with label/name/session count/next-session text and a `FilledButton.icon` Continue/View program action. `ProgramsEntryRow` and `RecommendedProgramCard` exist but are referenced by nothing (dead widgets).
- Custom Workouts states: `_EmptyCustomState` flat white card (title, one sentence, create); `_CustomWorkoutCard` white cards with name, truthful target/exercise summary, resolvable estimate, movement chips, View/Edit actions and a real delete menu.
- Exercise Library / Skill Trees entries: two plain zero-padding `ListTile`s plus a `Divider` under the Explore heading.
- Existing navigation behavior: every entry `context.push`es a nested route; adaptive note `context.go(AppRoutes.home)`; `ActiveProgramCard` continuation routes by real next-session state.
- Visual V2 Step 1/2 primitives: `FitFlowVisualV2` roles, `FitFlowV2HeroSurface`/`InfoSurface`/`Tag`, `FitFlowV2SelectionSurface`/`ActionSurface`/`OptionGrid`, static original painters (`HomeFlowMotif`, `FitFlowV2AdaptiveMotif`), `SystemMotion`/FitFlow motion tokens, `FitFlowMaxWidth`, responsive hero composition that yields to large text.
- Part 4 Workouts tests (`part4_training_progress_test.dart`: WorkoutsScreen at six sizes × Light/Dark × 2× text with a long-named custom template), Workouts screen tests, adaptive-programs Workouts integration tests, skill-tree Workouts test, Part 6 per-width production-route matrices, V2 Home/setup tests — all green on this SDK; they are the preserved behavioral contract.

## Findings

- **Weak visual anchor:** the page is a plain scaffold-colored lane of white boxes; nothing identifies it as the training hub, nothing relates it to the Home experience established in Step 1. The first viewport is indistinguishable from settings.
- **Generic menu-card appearance:** Programs — the flagship guided-training destination — is an anonymous `Card`+`ListTile`+chevron row, visually identical to a preference row. It communicates navigation, not "structured training journey".
- **Excessive equal visual weight:** Programs row, Custom section, Explore rows and the trailing adaptive note carry the same weight; the most actionable content (the active program) is third in reading order and uses ordinary card geometry.
- **Poor differentiation between feature types:** a guided journey (Programs), user-authored content (Custom), and reference/exploration tools (Library, Skill Trees) share one list vocabulary, so users cannot tell a journey from a note they wrote from a reference index.
- **Large blank surfaces:** flat background + white cards with generous gaps; no layered tint relationships; on tablets the single column stretches wide empty bands within `FitFlowMaxWidth` — a phone layout floating in a bigger white box.
- **Weak content imagery:** zero imagery anywhere. No motif, no artwork, no illustrational slot; only a calendar icon and two chevrons. Nothing suggests movement, progression, or training.
- **Insufficient hierarchy:** page title (headlineMedium) → section headings (titleLarge) → row titles is a shallow slope; no kicker/eyebrow; descriptions are uniform muted body text.
- **Card repetition:** Programs card, empty-custom card, and every `_CustomWorkoutCard` are the same 20-radius white container with stacked text; a populated custom list repeats identical cards down the page ("card soup").
- **CTA competition:** the empty state's filled Create, the populated OutlinedButton Create, per-card filled View + text Edit, the active card's filled Continue, the Programs chevron row, and a "Go to Home" text button present five differently-styled actions on one screen with no ordering.
- **Tablet composition:** no column strategy; feature rows stretch edge-to-edge within the max width; Explore rows look orphaned under their heading.
- **Empty-state quality:** the no-custom-workouts state reads as an unfinished disclaimer — flat card, title, one grey sentence, button floating at bottom-left with dead space around it.

These are presentation findings only. No functionality issues were found or invented: routes, active-program logic, custom-workout CRUD, catalog, skill trees, persistence, generation and history all behave correctly and stay untouched.

## Planned visual direction

Workouts becomes a premium fitness-content hub on the Step 1 layered background (`FitFlowVisualV2.page`), with unmistakable hierarchy:

1. Page header — brand kicker + page title + one-line intro (Home's header rhythm).
2. **Active program continuation** (only when real) — promoted to first-class emphasis using the V2 hero surface and the programs art, with exactly the current name/session-position texts and the current Continue navigation.
3. **Programs — primary feature card** — full-width media card: original "path and terraces" progression artwork over the hero band, the existing truthful Programs copy, single clear native action to the unchanged programs route. It carries the strongest visual weight and reads "structured training over time".
4. **Custom Workouts — medium section** — clearly user-authored: designed empty state (compact original builder artwork + existing explanation + one existing Create action); populated state keeps real templates, truthful summaries/estimates and existing View/Edit, restyled onto V2 surfaces with one restrained create action.
5. **Explore — compact secondary tiles** — Exercise Library and Skill Trees as smaller tonal tiles with original atlas/branch artwork chips and existing copy; same destinations, clearly lower mass than Programs/Custom.
6. Trailing adaptive-workout note retained unchanged (text + `Go to Home`).

A single reusable, opt-in media system ships with it: `FitFlowV2FeatureCard` (emphasis variants + art/title/supporting text/metadata/action slots) and `FitFlowV2ExploreTile`, backed by a small original static `CustomPainter` artwork family (Programs / Custom / Library / Skill Trees) in the FitFlow illustration language: premium editorial geometry, gender-neutral movement/equipment/progression themes, emerald-mint family with restrained warm accents, crisp at small sizes, decorative-only, no text, no network or bitmap assets.

Controlled variation — one hero-scale feature card, medium cards, compact tiles — same system, no card soup. Restrained entrance fade + native press states only; reduced motion is immediate. Artwork always yields before text at large scales.

## Verification plan

Light/Dark at 320×700, 360×800, 390×844, 430×900, 600×900, 840×1000, 1024×768 and 900×320 landscape; 1× and 2× text; reduced motion; empty and populated custom states; no active program, mid-program and complete-program states; decorative-artwork semantics; painter repaint contracts; native tap/keyboard actions; dispose checks. Preserved Part 4/Part 6/Workouts/program/skill-tree suites remain the behavioral contract. Analyze, targeted tests, full serial test run, `git diff --check`, and test-only captures reviewed outside the repo. Physical Oppo A12 appearance, font rasterization, TalkBack, insets and scrolling smoothness remain pending manual QA.
