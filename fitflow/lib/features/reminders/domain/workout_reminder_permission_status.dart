/// Real OS notification permission state, always queried live (never persisted).
enum WorkoutReminderPermissionStatus {
  /// Platform has no runtime notification permission gate (or none needed).
  notRequired,

  /// Permission granted / notifications enabled for FitFlow.
  granted,

  /// Denied by the user or blocked in Android Settings.
  denied,

  /// Could not be determined (plugin unavailable / error).
  unknown;

  /// Whether FitFlow may post notifications right now.
  bool get allowsNotifications =>
      this == WorkoutReminderPermissionStatus.granted ||
      this == WorkoutReminderPermissionStatus.notRequired;
}
