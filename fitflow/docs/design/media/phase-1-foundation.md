# Production visual foundation, Phase 1

Baseline: 37215e4ccd3e0c4b615ac99e5f85c8c6460f3552.
The reference image was not attached to this implementation request. Token values follow the written direction and remain subject to visual-reference review. No full screen redesign or photography delivery is claimed.

## Architecture

- exercise_media_spec.dart: immutable presentation-only asset size, fit and alignment; exercise ID, thumbnail, hero and optional secondary static frame.
- exercise_media_registry.dart: explicit 88-entry ID allowlist and exact O(1) lookup. No catalog imports, names, domain metadata, guesses or network fallback.
- program_media_registry.dart: explicit five-program cover registry, no session selection.
- fitflow_media_image.dart: shared local asset renderer, reserved dimensions, decode sizing, neutral loading/error fallback and caller-owned semantics.
- fitflow_exercise_image.dart: opt-in thumbnail/hero widgets accepting an existing exercise ID.
- fitflow_program_image.dart: opt-in program image widget accepting an existing program ID.
- asset-handoff.md: all expected paths and proposed casting. All actual photography is pending.

## Integration contract

Pass exercise.id or program.id directly. Keep exercise names, instructions, prescriptions, routes and callbacks in their existing owners. Never read Exercise.assetPath or match display names in this new registry. Unknown IDs return null, causing neutral fallback rather than another exercise's photo.

The widgets are decorative by default because adjacent text owns the accessible identity. For standalone content, set decorative: false and provide a localized semanticLabel describing the exercise/program, not claiming that a photo exists. The fallback preserves that identity without announcing asset paths, icons, or English-only status strings. Media is not an interactive control. Callers retain visible names and content.

Pass finite width/height based on local layout constraints; defaults are 72x72 thumbnail and 320x240 hero. Actual constrained size drives decode sizing. Do not crop technique-critical limbs. Do not mirror exercise imagery automatically for RTL layouts.

## Dark tokens

| Role | Value |
|---|---|
| Background | #0B1210 |
| Surface | #141E19 |
| Subtle/media surface | #19251F |
| Raised surface | #202D25 |
| Mint primary | #67E8C3 |
| On primary | #06241C |
| Deeper teal accent | #45BFA6 |
| Brand container | #163C32 |
| Primary text | #F3F7F4 |
| Secondary text | #B9C7BF |
| Muted text | #97ACA0 |
| Border | #304138 |
| Divider | #25362C |

Success, warning, error and other status meanings are preserved. Light palette remains available and is contrast-tested. Appearance selection, system mode and persistence are untouched.

## Typography, surfaces and actions

Use the system font, no new font dependency. Screen title 26, hero title 28, section 20, list title 16, body 16/14, label 15, metadata 12, timer 56 with tabular figures. Text scaling remains unrestricted; screen-level wrapping changes are deferred.

Major cards radius 16, sheets/legacy hero 18, media/controls 12, small elements 8. Zero card elevation; dark depth uses tone. Shared legacy hero surface is solid, and its compatibility start/end colors are equal so remaining consumers no longer produce large gradients. Screen padding and layout trees remain unchanged. Later screen work must remove nested card clutter, not just reduce padding.

Primary buttons: mint/dark ink in dark mode, 52 minimum height. Secondary: surface fill, subtle border, primary text. Tertiary remains minimal. All controls retain minimum 48dp interactions and existing focus/disabled/pressed semantics. Existing screen overrides are deliberately retained until those screens migrate.

Bottom navigation: 64dp normal height, mint selected icon/text, muted inactive states, low-opacity rounded rectangular indicator (8px radius). Existing large-text sizing and expanded rail behavior are preserved. No destination changes.

## Performance

Bundled WebP only. No startup preload. A thumbnail request never decodes its hero. Decode uses physical display size, quantized to 64-pixel width steps, preserving source aspect and capping at export dimensions. Stable asset paths/sizes allow Flutter's image cache to reuse decodes. No global cache-size changes without device measurements.

Later Library adoption must retain lazy SliverList construction. Later Player adoption may precache current plus next effective prescription only, using the same decode sizing; do not add bulk preloading here or change provider subscriptions. Keep media independent of countdown animation, and avoid retaining the previous exercise image while a new ID loads.

256x256 decoded RGBA is approximately 0.25 MiB; 960x720 approximately 2.64 MiB, excluding overhead. Suggested compressed budgets: 15-35 KB thumbnail, 100-220 KB hero. Final visual quality and Oppo A12 frame/memory profiling remain pending.

## Painter migration (deferred)

| Existing system | Future replacement |
|---|---|
| FitFlowV2ExerciseMedia / _FitFlowV2ExerciseMediaPainter | FitFlowExerciseImage using exact exercise.id |
| FitFlowV2WorkoutMedia / FitFlowV2WorkoutMovementPainter | Exercise image using the existing plan/current prescription |
| FitFlowV2ProgramCover / FitFlowV2ProgramCoverPainter | FitFlowProgramImage using program.id |
| FitFlowV2FeatureArt Programs/Library/Custom painters | Approved photography or smaller utility presentation |
| HomeFlowPainter | Media from an exercise already in the resolved plan |
| FitFlowV2AdaptivePainter | Approved onboarding editorial media, when supplied |
| Skill-tree decorative painter | Remove large decorative cover when that screen migrates |

No referenced painters were deleted or rewired in Phase 1. The new renderer never falls back to them. Functional charts, timeline nodes, status icons and diagrams remain.

After photography/reference review, migrate Library and Detail first; then Home/Workouts/Programs; then previews and Player with behavioral regression checks. Delete legacy painter code only after its last caller and painter-specific test have migrated.

## Scope boundary

No edits to domain models, catalog, generation, adaptive/capability logic, session modes, eligibility, prescriptions, Player lifecycle/timers/replacement, history/completion, Progress calculations, custom-workout behavior, reminders, backup/restore, persistence, controllers/providers, routing, localization or Android configuration. No dependency changes or invented product data/features. Shared tokens affect existing screens, but screen composition and feature code are untouched.

## Validation recorded 2026-10-16

- Dart format: 15 changed/new Dart files formatted successfully using the installed SDK binary.
- flutter analyze --no-pub: no issues found.
- Focused run: 203 passed, one explicitly skipped asset-delivery release gate, zero failures.
- Strict asset gate: intentionally failed with missing photography, verifying that incomplete delivery cannot satisfy that gate. 176 exercise files and five program files remain missing.
- git diff --check: clean.
- No full-suite run, device profiling or rendered-reference comparison was performed.

Focused run included:

```text
test/production_media_registry_test.dart
test/production_media_image_test.dart
test/production_visual_foundation_test.dart
test/fitflow_design_system_test.dart
test/exercise_catalog_test.dart
test/exercise_catalog_quality_validator_test.dart
test/exercise_catalog_quality_test.dart
test/exercise_catalog_coverage_test.dart
test/exercise_library_test.dart
test/exercise_library_search_filter_test.dart
test/exercise_library_filter_test.dart
test/exercise_library_detail_widget_test.dart
test/exercise_detail_test.dart
test/exercise_skill_tree_exercise_detail_test.dart
test/visual_v2_step6a_exercise_media_test.dart
test/visual_v2_step6b_exercise_library_test.dart
test/visual_v2_step6c_exercise_detail_test.dart
```

The existing design-system assertion was updated from exactly 48px to exactly 52px primary-button minimum height, matching the new requested visual contract. Existing functional tests were retained unchanged.

Pre-existing changes to android/app/build.gradle.kts and android/gradle.properties, plus existing JVM crash/replay logs, were left untouched. No commit or push was performed.
