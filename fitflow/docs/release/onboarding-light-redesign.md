# Onboarding: light redesign

All eight first-run steps (`OnboardingPages.all`: welcome, goal, experience,
workout_time, environment, equipment, preferences, ready) now share one white
surface. No photography, scrim, overlay or decorative image is used anywhere in
the flow, and no image asset is loaded by onboarding at runtime.

Scope note: the Movement Check screen (`capability_assessment`) is a separate
route and was intentionally left untouched.

## Files

| File | Change |
| --- | --- |
| `lib/features/onboarding/presentation/onboarding_design.dart` | New. Tokens plus `OnboardingSurface` (flat card) and `OnboardingNote` (quiet note). |
| `lib/features/onboarding/presentation/onboarding_shell.dart` | Rewritten. White `Scaffold`, dark system bars, heading/description typography, Back/Continue styles. The per-step photo list and `SetupPhotoBackground` / `SetupPhotoTheme` / `SetupPhotoPanel` usage are gone. |
| `lib/features/onboarding/presentation/widgets/onboarding_choice.dart` | Rewritten for light cards and the green selection state. Same constructor, same semantics. |
| `lib/features/onboarding/presentation/widgets/onboarding_progress.dart` | Restyled: dark brand row, muted step count, light-grey inactive and icon-green active segments. Same keys and semantics. |
| `lib/features/onboarding/presentation/widgets/onboarding_intro.dart` | Welcome step now has real content built from existing strings (no imagery). |
| `lib/features/onboarding/presentation/preferences_step_content.dart` | Photo panel replaced by `OnboardingNote`. |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | Photo import removed; the `ready` step renders an `OnboardingNote`. |
| `test/visual_v2_setup_test.dart` | Photo-surface contrast test replaced by a light-design contrast/state test; the per-step matrix now asserts a white, image-free step. |

`setup_photo_background.dart` is unchanged and still used by Movement Check.

## Tokens

| Role | Value | Contrast |
| --- | --- | --- |
| Page | `#FFFFFF` | - |
| Heading | `#111111` | 18.9:1 on white |
| Option title | `#171717` | 16.6:1 on `#F5F6F7` |
| Description | `#555555` | 7.5:1 on white |
| Secondary/helper | `#5F6873` | 5.6:1 on white, 5.1:1 on `#F5F6F7` |
| Card surface | `#F5F6F7` | unselected |
| Selected wash | `#F3FCE9` | selected |
| Border | `#E6E9EB` / `#EDEFF1` | unselected |
| Icon green | `#48E61D` | selected border, active progress |
| Deep icon green | `#1E8214` | primary button (4.9:1 with white text), selection glyphs, leading icons |
| Inactive progress | `#ECEEEF` | - |
| Disabled button | `#E9EBED` fill, `#9AA1A9` text | clearly inert |

## Behaviour preserved

Questions, options, helper copy, validation (`_canContinue`), saved preferences,
step count, progress keys (`setup_segment_$i`), scroll keys, Back/Continue and
Get Started, the save-error message and the six-second per-step motion setting
are all unchanged. Onboarding still depends on nothing outside its feature.

## Image assets

Nothing is deleted. Onboarding used shared exercise hero photographs
(`ExerciseMediaRegistry`), which are also the media for the exercise library,
exercise detail and workout player, so removing them would break those screens.
`pubspec.yaml` is untouched.

## Verification

* `flutter analyze`: 16 issues, all pre-existing and outside the touched files.
* `test/visual_v2_setup_test.dart`: 8 passing, including the new contrast/state
  test in both brightnesses. The 32 matrix cases run all eight steps
  successfully (white background, no `Image`, no photo key, correct labels,
  disabled/enabled Continue, `Get Started`) and then fail on the Movement Check
  backdrop assertion, which was already failing before this change - see below.
* Asset audit: all 65 files under `assets/images` are referenced, either
  explicitly in Dart or through the media registry / program id pattern.
  0 orphans, 0 KB removable.
