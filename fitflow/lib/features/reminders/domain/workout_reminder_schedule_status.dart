/// User-facing reminder status derived from preferences + OS permission +
/// the last scheduling outcome. Internal errors are never exposed.
enum WorkoutReminderScheduleStatus {
  /// Reminders are off in FitFlow.
  off,

  /// Enabled and scheduled (weekly, inexact).
  scheduled,

  /// Enabled in FitFlow but Android blocks notifications.
  permissionBlocked,

  /// Enabled but the last scheduling attempt failed.
  scheduleError,
}
