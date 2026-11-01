# Reference redesign workflow — 29 October 2026

Baseline: `f077c64`, branch `arena-workouts-redesign`, 25 active exercises.

The user's reference screenshots and recordings guide visual hierarchy and organization. Keep Home Workout's real features, exercise catalog, saved data and behavior. Ignore reference advertising. Animation work remains deferred.

## Visual foundation

- Light: cool grey page, white grouped panels, dark ink and black primary actions.
- Lime header fade and restrained lime emphasis. Dark: charcoal panels, readable pale text and lime actions.
- Strong page heading, compact section labels, quieter factual metadata.
- Rounded panels for related content, with minimal borders and accessible wrapping.
- Neutral bottom navigation: selected dark/light icon and label; no teal selection pill.
- Existing exercise media and actual data only. Do not invent calories, body measurements, food tracking, challenges or recommendations.

## Milestones and review checkpoints

1. **Foundation, navigation chrome and Home**: opt-in theme, Home header/workout panel/action, compact mode and grouped details/Library. Preserve generation, state handling and Preview handoff. Device review before extending the treatment.
2. **Workouts and Programs**: compact discovery and saved workout sections, program covers, factual schedules/status, clear continuation and session rows.
3. **Exercise browsing and workout preparation**: Library, Exercise Detail, skill trees, Preview and custom builder. Consistent media, readable prescriptions, accessible filtering/editing.
4. **Player and completion**: reference-inspired hierarchy using existing controls, timers, pause/rest/replacement eligibility and completion semantics. No new auto-start or previous/next behavior. Animation deferred.
5. **Progress and history**: at-a-glance truthful summaries, readable activity charts and concise history, preserving calculations and completion definitions.
6. **Profile, Settings and onboarding**: grouped preferences, short summaries, readable choices and unchanged save/cancel/persistence behavior.
7. **Cross-flow review**: light/dark consistency, small phones, large text, navigation, recovery/empty states and device review.

## Milestone 1 implementation

`WorkoutDesignTheme` is reusable but opt-in; only Home consumes it now. Navigation appearance is scoped to the bar/rail, leaving all branch content themes intact. Home keeps its actual generated exercise media, proportional 4:3 presentation, planned-versus-target metadata, View workout -> Preview, mode sheet, conditional Comeback action, collapsed setup details, and Browse exercises destination.

No providers, routes, generation, stored data, media, dependencies, protected Android files or signing files are changed. Untracked backup/log/animation work is excluded.

## Verification

Scoped Flutter analysis: passed. Focused Home/dashboard/mode/design-system tests: 43 passed. Home responsive/navigation matrix: 43 passed after correcting primary-action clearance on 360x640 in both themes. Checks include 360x640, 360x800 and 412x915, other existing phone/tablet/landscape sizes, both themes, 1x/2x text, full 4:3 media, 48dp minimum action size, collapsed/expanded details, actual metadata, mode changes and Preview/Library navigation. Initial test compilation failed because C: had zero free space; retry uses ignored `build/home-review-temp` on D: without deleting user data.

Final verification after the last color adjustments: scoped analysis passed with no issues (17.2 seconds); the Home matrix and design-system tests passed again (56 tests). This rerun is a subset of the 86 focused tests above.

Physical device review remains required for actual font rendering, photography balance, scrolling and TalkBack. No APK/AAB, Gradle, screenshots, full suite, push or merge.

## Home organization revision — 30 October 2026

Device feedback requested the reference's discovery organization, rather than an oversized workout hero. Home now starts with seven local calendar dates and actual saved-completion markers, followed by a compact generated-workout card and its existing Preview action. A horizontal shelf displays the five real programs with their exact registered covers, names and week counts. Activity and Programs link to their existing destinations. Browse exercises remains visible outside the collapsed setup disclosure; its label/value rows now fit side by side on normal small phones and stack at large text sizes.

Workout generation, mode adjustment, Comeback behavior, metadata, saved preferences, media and neighboring screens are unchanged. The activity strip distinguishes today's date from saved completions and excludes future-dated records.

Validation: final scoped analysis passed with no issues. All 76 unique focused Home/dashboard/mode tests passed, including the responsive matrix, Preview/Library navigation, details expansion, actual activity dates, exact program-cover mapping and all program destinations. One new test initially failed due to an undisposed semantics test handle; after correcting test cleanup, only that failed test was rerun and passed. The matrix covers both themes, normal/enlarged text and representative 360x640, 360x800 and 412x915 layouts. Device review remains pending; no screenshots or APK were generated.

## Home identity polish — 30 October 2026

Home now uses a blue/lavender header wash, a flat activity timeline with an underline for today, and distinct peach, blue, mint, lavender and rose program cards (paired dark surfaces). Completion markers still represent actual saved records. Larger program photographs retain their original 4:3 composition and exact canonical mapping. Home's workout photograph now resolves directly through the static media registry, independently of animation availability elsewhere. The main heading remains 28 logical pixels, with 18-pixel shelf headings and 16-pixel program names; text scaling remains enabled.

Navigation and mode icons use the bundled Google Material family, available under Apache 2.0: https://developers.google.com/fonts/docs/material_icons. No new dependency, downloaded icon pack or stock photography was added. Existing approved static photography is reused. Navigation changes are icons only; destinations and shell behavior are unchanged.

Validation: scoped analysis passed with no issues; 76 focused Home/dashboard/mode tests and the existing four-tab navigation test passed (77 total). Coverage includes light/dark, 1x/2x text, 360x640, 360x800 and 412x915, program-card text contrast, exact static image mapping, Preview/Library/program routes, activity semantics and mode changes. Physical device visual review remains pending. No screenshots, media changes, APK/AAB, Gradle, push or merge.

## Home photographic cards — 30 October 2026

Device feedback requested larger image-led cards and richer colors. The workout card now uses full-width static registry photography with white title, actual planned/target duration and exercise count over a deep-blue lower-image overlay. The existing Preview action stays prominent. Program cards occupy most of the phone width, with canonical covers and saturated blue, purple, teal, burnt-orange and berry overlays. Their height grows with text instead of truncating titles.

The seven-date activity strip uses a compact navy panel with actual completion marks and a separate today indicator. Mode adjustment is grouped in a compact surface with a pill action; all existing modes and Comeback behavior remain intact. The bulky setup card enclosure is removed, while its collapsed disclosure retains real setup values and explanations. Browse exercises remains separate.

Validation: 76 unique focused Home/dashboard/mode tests passed. Coverage includes exact photo/program mapping, activity semantics, Preview/Library/program navigation, mode changes, disclosure content, 360x640, 360x800 and 412x915 plus existing responsive sizes, light/dark and 1x/2x text. The initial check identified one overlay contrast failure and mode tests needing to scroll to the larger layout; both were corrected and the affected 60 tests passed on rerun. White overlay text meets 4.5:1 contrast even over a white source image. Scoped analysis and diff checks pass. No media, domain, shared navigation, protected Android or signing files changed. No screenshots or APK built; device visual review remains required.
