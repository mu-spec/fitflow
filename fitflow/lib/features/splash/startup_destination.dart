/// Pure startup routing decision, extracted from the splash widget so it is
/// deterministic and unit-testable (M21).
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

  /// A required read threw. Show a retryable recovery state and do not route.
  recovery,
}

/// Outcome of loading one persisted startup value.
///
/// [missing] means the storage read succeeded and reported no (valid) value.
/// [failed] means the read itself threw. It must never be treated as normal
/// application state: a transient read failure is not onboarding, assessment,
/// or home.
///
/// Storage that deliberately converts malformed JSON into null (capability
/// profiles, for example) reports [missing], not [failed].
enum StartupLoadState {
  present,
  missing,
  failed,
}

/// Decides the startup destination from the two required persisted states.
///
/// Rules (M21 Part 2):
/// - either required read [StartupLoadState.failed] -> [StartupDestination.recovery]
/// - profile present + capability present -> home
/// - profile present + capability missing -> capability assessment
///   (corrupt capability JSON that storage loads as null is missing, not failed)
/// - profile missing (and capability read did not fail) -> onboarding
StartupDestination decideStartupDestination({
  required StartupLoadState userProfile,
  required StartupLoadState capabilityProfile,
}) {
  if (userProfile == StartupLoadState.failed ||
      capabilityProfile == StartupLoadState.failed) {
    return StartupDestination.recovery;
  }
  switch (userProfile) {
    case StartupLoadState.present:
      return capabilityProfile == StartupLoadState.present
          ? StartupDestination.home
          : StartupDestination.capabilityAssessment;
    case StartupLoadState.missing:
      return StartupDestination.onboarding;
    case StartupLoadState.failed:
      return StartupDestination.recovery;
  }
}
