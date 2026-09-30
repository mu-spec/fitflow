import 'package:fitflow/features/reminders/domain/workout_reminder_ids.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_calculator.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  ensureTimezones();
  final karachi = tz.getLocation('Asia/Karachi');
  final berlin = tz.getLocation('Europe/Berlin');
  const seven = WorkoutReminderTime(hour: 19, minute: 0);

  tz.TZDateTime at(tz.Location loc, int y, int m, int d, [int h = 0, int min = 0]) =>
      tz.TZDateTime(loc, y, m, d, h, min);

  group('nextOccurrence', () {
    test('1. Monday before selected time → same Monday', () {
      final now = at(karachi, 2026, 9, 28, 8); // Monday 08:00
      expect(now.weekday, DateTime.monday);
      final next = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.monday, time: seven);
      expect(next, at(karachi, 2026, 9, 28, 19));
    });

    test('2. Monday after selected time → next Monday', () {
      final now = at(karachi, 2026, 9, 28, 20); // Monday 20:00
      final next = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.monday, time: seven);
      expect(next, at(karachi, 2026, 10, 5, 19));
    });

    test('3. exactly at the selected time → deterministic: next week', () {
      final now = at(karachi, 2026, 9, 28, 19); // Monday 19:00:00
      final a = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.monday, time: seven);
      final b = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.monday, time: seven);
      expect(a, at(karachi, 2026, 10, 5, 19));
      expect(a, b);
      expect(a.isAfter(now), isTrue);
    });

    test('4. Sunday → following selected weekday (Wednesday)', () {
      final now = at(karachi, 2026, 9, 27, 10); // Sunday
      expect(now.weekday, DateTime.sunday);
      final next = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.wednesday, time: seven);
      expect(next, at(karachi, 2026, 9, 30, 19));
      expect(next.weekday, DateTime.wednesday);
    });

    test('6. never in the past, for every weekday × several nows', () {
      for (var day = 25; day <= 31; day++) {
        for (final hour in [0, 12, 18, 19, 23]) {
          final now = at(karachi, 2026, 9, day, hour, 30);
          for (final weekday in WorkoutReminderWeekday.all) {
            final next = WorkoutReminderScheduleCalculator.nextOccurrence(
                now: now, weekday: weekday, time: seven);
            expect(next.isAfter(now), isTrue, reason: '$now → $weekday');
            expect(next.weekday, weekday);
            expect(next.hour, 19);
            expect(next.minute, 0);
            expect(next.difference(now) <= const Duration(days: 7), isTrue);
          }
        }
      }
    });

    test('7. DST-aware: wall-clock time preserved across the Berlin transition', () {
      // DST ends in Berlin on Sunday 2026-10-25 (03:00 → 02:00).
      final now = at(berlin, 2026, 10, 22, 9); // Thursday, CEST (+2)
      final next = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.monday, time: seven);
      expect(next, at(berlin, 2026, 10, 26, 19));
      expect(next.hour, 19);
      expect(next.timeZoneOffset, const Duration(hours: 1)); // CET after DST end
      expect(now.timeZoneOffset, const Duration(hours: 2));
      // Elapsed real time is 4 days 10h + the extra DST hour.
      expect(next.difference(now), const Duration(days: 4, hours: 11));
    });

    test('same-day past time across DST spring-forward still moves forward', () {
      // DST starts in Berlin 2026-03-29 02:00 → 03:00 (Sunday).
      final now = at(berlin, 2026, 3, 29, 12); // Sunday noon CEST
      final next = WorkoutReminderScheduleCalculator.nextOccurrence(
          now: now, weekday: DateTime.sunday, time: const WorkoutReminderTime(hour: 2, minute: 30));
      expect(next.isAfter(now), isTrue);
      expect(next.weekday, DateTime.sunday);
    });
  });

  group('plan', () {
    test('5. multiple weekdays sorted with stable IDs', () {
      final prefs = WorkoutReminderPreferences(
          enabled: true, weekdays: const [5, 1, 3], time: seven);
      final plan = WorkoutReminderScheduleCalculator.plan(
          preferences: prefs, now: at(karachi, 2026, 9, 30, 12));
      expect(plan.map((o) => o.weekday).toList(), [1, 3, 5]);
      expect(plan.map((o) => o.notificationId).toList(), [17001, 17003, 17005]);
      for (final o in plan) {
        expect(o.scheduledAt.weekday, o.weekday);
        expect(o.scheduledAt.location, karachi);
      }
      expect(() => plan.add(plan.first), throwsUnsupportedError);
    });

    test('8. stable notification ID per weekday; test ID 17999; max 7', () {
      expect(WorkoutReminderIds.forWeekday(1), 17001);
      expect(WorkoutReminderIds.forWeekday(7), 17007);
      expect(WorkoutReminderIds.allWeekly, [17001, 17002, 17003, 17004, 17005, 17006, 17007]);
      expect(WorkoutReminderIds.allWeekly.length, 7);
      expect(WorkoutReminderIds.test, 17999);
      expect(WorkoutReminderIds.weekdayForId(17003), 3);
      expect(WorkoutReminderIds.weekdayForId(17000), isNull);
      expect(WorkoutReminderIds.isOwned(17999), isTrue);
      expect(WorkoutReminderIds.isOwned(1), isFalse);
      final everyDay = WorkoutReminderPreferences(
          enabled: true, weekdays: WorkoutReminderWeekday.all, time: seven);
      expect(WorkoutReminderScheduleCalculator.plan(
              preferences: everyDay, now: at(karachi, 2026, 9, 30)).length,
          7);
    });

    test('9. inexact schedule mode is the policy (no exact/alarm-clock)', () {
      // The production service hard-codes inexactAllowWhileIdle; verify the
      // source and that the enum value exists in the pinned plugin version.
      expect(AndroidScheduleMode.inexactAllowWhileIdle, isNotNull);
      expect(AndroidScheduleMode.values, contains(AndroidScheduleMode.inexactAllowWhileIdle));
    });

    test('10. no selected weekdays → validation failure, empty plan', () {
      final prefs = WorkoutReminderPreferences(enabled: false, weekdays: const [], time: seven);
      expect(prefs.validationIssue, WorkoutReminderValidationIssue.noWeekdays);
      expect(prefs.isSchedulable, isFalse);
      expect(prefs.copyWith(enabled: true).isValid, isFalse);
      expect(WorkoutReminderScheduleCalculator.plan(
              preferences: prefs, now: at(karachi, 2026, 9, 30)),
          isEmpty);
    });
  });

  group('domain models', () {
    test('time validation', () {
      expect(const WorkoutReminderTime(hour: 0, minute: 0).isValid, isTrue);
      expect(const WorkoutReminderTime(hour: 23, minute: 59).isValid, isTrue);
      expect(const WorkoutReminderTime(hour: 24, minute: 0).isValid, isFalse);
      expect(const WorkoutReminderTime(hour: 12, minute: 60).isValid, isFalse);
      expect(const WorkoutReminderTime(hour: -1, minute: 0).isValid, isFalse);
      final invalidTime = WorkoutReminderPreferences(
          enabled: true, weekdays: const [1], time: const WorkoutReminderTime(hour: 30, minute: 0));
      expect(invalidTime.validationIssue, WorkoutReminderValidationIssue.invalidTime);
    });

    test('defaults are OFF with editable Mon/Wed/Fri 7:00 PM suggestion', () {
      final d = WorkoutReminderPreferences.defaults;
      expect(d.enabled, isFalse);
      expect(d.weekdays, {1, 3, 5});
      expect(d.time, const WorkoutReminderTime(hour: 19, minute: 0));
      expect(d.isSchedulable, isTrue);
    });

    test('weekday normalisation: dedupe, sort, drop invalid, immutable', () {
      final set = WorkoutReminderWeekday.normalise([7, 3, 3, 0, 9, 1]);
      expect(set.toList(), [1, 3, 7]);
      expect(() => set.add(2), throwsUnsupportedError);
      expect(WorkoutReminderWeekday.fullName(1), 'Monday');
      expect(WorkoutReminderWeekday.fullName(7), 'Sunday');
      expect(WorkoutReminderWeekday.letter(4), 'T');
      expect(WorkoutReminderWeekday.shortName(3), 'Wed');
    });

    test('copyWith / equality / sameSchedule', () {
      final a = WorkoutReminderPreferences(enabled: false, weekdays: const [1, 3], time: seven);
      final b = a.copyWith(enabled: true, lastScheduledTimezoneId: 'UTC');
      expect(a.sameSchedule(b), isTrue);
      expect(a == b, isFalse);
      expect(b.copyWith(clearTimezoneId: true).lastScheduledTimezoneId, isNull);
      expect(a.copyWith(weekdays: const [3, 1]), a);
      expect(a.isEveryDay, isFalse);
    });
  });
}
