import 'dart:convert';
import 'dart:typed_data';

import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_validation_result.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/backup_test_helpers.dart';

void main() {
  group('BackupFormat', () {
    test('file name pattern FitFlow-backup-YYYYMMDD-HHmmss.json', () {
      final name = BackupFormat.defaultFileName(DateTime(2026, 9, 30, 7, 5, 9));
      expect(name, 'FitFlow-backup-20260930-070509.json');
      expect(
          RegExp(r'^FitFlow-backup-\d{8}-\d{6}\.json$').hasMatch(name), isTrue);
    });

    test('owns exactly the eight persisted keys', () {
      expect(BackupFormat.ownedPreferenceKeys, [
        UserFitnessProfileStorage.profileKey,
        CapabilityProfileStorage.profileKey,
        AdaptiveProgressionEvidenceStorage.evidenceKey,
        WorkoutHistoryStorage.key,
        CustomWorkoutStorage.key,
        AdaptiveProgramsStorage.key,
        WorkoutReminderStorage.key,
        AppearanceStorage.appearanceKey,
      ]);
      expect(BackupFormat.maxImportBytes, 5 * 1024 * 1024);
    });
  });

  group('BackupCodec.encode — content', () {
    late Map<String, dynamic> root;
    late Map<String, dynamic> data;

    setUp(() {
      root = fullBackupJson();
      data = dataOf(root);
    });

    test('envelope has marker, schemaVersion 1, createdAtUtc and data', () {
      expect(root['format'], 'fitflow_backup');
      expect(root['schemaVersion'], 1);
      expect(root['createdAtUtc'], '2026-09-30T07:05:09.000Z');
      expect(data.keys.toSet(), BackupFormat.sections.toSet());
    });

    test('profile: enum names, sorted equipment & preferences', () {
      final p = data['userFitnessProfile'] as Map<String, dynamic>;
      expect(p['goal'], 'buildStrength');
      expect(p['experience'], 'someExperience');
      expect(p['workoutDuration'], 'twentyMinutes');
      expect(p['environment'], 'normalHome');
      expect(p['equipment'], ['chair', 'resistanceBands']);
      expect(p['preferences'], ['lowImpact', 'noJumping']);
    });

    test('capability: all 10 patterns with level/source/updatedAt/anchor', () {
      final c = data['capabilityProfile'] as Map<String, dynamic>;
      final list = (c['capabilities'] as List).cast<Map<String, dynamic>>();
      expect(list.length, 10);
      expect(list.map((e) => e['movementPattern']),
          CapabilityProfile.trainablePatterns.map((p) => p.name));
      final first = list.first;
      expect(first['level'], 'level1');
      expect(first['source'], 'initialAssessment');
      expect(first['updatedAt'], '2026-09-01T10:00:00.000Z');
      expect(first['anchorExerciseId'], 'anchor_push');
      expect(list[1].containsKey('anchorExerciseId'), isFalse);
    });

    test('evidence: real counts for every trainable pattern', () {
      final e = data['adaptiveProgressionEvidence'] as Map<String, dynamic>;
      final counts = e['counts'] as Map<String, dynamic>;
      expect(counts.length, 10);
      expect(counts['push'], 1);
      expect(counts['squat'], 1);
      expect(counts['core'], 0);
      expect(counts['balance'], 0);
    });

    test('history: newest-first with sections and UTC timestamps', () {
      final h = (data['workoutHistory'] as List).cast<Map<String, dynamic>>();
      expect(h.map((w) => w['id']), ['hist_2', 'hist_1', 'hist_0']);
      expect(h.first['completedAt'], '2026-09-03T08:00:00.000Z');
      expect((h.first['warmup'] as List).length, 1);
      expect((h.first['main'] as List).length, 1);
      expect((h.first['cooldown'] as List).length, 1);
      final ex = (h.first['main'] as List).first as Map<String, dynamic>;
      expect(ex['exerciseId'], 'm_hist_2');
      expect(ex['sectionType'], 'main');
      expect(ex['difficulty'], 'level2');
    });

    test('custom workouts: most recently updated first with entries', () {
      final c = (data['customWorkouts'] as List).cast<Map<String, dynamic>>();
      expect(c.map((t) => t['id']), ['cw_b', 'cw_a']);
      expect(c.first['name'], 'Custom cw_b');
      expect(c.first['updatedAt'], '2026-09-12T12:00:00.000Z');
      expect((c.first['main'] as List).length, 2);
    });

    test('programs: active id + progress sorted by program id, no definitions',
        () {
      final p = data['adaptivePrograms'] as Map<String, dynamic>;
      expect(
          p['activeProgramId'], AdaptiveProgramCatalog.balancedFoundationsId);
      final progress = (p['progress'] as List).cast<Map<String, dynamic>>();
      expect(progress.map((e) => e['programId']),
          ['balanced_foundations', 'strength_foundations']);
      final balanced = progress.first;
      expect(balanced['startedAt'], '2026-08-20T06:00:00.000Z');
      expect(balanced['updatedAt'], '2026-08-23T06:00:00.000Z');
      final completions =
          (balanced['completions'] as List).cast<Map<String, dynamic>>();
      expect(completions.length, 2);
      expect(
          completions.first['plannedSessionId'], 'balanced_foundations_w1_s1');
      expect(completions.first['playerSessionId'], 'session_a');
      expect(completions.first['completedAt'], '2026-08-21T06:00:00.000Z');
      expect(p.containsKey('definitions'), isFalse);
      expect(p.containsKey('weeks'), isFalse);
      expect(p.containsKey('sessions'), isFalse);
    });

    test('reminders: only enabled/weekdays/hour/minute', () {
      final r = data['workoutReminders'] as Map<String, dynamic>;
      expect(r, {
        'enabled': true,
        'weekdays': [1, 3, 5],
        'hour': 7,
        'minute': 30,
      });
    });

    test('appearance is the enum name', () {
      expect(data['appearance'], 'dark');
    });

    test('empty state encodes nulls / empty lists (never omits sections)', () {
      final root = jsonDecode(
              utf8.decode(BackupCodec.encode(envelopeOf(emptyBackupData()))))
          as Map<String, dynamic>;
      final d = dataOf(root);
      expect(d['userFitnessProfile'], isNull);
      expect(d['capabilityProfile'], isNull);
      expect(d['workoutHistory'], isEmpty);
      expect(d['customWorkouts'], isEmpty);
      expect((d['adaptivePrograms'] as Map)['activeProgramId'], isNull);
      expect((d['adaptivePrograms'] as Map)['progress'], isEmpty);
      expect((d['workoutReminders'] as Map)['enabled'], isFalse);
      expect(d['appearance'], 'system');
    });
  });

  group('BackupCodec.encode — exclusions', () {
    test(
        'never contains session mode, player, TTS, timezone, permission or plans',
        () {
      final text = utf8.decode(fullBackupBytes()).toLowerCase();
      for (final forbidden in [
        'sessionmode',
        'workoutsessionmode',
        'player',
        'tts',
        'mute',
        'timezone',
        'lastscheduledtimezoneid',
        'permission',
        'pendingids',
        'notificationid',
        'skilltree',
        'workoutplan',
        'catalog',
        'token',
        'password',
      ]) {
        // "playerSessionId" is a legitimate program completion field.
        final scrubbed = text.replaceAll('playersessionid', '');
        expect(scrubbed.contains(forbidden), isFalse,
            reason: 'backup must not contain "$forbidden"');
      }
    });

    test('is logical JSON, not raw SharedPreferences strings', () {
      final data = dataOf(fullBackupJson());
      // Every section is a structured value (object/list/string enum), never
      // a JSON-encoded string.
      expect(data['userFitnessProfile'], isA<Map>());
      expect(data['capabilityProfile'], isA<Map>());
      expect(data['adaptiveProgressionEvidence'], isA<Map>());
      expect(data['workoutHistory'], isA<List>());
      expect(data['customWorkouts'], isA<List>());
      expect(data['adaptivePrograms'], isA<Map>());
      expect(data['workoutReminders'], isA<Map>());
      expect(
          (data['adaptiveProgressionEvidence'] as Map).containsKey('version'),
          isFalse);
    });
  });

  group('BackupCodec — determinism & round-trip', () {
    test('same data + timestamp → identical bytes', () {
      final a = BackupCodec.encode(envelopeOf(fullBackupData()));
      final b = BackupCodec.encode(envelopeOf(fullBackupData()));
      expect(a, equals(b));
    });

    test('unordered input orders identically', () {
      final data = fullBackupData();
      final shuffled = data.copyWith(
        workoutHistory: data.workoutHistory.reversed.toList(),
        customWorkouts: data.customWorkouts.reversed.toList(),
      );
      expect(BackupCodec.encode(envelopeOf(shuffled)),
          equals(BackupCodec.encode(envelopeOf(data))));
    });

    test('decode(encode(x)) == x for the full fixture', () {
      final original = fullBackupData();
      final result =
          BackupCodec.decode(BackupCodec.encode(envelopeOf(original)));
      expect(result.isSuccess, isTrue, reason: result.detail);
      // Structural equality via the deterministic encoder.
      expect(BackupCodec.encode(envelopeOf(result.envelope!.data)),
          equals(BackupCodec.encode(envelopeOf(original))));
      final decoded = result.envelope!.data;
      expect(decoded.capabilityProfile, equals(original.capabilityProfile));
      expect(decoded.workoutHistory, equals(original.workoutHistory));
      expect(decoded.customWorkouts, equals(original.customWorkouts));
      expect(decoded.adaptivePrograms, equals(original.adaptivePrograms));
      expect(decoded.adaptiveProgressionEvidence,
          equals(original.adaptiveProgressionEvidence));
      expect(decoded.workoutReminders, equals(original.workoutReminders));
      expect(decoded.userFitnessProfile!.equipment,
          original.userFitnessProfile!.equipment);
      expect(result.envelope!.createdAtUtc, backupTestNow);
      expect(result.envelope!.createdAtUtc.isUtc, isTrue);
    });

    test('decode(encode(empty)) == empty', () {
      final result =
          BackupCodec.decode(BackupCodec.encode(envelopeOf(emptyBackupData())));
      expect(result.isSuccess, isTrue, reason: result.detail);
      expect(BackupCodec.encode(envelopeOf(result.envelope!.data)),
          equals(BackupCodec.encode(envelopeOf(emptyBackupData()))));
    });
  });

  group('BackupCodec.decode — validation', () {
    BackupValidationError? errorOf(Uint8List bytes) =>
        BackupCodec.decode(bytes).error;

    test('rejects files over 5 MiB before parsing', () {
      final big = Uint8List(BackupFormat.maxImportBytes + 1);
      expect(errorOf(big), BackupValidationError.tooLarge);
      // Exactly the limit is allowed through to parsing (fails later, not size).
      final atLimit = Uint8List(BackupFormat.maxImportBytes);
      expect(errorOf(atLimit), isNot(BackupValidationError.tooLarge));
    });

    test('rejects empty and invalid UTF-8', () {
      expect(errorOf(Uint8List(0)), BackupValidationError.unreadable);
      expect(errorOf(Uint8List.fromList([0xC3, 0x28, 0x7B])),
          BackupValidationError.unreadable);
    });

    test('rejects invalid JSON and non-object roots', () {
      expect(errorOf(Uint8List.fromList(utf8.encode('{not json'))),
          BackupValidationError.unreadable);
      expect(errorOf(bytesOf([1, 2, 3])), BackupValidationError.unreadable);
      expect(errorOf(bytesOf('text')), BackupValidationError.unreadable);
    });

    test('rejects missing or wrong format marker', () {
      expect(errorOf(bytesOf({'schemaVersion': 1, 'data': {}})),
          BackupValidationError.notFitFlowBackup);
      expect(errorOf(mutatedBackup((r) => r['format'] = 'other_app')),
          BackupValidationError.notFitFlowBackup);
    });

    test('rejects newer schema version with dedicated error', () {
      expect(errorOf(mutatedBackup((r) => r['schemaVersion'] = 2)),
          BackupValidationError.newerVersion);
      expect(errorOf(mutatedBackup((r) => r['schemaVersion'] = 99)),
          BackupValidationError.newerVersion);
    });

    test('rejects malformed / older schema versions', () {
      expect(errorOf(mutatedBackup((r) => r['schemaVersion'] = 0)),
          BackupValidationError.unsupportedVersion);
      expect(errorOf(mutatedBackup((r) => r['schemaVersion'] = '1')),
          BackupValidationError.unsupportedVersion);
      expect(errorOf(mutatedBackup((r) => r.remove('schemaVersion'))),
          BackupValidationError.unsupportedVersion);
      expect(errorOf(mutatedBackup((r) => r['schemaVersion'] = 1.5)),
          BackupValidationError.unsupportedVersion);
    });

    test('rejects missing data object or missing section', () {
      expect(errorOf(mutatedBackup((r) => r.remove('data'))),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => r['data'] = [])),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => dataOf(r).remove('appearance'))),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => r['createdAtUtc'] = 'yesterday')),
          BackupValidationError.invalidData);
    });

    test('rejects invalid profile enum and empty equipment', () {
      expect(
          errorOf(mutatedBackup((r) =>
              (dataOf(r)['userFitnessProfile'] as Map)['goal'] = 'getRipped')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              (dataOf(r)['userFitnessProfile'] as Map)['equipment'] = [])),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              (dataOf(r)['userFitnessProfile'] as Map)['preferences'] = 'x')),
          BackupValidationError.invalidData);
    });

    test('rejects incomplete, duplicate or invalid capability profile', () {
      List<dynamic> caps(Map<String, dynamic> r) =>
          (dataOf(r)['capabilityProfile'] as Map)['capabilities'] as List;
      expect(errorOf(mutatedBackup((r) => caps(r).removeLast())),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => caps(r)[1] = caps(r)[0])),
          BackupValidationError.invalidData);
      expect(
          errorOf(
              mutatedBackup((r) => (caps(r)[0] as Map)['level'] = 'level9')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (caps(r)[0] as Map)['updatedAt'] = 'not-a-date')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (caps(r)[0] as Map)['anchorExerciseId'] = '  ')),
          BackupValidationError.invalidData);
    });

    test('rejects malformed progression evidence', () {
      Map<String, dynamic> ev(Map<String, dynamic> r) =>
          dataOf(r)['adaptiveProgressionEvidence'] as Map<String, dynamic>;
      expect(errorOf(mutatedBackup((r) => ev(r)['counts'] = 'x')),
          BackupValidationError.invalidData);
      expect(
          errorOf(
              mutatedBackup((r) => (ev(r)['counts'] as Map)['push'] = 'one')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) => (ev(r)['counts'] as Map)['push'] = 5)),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) => (ev(r)['counts'] as Map)['warmup'] = 1)),
          BackupValidationError.invalidData);
    });

    test('rejects malformed history records (whole backup fails)', () {
      List<dynamic> hist(Map<String, dynamic> r) =>
          dataOf(r)['workoutHistory'] as List;
      expect(errorOf(mutatedBackup((r) => (hist(r)[0] as Map).remove('id'))),
          BackupValidationError.invalidData);
      expect(
          errorOf(
              mutatedBackup((r) => (hist(r)[0] as Map)['completedAt'] = 12)),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (hist(r)[1] as Map)['id'] = (hist(r)[0] as Map)['id'])),
          BackupValidationError.invalidData);
      // A bad nested exercise (tolerant loader would silently drop it).
      expect(
          errorOf(mutatedBackup((r) =>
              ((hist(r)[0] as Map)['main'] as List)[0] = {'exerciseId': 'x'})),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => hist(r).add('junk'))),
          BackupValidationError.invalidData);
    });

    test('rejects malformed custom workouts', () {
      List<dynamic> cw(Map<String, dynamic> r) =>
          dataOf(r)['customWorkouts'] as List;
      expect(errorOf(mutatedBackup((r) => (cw(r)[0] as Map)['name'] = 7)),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (cw(r)[0] as Map)['targetDuration'] = 'forever')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (cw(r)[1] as Map)['id'] = (cw(r)[0] as Map)['id'])),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              ((cw(r)[0] as Map)['main'] as List)[0] = {'sets': 'three'})),
          BackupValidationError.invalidData);
    });

    test('rejects unknown program ids and malformed completions', () {
      Map<String, dynamic> pr(Map<String, dynamic> r) =>
          dataOf(r)['adaptivePrograms'] as Map<String, dynamic>;
      expect(
          errorOf(mutatedBackup((r) =>
              ((pr(r)['progress'] as List)[0] as Map)['programId'] = 'nope')),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => pr(r)['activeProgramId'] = 'nope')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              (((pr(r)['progress'] as List)[0] as Map)['completions'] as List)
                  .add({'plannedSessionId': 'x'}))),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              (pr(r)['progress'] as List).add((pr(r)['progress'] as List)[0]))),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => pr(r)['progress'] = {})),
          BackupValidationError.invalidData);
    });

    test('rejects invalid reminder preferences', () {
      Map<String, dynamic> rem(Map<String, dynamic> r) =>
          dataOf(r)['workoutReminders'] as Map<String, dynamic>;
      expect(errorOf(mutatedBackup((r) => rem(r)['hour'] = 24)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => rem(r)['minute'] = -1)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => rem(r)['weekdays'] = [0, 8])),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => rem(r)['weekdays'] = [1, 1])),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => rem(r)['enabled'] = 'yes')),
          BackupValidationError.invalidData);
      // enabled with no weekdays is contradictory.
      expect(errorOf(mutatedBackup((r) => rem(r)['weekdays'] = [])),
          BackupValidationError.invalidData);
      // disabled with no weekdays is fine.
      expect(
          BackupCodec.decode(mutatedBackup((r) {
            rem(r)['weekdays'] = [];
            rem(r)['enabled'] = false;
          })).isSuccess,
          isTrue);
    });

    test('rejects invalid appearance and accepts each valid mode', () {
      expect(errorOf(mutatedBackup((r) => dataOf(r)['appearance'] = 'neon')),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => dataOf(r)['appearance'] = null)),
          BackupValidationError.invalidData);
      for (final mode in AppearanceMode.values) {
        final result = BackupCodec.decode(
            mutatedBackup((r) => dataOf(r)['appearance'] = mode.name));
        expect(result.envelope?.data.appearance, mode);
      }
    });

    test('null profile / capability sections are valid (not included)', () {
      final result = BackupCodec.decode(mutatedBackup((r) {
        dataOf(r)['userFitnessProfile'] = null;
        dataOf(r)['capabilityProfile'] = null;
      }));
      expect(result.isSuccess, isTrue, reason: result.detail);
      expect(result.envelope!.data.userFitnessProfile, isNull);
      expect(result.envelope!.data.capabilityProfile, isNull);
    });

    test('failure results carry no envelope and a concise detail', () {
      final result = BackupCodec.decode(mutatedBackup(
          (r) => (dataOf(r)['workoutReminders'] as Map)['hour'] = 99));
      expect(result.isSuccess, isFalse);
      expect(result.envelope, isNull);
      expect(result.detail, isNotNull);
      expect(result.detail!.length, lessThan(80));
      expect(result.detail, isNot(contains('#0')));
    });

    test('decode ignores unknown extra root keys but keeps strict data', () {
      final result =
          BackupCodec.decode(mutatedBackup((r) => r['appVersion'] = '1.2.3'));
      expect(result.isSuccess, isTrue);
    });

    test(
        'history ordering after decode is newest-first regardless of file order',
        () {
      final result = BackupCodec.decode(mutatedBackup((r) {
        final h = dataOf(r)['workoutHistory'] as List;
        dataOf(r)['workoutHistory'] = h.reversed.toList();
      }));
      expect(result.envelope!.data.workoutHistory.map((w) => w.id),
          ['hist_2', 'hist_1', 'hist_0']);
      expect(
          result.envelope!.data.adaptiveProgressionEvidence
              .countFor(MovementPattern.push),
          1);
    });
  });
}
