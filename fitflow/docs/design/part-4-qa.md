# Part 4 — training and progress QA

Baseline: `a4be213dfcf6c0d2c28ad4c263ae165f64e2a6b3`.
Scope: Workouts, Programs browse/detail, Custom list/detail, Exercise Library/detail, skill trees, Progress/history presentation and localization. See `part-4-audit.md` for the audit recorded before source edits.

## Implementation boundaries

- No production domain/application/data/state, router, core design/theme, Player, timer/TTS, program origin, storage/schema, catalog, eligibility, scoring or analytics/recovery calculation changes.
- `exercise_library_filter.dart` and the entire Custom Builder remain unchanged. Query matching, AND-between/OR-within categories, ordering, prescriptions and persistence use the existing implementations.
- Program start/resume/switch/restart/completion APIs and every session-preview route remain intact. Completed sessions remain inspectable. Presentation maps `planned` to Upcoming; it adds no lock or completion rule.
- Current skill-tree fit is not exercise mastery. The resolver does not identify one assessed current exercise, so the family screen does not invent one. Exercise detail retains the existing easier/current/harder neighborhood.
- History has no stored workout title/origin or elapsed duration. It shows generic Completed workout, real timestamp/counts and explicitly estimated/planned duration; it does not infer origin from IDs or change schema. Effective replacements remain visible through the existing history detail.
- History Show more is local presentation pagination, ten records at a time. It does not re-sort, fetch, mutate or truncate storage.
- No package, network asset, font architecture, identity, signing, Gradle, release or APK/AAB changes. Profile/Settings/Reminders/Backup-Restore are not redesigned.

## Regression fixes discovered during development

1. Exact counts must not be supplied as the numeric semantic value of Flutter's progress-bar role. Counts are visible text and the semantic label; the determinate bar retains the real numeric fraction.
2. Uncontained native ListTile ink on an offstage shell branch can register against the outer shell Material before its route is laid out. Local transparent Material boundaries in Workouts and Progress contain ink; the canonical shell/router remain unchanged. Real deep-link Library/Detail tests exercise this path.
3. New hierarchy/disclosure requires tests to scroll to Explore, scroll to later program rows, or open Default Prescription / Exercise characteristics / Training recovery. These are real UI actions, not suppressed tap warnings or removed assertions.
4. Native text-button compact density was removed from program session actions so the canonical 48dp minimum is retained.
5. Native semantics selection is Flutter's tristate value; the added test explicitly verifies selected, tap and focus semantics and disposes its semantics handle in a finally block.

## Added coverage

`test/part4_training_progress_test.dart` adds 21 tests, including:

- Twelve 2× Light/Dark viewport cases: 320×700, 390×844, 430×900, 600×800, 900×800 and 900×320. Each exercises ten production reading surfaces (120 combinations), including a long-name saved custom workout, real skill family, populated Progress/history, and deep exercise/analytics disclosures.
- Stable query/controller under keyboard inset changes, scrolling back to search, combined quick filters, clear-filter versus clear-search behavior, lazy row construction and immediate reduced-motion selection.
- Genuine advanced movement/difficulty filtering through human labels, active count/selection summary and Clear all, compared against the unchanged filter implementation.
- Both native disclosure durations (200ms / zero), history pagination with real records, truthful empty Progress, exact chart text/bar values against the unchanged engine, sanitized history error + native retry recovery, and 48dp/focus/tap/selected semantics.

Existing tests retain functional assertions for custom save/edit/delete and persistence, program progress and exactly-once origin/Player flow, catalog content, search/filter semantics, progression/eligibility and analytics calculations. Presentation-only assertions change where the UI intentionally changes. No tests are skipped or disabled.

## Validation results

Final serial validation on Flutter 3.47.7 / Dart 3.13.5:

- `flutter analyze`: **no issues**, 6.1s.
- Focused 40 suites, `flutter test --concurrency=1 …`: **500 passed**, 2m39s.
- FULL `flutter test --concurrency=1`: **2,076 passed**, 8m07s.
- `git diff --check`: **clean**.
- Six production-widget captures: successful; temporary capture harness removed.
- No build command run, no APK/AAB, no physical-device QA claimed.

Earlier failed development runs are not represented as passing final validation.
The final full suite includes all prior functional regression coverage and 21 new
Part 4 tests. Protected production paths, the custom Builder and the Library
filter implementation were verified unchanged.

Six real widget captures at 390×844 are provided outside the repository in the visual-review gallery. They use seeded test profiles/history, not the user's records. Roboto and Material Icons are explicitly supplied to the test renderer, including native control text; production fonts are unchanged. These captures do not establish physical-device performance or TalkBack behavior.

## Oppo A12 checklist — not yet executed

Use a separate test installation; do not clear wanted history without backing it up. Record the tested commit, Android version, theme, orientation and font/display scale. No APK/AAB is produced in this task.

1. **Organization:** Home still owns today's adaptive workout. Workouts clearly prioritizes Programs and Custom Workouts, with Explore secondary. No duplicated recommended-card stack or cramped grid. Home text action returns to the existing destination.
2. **Programs browse:** verify all five factual names/purposes, length/session facts, selected-goal match and Not started / In progress / Completed. No ratings, calorie estimates or fake difficulty.
3. **Detail / continue:** start a program, identify exact count and next session, then Continue into the unchanged preview/Player. Check week structure and text+icon status. View a completed session without changing counts merely by inspecting it.
4. **Completion / persistence:** complete a session and verify one history record and one program completion. Relaunch and confirm the next session. An entirely completed active program offers View program, not a nonexistent next session. Cancel restart/switch dialogs and verify no mutation; confirm only on test data.
5. **Custom empty / create:** one useful Create action. Build and save a workout using the unchanged Builder. Verify name, ordering, all sections and prescribed workload after reopening.
6. **Custom actions:** View, Edit and delete confirmation remain usable. A long name wraps; target and estimated durations are distinguished. Cancel deletion preserves data; confirmed deletion does not remove workout history. Missing catalog entries do not display internal IDs in detail.
7. **Library discovery:** scroll the actual 88 active exercises, inspect concise name/focus/equipment rows, search mixed case and muscle/equipment terms, clear the query, and open details.
8. **Filters:** combine quick and advanced movement/difficulty/equipment/position selections. Verify active count and visible selection summary. Clear filters preserves query; Clear all resets both. Check empty results and recovery action.
9. **Keyboard / search state:** type with the keyboard open, rotate, scroll and return to the field; query is not lost. Open filters without the keyboard obstructing them. No per-keystroke animation or layout overflow.
10. **Exercise detail:** verify catalog name/description/setup/instructions, factual muscle/caution/breathing content, then expand workload and characteristics. No illustration promise, raw enum/rank/ID or invented form/medical claim.
11. **Progressions:** inspect easier/current/harder detail links and full family. Movement-level fit and setup fit remain separate. No locks, XP, completion/mastery or inferred unlocks. Unknown level stays unavailable.
12. **Progress / history:** three real headline signals, recent history before detail analytics, date/time and real counts. Planned/estimated duration is not labeled elapsed. Open a history row and verify effective replaced exercise, ordered sections and workload. With >10 records, Show more preserves order.
13. **Trends / empty / retry:** expand actual eight-period chart and switch workouts/sets; compare labels/counts, including zeros. Read the text equivalent with TalkBack. Empty Progress explains completed workouts and has one training action. Simulated storage error is sanitized and retry uses the existing controller refresh.
14. **Light / Dark / large type:** review text, outlines, selection and disabled controls in both themes at default and 2× text. No clamping. Rotate phone/landscape, scroll long content and confirm the same selected filters/program state.
15. **Accessibility / motion:** native buttons/chips/menu actions are reachable with TalkBack and focus navigation, selected/progress states are understandable without color. Enable reduced animations: disclosure/filter/sheet changes complete immediately; no decorative loops or cascading list entry.
16. **Performance:** fling through Library repeatedly, type/clear rapidly, open/close filters and exercise detail, and paginate history. Note input delay, dropped frames, memory growth or clipped labels. Widget tests do not substitute for this low-end-device check.

Stop after Part 4. No Part 5 redesign or release build is included.
