# Visual V2 / Step 2 — onboarding and Movement Check

Baseline: `a9d9edc20574c650975d73179b22387b00d305c4`. Step 1 Home is unchanged. Preimplementation findings: `visual-v2-step-2-onboarding-audit.md`.

## Visual decisions

- Reuse the existing `FitFlowVisualV2` palette adapter, hero and supporting surfaces; no global palette/theme changes. New opt-in `fitflow_v2_setup.dart` supplies selection surface, action boundary/style, compact adaptive option grid and an original static branching-track motif.
- Welcome retains existing factual localized copy and the same first route. An emerald/mint composition supplies a strong anchor; title roles are deliberately different rather than two competing display headlines. The motif stacks below the title at large text, avoiding narrow word breaks.
- Eight true progress segments plus the existing localized fraction replace the generic line. Brand and progress stay outside the normal-height scroll area; short windows retain the existing all-in-one scroll fallback.
- Goal and environment have purposeful semantic icons; experience retains its neutral helper language. Duration and equipment use compact two-column options where readable, single-column at narrow widths/large text. Preferences remain full-width for their longer labels, without invented groupings or medical implications.
- Emerald selected surfaces, mint check indicators and native selection semantics distinguish selection by more than color. Native InkWell, CheckboxListTile and ChoiceChip behavior remains; no nested custom tap replacements. No icon was added to every label.
- Bottom actions have a quiet top boundary, 56dp minimum primary height, emerald emphasis in Light and mint emphasis in Dark. Existing safe areas, scaffold keyboard resizing, short-height fallback, enablement and callbacks remain.
- Movement Check has a compact branded header, the same truthful ready count, and ten ordinal category markers (not scores). Alternating quiet support/tonal surfaces reduce repeated white-box rhythm. The five human-level chips retain native selection/checkmark/tooltip behavior and wrap. Existing prompt, examples, selected explanation and suggested/changed wording remain.
- Loading/recovery backgrounds adopt V2. Existing saving text, disabled save, live error feedback and retry remain truthful; no success is shown before persistence.

## Behavior preservation

Onboarding page list/order, controller, screen state/save logic, all enums, profile model/storage and routing are unchanged. Required selections and optional preferences are identical. Equipment None exclusivity and all exact stored values remain controller-owned. Movement Check state/update/save methods were compared byte-for-byte to the baseline and are unchanged; experience suggestions, all ten patterns, all five levels, first-run gating and redirect behavior remain intact. Home and its V2 foundation file are byte-for-byte unchanged. No dependencies, localization changes, release/Android/signing changes, accounts or new inputs.

## Automated validation

Flutter 3.47.7 / Dart 3.13.5. Initial focused attempt exposed only the changed check-icon identifier in existing selection tests; restored the canonical icon rather than weakening assertions. An initial runner stalled after its unbounded AOT compiler disappeared; stopped that run and bounded the external SDK AOT compiler to 768MB and tester to 384MB. This changes no repository/test semantics and skips no tests. A new test's SemanticsHandle cleanup was corrected to use `finally` before final validation.

- Existing focused suite: **116 passed** across onboarding, equipment/preferences, capability assessment domain/UI/saving, Part 2 experience and Step 1 Home V2 files. No existing test files modified.
- New `visual_v2_setup_test.dart`: **38 passed**. 32 combinations: 320×700, 360×800, 390×844, 430×900, 600×900, 840×1000, 1024×768, 900×320 × Light/Dark × 1×/2× text. Each walks all eight onboarding steps, checks all existing option labels, required choice enablement, None exclusivity, preferences multi-select, reduced-motion progress, reachable CTA, all ten movement categories/defaults/independent level selection and reachable save. Additional checks cover native tap/Tab+Space activation, selected semantics, delayed save/failure recovery, 2× keyboard-inset phone/landscape and static repaint policy.
- External actual-widget capture harness: **1 passed**, 17 TEST-only captures with Roboto/Material Icons. Light/Dark welcome, all six field steps, compact phone, 2× welcome, Movement Check top/mid/changed level/Dark/2×, short landscape and tablet. No capture route or bitmap ships with production. Scrolled images show normal scroll behavior, not text compression.
- `flutter analyze --no-pub`: **no issues**.
- Full `flutter test --no-pub --concurrency=1`: **2,253 passed**, exit 0, 8m50s. Entire repository suite, including existing per-width cross-app matrices; no tests skipped or weakened. No hit-test warnings in the full run.
- `git diff --check`: clean, including final documentation.

## Remaining real-device judgment

Physical Oppo A12 QA is not performed. Check Light/Dark rendering, font/display-size combinations, TalkBack reading/selected state/announcements, focus/pressed feedback, system gesture and keyboard insets, rotation/short landscape, all choice types, saving and failure recovery against real storage, and scrolling/launch/memory behavior. Static paths, no network media, no bitmaps, no blur, no new packages, no looping animation; those implementation choices are not measured smoothness/battery claims. No APK/AAB built.

Step 2 only. Workouts, Programs, Preview, Player, Progress, Profile, Settings, Library, custom builder and all other deferred features remain untouched. No Step 3 work.
