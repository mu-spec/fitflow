import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:timezone/timezone.dart' as tz;

/// Payload carried by every FitFlow workout reminder notification.
const String workoutReminderPayload = 'workout_reminder';

/// What to schedule for one weekly reminder.
class WorkoutReminderScheduleRequest {
  const WorkoutReminderScheduleRequest({
    required this.id,
    required this.weekday,
    required this.scheduledAt,
    required this.title,
    required this.body,
    this.payload = workoutReminderPayload,
  });

  final int id;
  final int weekday;

  /// First occurrence in the device's local timezone; repeats weekly on the
  /// same weekday + time.
  final tz.TZDateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
}

/// Backend seam for local notifications. Widgets never call the plugin;
/// the controller talks to this interface and tests use a fake.
///
/// Every method is non-throwing by contract: failures are reported through
/// return values so notification problems are never fatal for FitFlow.
abstract class WorkoutReminderNotificationService {
  /// Initialise the plugin (channel, tap callbacks). Returns availability.
  /// Idempotent.
  Future<bool> initialize();

  /// Initialise the timezone database, read the device timezone, set it as
  /// `tz.local`, and return its IANA ID. Returns null on any failure — the
  /// caller must then refuse to schedule (never fall back to UTC silently).
  Future<String?> resolveLocalTimezone();

  Future<WorkoutReminderPermissionStatus> permissionStatus();

  /// Requests the runtime permission where required (Android 13+).
  Future<WorkoutReminderPermissionStatus> requestPermission();

  /// Opens the OS notification settings for FitFlow, if supported.
  Future<bool> openNotificationSettings();

  /// Schedules (or replaces) one weekly, INEXACT reminder.
  Future<bool> schedule(WorkoutReminderScheduleRequest request);

  /// Cancels one FitFlow-owned notification ID.
  Future<bool> cancel(int id);

  /// Shows an immediate, one-off notification (test notification).
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// IDs of currently pending scheduled notifications, or null if unknown.
  Future<List<int>?> pendingIds();

  /// Payload of the notification that launched the app (terminated state),
  /// delivered at most once.
  Future<String?> takeLaunchPayload();

  /// Payloads of notification taps while the app is running
  /// (foreground/background).
  Stream<String?> get tapPayloads;
}
