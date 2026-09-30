import 'dart:typed_data';

import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/data/backup_persistence_codec.dart';
import 'package:fitflow/features/backup/data/backup_restore_transaction.dart';
import 'package:fitflow/features/backup/data/backup_snapshot_reader.dart';
import 'package:fitflow/features/backup/domain/backup_validation_result.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_limits.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/backup_test_helpers.dart';

/// M18 stabilization: a backup that passes strict validation must restore
/// without silent normalization, record dropping, de-duplication, fallback
/// timestamps or limit trimming anywhere in
/// `decode → BackupPersistenceCodec → existing storage loaders`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BackupValidationResult decode(Uint8List bytes) => BackupCodec.decode(bytes);
  BackupValidationError? errorOf(Uint8List bytes) => decode(bytes).error;

  Map<String, dynamic> evidenceCounts(Map<String, dynamic> r) =>
      (dataOf(r)['adaptiveProgressionEvidence'] as Map)['counts']
          as Map<String, dynamic>;

  Map<String, dynamic> programs(Map<String, dynamic> r) =>
      dataOf(r)['adaptivePrograms'] as Map<String, dynamic>;

  Map<String, dynamic> balanced(Map<String, dynamic> r) =>
      (programs(r)['progress'] as List).cast<Map<String, dynamic>>().firstWhere(
          (p) =>
              p['programId'] == AdaptiveProgramCatalog.balancedFoundationsId);

  List<dynamic> balancedCompletions(Map<String, dynamic> r) =>
      balanced(r)['completions'] as List;

  Map<String, dynamic> completion(String planned, String player,
          [String completedAt = '2026-08-22T06:00:00.000Z']) =>
      {
        'plannedSessionId': planned,
        'playerSessionId': player,
        'completedAt': completedAt,
      };

  // ---------------------------------------------------------------------------
  // Evidence completeness
  // ---------------------------------------------------------------------------
  group('Evidence completeness', () {
    test('1. all 10 trainable keys valid → accepted with exact values', () {
      final result = decode(mutatedBackup((r) {
        final counts = evidenceCounts(r);
        for (final p in CapabilityProfile.trainablePatterns) {
          counts[p.name] = 1;
        }
      }));
      expect(result.isSuccess, isTrue, reason: result.detail);
      final ev = result.envelope!.data.adaptiveProgressionEvidence;
      for (final p in CapabilityProfile.trainablePatterns) {
        expect(ev.countFor(p), 1, reason: p.name);
      }
      expect(CapabilityProfile.trainablePatterns.length, 10);
    });

    test('2. one trainable key missing → rejected (never silent zero)', () {
      final bytes = mutatedBackup((r) => evidenceCounts(r).remove('push'));
      final result = decode(bytes);
      expect(result.error, BackupValidationError.invalidData);
      expect(result.envelope, isNull);
      expect(result.detail, contains('evidence'));
    });

    test('3. two trainable keys missing → rejected', () {
      expect(errorOf(mutatedBackup((r) {
        evidenceCounts(r).remove('hinge');
        evidenceCounts(r).remove('balance');
      })), BackupValidationError.invalidData);
    });

    test('4. unknown movement key → rejected (even with all 10 present)', () {
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['warmup'] = 0)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['cooldown'] = 1)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['made_up'] = 1)),
          BackupValidationError.invalidData);
    });

    test(
        '5. fewer than 10 entries → rejected; replacing a key keeps count 10 but is rejected too',
        () {
      expect(
          errorOf(mutatedBackup((r) => (dataOf(r)['adaptiveProgressionEvidence']
              as Map)['counts'] = <String, Object?>{})),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) => (dataOf(r)['adaptiveProgressionEvidence']
              as Map)['counts'] = {'push': 1})),
          BackupValidationError.invalidData);
      // Swap a valid key for an unknown one: still 10 entries, still invalid.
      expect(errorOf(mutatedBackup((r) {
        evidenceCounts(r).remove('core');
        evidenceCounts(r)['warmup'] = 0;
      })), BackupValidationError.invalidData);
    });

    test('6. value < 0 → rejected', () {
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = -1)),
          BackupValidationError.invalidData);
    });

    test('7. value > 1 → rejected', () {
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = 2)),
          BackupValidationError.invalidData);
    });

    test('8. non-int value → rejected', () {
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = '1')),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = 1.0)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = true)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => evidenceCounts(r)['squat'] = null)),
          BackupValidationError.invalidData);
    });

    test(
        'missing evidence is rejected by the backup decoder even though the runtime storage would zero-fill',
        () async {
      // Runtime tolerance (M10) is unchanged …
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":1}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final runtime = AdaptiveProgressionEvidenceStorage(prefs).load();
      expect(runtime.countFor(MovementPattern.push), 1);
      expect(runtime.countFor(MovementPattern.squat), 0);
      // … but the backup decoder never fills gaps.
      expect(
          errorOf(mutatedBackup((r) => (dataOf(r)['adaptiveProgressionEvidence']
              as Map)['counts'] = {'push': 1})),
          BackupValidationError.invalidData);
    });
  });

  // ---------------------------------------------------------------------------
  // Program strictness
  // ---------------------------------------------------------------------------
  group('Program strictness', () {
    test('9. valid program progress accepted losslessly', () {
      final result = decode(fullBackupBytes());
      expect(result.isSuccess, isTrue, reason: result.detail);
      final progress = result.envelope!.data.adaptivePrograms
          .progressFor(AdaptiveProgramCatalog.balancedFoundationsId)!;
      expect(progress.startedAt, DateTime.utc(2026, 8, 20, 6));
      expect(progress.updatedAt, DateTime.utc(2026, 8, 23, 6));
      expect(progress.completions.length, 2);
      expect(progress.completions.map((c) => c.plannedSessionId),
          ['balanced_foundations_w1_s1', 'balanced_foundations_w1_s2']);
    });

    test('10. missing updatedAt → rejected (no fallback to startedAt)', () {
      final result =
          decode(mutatedBackup((r) => balanced(r).remove('updatedAt')));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('updatedAt'));
    });

    test('11. invalid updatedAt → rejected', () {
      expect(errorOf(mutatedBackup((r) => balanced(r)['updatedAt'] = 'later')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) => balanced(r)['updatedAt'] = 1700000000)),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => balanced(r)['updatedAt'] = null)),
          BackupValidationError.invalidData);
    });

    test('12. missing / invalid startedAt → rejected', () {
      expect(errorOf(mutatedBackup((r) => balanced(r).remove('startedAt'))),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) => balanced(r)['startedAt'] = 'yesterday')),
          BackupValidationError.invalidData);
    });

    test('13. invalid completion timestamp → rejected (not skipped)', () {
      expect(
          errorOf(mutatedBackup((r) => (balancedCompletions(r)[0]
              as Map)['completedAt'] = 'not-a-date')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup(
              (r) => (balancedCompletions(r)[0] as Map).remove('completedAt'))),
          BackupValidationError.invalidData);
    });

    test('14. unknown planned session → rejected', () {
      final result = decode(mutatedBackup((r) => balancedCompletions(r)
          .add(completion('balanced_foundations_w99_s9', 'session_z'))));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('balanced_foundations_w99_s9'));
    });

    test('15. session belonging to another program → rejected', () {
      // The session exists in the global catalog but not in balanced_foundations.
      expect(AdaptiveProgramCatalog.sessionById('strength_foundations_w1_s1'),
          isNotNull);
      final result = decode(mutatedBackup((r) => balancedCompletions(r)
          .add(completion('strength_foundations_w1_s1', 'session_z'))));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('strength_foundations_w1_s1'));
    });

    test('16. duplicate planned-session ID → rejected (no de-duplication)', () {
      final result = decode(mutatedBackup((r) => balancedCompletions(r)
          .add(completion('balanced_foundations_w1_s1', 'session_other'))));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('duplicate planned session'));
    });

    test(
        '17. duplicate player-session ID across different planned sessions → rejected',
        () {
      final result = decode(mutatedBackup((r) => balancedCompletions(r)
          .add(completion('balanced_foundations_w1_s3', 'session_a'))));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('duplicate player session'));
    });

    test('18. two valid different completions remain two after decode', () {
      final result = decode(fullBackupBytes());
      final progress = result.envelope!.data.adaptivePrograms
          .progressFor(AdaptiveProgramCatalog.balancedFoundationsId)!;
      expect(progress.completions.length, 2);
      expect(progress.completions.map((c) => c.playerSessionId),
          ['session_a', 'session_b']);
    });

    test('19. parsed completion count always equals raw count on success', () {
      final sessions = AdaptiveProgramCatalog.byId(
              AdaptiveProgramCatalog.balancedFoundationsId)!
          .sessions;
      expect(sessions.length, greaterThanOrEqualTo(4));
      final bytes = mutatedBackup((r) {
        balanced(r)['completions'] = [
          for (var i = 0; i < sessions.length; i++)
            completion(
                sessions[i].id,
                'player_$i',
                DateTime.utc(2026, 8, 21)
                    .add(Duration(days: i))
                    .toIso8601String()),
        ];
      });
      final result = decode(bytes);
      expect(result.isSuccess, isTrue, reason: result.detail);
      final progress = result.envelope!.data.adaptivePrograms
          .progressFor(AdaptiveProgramCatalog.balancedFoundationsId)!;
      expect(progress.completions.length, sessions.length);
      expect(progress.completions.map((c) => c.plannedSessionId),
          sessions.map((s) => s.id));
    });

    test('missing / empty ids and non-list completions → rejected', () {
      expect(
          errorOf(mutatedBackup((r) =>
              (balancedCompletions(r)[0] as Map)['plannedSessionId'] = '')),
          BackupValidationError.invalidData);
      expect(
          errorOf(mutatedBackup((r) =>
              (balancedCompletions(r)[0] as Map).remove('playerSessionId'))),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => balanced(r)['completions'] = {})),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => balanced(r).remove('completions'))),
          BackupValidationError.invalidData);
      expect(errorOf(mutatedBackup((r) => balanced(r)['programId'] = '')),
          BackupValidationError.invalidData);
    });

    test('runtime AdaptiveProgramProgress.fromJson tolerance is unchanged', () {
      final tolerant = {
        'programId': AdaptiveProgramCatalog.balancedFoundationsId,
        'startedAt': '2026-08-20T06:00:00.000Z',
        'completions': [
          completion('balanced_foundations_w1_s1', 'p1'),
          completion('balanced_foundations_w1_s1', 'p2'),
          {'plannedSessionId': 'broken'},
        ],
      };
      final progress = AdaptiveProgramProgress.fromJson(tolerant);
      expect(progress, isNotNull);
      expect(progress!.updatedAt, progress.startedAt);
      expect(progress.completions.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Bounded collections
  // ---------------------------------------------------------------------------
  group('Bounded collections', () {
    Uint8List withHistory(int count) =>
        BackupCodec.encode(envelopeOf(fullBackupData()
            .copyWith(workoutHistory: backupHistory(count: count))));

    Uint8List withCustom(int count) => BackupCodec.encode(
            envelopeOf(fullBackupData().copyWith(customWorkouts: [
          for (var i = 0; i < count; i++)
            backupTemplate(
                'cw_$i', DateTime.utc(2026, 1, 1).add(Duration(hours: i))),
        ])));

    test('20. 100 history sessions → valid', () {
      final result = decode(withHistory(WorkoutHistoryStorage.maxEntries));
      expect(result.isSuccess, isTrue, reason: result.detail);
      expect(result.envelope!.data.workoutHistory.length, 100);
    });

    test('21. 101 history sessions → rejected (no trimming)', () {
      final result = decode(withHistory(WorkoutHistoryStorage.maxEntries + 1));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('history count 101'));
    });

    test('22. accepted 100 remain 100 after persistence encode/decode',
        () async {
      final data = decode(withHistory(100)).envelope!.data;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect((await BackupRestoreTransaction(prefs: prefs).run(data)).success,
          isTrue);
      final loaded = WorkoutHistoryStorage(prefs).load();
      expect(loaded.length, 100);
      expect(loaded.map((w) => w.id).toSet(),
          data.workoutHistory.map((w) => w.id).toSet());
      expect(loaded.map((w) => w.id), data.workoutHistory.map((w) => w.id),
          reason: 'order preserved (newest first)');
    });

    test('23. 50 custom workouts → valid', () {
      final result = decode(withCustom(CustomWorkoutLimits.maxTemplates));
      expect(result.isSuccess, isTrue, reason: result.detail);
      expect(result.envelope!.data.customWorkouts.length, 50);
    });

    test('24. 51 custom workouts → rejected (no truncation)', () {
      final result = decode(withCustom(CustomWorkoutLimits.maxTemplates + 1));
      expect(result.error, BackupValidationError.invalidData);
      expect(result.detail, contains('customWorkouts count 51'));
    });

    test('25. accepted 50 remain 50 after persistence encode/decode', () async {
      final data = decode(withCustom(50)).envelope!.data;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect((await BackupRestoreTransaction(prefs: prefs).run(data)).success,
          isTrue);
      final loaded =
          await CustomWorkoutStorage(getPrefs: () async => prefs).loadAll();
      expect(loaded.length, 50);
      expect(loaded.map((t) => t.id), data.customWorkouts.map((t) => t.id));
    });

    test('runtime storages stay tolerant (trim on their own save paths)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await WorkoutHistoryStorage(prefs).saveAll(backupHistory(count: 101));
      expect(WorkoutHistoryStorage(prefs).load().length, 100);
    });
  });

  // ---------------------------------------------------------------------------
  // Lossless persistence boundary
  // ---------------------------------------------------------------------------
  group('Lossless restore', () {
    test(
        'maximum-valid backup survives decode → persistence → storage loaders intact',
        () async {
      final sessions = AdaptiveProgramCatalog.byId(
              AdaptiveProgramCatalog.balancedFoundationsId)!
          .sessions;
      final maxBytes = mutatedBackup((r) {
        final counts = evidenceCounts(r);
        for (final p in CapabilityProfile.trainablePatterns) {
          counts[p.name] = 1;
        }
        dataOf(r)['workoutHistory'] = [
          for (final w in backupHistory(count: 100))
            BackupCodec.workoutToJson(w),
        ];
        dataOf(r)['customWorkouts'] = [
          for (var i = 0; i < 50; i++)
            BackupCodec.templateToJson(backupTemplate(
                'cw_$i', DateTime.utc(2026, 1, 1).add(Duration(hours: i)))),
        ];
        balanced(r)['completions'] = [
          for (var i = 0; i < sessions.length; i++)
            completion(
                sessions[i].id,
                'player_$i',
                DateTime.utc(2026, 8, 21)
                    .add(Duration(days: i))
                    .toIso8601String()),
        ];
      });

      // 1–2. strict decode succeeds
      final result = decode(maxBytes);
      expect(result.isSuccess, isTrue, reason: result.detail);
      final validated = result.envelope!.data;
      expect(validated.workoutHistory.length, 100);
      expect(validated.customWorkouts.length, 50);
      expect(validated.adaptivePrograms.progressByProgram.length, 2);
      expect(validated.completedProgramSessionCount, sessions.length);

      // 3. persistence codec + 4. existing storages
      final raw = BackupPersistenceCodec.rawValuesFor(validated);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      for (final entry in raw.entries) {
        if (entry.value != null) await prefs.setString(entry.key, entry.value!);
      }
      Future<SharedPreferences> same() async => prefs;

      // 5. counts and IDs identical
      final history = WorkoutHistoryStorage(prefs).load();
      expect(history.length, 100);
      expect(
          history.map((w) => w.id), validated.workoutHistory.map((w) => w.id));

      final custom = await CustomWorkoutStorage(getPrefs: same).loadAll();
      expect(custom.length, 50);
      expect(
          custom.map((t) => t.id), validated.customWorkouts.map((t) => t.id));

      final programsState =
          await AdaptiveProgramsStorage(getPrefs: same).load();
      expect(programsState, equals(validated.adaptivePrograms));
      final loadedBalanced = programsState
          .progressFor(AdaptiveProgramCatalog.balancedFoundationsId)!;
      expect(loadedBalanced.completions.length, sessions.length);
      expect(loadedBalanced.completions.map((c) => c.plannedSessionId),
          sessions.map((s) => s.id));
      expect(loadedBalanced.completions.map((c) => c.playerSessionId),
          [for (var i = 0; i < sessions.length; i++) 'player_$i']);
      expect(loadedBalanced.updatedAt, DateTime.utc(2026, 8, 23, 6),
          reason: 'updatedAt restored verbatim, not recomputed');

      final evidence = AdaptiveProgressionEvidenceStorage(prefs).load();
      for (final p in CapabilityProfile.trainablePatterns) {
        expect(evidence.countFor(p), 1, reason: p.name);
      }

      // Full round trip through the snapshot reader reproduces identical bytes.
      final reread = await BackupSnapshotReader(getPrefs: same).read();
      expect(BackupCodec.encode(envelopeOf(reread)),
          equals(BackupCodec.encode(envelopeOf(validated))));
      expect(reread.workoutHistory.length, 100);
    });
  });
}
