/// Pure startup routing decision, extracted from the splash widget so it is
/// deterministic and unit-testable (M21 Part 1).
///
/// Splash loads exactly the persisted state required for routing — the user
/// fitness profile and the capability profile — and routes as soon as both
/// are resolved. Reminders, notifications, TTS, backup, history analytics,
/// and Programs are NOT startup-routing dependencies.
library;

/// Where the app should route once startup state is resolved.
enum StartupDestination {
  onboarding,
  capabilityAssessment,
  home,
}

/// Outcome of loading one persisted startup value.
///
/// [missing] means the storage read succeeded and reported no (valid) value.
/// [failed] means the read itself threw; it must be treated differently from
/// a genuinely missing value so a fully configured user is not silently sent
/// back to onboarding by one transient storage failure.
enum StartupLoadState {
  present,
  missing,
  failed,
}

/// Decides the startup destination from the two required persisted states.
///
/// Rules:
/// - profile present + capability present -> home
/// - profile present + capability missing/failed -> capability assessment
///   (storage deliberately converts corrupt capability JSON to null, which is
///   indistinguishable from missing and equally re-assessable)
/// - profile missing -> onboarding (an empty store is the only normal source
///   of a clean null on first launch)
/// - profile failed -> NEVER onboarding: onboarding would overwrite a profile
///   that likely exists on disk. A present capability proves a configured
///   user, so route home; otherwise fall back to the non-destructive
///   capability assessment. Broader failure recovery is Part 2 scope.
StartupDestination decideStartupDestination({
  required StartupLoadState userProfile,
  required StartupLoadState capabilityProfile,
}) {
  switch (userProfile) {
    case StartupLoadState.present:
      return capabilityProfile == StartupLoadState.present
          ? StartupDestination.home
          : StartupDestination.capabilityAssessment;
    case StartupLoadState.missing:
      return StartupDestination.onboarding;
    case StartupLoadState.failed:
      return capabilityProfile == StartupLoadState.present
          ? StartupDestination.home
          : StartupDestination.capabilityAssessment;
  }
}
