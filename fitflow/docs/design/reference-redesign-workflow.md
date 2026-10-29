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
