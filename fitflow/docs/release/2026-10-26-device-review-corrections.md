# Setup and animation device-review corrections

Baseline: e9c2a34e852c05a61bcf2d838a6ca532ff6c6bc1, arena-workouts-redesign.

## Presentation
- Replaced opaque light setup panels with translucent black panels, light text and citrus selection cues across the eight onboarding pages and Movement Check. Fullscreen photo assets are unchanged. The photographic foreground has its own contrast theme; saved appearance, preparation and neighboring screens retain their themes.
- Removed duplicate native logo/text from the Android starting window. A matching slate starting background hands off to the existing large Flutter brand lockup, avoiding a small native logo followed by a larger Flutter logo. The existing 5.5-second Flutter splash duration and routing are unchanged.
- Reviewed the supplied recording. Replaced the narrow side-profile pilot with a front-facing illustrated athlete, separated limbs, tapered silhouettes and a continuous hip/leg connection. Marching alternates opposite arms and knees; squat feet remain grounded with fixed leg-segment lengths. Pilot remains limited to March in Place and Bodyweight Squat.

## Checks
- Scoped Dart analysis of five presentation files and three affected tests: no issues.
- Setup, splash/preparation and pilot batch: 82 tests passed, plus one temporary isolated-art pose-render check (83 total). No application screenshots were generated.
- After further joint/hip refinement: 18 pilot tests and 6 existing splash routing tests passed, plus the isolated-art check (25 total).
- Setup coverage includes all choices, ten movement assessments, retry/keyboard behavior, small/large layouts and 2x text in both appearance modes. Splash/pilot matrix includes 360x640, 360x800 and 412x915.
- Native resources compile with AAPT2. No Gradle or app build.
- All media, workout controllers, timers, persistence and protected Android build configuration remain outside this commit.

## Limits
The pilot is an illustrated 2D fallback, not realistic 3D. Review its appearance and cadence on device before extending it. Android cold/warm launch continuity needs device confirmation: the OS starting window is intentionally plain slate until Flutter can paint the full-size branding. Test/pose rendering does not establish exercise-instruction accuracy. No paid generation, dependencies, push or merge.
