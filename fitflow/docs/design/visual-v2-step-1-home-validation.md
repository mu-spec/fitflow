# Visual V2 / Step 1 — implementation and verification

Scope: production Home and opt-in primitives only, based on published `85a298530ebc260142d8f5a8925d6e23db43ac2a`. No Step 2. The preimplementation findings are in `visual-v2-step-1-home-audit.md`.

## Design delivered

- Existing teal identity extended through semantic palette-derived roles: cool tinted page, deep emerald hero, mint action, quiet supporting surface, smaller tonal facts and wrapping focus tags. No global theme change.
- Existing typography roles deliberately separate page orientation, session title, target duration, generated count/estimate, supporting rationale, mode and section composition. The target's complete localized phrase remains its semantic label; one localized `min target` unit supports the visible split type treatment.
- One restrained hero gradient; no shadows, blur, glass, shader, image downloads or new dependencies. An original three-path static movement motif is decorative and excluded from semantics. It is neither exercise instruction nor a numeric progress visualization.
- One native View workout button still pushes Workout Preview. Optional shared button style/hint parameters retain default behavior for every other caller. The hint is inside the native button semantics. Adjust still opens the same mode sheet/provider; recommendation generation and mode eligibility are untouched.
- Saved goal and environment are visible without expanding. The existing setup disclosure retains usual time, actual equipment, preferences and capability explanation. Existing movement-pattern extraction/order/limit are unchanged; only its presentation becomes tags.
- Comeback suggestion keeps its exact existing condition and action, with a quieter tonal surface. Navigation, branches, same-tab behavior, routes and bar/rail are untouched.
- Existing scrolling, safe areas and maximum width remain. Facts stack when space/text requires; tags and section metadata wrap. Only decorative art yields width; text is not clamped or fitted. Native controls remain at least 48dp; Preview is at least 56dp. Existing reduced-motion policy governs the short fades and setup disclosure; no ticker or loop was added.

## Automated evidence

Flutter 3.47.7; no dependency updates, APK or AAB.

- `flutter analyze --no-pub`: no issues.
- Existing focused Home/dashboard/session-mode/Part 2/design-system files: **63 passed**. Only five disclosure interaction selectors changed from the old heading to the actual disclosure label. Business-data, route and semantics assertions remain intact.
- New `visual_v2_home_test.dart`: **33 passed**. 32 combinations of 320×700, 360×800, 390×844, 430×900, 600×900, 840×1000, 1024×768, 900×320 × Light/Dark × 1×/2× text, plus repaint-policy test. Checks actual routed Home, layout exceptions, reachable native Preview, minimum tap height, real setup disclosure, tags and ≥4.5:1 key hero text/accent/action contrast.
- External production-widget capture harness: **1 passed**, eight captures, using Roboto and Material Icons with explicitly TEST saved profiles/history. No capture routes/assets committed. Reviewed Light/Dark, compact, expanded setup, tablet, and 2× compact/tablet/short landscape. Large-text captures are scrolled to Preview, not artificially compressed to fit one screen.
- Initial focused attempt exposed a ListTile ink occlusion assertion in the supporting decorated surface. Resolved with a transparent Material inside that surface; final focused run passed. Initial unbounded runner was stopped; subsequent validation bounds the external compiler heap to 768MB and tester to 384MB. No test or production memory policy was changed.
- `flutter test --no-pub --concurrency=1`: **2,215 passed**, exit 0, 7m18s. Entire suite ran, including existing per-width cross-app matrices; no assertions weakened or tests disabled.
- `git diff --check`: clean, including final documentation.

## Physical QA still required

On Oppo A12 / Android: inspect both themes, system font/display sizes, portrait/rotation, bottom safe area and gesture navigation; TalkBack heading order, duration phrase, Preview hint/action, setup disclosure and mode announcements; touch/keyboard focus and pressed feedback; native mode sheet; real profile/mode combinations; scroll/launch smoothness and memory under ordinary use. No physical device, smoothness, battery, OEM or rasterization claim is made from widget tests. No release artifacts generated.
