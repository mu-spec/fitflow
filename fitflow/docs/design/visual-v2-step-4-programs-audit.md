# Visual V2 Step 4 — Programs audit

## Baseline and boundary

Reimplemented from clean `main` at
`d6535c94d8219fe837440699d158141e06e395d8`.
No old Step 4 backup or attached document was restored into the project.
The repository's QA notes recommend Flutter 3.47.7 / Dart 3.13.5;
that exact official SDK tag was used, with `flutter pub get`, not an upgrade.

This is an opt-in presentation change for Programs Overview, its program
cards, Program Detail and its existing week/session rows. Production edits
are restricted to:

- `lib/core/design/widgets/fitflow_v2_program_cover.dart` (new)
- `lib/features/programs/presentation/programs_overview_screen.dart`
- `lib/features/programs/presentation/program_detail_screen.dart`
- `lib/features/programs/presentation/widgets/program_widgets.dart`

Workouts landing, Home, Onboarding, Program Session Preview, Workout Preview,
Player, Rest, Completion, Library, Builder, Progress, Profile and Settings
are not redesigned. Step 5 is not begun.

## Canonical catalog audit

The existing `AdaptiveProgramCatalog` remains the sole definition source.
Its deterministic ordering, names, descriptions, focuses, recommendation
sets, weeks, session templates and generation goals are unchanged.

| Stable ID | Existing program | Weeks | Sessions/week | Total sessions | Original cover metaphor |
| --- | --- | ---: | ---: | ---: | --- |
| `balanced_foundations` | Balanced Foundations | 4 | 3 | 12 | Equal grounded platforms and a central bridge |
| `strength_foundations` | Strength Foundations | 6 | 3 | 18 | Supported structural frame and bracing |
| `endurance_builder` | Endurance Builder | 4 | 4 | 16 | A continuous curved route with rhythmic bends |
| `mobility_movement` | Mobility & Movement | 4 | 3 | 12 | Two broad crossing arcs |
| `stay_active_starter` | Stay Active Starter | 4 | 3 | 12 | Low stepping stones and gentle upward momentum |

Session identities are still `<programId>_w<week>_s<session>`.
No sessions, goals, focus labels or program definitions are created by UI code.

## Cover family

`FitFlowV2ProgramCover` maps stable IDs to five distinct motifs. Display-name
strings are not consulted. An unknown ID receives neutral decoration, not a
made-up program or a known program's identity. Actual unknown-program routes
retain the existing not-found state.

The artwork is original deterministic `CustomPainter` geometry: rounded
slabs, round-capped strokes, a quiet ground anchor and one restrained warm
accent. It reuses `FitFlowV2ArtStyle.standard` / `.onHero`, so ordinary and
active-program plates are intentionally tuned for both themes using the
existing V2 palette. No text is painted. Platforms/routes are abstract
metaphors, not charts, measurements, progress indicators or anatomical art.

Every cover is `ExcludeSemantics` + `RepaintBoundary`. Its painter has no
animation/listener; `shouldRepaint` compares motif and all five palette
inputs. Uniform normalized scaling preserves proportions on short/wide
plates and safely handles zero-size painting. No asset files, images,
network calls, random values or dependencies are added.

## Overview presentation

- V2 page surface, short native Programs app bar, brand kicker, semantic
  Adaptive programs heading and the existing introductory copy.
- Media-led zero-elevation cards retain canonical name, focus, structural
  facts and status, and the existing detail route.
- A real active catalog program leads as one prominent card; its ID is
  filtered from the discovery list. All remaining definitions keep their
  catalog order. No program is duplicated or invented.
- Goal-match badges still come exclusively from
  `AdaptiveProgramRecommendationPolicy.isRecommended(id, goal)`. Missing
  profile means no invented match or fallback recommendation.
- Active continuation displays the saved canonical session count/fraction
  and actual structural next week/session. Continue pushes the same
  `AppRoutes.programSessionPreview(programId, nextSession.id)` destination
  used by existing program continuation; no workout is generated in Overview.
- Completed programs use a supporting surface, the factual count, a textual
  Program complete label and a check. No Continue is shown when there is no
  next session; the ordinary card still opens the existing detail route.
- Detail navigation and Continue are separate native interactive targets,
  not a merged semantic action or a fake selectable metadata chip.

## Detail and timeline presentation

The content owns one semantic program-title heading. The short app-bar parent
label avoids duplicating that heading and leaves room for 2x type. Cover,
original description, canonical focus and existing metadata lead the screen.
On readable wide views the art sits beside copy; on compact/large-type views
it moves above. Content stops at the existing 640dp readable-width token.

The existing status calculator supplies all progress and session states.
The same completion fraction drives a linear completion bar; no new metric
or percentage label is introduced. Wide status metadata can wrap inline;
narrow/large-type status copy stacks naturally.

Weeks and sessions are iterated in their original order. The compact
`ProgramSessionRow` uses a quiet rail and node, highlights only the real next
session, and retains:

- existing localized Session N title beneath the actual week heading;
- existing `ProgramSessionStatusChip` text/icon/color mapping: Completed,
  Next, Upcoming (the unchanged localized label for the domain `planned` state);
- original focus and generation-goal text;
- native View workout action, at least 48dp, pushing the unchanged session ID.

On readable rows, copy and View workout sit alongside one another. Narrow or
large-type rows stack them without truncation. Timeline widgets contain no
local program state. Visible rows are lazily laid out with zero cache extent
on Detail, reducing unused row work on low-end devices.

## Locked behavior / shared-widget boundary

No catalog, controller, provider, recommendation policy, status calculator,
completion logic, storage schema, persistence, router or workout resolver is
modified. Start/resume, Continue, switch/restart confirmation and failure
snackbar callbacks retain their original implementations; button changes
are spacing/minimum-size presentation only.

`ProgramTag`, `ProgramSessionStatusChip`, `ProgramDialogs`,
`ProgramNotFoundBody`, `ProgramProgressState` and `programStatusLabel` retain
their existing implementations. In particular the shared status chip used
by Program Session Preview is not restyled. New V2 helpers and optional
completion/structure colors are used only by the scoped Programs screens.
`workouts_program_cards.dart` and Program Session Preview are unchanged.

## Responsiveness, accessibility and performance

Overview uses the existing 760dp content-width token. Two columns are chosen
only at expanded viewport width (>=840dp) and when 16sp scales to <=22dp;
a local pair-level constraint check also requires room for two >=340dp
cards plus their gap, so a narrow pane inside a wide window still stacks. Narrow and large-type layouts
return to one column. No fixed card aspect ratio, line limit, ellipsis or
text-scaling clamp is introduced.

Art yields before text: 56dp at large type, 64dp in short landscape, and
normal covers chosen by viewport/detail context. Copy can grow and scroll.
Heading semantics, textual identity/status, native focus/keyboard activation,
back navigation and >=48dp action targets are retained. Decorative nodes,
chevrons and covers are excluded from semantics. Status is never color alone.
No new animation is added, so reduced motion is immediate and there is no
continuous painting loop.

This design avoids blur, shadows, network/raster assets, custom shaders and
continuous animation. Widget/contrast/repaint tests establish the static
implementation contract, not an Oppo A12 hardware benchmark. Physical-device
performance and platform builds are explicitly not claimed in this turn.

## Forbidden metrics check

Only existing canonical counts, structural facts, labels, next-session text
and the original completion fraction are rendered. There are no radial
charts, difficulty charts/scores, focus/muscle percentages, calories, XP,
trophies, achievements, predictions or transformation estimates.

See the accompanying validation document for commands and actual results.
