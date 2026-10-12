# Visual V2 / Step 3 — Workouts validation

Baseline: `8f2277e9ee4753bd072f589d2873b549995d1904` → commit `feat: bring FitFlow Visual V2 to workouts`. Scope: the Workouts landing screen and the reusable Visual V2 feature/media primitives it requires. No other screens were redesigned. See `visual-v2-step-3-workouts-audit.md` for the pre-implementation audit.

## Feature visual language

One coherent FitFlow illustration family (`lib/core/design/widgets/fitflow_v2_feature_art.dart`): original static `CustomPainter` compositions built from rounded geometric slabs, single round-capped movement paths, milestone nodes and faint ground lines — premium editorial geometry in the emerald/mint palette with one restrained warm accent. Gender-neutral themes of progression, user-authored content and movement exploration; no anatomy, no figures-as-models, no medical graphics, no photo-styled instruction, no text, no logos, no competitor-derived compositions, no assets and no network.

- **Programs — "Path & Terraces":** ascending weekly terraces with one guided route and milestone nodes rising to a warm-ringed destination — structured training over time.
- **Custom Workouts — "Built by you":** a user-assembled stack of slabs, the top one still being placed, beside tuning sliders — authorship and control.
- **Exercise Library — "Movement atlas":** a field of atlas tiles holding two abstract movement marks with one focus ring — reference and exploration, not fake screenshots.
- **Skill Trees — "Branching path":** one base node growing upward into split branches with a warm growth tip — a secondary progression tool.

Art is decoration-only (`ExcludeSemantics`), static, deterministic; painters repaint only when a color input (or the composition kind) changes, verified by test. Styles are explicit per surface: hero styles derive from the hero band's own contrasting roles; standard styles use brand-on-tint — Light and Dark are intentionally tuned, never inverted.

## Media components

`lib/core/design/widgets/fitflow_v2_feature_card.dart` (opt-in, Step 3+):

- `FitFlowV2FeatureCard` — art panel + title + concise supporting text + optional metadata; `primary` emphasis is the V2 hero band, `secondary` a quieter supporting surface. Exactly one action per card: a native `ListTile` for navigation-led features, or one explicit CTA below the copy. Artwork is caller-sized and always yields before text at large type scales.
- `FitFlowV2ExploreTile` — compact secondary tile (52dp art chip + concise copy + chevron + native `InkWell`, ≥64dp target) so explorer tools support the hub without rivaling primary features.

Both render on the shared V2 roles, wrap freely, and suit later Programs / Library / Progress / Profile entry points without forcing one layout.

## Hub hierarchy (all real state, all existing destinations)

1. **Page header** — brand kicker, `Your workouts` title, one-line intro (Home's V2 header rhythm).
2. **Active program continuation** (only when real) — promoted to first-class emphasis on the V2 hero surface with 88dp (64dp at large text) decorative programs art; identical texts, factual session counts/next-session position, identical Continue/View navigation to session preview or detail.
3. **Programs — primary feature card** — full-width hero media card, Path & Terraces banner, existing truthful `Programs`/`Structured plans that adapt…` copy, single native row action to the unchanged `/workouts/programs` route. Strongest visual weight on the page.
4. **Custom Workouts** — section heading plus: (empty) a designed secondary feature card with the builder artwork, the existing explanation and exactly one existing Create action; (populated) the existing authored list with truthful target/exercise/estimate/movement chips and unchanged View/Edit/delete behaviors on V2 info surfaces, with the existing restrained `Create custom workout` action.
5. **Explore** — Exercise Library (`Browse {realCount}` from the real catalog) and Skill Trees as two compact tiles; a two-column grid only where labels remain readable (≥520dp, normal text), otherwise one readable column. Clearly secondary mass.
6. **Adaptive note** — existing text + `Go to Home` on a tonal supporting surface.

Controlled variation — one hero-scale card, medium cards, compact tiles — one system, no card soup. The page uses the Step 1 layered V2 background; emerald emphasis is applied selectively (hero features only).

## Behavior preserved

Routes and destination ownership, active-program logic, program switching/progress/catalog, custom-workout CRUD and resolver, Exercise Library and Skill Tree behavior, persisted state, generation, capability logic, history, Player, backup, reminders and navigation-shell semantics are untouched — the diff touches two presentation files plus new widgets/tests/docs. All pre-existing Workouts, programs-integration, skill-tree, custom-workout, Part 4 (2× reading surfaces at six sizes both themes) and Part 6 production-route suites pass unchanged.

## Automated validation

Test-only captures were rendered at 430×1560 (light/dark), populated and active states, 320dp, 2× text, 840dp tablet and 900×320 landscape, reviewed against the production widgets and discarded (never committed). Automated checks added in `test/visual_v2_workouts_test.dart` (47 tests):

- **Hierarchy/content:** header order, feature-card count, V2 background on the hub scaffold, vertical section ordering; active program leads Programs when real; no hero band when nothing is active.
- **Programs entry:** hero art kind, decorative semantics, `ListTile` native action to ProgramsOverview; complete-program continuation to detail.
- **Active program:** `FitFlowV2HeroSurface` emphasis, real `4 of 12 sessions`/`Week 2 • Next: Session 2`/Continue ≥48dp to session preview; absent state shows no hero.
- **Custom empty/populated:** designed secondary card, builder art non-hero, exactly one Create (≥48dp) routing to create; authored names, truth-bearing summary/estimate/View/Edit retained.
- **Explore:** both tiles with real destinations and counts, ≥64dp targets, taps reach Library/Skill stubs.
- **Media semantics/perf contracts:** every art subtree is `ExcludeSemantics`; no status by image/color alone (text labels asserted); all four painters repaint exactly on kind/color change.
- **Light/Dark:** art ink equals the surface role in each mode, differs between modes (tuned, not inverted), ink/panel contrast ≥2.0 in both.
- **Layout matrix:** 320×700, 360×800, 390×844, 430×900, 600×900, 840×1000, 1024×768, 900×320 × Light/Dark × 1×/2× text with active-program and populated-custom states — no overflow, landmarks present, Programs scroll-reachable.
- **2× text:** Programs art shrinks 116→76 (artwork yields before text); tablet Explore collapses from two columns to one at 2×; feature cards stay within the readable max width.
- **Landscape:** content scrolls, `Go to Home` reachable.
- **Reduced motion:** all screen-owned entrance builders are `Duration.zero` under `disableAnimations`, nonzero otherwise.
- **Targets/actions:** ListTile/InkWell ancestors present; Create/Continue/View/Go to Home ≥48dp.

Commands (this SDK): `flutter analyze --no-pub` — clean; targeted Workouts/V2 suites — green; full `flutter test --no-pub --concurrency=1` — **2300/2300 green**; `git diff --check` — clean.

## Performance considerations

No network image fetches, no bitmap assets, no packages, no shaders/blur/expensive shadows, no loops or tickers: four tiny `CustomPaint`s paint once and repaint only on theme/kind change; two restrained 200ms entrance fades honor reduced motion; explore tiles share the existing surface vocabulary. No physical smoothness claims — on-device appearance remains to be verified.

## Physical QA still pending (Oppo A12)

Real appearance and emerald/mint tuning on a physical display; font rasterization and wrapped-label rendering; TalkBack reading order and grouping on feature cards; system insets/nav-bar contrast at the hub scroll edges; large-dynamic-type rendering beyond the 2× matrix; scrolling smoothness with the static painters; reduced-motion behavior at system level.

## Regression found and fixed during final validation

The full-suite rerun caught a Part 6 cross-app failure that the targeted suites
had not: `showModalBottomSheet` on the deep-linked custom-workout builder never
mounted (only under the deep-linked `/workouts/custom/new` initial-location
stack; the same flow via explicit `router.push` worked). Bisection isolated the
trigger to a root-level `LayoutBuilder` on the Workouts route page — when that
page is built offstage in the deep-linked route stack, its deferred build
disturbed the modal route's presentation on the leaf page. Fix: the page now
sizes its root padding/art-menu via `MediaQuery.sizeOf(context)` (commented in
code) instead of a root `LayoutBuilder`; inner `LayoutBuilder`s (hero card
split, Explore grid) were A/B-proven harmless and remain. The focused V2
harness was also updated to mirror the production `MediaQuery` size (its
custom wrapper shadowed the view size at the root lookups). Re-verified:
analyze clean, Part 6 cross-app suite green, V2 suite 47/47, full suite
2300/2300, `git diff --check` clean.
