# FitFlow

Adaptive home workout app built with Flutter (Material 3, Riverpod, go_router).

## Status

Foundation and onboarding shell complete (Milestones 1A–2A). No workout
functionality yet.

- **1A** — Project foundation: feature-first structure, Material 3 theme, Riverpod setup
- **1B** — Routing & navigation: bottom navigation with four tabs (Home / Workouts / Progress / Profile)
- **1C** — Appearance: System / Light / Dark theme selection, persisted locally with SharedPreferences (Profile → Settings)
- **2A** — Onboarding shell: 8 placeholder steps with progress indicator and Back/Continue navigation, ending in Get Started

App flow: Splash → Onboarding → Home. Onboarding always shows after splash
for now; completion is not persisted yet.

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
```
