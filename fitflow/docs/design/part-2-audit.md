# Part 2 pre-implementation audit

Baseline: `f638ac1c5e4d62092242d8069c7f140c34821faf` on GitHub main.
The restored source tree was verified byte-for-byte against that commit before
aligning local Git metadata. Part 1 remains the only design system.

## Onboarding and assessment
- Eight stable steps: welcome, goal, experience, time, environment, equipment,
  optional preferences, ready. Required fields gate Continue. Back changes the
  local step index, not selections. Equipment has exclusive None behavior.
- Fitness profile must save successfully before Movement Check. Assessment seeds
  ten movement answers from experience; changes preserve per-movement values.
  Only a successful capability save goes to Home. Existing valid capability skips
  assessment. Back and startup recovery semantics must remain unchanged.
- Welcome/ready body copy bypasses existing localization helpers. Preference notes,
  progress, assessment prompts, labels and errors are mostly hard-coded English.
- Progress, content and actions are unbounded on tablets. Titles have weak hierarchy;
  option cards repeat styling. The legacy option card is also reused by Profile
  editors: keep it unchanged and scope the new composition to onboarding steps.
  The option wrapper excludes the tappable child's
  semantics, so a named button may lack a native accessibility tap action.
- Assessment repeats its title, experience explanation, progress and L1–L5 summary;
  technical rank labels dominate the choices. Large horizontal badges are fragile
  at 320dp / 2x text. Ten full cards make the save action unnecessarily distant.

## Home
- Both profile providers gate loading/error/missing-profile states. Generation uses
  existing context, capability and M12 mode. History only drives the existing
  comeback suggestion; there is no real recent-activity card to preserve.
- Header, hero, focus card, full profile snapshot and adaptation note repeatedly
  explain personalization. Six similarly weighted blocks obscure the one priority.
- CTA is separate from the hero and its semantics wrapper excludes native actions.
  Hero gives section counts similar emphasis to time and the actual next action.
- Mode control works but sits below the CTA in another card; mode is duplicated in
  temporary-mode hero labels. Mode descriptions and notes are not localized.
- Personalization repeats stored duration even when the effective mode duration is
  different. Keep both truthful but label the stored duration as usual time in
  disclosed setup details. Do not change generation or mode state.
- Loading is static (good); error copy incorrectly suggests a network connection
  for local profiles. Missing-profile states have recovery callbacks. No-plan state
  explains restrictions but offers no direct profile action.

## Navigation, localization and tests
- Four StatefulShellRoute branches, preserved state, same-tab initialLocation
  behavior. Part 1 bar/rail uses constraint breakpoints and scroll-safe rail.
  Retain this architecture, visible labels, callbacks and route definitions.
- English ARB + generated AppLocalizations + enum label helpers are canonical.
  All new/reworked feature copy will live there; no unsupported AI/medical claims.
- Existing tests assert all onboarding gates, choices, persistence/assessment
  values, profile-error recovery, actual generator counts, session-mode policy,
  preview navigation, M22 labels/targets/text scaling and bar/rail behavior.
  Some tests assert old copy/rank labels and always-expanded setup details; update
  only those presentation expectations, retaining behavioral/data assertions.

## Implementation boundary
- Preserve step IDs/order, field values, validation rules, persistence controllers,
  generation, M12 policy and callbacks. No feature outside Part 2 is redesigned.
- Guided bounded onboarding; consistent pinned actions with short-window fallback;
  single/multi-choice instructions; human movement choices and compact summary.
- One Home workout hero with effective duration, actual count, mode and preview CTA.
  Focus is secondary; full setup/adaptation details move into a disclosure, followed
  by the existing library shortcut. No invented readiness/history/calorie data.
- Native controls and Part 1 components/tokens; brief reduced-motion-aware fades,
  progress and selection feedback. No images/packages/blur/looped decoration.
