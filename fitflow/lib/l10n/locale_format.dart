import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Locale-aware presentation for dates, times, weekdays, durations and counts.
///
/// Nothing here is persisted. Stored values stay as timestamps, ISO weekdays,
/// hour/minute, and [Duration].
class FitFlowLocaleFormat {
  FitFlowLocaleFormat._();

  /// Material `firstDayOfWeekIndex` is 0 for Sunday. Returns ISO weekdays
  /// (Monday = 1 … Sunday = 7) in that locale's display order.
  static List<int> weekdayDisplayOrder(int firstDayOfWeekIndex) {
    int materialToIso(int index) => index == 0 ? DateTime.sunday : index;
    return [
      for (var i = 0; i < DateTime.daysPerWeek; i++)
        materialToIso((firstDayOfWeekIndex + i) % DateTime.daysPerWeek),
    ];
  }

  static String narrowWeekday(MaterialLocalizations material, int isoWeekday) {
    return material.narrowWeekdays[isoWeekday % DateTime.daysPerWeek];
  }

  /// Short label such as "Mon", taken from Material date formatting so it
  /// follows the active Material locale rather than a hardcoded English list.
  static String shortWeekday(MaterialLocalizations material, int isoWeekday) {
    final formatted = material.formatMediumDate(_sampleDate(isoWeekday));
    final comma = formatted.indexOf(',');
    return comma > 0 ? formatted.substring(0, comma) : formatted;
  }

  /// Full label such as "Monday", from Material full-date formatting.
  static String fullWeekday(MaterialLocalizations material, int isoWeekday) {
    final formatted = material.formatFullDate(_sampleDate(isoWeekday));
    final comma = formatted.indexOf(',');
    return comma > 0 ? formatted.substring(0, comma) : formatted;
  }

  static String formatDate(MaterialLocalizations material, DateTime date) {
    return material.formatShortDate(date.toLocal());
  }

  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final material = MaterialLocalizations.of(context);
    final local = dateTime.toLocal();
    final date = material.formatShortDate(local);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date $time';
  }

  static String formatReminderTime(BuildContext context, int hour, int minute) {
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }

  static String formatMinutes(AppLocalizations l10n, int minutes) =>
      l10n.minutes(minutes);

  static String formatSeconds(AppLocalizations l10n, int seconds) =>
      l10n.seconds(seconds);

  static String formatDuration(AppLocalizations l10n, Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    if (totalSeconds < 60) return l10n.seconds(totalSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) return l10n.minutes(minutes);
    return l10n.minutesAndSeconds(minutes, seconds);
  }

  static String formatWorkoutDelta(AppLocalizations l10n, int delta) {
    if (delta == 0) return l10n.noChange;
    final sign = delta > 0 ? '+' : '-';
    return l10n.signedWorkoutCount(sign, delta.abs());
  }

  /// 2024-01-01 is a Monday, so day-of-month matches the ISO weekday.
  static DateTime _sampleDate(int isoWeekday) => DateTime(2024, 1, isoWeekday);
}
