# Part 6 — cross-app audit (before implementation)

Baseline verified against fetched GitHub main: `c47cb9928a6bb00ff0fbd843f44e682f3904f039`; source clean. Parts 1–5 and all behavior/data contracts remain canonical. This is a correction pass, not a new design or release task.

## Concrete findings

| ID | Classification | Production evidence | Narrow correction |
|---|---|---|---|
| A1 | accessibility | `splash/splash_screen.dart`, recovery action wraps the native FilledButton in ExcludeSemantics and supplies a named/button node without its native tap action. | Preserve native button semantics and attach only the explanatory hint; do not change startup/retry logic or splash identity. |
| A2 | motion / accessibility | Program switch/restart, custom deletion/discard/prescription dialogs and custom add-exercise sheet use default overlay animations, unlike the reduced-motion-aware overlays elsewhere. | Use the existing SystemMotion architecture to supply token durations/zero reduced duration; callbacks/results stay identical. |
| A3 | loading/error/empty / accessibility | Progress movement snapshot uses a raw perpetual spinner and card-only error without Retry; equivalent Profile capability states use shared feedback. | Shared reduced-motion loading and sanitized Retry via invalidating the same read provider. Keep current data presentation/scoring unchanged. |
| A4 | loading/error/empty / motion | Tuning loads evidence using a label-free spinner; applying feedback replaces its labelled button with a spinner only. Custom builder similarly substitutes a label-free AppBar spinner. | Label activity using localization-ready existing/new copy and canonical feedback; provide a static reduced-motion alternative. Preserve every save/apply callback. |
| A5 | motion / consistency | The centralized page transition delegates to Material zoom (320ms forward), while authored feature motion is restrained, token-based and non-scaling. | A single 200ms fade in the existing page transition builder, immediate with reduced motion. No custom per-route implementation or route changes. |

No other issue is asserted solely from a stylistic preference. Additional issues may be added only if production-widget matrix/capture evidence reproduces them.

## Audited coverage and decisions retained

- Startup: routing/retry reads inspected; recovery action defect A1. No brand/splash redesign.
- Onboarding and Movement Check: canonical type/selection and width/short-height fallbacks; independent saving/gates remain untouched.
- Home: canonical typography/insets, current adaptive inputs, mode controls, bounded purposeful entrance fade; generation and comeback policy untouched.
- Main shell: same four destinations, same-tab reset and branch persistence; native bar/scrollable rail. Add cross-window regression coverage, not a navigation redesign.
- Workouts/custom list/detail/builder: hierarchy, menus, labelled icon actions, lazy add-exercise list, local draft controls examined; defects A2/A4. No ordering/validation/persistence changes.
- Programs overview/detail/session preview/player: saved versus generated session ownership, honest statuses/duration labels, native Back and program dialogs examined; A2 only. No program/progression changes.
- Library/detail/skill trees: lazy results, localized filter semantics, search keyboard behavior, level presentation and capped reading layouts examined. No media or new sorting/filter logic.
- Progress/history: pagination remains progressive disclosure; chart has text alternatives. Capability loading/error mismatch A3, otherwise no new metrics or analytics changes.
- Preview/Player/replacement/rest/completion/tuning: existing action hierarchy, semantic timer (not live), keyed phase-only surface motion, scrollable replacement and tuning examined; A4 only. No timer, TTS, replacement, completion/history or progression changes.
- Profile/editors/Settings/Appearance/reminders/Backup/Privacy: Part 5 information architecture, native states, capped content and restore consequences retained. No schema, scheduler, legal URL, additional setting or support feature added.

## Shared-system review

Production feature scan found no literal brand hex colors or arbitrary feature font sizes; only intentional transparent colors. Typography comes from canonical roles. Brand colors remain centralized. The 640/720/760/800 caps serve differing reading versus working layouts; do not mechanically homogenize them without a demonstrated defect. Existing spacing/surface hierarchy is retained rather than replacing every Card or gap. Inspect captures for double headings/padding before any additional correction.

Library and replacement lists are lazy; history reveals more on demand; program lists are small/bounded. Player phase animation is keyed by phase, not second, and countdown is not a live region. No measured rebuild defect justifies a refactor or speculative repaint/memoization boundary. No added packages, shaders, blur, heavy shadows or bitmap assets.

## Validation plan

Representative production-widget matrix: 320×700, 360×800, 390×844, 430×900, 600×900, 840×1000, 1024×768 and 900×320; normal and 2× text; Light/Dark. Add focused semantics/motion/navigation/overlay/keyboard checks; retain existing Parts 1–5 tests. Capture at least the 14 requested representative states with clearly labelled fixtures, outside the production bundle. Run analyze, focused tests, all tests serially and diff check. Record physical Oppo A12 work separately as pending; no APK/AAB, branding, package or release work.

### Additional static finding before its edit

A6 (copy/consistency): custom builder entry summaries and add-exercise results emit `Level ${difficulty.name}`, equipment `.name`, exercise type `.name`, and a section enum in the sheet heading. This exposes strings such as `level1`/`resistanceBand` instead of canonical human labels. Use the existing localized difficulty, movement, equipment and section adapters; localize the two new presentation labels. Do not change enum values, eligibility, default workloads or filtering.

### Matrix finding before its edit

A7 (responsive/spacing/accessibility): new production-route matrix reproduces custom builder action-row overflow at 320×700 even at 1× text for a stored missing-catalog entry (339px right overflow), and at 2× for ordinary actions (99px). The Edit/Remove/missing-exercise message is a nonwrapping Row. Change only that presentation row to Wrap with canonical spacing; preserve edit/remove callbacks and unavailable-entry validation. Keep missing-catalog TEST fixtures so recovery layout stays covered.

A7 also reproduces a 9.2px overflow in the builder section heading/Add exercise row at 2× text (358px available). Its existing compact fallback considers width only. Include large text in that existing stacked fallback; no new layout system.

### Interaction finding before its edit

A8 (responsive/loading-empty): custom add-exercise sheet at 2× text overflows its empty-results Column by 189px at 320×700 and 168px at 900×320. The fixed title/search + Expanded list cannot give its empty message a scroll fallback. Use one keyboard-aware CustomScrollView with a header sliver, empty-message sliver, and the same lazy separated result builder/controller. Eligibility, ordering, search, default prescription and pop result remain identical. Library keyboard checks additionally require a real scroll/drag (which dismisses focus) and a hit-testable Filters action, not merely finding offscreen text.

A2 follow-up scan: the sole authored PopupMenuButton (custom workout actions) also retains Material's 300ms default under reduced motion. Apply the same centralized 200ms/zero overlay style; preserve items and callbacks. The Part 1 route-duration test is updated from emphasized to standard to assert the intentionally refined central timing, not removed or relaxed.

A8 empty-state recovery: when search narrows the add sheet to zero results, describe no matching results rather than claiming no eligible exercises exist. Keep the eligible-empty explanation for an empty query and offer the existing search controller's Clear search action for a nonempty query. New copy goes through ARB; search/eligibility logic is unchanged.

### Final capture finding before its edit

A9 (responsive/navigation consistency): the font-corrected 840×1000 Home capture shows the rail floating vertically in the middle of the page. The rail explicitly requests `groupAlignment: -1`, but its outer Row uses default cross-axis centering and the short scrollable child shrink-wraps. Stretch the existing navigation chrome to the available height and retain its configured rail surface background, so destinations begin at the SafeArea top and the divider/surface span the window. Keep the same native NavigationRail, scroll fallback, breakpoints, state, labels and callbacks. Add a top-alignment assertion to the real branch-resize regression. No new shell or floating-navigation design.

## Validation resource handling

The original single-file matrix retained enough test-process memory across hundreds of route fixtures to pressure Arena's ~2GB sandbox. Keep all 77 new cases and all 800 route/phase combinations, but register the unchanged matrix through eight small per-width test entry points sharing `test/helpers/part6_quality_helpers.dart`; the cross-app interaction suite remains separate. This bounds individual test VM lifetimes without skipping, weakening or deleting assertions. Compiler/test-runtime heap limits are cache-only tooling, not production or repository configuration. Interrupted/heap-exhausted intermediate runs are not counted as passing full-suite evidence.

A1 regression follow-up: the unchanged M22 test requires Retry's explanatory hint on the named button node. The first native-action correction kept the hint on an outer semantics node, so that existing assertion correctly failed. Move the hint semantics inside the native button's text child, preserving the native action, label and hint together. Retain the M22 no-write/hint assertion unchanged and strengthen the Part 6 check with the hint. Only the final all-pass full run will count as completion evidence.

## Final outcomes — 2026-10-10

All A1–A9 corrections are implemented. Native Retry now retains label, hint and tap on the same button; M22's original hint/no-write assertion passes unchanged. No further cosmetic redesign was undertaken.

- Focused: `flutter test --no-pub --concurrency=1 test/part6*test.dart test/fitflow_design_system_test.dart test/accessibility_motion_target_test.dart test/accessibility_semantics_test.dart --reporter expanded` — **99 passed, 02:19** (77 new Part 6 cases plus 22 existing design/accessibility cases).
- Full: `flutter test --no-pub --concurrency=1 --reporter expanded` — **2,182 passed, 11:33**, exit 0. Includes all prior tests. The sole changed prior expectation asserts the intended central route token (standard, not emphasized); no test was disabled or weakened.
- `flutter analyze --no-pub` — **No issues found, 6.9s**. Dependencies resolved beforehand; manifests/lockfile unchanged.
- `git diff --check` — clean. Business/state/router/platform/dependency/release scope guard passed.
- Representative matrix: 8 requested sizes × 2 themes × 2 text scales × 22 production routes = **704 route combinations**, plus work/rest/completion in production navigation chrome = **96 phase combinations**. Dedicated tests cover navigation persistence/reset/Back/rail alignment, native semantics, keyboard filter activation and simulated keyboard scrolling, Program overlays, custom add/search/empty/clear and reduced-motion loading/menu/routes.
- This is not every transient state at every size. Existing Parts 1–5 suites supply additional onboarding, replacement, tuning, program-origin, editor, reminder, Backup/Restore and history assertions.
- External harness `/home/user/part6_visual_capture_test.dart` produces **17 actual production-widget captures**, all with TEST data: requested 14 states plus compact Library, short landscape Player (scrolled to timer), and expanded Home at 2×. Roboto/Material Icons and rail text styles are registered for captures only; no production font override. The final rail capture confirms top alignment and full-height chrome. Offline gallery: `/home/user/fitflow-part6-visual-review.html` (~2MB); PNGs and harness are outside the repository/application bundle.
- All 17 views reviewed for hierarchy, spacing, legibility and surface consistency. Existing typography, caps, brand palette and feature layouts retained where no defect was demonstrated. Brand configuration remains centralized and provisional.
- **Physical QA remains wholly pending** in `part-6-oppo-a12-qa.md`: smoothness, Android font rasterization, TalkBack, real keyboard/system insets, OEM notifications, TTS/file picker and lifecycle/restart behavior. No APK/AAB, release/signing/package or final-brand work.
