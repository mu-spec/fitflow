# Part 5 — utility experience validation

Baseline: `d04ca98781e458c5a1a0377495d9155556221cfb` (Parts 1–4).

## Scope and preserved contracts

Presentation, localized copy, focused tests, and design notes only. No changes to application/domain/data/state controllers, backup schema/codec/transaction, reminder services or Android code, routes, workout generation/progression, Player, TTS, history, custom persistence, dependencies, signing, branding, or release configuration. No APK/AAB was built.

- Profile summarizes the actual persisted fitness inputs and all equipment/preferences; editors retain independent drafts and explicit save/validation/discard behavior. Canonical selection controls, retry/missing states, Save/Cancel and keyboard-inset-aware capped actions replace legacy presentation.
- Fitness options are current-value disclosures, not an onboarding wizard. Existing save calls and adaptive invalidation remain unchanged. Busy presentation disables edits/Cancel/Back while an existing save completes.
- Movement levels are read-only current values with Just starting / Basic / Solid / Strong / Advanced labels. There was no post-setup capability editor to preserve; the first-run assessment and its redirect gate are untouched.
- Settings groups only existing utilities under Preferences / Data / About. Appearance uses native radio semantics and remains persist-first; selection is not published on failure.
- Reminder disclosure preserves lifecycle/status refresh, native time picker, ISO weekday values and controller calls. A presentation guard serializes disabled-preference writes and test actions not covered by controller busy state. Before preferences load, show loading rather than claiming Off. Native switch and chip semantics retain their actions.
- Backup Create remains primary and uses the existing picker. Preview renders only validated data, names movement progress without exposing internal evidence terminology, and states replacement/no merge before confirmation. “Cancel preview” accurately describes the existing discard-only action. Canonical destructive confirmation preserves cancel/restore semantics and precise rollback outcomes.
- Only the existing in-app privacy entry is exposed. Notification-permission copy now says “when Android requires it.” No version/contact/URL/support setting was invented; public policy publication remains a separate release blocker.

## Automated results

Environment: Flutter 3.47.7 / Dart 3.13.5. All runs below use the final source; no tests were skipped to obtain a pass.

- `flutter analyze --no-pub`: **PASS**, no issues, 3.2 seconds.
- Targeted Part 5 regression run: **PASS**, **560 tests across 37 suites**, 01:36, `--concurrency=1`.
- FULL `flutter test --no-pub --concurrency=1 --reporter expanded`: **PASS**, **2105 tests**, 05:11.
- `git diff --check`: **PASS**, clean before staging; staged diff is checked again before commit.
- Added **29 tests**, including **98 expanded utility-route layout combinations**: 7 routes × 7 window sizes × Light/Dark, all at 2× text. Sizes: 320×760, 390×844, 430×900, 600×900, 840×1000, 1024×768, 844×390 landscape.
- Additional new assertions cover actual current values, all ten human capability levels, native radio/chip tap + checked/selected semantics, disabled-write duplication, quiet native picker cancellation, unsaved Cancel/Keep editing, editor retry/missing recovery, reduced-motion disclosures, 48dp controls, keyboard-inset-safe save actions, restore consequences and discard-only preview behavior.
- Existing functional assertions were retained. The full-suite accessibility tests now open Appearance and inspect merged native radio semantics (including checked, mutual-exclusion and tap-action flags), rather than the old manually assembled label. Tests now open actual disclosures, inspect the actual busy label, wait for canonical dialog transitions, use the uncarded reminder section for theme inspection, and expect full wrapping equipment/preference values.

Targeted coverage: profile models/persistence/editing/safety; equipment/preferences; capability assessment/provider/storage; appearance persistence/restart; actual Settings routes; reminder controller/permission/schedule/cancellation/storage/navigation/widget flows; backup file service/codec/strict validation/transaction/controller/widget flows; localization; Part 5 presentation tests.

## Visual review and performance boundaries

Eight captures of real Flutter widgets with seeded fixtures were generated outside the repo: Profile Light/Dark, Settings Light/Dark, fitness editor, movement disclosure, reminders, and backup. Roboto and Material icons were loaded in the capture harness only. Visual review corrected vertical centering on short utility screens and removed the duplicate reminder switch heading. The optional workspace gallery is `fitflow-part5-visual-review.html`.

Existing color/type/motion/layout systems remain authoritative. Disclosures use the standard motion token (zero for reduced motion); canonical selection/confirmation components handle their own motion. No decorative controllers, looping animation, blur, network media, or new packages were added. Native pickers and Android delivery are not simulated device-performance evidence.

The first exploratory run exhausted the 2GB sandbox during compilation. A 512MB frontend cap was insufficient; a cache-only 768MB Dart AOT heap cap and serial tests completed the targeted run. This tooling adjustment is outside the repo, not an app modification. Failed exploratory runs are not counted as passing results.

## Oppo A12 checklist — not executed here

1. Open Profile and compare every summary with the actual saved values.
2. Edit goal and experience; test Save, Cancel, Back, Keep editing and Discard.
3. Edit usual duration and environment; verify future adaptive setup uses them.
4. Select None, then multiple equipment items; verify exclusivity and persistence.
5. Edit all workout preferences and verify the full wrapping summary.
6. Expand movement levels; verify ten human labels and no raw levels/enums.
7. Select System, Light and Dark; leave/reopen Settings and confirm selection.
8. Enable reminders; check permission behavior appropriate to Android and existing denied-permission recovery.
9. Edit reminder time/days; cancel the native picker once and verify no change.
10. Check actual reminder arrival when Android allows delivery, then tap it and verify the intended destination; do not assume exact delivery timing.
11. Disable reminders and verify the device no longer has the previous owned schedule.
12. Create a backup through the system picker; verify the chosen file, then repeat and cancel quietly.
13. Change recognizable profile/theme/workout data after the backup to distinguish restored values.
14. Try an invalid file and cancel a picker/confirmation; then restore the valid file after reviewing replacement/no-merge consequences.
15. Verify restored profile, movement levels/progress, history, program progress, custom workouts, reminders and appearance against the backup.
16. Restart the app/device; recheck profile, theme and reminder reconciliation.
17. Review all utility screens and dialogs in Dark mode.
18. Repeat at maximum/2× text with TalkBack and keyboard/focus navigation where available.
19. Repeat in landscape; verify scrolling, save actions and picker/dialog actions remain reachable.
20. Check clipping, tap targets, focus visibility, scroll smoothness and stutter on the physical Oppo A12.

Do not treat this checklist, widget tests or captures as completed physical-device testing. Part 6 and release work remain unstarted.
