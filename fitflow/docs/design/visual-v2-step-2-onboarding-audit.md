# Visual V2 / Step 2 — preimplementation audit

Baseline: published `a9d9edc20574c650975d73179b22387b00d305c4`. Inspected all eight onboarding pages and six field presentations, shell/progress/intro/choice controls, assessment screen/copy, native selection primitives, V2 palette/surfaces, typography/spacing/radii/motion, existing onboarding/equipment/preference/assessment/Part 2 tests and responsive helpers before production edits.

## Onboarding findings

- Welcome has two competing large titles followed by plain benefit rows. The identity and adaptive-home-training idea lack a distinctive visual anchor.
- The shell is a largely uniform neutral form: heading, explanatory text, generic choices, progress bar. It lacks the emerald/mint emphasis established by Home.
- Single choices and checkbox lists use similar pale surfaces; goal, duration and equipment do not have distinct content density or scanning cues.
- Progress is a generic unsegmented line. The exact eight-step position is truthful and useful, but visually disconnected from the brand.
- The existing bottom action arrangement is correct, but lacks a deliberate surface/boundary separating it from scroll content.
- Existing 320dp/short-height scrolling, disabled validation, state retention, error text, selection semantics and keyboard-inset resizing must be preserved. There are no text-entry fields in this setup: keyboard QA concerns an externally presented keyboard/inset, not invented input fields.

## Movement Check findings

- Intro, generic progress and repeated white cards resemble a questionnaire rather than one coherent movement setup.
- Category identity and suggested/changed status are low-emphasis text. Native level chips are usable but look generic and are weakly grouped with the selected explanation.
- Long prompts/examples are legitimate existing content; visual improvement should group them, not remove their meaning or add medical/exercise claims.
- The ten-category list is already lazy, the five human level labels are correct, and experience-derived defaults / per-pattern editing / persistence / completion gates are working contracts, not defects.
- Saving and recoverable failures already have truthful feedback. Style them without changing enablement, callbacks, retry paths or navigation.

## Planned direction

Reuse the V2 page/hero/support/tint roles, with an original static adaptive-track motif, a compact emerald welcome, segmented eight-step orientation and deliberate question headers. Add an opt-in reusable selection surface and safe-area-compatible action surface; retain native InkWell/CheckboxListTile/ChoiceChip behavior. Give duration a compact two-column layout where space permits, keep longer options readable, use purposeful goal/space cues rather than icons everywhere.

Movement Check gains a compact branded header, numbered category rhythm (ordinal only, not a score), grouped human-level controls and a quiet suggested/changed footer. No new disclosures, fields, screens, metrics, assets, dependencies or functional changes. Home and all deferred screens remain untouched.

## Verification plan

All requested sizes in Light/Dark; normal and 2× text; all steps/choices, None exclusivity, preference multi-select, suggested levels, ten categories, saving/failure/redirects, native semantics and reduced motion. Analyze + focused tests + ALL serial tests with external bounded heaps if needed; diff check. Actual-widget TEST-only captures outside Git. Physical Oppo A12 rendering, TalkBack, OS insets and smoothness remain unmeasured.
