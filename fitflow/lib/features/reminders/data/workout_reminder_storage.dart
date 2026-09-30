import 'dart:convert';

import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for [WorkoutReminderPreferences] (user intent only —
/// never the OS permission state). Key: `workout_reminders_v1`.
///
/// Malformed data degrades safely to disabled defaults / ignored values.
class WorkoutReminderStorage {
  const WorkoutReminderStorage({
    Future<SharedPreferences> Function()? getPrefs,
    Future<bool> Function(SharedPreferences prefs, String key, String value)?
        writeString,
  })  : _getPrefs = getPrefs,
        _writeString = writeString;

  static const String key = 'workout_reminders_v1';
  static const int schemaVersion = 1;

  final Future<SharedPreferences> Function()? _getPrefs;
  final Future<bool> Function(SharedPreferences prefs, String key, String value)?
      _writeString;

  Future<SharedPreferences> _prefs() =>
      _getPrefs != null ? _getPrefs!() : SharedPreferences.getInstance();

  Future<bool> _write(SharedPreferences prefs, String k, String v) =>
      _writeString != null ? _writeString!(prefs, k, v) : prefs.setString(k, v);

  /// Loads preferences; any failure yields [WorkoutReminderPreferences.defaults].
  Future<WorkoutReminderPreferences> load() async {
    try {
      final prefs = await _prefs();
      return decode(prefs.getString(key));
    } catch (_) {
      return WorkoutReminderPreferences.defaults;
    }
  }

  /// Persists [preferences]. Returns false when the write fails or throws.
  Future<bool> save(WorkoutReminderPreferences preferences) async {
    try {
      final prefs = await _prefs();
      return await _write(prefs, key, encode(preferences));
    } catch (_) {
      return false;
    }
  }

  static String encode(WorkoutReminderPreferences p) => jsonEncode({
        'version': schemaVersion,
        'enabled': p.enabled,
        'weekdays': p.weekdays.toList(),
        'hour': p.time.hour,
        'minute': p.time.minute,
        if (p.lastScheduledTimezoneId != null)
          'timezoneId': p.lastScheduledTimezoneId,
      });

  /// Tolerant decoder:
  /// - malformed root → disabled defaults
  /// - invalid/duplicate weekdays → ignored / de-duplicated
  /// - invalid hour/minute → suggested default time
  /// - enabled with zero valid weekdays → enabled forced false (never invalid)
  static WorkoutReminderPreferences decode(String? raw) {
    final defaults = WorkoutReminderPreferences.defaults;
    if (raw == null || raw.trim().isEmpty) return defaults;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return defaults;
    }
    if (decoded is! Map) return defaults;

    final enabledRaw = decoded['enabled'];
    final enabled = enabledRaw is bool ? enabledRaw : false;

    final weekdaysRaw = decoded['weekdays'];
    final weekdays = <int>[];
    if (weekdaysRaw is List) {
      for (final v in weekdaysRaw) {
        final n = v is int ? v : (v is num ? v.toInt() : null);
        if (n != null && WorkoutReminderWeekday.isValid(n)) weekdays.add(n);
      }
    }
    final normalised = WorkoutReminderWeekday.normalise(weekdays);

    final hourRaw = decoded['hour'];
    final minuteRaw = decoded['minute'];
    var time = WorkoutReminderTime(
      hour: hourRaw is int ? hourRaw : -1,
      minute: minuteRaw is int ? minuteRaw : -1,
    );
    if (!time.isValid) time = WorkoutReminderTime.suggested;

    final tzRaw = decoded['timezoneId'];
    final tzId = tzRaw is String && tzRaw.trim().isNotEmpty ? tzRaw : null;

    // Keep the user's (possibly empty) selection visible, but never report
    // an enabled schedule with nothing to schedule.
    final safeEnabled = enabled && normalised.isNotEmpty;
    return WorkoutReminderPreferences(
      enabled: safeEnabled,
      weekdays: normalised,
      time: time,
      lastScheduledTimezoneId: tzId,
    );
  }
}
