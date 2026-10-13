# Visual V2 Step 4 — Programs validation

The implementation-turn record is retained below. The finalization addendum
at the end records the subsequently authorized complete-suite result.

## Baseline / environment

- Branch: `main`.
- Baseline and pre-commit HEAD: `d6535c94d8219fe837440699d158141e06e395d8`.
- Initial `git status --short`: empty (clean).
- SDK: official Flutter tag **3.47.7**, framework revision `abaf9c5237`;
  Dart **3.13.5 stable**, Linux x64.
- Workspace-local SDK: `/home/user/.cache/flutter-sdk`.
- `flutter pub get`: **exit 0**. No upgrade command was run;
  `pubspec.yaml` and `pubspec.lock` are unchanged.
- The prior SDK cache was absent when this turn began, so the same exact
  official SDK tag was reprovisioned outside the repository before editing.
  It remains an Arena runtime cache, not a committed project dependency.

An initial unbounded diagnostic test run reported an unexpected compiler
exit. Implementation targeted runs used validation-only SDK executable wrappers: AOT compiler
old-generation heap capped at 768 MB, `flutter_tester` at 384 MB. Original
binaries are preserved beside the wrappers, and existing tester VM flags,
assertions, test selection and application semantics are preserved. These
runtime controls are outside the FitFlow repository. No production or
existing test code was altered for resource handling, and no tests were
skipped in the final runs.

## Implementation-turn targeted commands and results

Run from the nested Flutter app directory, `fitflow/`:

```bash
export PATH="/home/user/.cache/flutter-sdk/bin:$PATH"

dart format \
  lib/core/design/widgets/fitflow_v2_program_cover.dart \
  lib/features/programs/presentation/programs_overview_screen.dart \
  lib/features/programs/presentation/program_detail_screen.dart \
  lib/features/programs/presentation/widgets/program_widgets.dart \
  test/visual_v2_programs_test.dart

flutter analyze --no-pub

flutter test --no-pub --concurrency=1 \
  test/visual_v2_programs_test.dart --reporter expanded

flutter test --no-pub --concurrency=1 \
  test/adaptive_programs_ui_test.dart \
  test/adaptive_programs_workouts_screen_test.dart --reporter expanded

git diff --check
```

| Final validation | Actual result |
| --- | --- |
| Scoped Dart format | All five changed Dart files formatted; exit 0 |
| `flutter analyze --no-pub` | **No issues found**, exit 0 |
| `test/visual_v2_programs_test.dart` | **36 passed**, no failures/skips, exit 0 |
| `test/adaptive_programs_ui_test.dart` | **28 passed**, unchanged test file |
| `test/adaptive_programs_workouts_screen_test.dart` | **12 passed**, unchanged test file |
| Combined existing program UI invocation | **40 passed**, no failures/skips, exit 0 |
| Total final targeted tests | **76 passed** |
| `git diff --check` | No output, exit 0 |

During the implementation turn the full 2,300+ suite was **not run**, and no
commit or push was made. The authorized full-suite finalization is recorded
below. Step 5 was not begun.

## New Step 4 coverage

- Exactly the five canonical program IDs, immutable catalog validation and
  original structures: 4x3/12, 6x3/18, 4x4/16, 4x3/12, 4x3/12.
- Stable-ID cover mapping, neutral unknown-ID fallback, all five distinct
  rasterizations, deterministic repeated painting, and repaint decisions
  for identity plus each palette input.
- Decoration-only covers (`ExcludeSemantics`, `RepaintBoundary`), with no
  Text/Image widgets and no complex/will-change painting hints.
- Branded overview and canonical name/focus/structure/status in media-led
  cards; one real active card, no duplicate program, correct next-session
  continuation through the existing router.
- Recommendation for every existing fitness goal and no match when the
  profile is absent, using the existing recommendation policy.
- Restrained completed state: true count, Program complete text/check,
  supporting cover treatment and ordinary detail navigation.
- Two columns at expanded normal-text width, one column at compact/medium
  width or 2x text, plus a constrained 650dp pane inside an 840dp window.
  Actual pair constraints require two >=340dp cards and their gap.
- Each program's original detail cover/title/description/focus/structure;
  native Start target height >=48dp.
- Nonsequential saved completions: completed / next / completed / planned,
  original week/session identities, first/last rail geometry, unchanged
  focus/goal metadata, >=48dp View workout and exact session-preview route.
- Rendering, discovery navigation and scrolling do not write saved progress.
- No invented metric text, heading/button semantics, native Tab/Enter
  activation, >=48dp targets, and no idle animation frames in either motion
  preference.
- Intentional light/dark colors. Tested primary text pairs meet >=4.5:1;
  decorative cover ink meets the tested >=2:1 art-panel threshold.

The new loading/error/retry presentation test mounts the real Programs
Overview in an isolated route. Its deliberate thrown-storage fault initially
also reached the **unchanged offstage Workouts parent**, whose existing
`AsyncError.value` read throws. Workouts is outside Step 4 and was not fixed
or restyled. Isolation keeps that test focused on the scoped state surface;
normal navigation tests and all existing regressions use the original full
program test router. Error/retry assertions are retained, not suppressed.

Other new-test harness corrections reflect real UI contracts rather than
weaken them: scroll in active-first display order, ensure lazy art is built
before measuring, use the existing localized loading copy, and inspect the
leaf `GoRouterState` for imperative pushes instead of assuming browser URL
reflection. No existing assertion was edited.

## Responsive and theme matrix

For **both Programs Overview and Program Detail**:

| Logical viewport | Light 1x | Light 2x | Dark 1x | Dark 2x |
| --- | --- | --- | --- | --- |
| 320x700 | Pass | Pass | Pass | Pass |
| 390x844 | Pass | Pass | Pass | Pass |
| 600x900 | Pass | Pass | Pass | Pass |
| 840x1000 | Pass | Pass | Pass | Pass |
| 900x320 landscape | Pass | Pass | Pass | Pass |

All 20 combinations exercise both screens, giving 40 screen configurations.
Overview traverses all five programs, including the active-first layout.
Detail uses the real six-week Strength Foundations program with saved
nonsequential progress, checks Continue/Restart, traverses all six weeks and
reaches their final View workout targets. No overflow/Flutter exception was
reported. Text scaling remains 1x/2x without a clamp; artwork yields first.

## Existing behavior regression coverage

The unchanged **28-test** program UI file exercises overview/detail,
recommendation, fresh Start, active continuation, saved progress, Resume,
Switch confirmation/cancel/preservation, Restart confirmation and clearing
only program progress, completion, unknown IDs, failed persistence and the
existing session-preview generation/status/routes.

The unchanged **12-test** Workouts/program integration file exercises the
original Programs entry, all goal mappings, missing profile, detail routes,
active and completed continuation, provider-state updates and route helpers.
Workouts, Session Preview and other excluded surfaces retain their code.

## Scope / locked-code verification

Final changes are exactly the four scoped production paths plus the new
Step 4 test and the two new design documents. No backup file was restored.

`git diff HEAD` confirms no edits to the program domain, catalog, status,
recommendation, controller, storage, router, resolver/generation,
`pubspec.yaml`, `pubspec.lock`, Workouts landing, Workouts program cards,
Program Session Preview/Player or existing tests.

A normalized comparison to baseline verifies `_ProgramActions` conditions
and callbacks are identical after removing only new button style and spacing.
The shared `ProgramTag`, `ProgramSessionStatusChip`, `ProgramNotFoundBody`,
`ProgramDialogs`, `ProgramProgressState` and `programStatusLabel`
implementations are likewise unchanged apart from formatting.

## Readiness / limits

**Implementation-turn handoff:** the scoped implementation, analyzer and
all requested targeted tests passed, ready for separately authorized full-suite
validation. That finalization is now complete below; this is not a
release/build approval.

No physical Oppo A12 performance benchmark, device run, Android/web build or
manual assistive-technology session is claimed. Static paint/repaint,
contrast, native keyboard/semantics and representative widget-layout checks
are the evidence from this turn. In a recreated Arena worker, reprovision the
exact official SDK if the excluded runtime cache is absent before continuing
validation. The initial handoff stopped before commit/push. Finalization
is separately authorized below; Step 5 remains out of scope.


## Finalization — complete serial full suite

### Final result

- `flutter analyze --no-pub`: **No issues found**, exit 0.
- Complete suite: **2,336 passed / 0 failed / 0 skipped**.
- **164 distinct test files**, covered exactly once in the completed grouped
  validation: no missing, unexpected or duplicate file entries.
- **14 deterministic groups**, all exited 0 with successful reporter completion.
- All FitFlow production code, the new Step 4 test, all existing tests and
  the design audit remained byte-identical to the approved implementation.
  Only this validation document was updated to record finalization evidence.
- Dependencies, locked behavior and all excluded screens remain unchanged.
- No tests or VM assertions were weakened, and no group was omitted.

### Why grouped validation was necessary

The first `flutter test --no-pub --concurrency=1 --reporter=json` invocation
stalled in the sandbox after **974 passing tests**, with no recorded test
assertion failures. Compiler/tester child processes disappeared and sandbox
control calls became temporarily unresponsive. The incomplete attempt was
stopped; its partial counts are **not added** to the final complete-suite total.

A compiler-heap reduction to 512 MB then produced an explicit frontend
`Out of Memory` while serializing the first test's kernel, before any tests
ran. That runtime diagnostic was archived, not treated as a completed group
or bypassed by modifying tests. The final partition was rerun from its first
file with **768 MB compiler / 256 MB tester** old-generation limits.
The original SDK binaries and all original VM flags/assertions were retained
by the validation-only wrappers outside the repository.

### Deterministic partition and actual counts

Discover the exact default test-file set using sorted `test/**/*_test.dart`.
Partition it into contiguous batches of 12 files (last batch: 8). Each batch
runs with the same `--no-pub --concurrency=1` flags and JSON reporting.
Reporter suite-path sets were compared with the manifests, and visible
`testDone` results counted once; hidden loader events were not counted as
passing test cases. All hidden loader events also succeeded in the final run.

| Group | Files | Passed | Failed | Skipped | Flutter exit |
| --- | ---: | ---: | ---: | ---: | ---: |
| 01 | 12 | 143 | 0 | 0 | 0 |
| 02 | 12 | 158 | 0 | 0 | 0 |
| 03 | 12 | 204 | 0 | 0 | 0 |
| 04 | 12 | 97 | 0 | 0 | 0 |
| 05 | 12 | 205 | 0 | 0 | 0 |
| 06 | 12 | 164 | 0 | 0 | 0 |
| 07 | 12 | 132 | 0 | 0 | 0 |
| 08 | 12 | 193 | 0 | 0 | 0 |
| 09 | 12 | 97 | 0 | 0 | 0 |
| 10 | 12 | 192 | 0 | 0 | 0 |
| 11 | 12 | 277 | 0 | 0 | 0 |
| 12 | 12 | 148 | 0 | 0 | 0 |
| 13 | 12 | 189 | 0 | 0 | 0 |
| 14 | 8 | 137 | 0 | 0 | 0 |
| **Total** | **164** | **2,336** | **0** | **0** | **0 for every group** |

### Exact final full-suite commands

These app-relative command lists document every test-file entrypoint in the
completed validation. They add no dependency changes, skip filters, altered
timeouts inside tests or changed assertions.

#### Group 01

```bash
flutter test --no-pub --concurrency=1 \
  test/accessibility_large_text_test.dart \
  test/accessibility_motion_target_test.dart \
  test/accessibility_semantics_test.dart \
  test/adaptive_program_catalog_test.dart \
  test/adaptive_program_player_test.dart \
  test/adaptive_program_progression_test.dart \
  test/adaptive_program_recommendation_test.dart \
  test/adaptive_program_resolver_test.dart \
  test/adaptive_programs_concurrency_test.dart \
  test/adaptive_programs_controller_test.dart \
  test/adaptive_programs_storage_test.dart \
  test/adaptive_programs_ui_test.dart \
  --reporter=json
```

#### Group 02

```bash
flutter test --no-pub --concurrency=1 \
  test/adaptive_programs_workouts_screen_test.dart \
  test/adaptive_progression_application_test.dart \
  test/adaptive_progression_engine_test.dart \
  test/adaptive_progression_evidence_storage_test.dart \
  test/adaptive_progression_transaction_test.dart \
  test/adaptive_progression_widget_test.dart \
  test/android_notification_config_test.dart \
  test/app_test.dart \
  test/appearance_persistence_test.dart \
  test/appearance_test.dart \
  test/backup_codec_test.dart \
  test/backup_file_service_test.dart \
  --reporter=json
```

#### Group 03

```bash
flutter test --no-pub --concurrency=1 \
  test/backup_manifest_permissions_test.dart \
  test/backup_restore_controller_test.dart \
  test/backup_restore_screen_test.dart \
  test/backup_restore_transaction_test.dart \
  test/backup_strict_validation_test.dart \
  test/capability_assessment_saving_test.dart \
  test/capability_assessment_test.dart \
  test/capability_assessment_ui_test.dart \
  test/capability_domain_test.dart \
  test/capability_profile_provider_test.dart \
  test/capability_profile_storage_test.dart \
  test/comeback_suggestion_policy_test.dart \
  --reporter=json
```

#### Group 04

```bash
flutter test --no-pub --concurrency=1 \
  test/corrupt_local_state_test.dart \
  test/custom_workout_builder_filtering_test.dart \
  test/custom_workout_builder_state_test.dart \
  test/custom_workout_builder_widget_test.dart \
  test/custom_workout_completion_test.dart \
  test/custom_workout_concurrency_test.dart \
  test/custom_workout_player_integration_test.dart \
  test/custom_workout_preview_test.dart \
  test/custom_workout_resolver_focused_test.dart \
  test/custom_workout_resolver_test.dart \
  test/custom_workout_storage_failure_test.dart \
  test/custom_workout_storage_test.dart \
  --reporter=json
```

#### Group 05

```bash
flutter test --no-pub --concurrency=1 \
  test/custom_workouts_screen_test.dart \
  test/eligibility_restriction_matrix_test.dart \
  test/equipment_coverage_stabilization_test.dart \
  test/equipment_editor_test.dart \
  test/equipment_preferences_test.dart \
  test/exercise_catalog_coverage_test.dart \
  test/exercise_catalog_quality_test.dart \
  test/exercise_catalog_quality_validator_test.dart \
  test/exercise_catalog_test.dart \
  test/exercise_detail_test.dart \
  test/exercise_eligibility_collection_test.dart \
  test/exercise_eligibility_environment_test.dart \
  --reporter=json
```

#### Group 06

```bash
flutter test --no-pub --concurrency=1 \
  test/exercise_eligibility_no_jumping_test.dart \
  test/exercise_eligibility_test.dart \
  test/exercise_library_detail_widget_test.dart \
  test/exercise_library_filter_test.dart \
  test/exercise_library_search_filter_test.dart \
  test/exercise_library_test.dart \
  test/exercise_model_test.dart \
  test/exercise_progression_integrity_test.dart \
  test/exercise_progression_test.dart \
  test/exercise_ranking_final_test.dart \
  test/exercise_ranking_goal_test.dart \
  test/exercise_ranking_test.dart \
  --reporter=json
```

#### Group 07

```bash
flutter test --no-pub --concurrency=1 \
  test/exercise_skill_tree_exercise_detail_test.dart \
  test/exercise_skill_tree_fit_test.dart \
  test/exercise_skill_tree_provider_test.dart \
  test/exercise_skill_tree_resolver_test.dart \
  test/exercise_skill_tree_widget_test.dart \
  test/exercise_skill_tree_workouts_screen_test.dart \
  test/fitflow_design_system_test.dart \
  test/fitflow_reconciliation_test.dart \
  test/fitness_profile_editor_test.dart \
  test/generator_determinism_golden_test.dart \
  test/generator_viability_test.dart \
  test/history_storage_reuse_test.dart \
  --reporter=json
```

#### Group 08

```bash
flutter test --no-pub --concurrency=1 \
  test/home_dashboard_test.dart \
  test/home_session_mode_widget_test.dart \
  test/localization_readiness_test.dart \
  test/milestone19_integration_test.dart \
  test/milestone20_systems_integration_test.dart \
  test/onboarding_test.dart \
  test/part2_experience_test.dart \
  test/part3_workout_experience_test.dart \
  test/part4_training_progress_test.dart \
  test/part5_utility_experience_test.dart \
  test/part6_cross_app_quality_test.dart \
  test/part6_responsive_1024_test.dart \
  --reporter=json
```

#### Group 09

```bash
flutter test --no-pub --concurrency=1 \
  test/part6_responsive_320_test.dart \
  test/part6_responsive_360_test.dart \
  test/part6_responsive_390_test.dart \
  test/part6_responsive_430_test.dart \
  test/part6_responsive_600_test.dart \
  test/part6_responsive_840_test.dart \
  test/part6_responsive_900_test.dart \
  test/player_profile_stability_test.dart \
  test/player_reliability_stress_test.dart \
  test/player_timer_efficiency_test.dart \
  test/profile_editing_safety_test.dart \
  test/profile_model_test.dart \
  --reporter=json
```

#### Group 10

```bash
flutter test --no-pub --concurrency=1 \
  test/profile_persistence_test.dart \
  test/profile_screen_test.dart \
  test/progress_analytics_ui_test.dart \
  test/progress_screen_test.dart \
  test/release_readiness_test.dart \
  test/settings_screen_test.dart \
  test/splash_routing_test.dart \
  test/startup_destination_test.dart \
  test/startup_recovery_test.dart \
  test/training_analytics_determinism_test.dart \
  test/training_analytics_engine_test.dart \
  test/training_recovery_engine_test.dart \
  --reporter=json
```

#### Group 11

```bash
flutter test --no-pub --concurrency=1 \
  test/user_fitness_profile_test.dart \
  test/visual_v2_home_test.dart \
  test/visual_v2_programs_test.dart \
  test/visual_v2_setup_test.dart \
  test/visual_v2_workouts_test.dart \
  test/workout_candidate_resolver_test.dart \
  test/workout_completion_session_mode_test.dart \
  test/workout_generation_final_test.dart \
  test/workout_generator_test.dart \
  test/workout_history_completion_test.dart \
  test/workout_history_concurrency_test.dart \
  test/workout_history_null_movement_test.dart \
  --reporter=json
```

#### Group 12

```bash
flutter test --no-pub --concurrency=1 \
  test/workout_history_test.dart \
  test/workout_plan_test.dart \
  test/workout_player_completion_callback_test.dart \
  test/workout_player_completion_test.dart \
  test/workout_player_controller_test.dart \
  test/workout_player_exit_test.dart \
  test/workout_player_lifecycle_test.dart \
  test/workout_player_session_mode_test.dart \
  test/workout_player_state_equality_test.dart \
  test/workout_player_test.dart \
  test/workout_player_voice_test.dart \
  test/workout_preferences_editor_test.dart \
  --reporter=json
```

#### Group 13

```bash
flutter test --no-pub --concurrency=1 \
  test/workout_preview_session_mode_test.dart \
  test/workout_preview_test.dart \
  test/workout_reminder_cancellation_test.dart \
  test/workout_reminder_navigation_test.dart \
  test/workout_reminder_permission_test.dart \
  test/workout_reminder_schedule_test.dart \
  test/workout_reminder_storage_test.dart \
  test/workout_reminders_controller_test.dart \
  test/workout_reminders_settings_widget_test.dart \
  test/workout_replacement_controller_test.dart \
  test/workout_replacement_difficulty_invariant_test.dart \
  test/workout_replacement_engine_test.dart \
  --reporter=json
```

#### Group 14

```bash
flutter test --no-pub --concurrency=1 \
  test/workout_replacement_relevance_test.dart \
  test/workout_replacement_widget_test.dart \
  test/workout_section_builder_test.dart \
  test/workout_session_adaptation_policy_test.dart \
  test/workout_session_generator_test.dart \
  test/workout_session_mode_controller_test.dart \
  test/workout_structure_test.dart \
  test/workout_time_test.dart \
  --reporter=json
```

### Commit eligibility and safety

The final analyzer and complete grouped suite pass. `git diff --check` and
seven-file scope/hash inspection are the final pre-commit gates. The only
eligible staged paths are the four Step 4 production files, the new Step 4
test and the two Step 4 design documents. SDK/runtime wrappers, observer
scripts, logs and group manifests are outside the repository and must not
be committed. Commit/push verification and the resulting commit SHA are
recorded in Git and the finalization handoff, not self-embedded in this commit.

No design or Step 5 work was performed during finalization. No force push
is permitted.
