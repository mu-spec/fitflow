import 'dart:convert';

import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_persistence_codec.dart';
import 'package:fitflow/features/backup/data/backup_restore_transaction.dart';
import 'package:fitflow/features/backup/data/backup_snapshot_reader.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';

const _unrelatedKey = 'some_other_feature_key';
const _unrelatedValue = 'keep-me';

Future<SharedPreferences> _prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Raw values of the owned keys (null when absent).
Map<String, String?> _ownedRaw(SharedPreferences prefs) => {
      for (final k in BackupFormat.ownedPreferenceKeys) k: prefs.getString(k),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupPersistenceCodec', () {
    test('covers exactly the eight owned keys', () {
      final values = BackupPersistenceCodec.rawValuesFor(fullBackupData());
      expect(BackupPersistenceCodec.coversOwnedKeys(values), isTrue);
      expect(values.keys.toSet(), BackupFormat.ownedPreferenceKeys.toSet());
    });

    test('null profile/capability map to key removal; empty lists to "[]"', () {
      final values = BackupPersistenceCodec.rawValuesFor(emptyBackupData());
      expect(values[UserFitnessProfileStorage.profileKey], isNull);
      expect(values[CapabilityProfileStorage.profileKey], isNull);
      expect(values[WorkoutHistoryStorage.key], '[]');
      expect(values[CustomWorkoutStorage.key], '[]');
      expect(values[AppearanceStorage.appearanceKey], 'system');
    });

    test('reminders raw value carries NO timezone id', () {
      final values = BackupPersistenceCodec.rawValuesFor(fullBackupData());
      final json = jsonDecode(values[WorkoutReminderStorage.key]!) as Map;
      expect(json.containsKey('timezoneId'), isFalse);
      expect(json.containsKey('lastScheduledTimezoneId'), isFalse);
      expect(json['enabled'], isTrue);
      expect(json['weekdays'], [1, 3, 5]);
    });
  });

  group('BackupRestoreTransaction — success', () {
    test('writes all eight keys so the existing storages load the data',
        () async {
      final prefs = await _prefsWith({_unrelatedKey: _unrelatedValue});
      final data = fullBackupData();

      final result = await BackupRestoreTransaction(prefs: prefs).run(data);

      expect(result.success, isTrue);
      expect(result.rollbackComplete, isTrue);
      expect(prefs.getString(_unrelatedKey), _unrelatedValue);

      final profile = UserFitnessProfileStorage(prefs).load();
      expect(profile, isNotNull);
      expect(profile!.equipment, data.userFitnessProfile!.equipment);
      expect(CapabilityProfileStorage(prefs).load(), data.capabilityProfile);
      expect(
          AdaptiveProgressionEvidenceStorage(prefs)
              .load()
              .countFor(MovementPattern.push),
          1);
      expect(WorkoutHistoryStorage(prefs).load(), data.workoutHistory);
      Future<SharedPreferences> same() async => prefs;
      expect(await CustomWorkoutStorage(getPrefs: same).loadAll(),
          data.customWorkouts);
      expect(await AdaptiveProgramsStorage(getPrefs: same).load(),
          data.adaptivePrograms);
      final reminders = await WorkoutReminderStorage(getPrefs: same).load();
      expect(reminders.enabled, isTrue);
      expect(reminders.weekdays, {1, 3, 5});
      expect(reminders.lastScheduledTimezoneId, isNull);
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.dark);
    });

    test('REPLACE: existing data is replaced, not merged', () async {
      final prefs = await _prefsWith({});
      // Device currently holds a different, larger data set.
      final richer = fullBackupData().copyWith(
        workoutHistory: backupHistory(count: 6),
        appearance: AppearanceMode.light,
      );
      expect((await BackupRestoreTransaction(prefs: prefs).run(richer)).success,
          isTrue);
      expect(WorkoutHistoryStorage(prefs).load().length, 6);

      final smaller =
          fullBackupData().copyWith(workoutHistory: backupHistory(count: 2));
      expect(
          (await BackupRestoreTransaction(prefs: prefs).run(smaller)).success,
          isTrue);

      expect(WorkoutHistoryStorage(prefs).load().map((w) => w.id),
          ['hist_1', 'hist_0']);
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.dark);
    });

    test(
        'REPLACE: null profile/capability remove keys; empty lists become empty',
        () async {
      final prefs = await _prefsWith({_unrelatedKey: _unrelatedValue});
      expect(
          (await BackupRestoreTransaction(prefs: prefs).run(fullBackupData()))
              .success,
          isTrue);
      expect(prefs.containsKey(UserFitnessProfileStorage.profileKey), isTrue);

      final result =
          await BackupRestoreTransaction(prefs: prefs).run(emptyBackupData());

      expect(result.success, isTrue);
      expect(prefs.containsKey(UserFitnessProfileStorage.profileKey), isFalse);
      expect(prefs.containsKey(CapabilityProfileStorage.profileKey), isFalse);
      expect(UserFitnessProfileStorage(prefs).load(), isNull);
      expect(CapabilityProfileStorage(prefs).load(), isNull);
      expect(WorkoutHistoryStorage(prefs).load(), isEmpty);
      Future<SharedPreferences> same() async => prefs;
      expect(await CustomWorkoutStorage(getPrefs: same).loadAll(), isEmpty);
      expect(
          (await AdaptiveProgramsStorage(getPrefs: same).load())
              .progressByProgram,
          isEmpty);
      expect((await WorkoutReminderStorage(getPrefs: same).load()).enabled,
          isFalse);
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.system);
      expect(prefs.getString(_unrelatedKey), _unrelatedValue);
    });

    test('restore → snapshot → encode reproduces the original bytes', () async {
      final prefs = await _prefsWith({});
      final original = envelopeOf(fullBackupData());
      await BackupRestoreTransaction(prefs: prefs).run(original.data);

      final read =
          await BackupSnapshotReader(getPrefs: () async => prefs).read();

      expect(BackupCodec.encode(envelopeOf(read)),
          equals(BackupCodec.encode(original)));
    });

    test('never touches keys outside the owned set', () async {
      final prefs = await _prefsWith({
        _unrelatedKey: _unrelatedValue,
        'another_int': 7,
        'another_bool': true,
      });
      final touched = <String>{};
      final tx = BackupRestoreTransaction(
        prefs: prefs,
        setString: (k, v) {
          touched.add(k);
          return prefs.setString(k, v);
        },
        remove: (k) {
          touched.add(k);
          return prefs.remove(k);
        },
      );
      await tx.run(fullBackupData());
      await tx.run(emptyBackupData());
      expect(touched, BackupFormat.ownedPreferenceKeys.toSet());
      expect(prefs.getInt('another_int'), 7);
      expect(prefs.getBool('another_bool'), isTrue);
      expect(prefs.getKeys().length, 3 + 6); // 3 unrelated + 6 owned non-null
    });
  });

  group('BackupRestoreTransaction — rollback', () {
    late SharedPreferences prefs;
    late Map<String, String?> before;

    setUp(() async {
      prefs = await _prefsWith({_unrelatedKey: _unrelatedValue});
      // Seed a distinct "previous" data set (light appearance, 2 workouts).
      final previous = fullBackupData().copyWith(
        workoutHistory: backupHistory(count: 2),
        appearance: AppearanceMode.light,
        customWorkouts: const [],
      );
      await BackupRestoreTransaction(prefs: prefs).run(previous);
      before = _ownedRaw(prefs);
      expect(before[AppearanceStorage.appearanceKey], 'light');
    });

    for (final failingKey in BackupFormat.ownedPreferenceKeys) {
      test(
          'setString failure on "$failingKey" → rolled back, previous data kept',
          () async {
        // The apply write for [failingKey] fails once; the rollback write of
        // the same key succeeds (simulates a transient failure).
        var failed = false;
        final tx = BackupRestoreTransaction(
          prefs: prefs,
          setString: (k, v) async {
            if (k == failingKey && !failed) {
              failed = true;
              return false;
            }
            return prefs.setString(k, v);
          },
        );

        final result = await tx
            .run(fullBackupData().copyWith(appearance: AppearanceMode.dark));

        expect(result.success, isFalse);
        expect(result.rollbackComplete, isTrue);
        expect(result.failedKey, failingKey);
        expect(_ownedRaw(prefs), equals(before));
        expect(prefs.getString(_unrelatedKey), _unrelatedValue);
        expect(WorkoutHistoryStorage(prefs).load().length, 2);
      });
    }

    test('thrown exception during a write is treated as failure + rollback',
        () async {
      var thrown = false;
      final tx = BackupRestoreTransaction(
        prefs: prefs,
        setString: (k, v) async {
          if (k == WorkoutHistoryStorage.key && !thrown) {
            thrown = true;
            throw StateError('disk full');
          }
          return prefs.setString(k, v);
        },
      );
      final result = await tx.run(fullBackupData());
      expect(result.success, isFalse);
      expect(result.rollbackComplete, isTrue);
      expect(_ownedRaw(prefs), equals(before));
    });

    test('remove failure (null profile) → rolled back', () async {
      // Apply-time remove fails; rollback only uses setString (values existed).
      final tx = BackupRestoreTransaction(
        prefs: prefs,
        remove: (k) async => false,
      );
      final result = await tx.run(emptyBackupData());
      expect(result.success, isFalse);
      expect(result.rollbackComplete, isTrue);
      expect(result.failedKey, UserFitnessProfileStorage.profileKey);
      expect(_ownedRaw(prefs), equals(before));
    });

    test('rollback restores absent keys as absent', () async {
      // Previous state: no capability profile stored.
      await prefs.remove(CapabilityProfileStorage.profileKey);
      before = _ownedRaw(prefs);
      var failed = false;
      final tx = BackupRestoreTransaction(
        prefs: prefs,
        setString: (k, v) async {
          if (k == AppearanceStorage.appearanceKey && !failed) {
            failed = true;
            return false;
          }
          return prefs.setString(k, v);
        },
      );
      final result = await tx.run(fullBackupData());
      expect(result.success, isFalse);
      expect(result.rollbackComplete, isTrue);
      expect(prefs.containsKey(CapabilityProfileStorage.profileKey), isFalse);
      expect(_ownedRaw(prefs), equals(before));
    });

    test(
        'rollback that itself fails is reported as incomplete (never as success)',
        () async {
      var appearanceWrites = 0;
      final tx = BackupRestoreTransaction(
        prefs: prefs,
        setString: (k, v) async {
          if (k == AppearanceStorage.appearanceKey) {
            appearanceWrites++;
            // First call = apply (fails). Second call = rollback of an
            // earlier key would be fine, but make the history rollback fail.
            return false;
          }
          if (k == WorkoutHistoryStorage.key && appearanceWrites > 0) {
            return false;
          }
          return prefs.setString(k, v);
        },
      );
      final result = await tx.run(fullBackupData());
      expect(result.success, isFalse);
      expect(result.rollbackComplete, isFalse);
      expect(result.failedKey, AppearanceStorage.appearanceKey);
      // Everything except history was rolled back; history keeps the new value.
      final after = _ownedRaw(prefs);
      expect(after[WorkoutHistoryStorage.key],
          isNot(before[WorkoutHistoryStorage.key]));
      expect(after[UserFitnessProfileStorage.profileKey],
          before[UserFitnessProfileStorage.profileKey]);
      expect(after[AppearanceStorage.appearanceKey],
          before[AppearanceStorage.appearanceKey]);
      expect(prefs.getString(_unrelatedKey), _unrelatedValue);
    });
  });

  group('BackupSnapshotReader', () {
    test('reads persisted data, not defaults, and tolerates a fresh install',
        () async {
      final prefs = await _prefsWith({});
      final fresh =
          await BackupSnapshotReader(getPrefs: () async => prefs).read();
      expect(fresh.userFitnessProfile, isNull);
      expect(fresh.capabilityProfile, isNull);
      expect(fresh.workoutHistory, isEmpty);
      expect(fresh.customWorkouts, isEmpty);
      expect(fresh.adaptivePrograms.progressByProgram, isEmpty);
      expect(fresh.workoutReminders.enabled, isFalse);
      expect(fresh.appearance, AppearanceMode.system);
      expect(BackupCodec.encode(envelopeOf(fresh)),
          equals(BackupCodec.encode(envelopeOf(emptyBackupData()))));
    });

    test('reminders snapshot drops the persisted timezone id', () async {
      final prefs = await _prefsWith({
        WorkoutReminderStorage.key: jsonEncode({
          'version': 1,
          'enabled': true,
          'weekdays': [2, 4],
          'hour': 6,
          'minute': 15,
          'timezoneId': 'Asia/Karachi',
        }),
      });
      final data =
          await BackupSnapshotReader(getPrefs: () async => prefs).read();
      expect(data.workoutReminders.enabled, isTrue);
      expect(data.workoutReminders.weekdays, {2, 4});
      final text = utf8.decode(BackupCodec.encode(envelopeOf(data)));
      expect(text.contains('Karachi'), isFalse);
      expect(text.contains('timezone'), isFalse);
    });
  });
}
