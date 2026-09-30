/// Calm, factual copy for local workout reminders. No guilt, no urgency,
/// no medical/AI claims.
class WorkoutReminderCopy {
  WorkoutReminderCopy._();

  // Notification content
  static const String notificationTitle = 'FitFlow workout reminder';
  static const String notificationBody =
      'Your workout reminder is ready when you are.';
  static const String testTitle = 'FitFlow test reminder';
  static const String testBody = 'Notifications are working.';

  // Settings section
  static const String sectionTitle = 'Workout reminders';
  static const String toggleTitle = 'Workout reminders';
  static const String toggleSubtitle =
      'Weekly local reminders on the days and time you choose.';
  static const String daysLabel = 'Reminder days';
  static const String timeLabel = 'Reminder time';
  static const String sendTest = 'Send test notification';
  static const String openSettings = 'Open notification settings';
  static const String inexactNote =
      'Android may deliver reminders slightly later to reduce battery use.';
  static const String everyDay = 'Every day';

  // Status
  static const String statusOff = 'Reminders are off.';
  static const String statusScheduled = 'Workout reminders are scheduled.';
  static const String statusBlocked =
      'Reminders are enabled in FitFlow, but notifications are blocked by Android.';
  static const String statusScheduleError =
      "Couldn't schedule reminders. Try again.";

  // One-shot messages
  static const String permissionNeeded =
      'Notification permission is needed to send workout reminders.';
  static const String selectAtLeastOneDay = 'Select at least one day.';
  static const String saveFailed = "Couldn't save reminder settings. Try again.";
  static const String testSent = 'Test notification sent.';
  static const String testFailed = "Couldn't send a test notification.";
  static const String settingsUnavailable =
      'Notification settings are not available on this device.';
}
