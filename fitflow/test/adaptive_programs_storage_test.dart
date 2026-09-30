import 'dart:convert';

import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime.utc(2026, 9, 1, 8);
  final t1 = DateTime.utc(2026, 9, 2, 8);
  final t2 = DateTime.utc(2026, 9, 3, 8);

  AdaptiveProgramSessionCompletion completion(String planned, String player,
          DateTime at) =>
      AdaptiveProgramSessionCompletion(
          plannedSessionId: planned, playerSessionId: player, completedAt: at);

  group('AdaptiveProgramsStorage', () {
    test('key is adaptive_programs_v1 and differs from history key', () {
      expect(AdaptiveProgramsStorage.key, 'adaptive_programs_v1');
      expect(AdaptiveProgramsStorage.key, isNot(WorkoutHistoryStorage.key));
    });

    test('empty prefs → empty state', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await const AdaptiveProgramsStorage().load();
      expect(state.activeProgramId, isNull);
      expect(state.progressByProgram, isEmpty);
      expect(state, AdaptiveProgramsState.empty);
    });

    test('roundtrip active ID, progress and completions', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = AdaptiveProgramsStorage();
      final progress = AdaptiveProgramProgress(
        programId: 'balanced_foundations',
        startedAt: t0,
        updatedAt: t2,
        completions: [
          completion('balanced_foundations_w1_s1', 'player_a', t1),
          completion('balanced_foundations_w1_s3', 'player_b', t2),
        ],
      );
      final other = AdaptiveProgramProgress.fresh(
          programId: 'mobility_movement', startedAt: t1);
      final state = AdaptiveProgramsState(
        activeProgramId: 'balanced_foundations',
        progressByProgram: {
          progress.programId: progress,
          other.programId: other,
        },
      );
      expect(await storage.save(state), isTrue);
      final loaded = await storage.load();
      expect(loaded.activeProgramId, 'balanced_foundations');
      expect(loaded.progressByProgram.length, 2);
      final lp = loaded.progressFor('balanced_foundations')!;
      expect(lp.startedAt, t0);
      expect(lp.updatedAt, t2);
      expect(lp.completions.length, 2);
      expect(lp.completions.first.plannedSessionId, 'balanced_foundations_w1_s1');
      expect(lp.completions.first.playerSessionId, 'player_a');
      expect(lp.completions.first.completedAt, t1);
      expect(lp.completions.last.plannedSessionId, 'balanced_foundations_w1_s3');
      expect(loaded.progressFor('mobility_movement')!.completions, isEmpty);
      expect(loaded, state);
    });

    test('encode is deterministic (sorted program order)', () {
      final a = AdaptiveProgramsState(
        activeProgramId: 'stay_active_starter',
        progressByProgram: {
          'stay_active_starter':
              AdaptiveProgramProgress.fresh(programId: 'stay_active_starter', startedAt: t0),
          'balanced_foundations':
              AdaptiveProgramProgress.fresh(programId: 'balanced_foundations', startedAt: t0),
        },
      );
      final b = AdaptiveProgramsState(
        activeProgramId: 'stay_active_starter',
        progressByProgram: {
          'balanced_foundations':
              AdaptiveProgramProgress.fresh(programId: 'balanced_foundations', startedAt: t0),
          'stay_active_starter':
              AdaptiveProgramProgress.fresh(programId: 'stay_active_starter', startedAt: t0),
        },
      );
      expect(AdaptiveProgramsStorage.encode(a), AdaptiveProgramsStorage.encode(b));
      final decoded = jsonDecode(AdaptiveProgramsStorage.encode(a)) as Map;
      final ids = (decoded['progress'] as List).map((e) => e['programId']).toList();
      expect(ids, ['balanced_foundations', 'stay_active_starter']);
    });

    test('malformed root → safe empty state', () async {
      for (final raw in ['not json', '[]', '42', '"str"', '{"progress": 5}']) {
        SharedPreferences.setMockInitialValues({AdaptiveProgramsStorage.key: raw});
        final state = await const AdaptiveProgramsStorage().load();
        expect(state.activeProgramId, isNull, reason: raw);
        expect(state.progressByProgram, isEmpty, reason: raw);
      }
    });

    test('malformed child entries are skipped individually', () async {
      final raw = jsonEncode({
        'activeProgramId': 'balanced_foundations',
        'progress': [
          'garbage',
          {'programId': 42},
          {'programId': 'balanced_foundations'}, // missing startedAt
          {
            'programId': 'balanced_foundations',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t1.toIso8601String(),
            'completions': [
              'bad',
              {'plannedSessionId': 'balanced_foundations_w1_s1'}, // missing fields
              {
                'plannedSessionId': 'balanced_foundations_w1_s2',
                'playerSessionId': 'p2',
                'completedAt': 'not-a-date',
              },
              {
                'plannedSessionId': 'balanced_foundations_w1_s3',
                'playerSessionId': 'p3',
                'completedAt': t1.toIso8601String(),
              },
            ],
          },
          {
            'programId': 'mobility_movement',
            'startedAt': t0.toIso8601String(),
            // no updatedAt / completions → tolerated
          },
        ],
      });
      SharedPreferences.setMockInitialValues({AdaptiveProgramsStorage.key: raw});
      final state = await const AdaptiveProgramsStorage().load();
      expect(state.activeProgramId, 'balanced_foundations');
      expect(state.progressByProgram.keys.toSet(),
          {'balanced_foundations', 'mobility_movement'});
      final bp = state.progressFor('balanced_foundations')!;
      expect(bp.completions.length, 1);
      expect(bp.completions.single.plannedSessionId, 'balanced_foundations_w1_s3');
      final mp = state.progressFor('mobility_movement')!;
      expect(mp.updatedAt, t0);
      expect(mp.completions, isEmpty);
    });

    test('duplicate progress IDs resolve deterministically (latest updatedAt)',
        () async {
      final raw = jsonEncode({
        'activeProgramId': null,
        'progress': [
          {
            'programId': 'balanced_foundations',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t2.toIso8601String(),
            'completions': [
              {
                'plannedSessionId': 'balanced_foundations_w1_s1',
                'playerSessionId': 'p1',
                'completedAt': t1.toIso8601String(),
              },
            ],
          },
          {
            'programId': 'balanced_foundations',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t1.toIso8601String(),
            'completions': [],
          },
          {
            // same updatedAt as first → first wins (tie)
            'programId': 'balanced_foundations',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t2.toIso8601String(),
            'completions': [],
          },
        ],
      });
      SharedPreferences.setMockInitialValues({AdaptiveProgramsStorage.key: raw});
      final a = await const AdaptiveProgramsStorage().load();
      final b = await const AdaptiveProgramsStorage().load();
      expect(a.progressByProgram.length, 1);
      expect(a.progressFor('balanced_foundations')!.completions.length, 1);
      expect(a, b);
    });

    test('duplicate completion IDs are de-duplicated deterministically',
        () async {
      final raw = jsonEncode({
        'activeProgramId': 'balanced_foundations',
        'progress': [
          {
            'programId': 'balanced_foundations',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t2.toIso8601String(),
            'completions': [
              {
                'plannedSessionId': 'balanced_foundations_w1_s1',
                'playerSessionId': 'p1',
                'completedAt': t1.toIso8601String(),
              },
              {
                // duplicate planned session
                'plannedSessionId': 'balanced_foundations_w1_s1',
                'playerSessionId': 'p9',
                'completedAt': t2.toIso8601String(),
              },
              {
                // duplicate player session
                'plannedSessionId': 'balanced_foundations_w1_s2',
                'playerSessionId': 'p1',
                'completedAt': t2.toIso8601String(),
              },
              {
                'plannedSessionId': 'balanced_foundations_w1_s3',
                'playerSessionId': 'p3',
                'completedAt': t2.toIso8601String(),
              },
            ],
          },
        ],
      });
      SharedPreferences.setMockInitialValues({AdaptiveProgramsStorage.key: raw});
      final state = await const AdaptiveProgramsStorage().load();
      final p = state.progressFor('balanced_foundations')!;
      expect(p.completions.map((c) => c.plannedSessionId).toList(),
          ['balanced_foundations_w1_s1', 'balanced_foundations_w1_s3']);
      expect(p.completions.first.playerSessionId, 'p1');
    });

    test('unknown program IDs are safe', () async {
      final raw = jsonEncode({
        'activeProgramId': 'no_such_program',
        'progress': [
          {
            'programId': 'no_such_program',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t0.toIso8601String(),
            'completions': [],
          },
          {
            'programId': 'endurance_builder',
            'startedAt': t0.toIso8601String(),
            'updatedAt': t0.toIso8601String(),
            'completions': [],
          },
        ],
      });
      SharedPreferences.setMockInitialValues({AdaptiveProgramsStorage.key: raw});
      final state = await const AdaptiveProgramsStorage().load();
      expect(state.activeProgramId, isNull);
      expect(state.progressByProgram.keys.toList(), ['endurance_builder']);
    });

    test('setString returning false → save fails, previous data preserved',
        () async {
      final existing = AdaptiveProgramsState(
        activeProgramId: 'balanced_foundations',
        progressByProgram: {
          'balanced_foundations': AdaptiveProgramProgress.fresh(
              programId: 'balanced_foundations', startedAt: t0),
        },
      );
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(existing)});
      final failing = AdaptiveProgramsStorage(
        writeString: (prefs, key, value) async => false,
      );
      final ok = await failing.save(AdaptiveProgramsState(
        activeProgramId: 'mobility_movement',
      ));
      expect(ok, isFalse);
      final reloaded = await failing.load();
      expect(reloaded, existing);
    });

    test('exception during write → save fails, previous data preserved',
        () async {
      final existing = AdaptiveProgramsState(activeProgramId: null);
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(existing)});
      final throwing = AdaptiveProgramsStorage(
        writeString: (prefs, key, value) async => throw StateError('disk'),
      );
      final ok = await throwing.save(
          AdaptiveProgramsState(activeProgramId: 'balanced_foundations'));
      expect(ok, isFalse);
      final reloaded = await throwing.load();
      expect(reloaded, existing);
    });

    test('exception during prefs access → load returns empty, save false',
        () async {
      final broken = AdaptiveProgramsStorage(
        getPrefs: () async => throw StateError('no prefs'),
      );
      expect(await broken.load(), AdaptiveProgramsState.empty);
      expect(await broken.save(AdaptiveProgramsState.empty), isFalse);
    });

    test('loaded state is immutable', () async {
      final existing = AdaptiveProgramsState(
        activeProgramId: 'balanced_foundations',
        progressByProgram: {
          'balanced_foundations': AdaptiveProgramProgress(
            programId: 'balanced_foundations',
            startedAt: t0,
            updatedAt: t1,
            completions: [
              completion('balanced_foundations_w1_s1', 'p1', t1),
            ],
          ),
        },
      );
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(existing)});
      final state = await const AdaptiveProgramsStorage().load();
      expect(() => state.progressByProgram.clear(), throwsUnsupportedError);
      expect(
          () => state.progressFor('balanced_foundations')!.completions.clear(),
          throwsUnsupportedError);
      expect(
          () => state
              .progressFor('balanced_foundations')!
              .completedSessionIds
              .add('x'),
          throwsUnsupportedError);
      expect(() => state.startedProgramIds.add('x'), throwsUnsupportedError);
    });

    test('does not touch history storage key', () async {
      SharedPreferences.setMockInitialValues(
          {WorkoutHistoryStorage.key: '[{"id":"h1"}]'});
      const storage = AdaptiveProgramsStorage();
      await storage.save(AdaptiveProgramsState(activeProgramId: 'balanced_foundations'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WorkoutHistoryStorage.key), '[{"id":"h1"}]');
    });
  });
}
