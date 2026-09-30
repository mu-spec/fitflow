import 'dart:async';
import 'dart:io' show Platform;

import 'package:fitflow/features/reminders/application/workout_reminder_notification_service.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Production backend wrapping `flutter_local_notifications` + `timezone`.
///
/// Scheduling policy (release-important):
/// - `AndroidScheduleMode.inexactAllowWhileIdle` only — never exact/alarm-clock.
/// - default importance channel; no full-screen intent, no foreground service.
/// - only FitFlow-owned IDs are ever cancelled (never a blanket cancel).
class LocalWorkoutReminderNotificationService
    implements WorkoutReminderNotificationService {
  LocalWorkoutReminderNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    MethodChannel? settingsChannel,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _settingsChannel =
            settingsChannel ?? const MethodChannel(settingsChannelName);

  static const String channelId = 'fitflow_workout_reminders_v1';
  static const String channelName = 'Workout reminders';
  static const String channelDescription =
      'Reminders for your FitFlow workout schedule.';
  static const String settingsChannelName = 'fitflow/notification_settings';
  static const String _androidIcon = '@mipmap/ic_launcher';

  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _settingsChannel;
  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  bool? _available;
  bool _timezoneDbReady = false;
  bool _launchPayloadTaken = false;

  /// Local notifications are only wired on Android/iOS. Elsewhere (desktop
  /// hosts, tests) the service reports itself unavailable and never touches
  /// platform channels.
  static bool get _platformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> initialize() async {
    if (_available != null) return _available!;
    if (!_platformSupported) return _available = false;
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          _taps.add(response.payload);
        },
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.defaultImportance,
        ),
      );
      return _available = ok ?? true;
    } catch (_) {
      return _available = false;
    }
  }

  @override
  Future<String?> resolveLocalTimezone() async {
    if (!_platformSupported) return null;
    try {
      if (!_timezoneDbReady) {
        tzdata.initializeTimeZones();
        _timezoneDbReady = true;
      }
      final info = await FlutterTimezone.getLocalTimezone();
      final id = info.identifier;
      final location = tz.getLocation(id); // throws for unknown IDs
      tz.setLocalLocation(location);
      return id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WorkoutReminderPermissionStatus> permissionStatus() async {
    if (!_platformSupported) return WorkoutReminderPermissionStatus.unknown;
    try {
      if (Platform.isAndroid) {
        final enabled = await _android?.areNotificationsEnabled();
        if (enabled == null) return WorkoutReminderPermissionStatus.unknown;
        return enabled
            ? WorkoutReminderPermissionStatus.granted
            : WorkoutReminderPermissionStatus.denied;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      if (options == null) return WorkoutReminderPermissionStatus.unknown;
      return options.isEnabled
          ? WorkoutReminderPermissionStatus.granted
          : WorkoutReminderPermissionStatus.denied;
    } catch (_) {
      return WorkoutReminderPermissionStatus.unknown;
    }
  }

  @override
  Future<WorkoutReminderPermissionStatus> requestPermission() async {
    if (!_platformSupported) return WorkoutReminderPermissionStatus.unknown;
    try {
      if (Platform.isAndroid) {
        // On Android < 13 this resolves true without a runtime dialog.
        final granted = await _android?.requestNotificationsPermission();
        if (granted == null) return await permissionStatus();
        return granted
            ? WorkoutReminderPermissionStatus.granted
            : WorkoutReminderPermissionStatus.denied;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted =
          await ios?.requestPermissions(alert: true, badge: false, sound: true);
      if (granted == null) return WorkoutReminderPermissionStatus.unknown;
      return granted
          ? WorkoutReminderPermissionStatus.granted
          : WorkoutReminderPermissionStatus.denied;
    } catch (_) {
      return WorkoutReminderPermissionStatus.unknown;
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (!_platformSupported) return false;
    try {
      final result =
          await _settingsChannel.invokeMethod<bool>('openNotificationSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      );

  @override
  Future<bool> schedule(WorkoutReminderScheduleRequest request) async {
    if (!await initialize()) return false;
    try {
      await _plugin.zonedSchedule(
        id: request.id,
        title: request.title,
        body: request.body,
        scheduledDate: request.scheduledAt,
        notificationDetails: _details,
        // Inexact by design: workout reminders are not alarm-critical.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: request.payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> cancel(int id) async {
    if (!await initialize()) return false;
    try {
      await _plugin.cancel(id: id);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await initialize()) return false;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<int>?> pendingIds() async {
    if (!await initialize()) return null;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((p) => p.id).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> takeLaunchPayload() async {
    if (_launchPayloadTaken) return null;
    _launchPayloadTaken = true;
    if (!await initialize()) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String?> get tapPayloads => _taps.stream;
}
