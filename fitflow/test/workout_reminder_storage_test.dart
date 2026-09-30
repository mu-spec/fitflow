import 'dart:convert';

import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/workout_reminder_test_helpers.dart';

void main() {
  const key = WorkoutReminderStorage.key;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  WorkoutReminderPreferences sample({bool enabled = true}) =>
      WorkoutReminderPreferences(
        enabled: enabled,
        weekdays: const [2, 4, 6],
        time: const WorkoutReminderTime(hour: 6, minute: 45),
        lastScheduledTimezoneId: 'Europe/Berlin',
      );

  test('key is workout_reminders_v1', () {
    expect(key, 'workout_reminders_v1');
  });

  test('1. missing key → disabled defaults (Mon/Wed/Fri 19:00)', () async {
    final loaded = await const WorkoutReminderStorage().load();
    expect(loaded.enabled, isFalse);
    expect(loaded.weekdays, {1, 3, 5});
    expect(loaded.time, const WorkoutReminderTime(hour: 19, minute: 0));
    expect(loaded.lastScheduledTimezoneId, isNull);
    expect(loaded, WorkoutReminderPreferences.defaults);
  });

  test('2. round-trip', () async {
    const storage = WorkoutReminderStorage();
    expect(await storage.save(sample()), isTrue);
    final loaded = await storage.load();
    expect(loaded, sample());
    expect(loaded.enabled, isTrue);
  });

  test('3. weekdays preserved (sorted)', () async {
    const storage = WorkoutReminderStorage();
    await storage.save(WorkoutReminderPreferences(
        enabled: false, weekdays: const [7, 1, 4], time: WorkoutReminderTime.suggested));
    expect((await storage.load()).weekdays.toList(), [1, 4, 7]);
  });

  test('4. time preserved', () async {
    const storage = WorkoutReminderStorage();
    await storage.save(sample());
    expect((await storage.load()).time, const WorkoutReminderTime(hour: 6, minute: 45));
  });

  test('5. timezone ID preserved', () async {
    const storage = WorkoutReminderStorage();
    await storage.save(sample());
    expect((await storage.load()).lastScheduledTimezoneId, 'Europe/Berlin');
  });

  test('6. duplicate weekdays de-duplicated', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'enabled': true, 'weekdays': [1, 1, 3, 3, 3], 'hour': 8, 'minute': 0}),
    });
    final loaded = await const WorkoutReminderStorage().load();
    expect(loaded.weekdays.toList(), [1, 3]);
  });

  test('7. invalid weekday values ignored', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'enabled': true, 'weekdays': [0, 8, -1, 'x', 2.0, 5, null], 'hour': 8, 'minute': 0}),
    });
    final loaded = await const WorkoutReminderStorage().load();
    expect(loaded.weekdays.toList(), [2, 5]);
  });

  test('8. invalid hour/minute → safe default time', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'enabled': false, 'weekdays': [1], 'hour': 25, 'minute': 61}),
    });
    expect((await const WorkoutReminderStorage().load()).time, WorkoutReminderTime.suggested);
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'enabled': false, 'weekdays': [1], 'hour': 'nine', 'minute': null}),
    });
    expect((await const WorkoutReminderStorage().load()).time, WorkoutReminderTime.suggested);
  });

  test('9. malformed JSON / wrong root → disabled defaults', () async {
    for (final raw in ['{not json', '[]', '42', '"str"', '   ']) {
      SharedPreferences.setMockInitialValues({key: raw});
      final loaded = await const WorkoutReminderStorage().load();
      expect(loaded, WorkoutReminderPreferences.defaults, reason: raw);
    }
  });

  test('enabled with zero valid weekdays is never reported enabled', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'enabled': true, 'weekdays': [9], 'hour': 8, 'minute': 0}),
    });
    final loaded = await const WorkoutReminderStorage().load();
    expect(loaded.enabled, isFalse);
    expect(loaded.weekdays, isEmpty);
    expect(loaded.isValid, isTrue);
  });

  test('10. setString false → failure, nothing written', () async {
    final toggle = ToggleReminderStorage()..allowWrites = false;
    expect(await toggle.storage.save(sample()), isFalse);
    expect(await storedReminderJson(), isNull);
  });

  test('11. exception → failure', () async {
    final toggle = ToggleReminderStorage()..throwOnWrite = true;
    expect(await toggle.storage.save(sample()), isFalse);
    final throwingLoad = WorkoutReminderStorage(getPrefs: () async => throw StateError('x'));
    expect(await throwingLoad.load(), WorkoutReminderPreferences.defaults);
    expect(await throwingLoad.save(sample()), isFalse);
  });

  test('12. returned weekdays are immutable', () async {
    const storage = WorkoutReminderStorage();
    await storage.save(sample());
    final loaded = await storage.load();
    expect(() => loaded.weekdays.add(1), throwsUnsupportedError);
    expect(() => WorkoutReminderPreferences.defaults.weekdays.remove(1), throwsUnsupportedError);
  });

  test('persists preference data only (no permission field)', () async {
    await const WorkoutReminderStorage().save(sample());
    final json = jsonDecode((await storedReminderJson())!) as Map;
    expect(json.keys.toSet(), {'version', 'enabled', 'weekdays', 'hour', 'minute', 'timezoneId'});
    expect(json.containsKey('permission'), isFalse);
  });
}
