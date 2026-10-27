Home simplification review

Commit: 26847d1f49c4c7b7593e2886e72e985a9f773e13
Branch: codex-premium-redesign

Implemented: localized Your workout header at 21px/medium, quieter wordmark, full 4:3 existing generated-workout photography, compact title/metadata/action, planned estimate retained when different or unknown, current mode and Adjust, initially collapsed Workout details & preferences, and Browse exercises below it.

Disclosure contents: warm-up/main/cooldown counts, adaptation summary, movement focus tags, Built for you heading, goal, environment, usual time, equipment, preferences, and capability/setup explanation. Existing Home had saved preference values rather than a separate inline preference editor; those values and all existing destinations are retained. Conditional Comeback and recovery messages remain outside the disclosure.

Validation: flutter analyze clean. 165 tests passed across 13 focused Home and affected navigation files. Includes 32 light/dark, phone/tablet/landscape, 1x/2x combinations with collapsed/expanded/collapsed interactions, native tap and expanded/collapsed semantics, all moved details, reachable Browse, image registry and 4:3 checks, and distinct/equal/unknown planned-time display.

Preservation: all 181 media assets and every other tracked file outside the 20 scoped paths matched the pre-task SHA256 snapshot. Existing Android changes remain unchanged and uncommitted. No shared theme, providers, generation, adaptive rules, media, dependencies or other production screens changed.

Captures: media_inbox/review/home-simplify-captures. Inspected 390px dark/light collapsed and expanded, 320px dark 2x action, and 320px light 2x expanded. Existing Comeback action still uses a block test font in captures; production semantics and behavior tests pass. Physical Android typography, TalkBack, device/system insets and smoothness remain manual checks. No APK/AAB/Gradle build, push or merge.

Changed files:
- lib/features/home/presentation/home_screen.dart
- lib/features/home/presentation/widgets/home_header.dart
- lib/features/home/presentation/widgets/home_personalization_card.dart
- lib/features/home/presentation/widgets/home_session_mode_widgets.dart
- lib/features/home/presentation/widgets/home_workout_hero_card.dart
- lib/l10n/app_en.arb
- lib/l10n/app_localizations.dart
- lib/l10n/app_localizations_en.dart
- test/app_test.dart
- test/capability_assessment_saving_test.dart
- test/home_dashboard_test.dart
- test/home_session_mode_widget_test.dart
- test/progress_screen_test.dart
- test/splash_routing_test.dart
- test/startup_destination_test.dart
- test/startup_recovery_test.dart
- test/user_fitness_profile_test.dart
- test/visual_v2_home_test.dart
- test/workout_player_completion_test.dart
- test/workout_preview_test.dart
