import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 9, 30, 10);
  const balanced = 'balanced_foundations';
  const mobility = 'mobility_movement';

  Future<ProviderContainer> makeContainer({
    Map<String, Object> initial = const {},
    AdaptiveProgramsStorage? storage,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final container = ProviderContainer(overrides: [
      adaptiveProgramsClockProvider.overrideWithValue(() => now),
      if (storage != null)
        adaptiveProgramsStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    container.read(adaptiveProgramsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return container;
  }

  AdaptiveProgramsController notifier(ProviderContainer c) =>
      c.read(adaptiveProgramsControllerProvider.notifier);

  AdaptiveProgramsState stateOf(ProviderContainer c) =>
      c.read(adaptiveProgramsControllerProvider).value!;

  group('AdaptiveProgramsController', () {
    test('loads empty state', () async {
      final c = await makeContainer();
      expect(stateOf(c), AdaptiveProgramsState.empty);
      expect(notifier(c).activeProgramId, isNull);
      expect(notifier(c).activeDefinition, isNull);
    });

    test('fresh start initialises progress, sets startedAt and active', () async {
      final c = await makeContainer();
      final ok = await notifier(c).startOrResumeProgram(balanced);
      expect(ok, isTrue);
      final s = stateOf(c);
      expect(s.activeProgramId, balanced);
      final p = s.progressFor(balanced)!;
      expect(p.startedAt, now);
      expect(p.updatedAt, now);
      expect(p.completions, isEmpty);
      expect(notifier(c).completedCount(balanced), 0);
      expect(notifier(c).firstIncompleteSession(balanced)!.id,
          'balanced_foundations_w1_s1');
      expect(notifier(c).isProgramComplete(balanced), isFalse);

      // Persisted.
      final reloaded = await const AdaptiveProgramsStorage().load();
      expect(reloaded, s);
    });

    test('unknown program cannot be started', () async {
      final c = await makeContainer();
      expect(await notifier(c).startOrResumeProgram('nope'), isFalse);
      expect(stateOf(c), AdaptiveProgramsState.empty);
    });

    test('resume keeps existing progress and does not reset', () async {
      final c = await makeContainer();
      final n = notifier(c);
      await n.startOrResumeProgram(balanced);
      await n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: 'balanced_foundations_w1_s1',
        playerSessionId: 'player_1',
      );
      // Switch away then resume.
      await n.switchActiveProgram(mobility);
      expect(stateOf(c).activeProgramId, mobility);
      final ok = await n.startOrResumeProgram(balanced);
      expect(ok, isTrue);
      expect(stateOf(c).activeProgramId, balanced);
      expect(n.completedCount(balanced), 1);
      expect(stateOf(c).progressFor(balanced)!.startedAt, now);
    });

    test('switching preserves previous program progress', () async {
      final c = await makeContainer();
      final n = notifier(c);
      await n.startOrResumeProgram(balanced);
      await n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: 'balanced_foundations_w1_s2',
        playerSessionId: 'player_2',
      );
      final ok = await n.switchActiveProgram(mobility);
      expect(ok, isTrue);
      final s = stateOf(c);
      expect(s.activeProgramId, mobility);
      expect(s.progressByProgram.keys.toSet(), {balanced, mobility});
      expect(s.progressFor(balanced)!.completions.length, 1);
      expect(s.progressFor(mobility)!.completions, isEmpty);
      expect(s.startedProgramIds, [balanced, mobility]);
    });

    test('startOrResume on already-active program is a no-op success', () async {
      final c = await makeContainer();
      final n = notifier(c);
      await n.startOrResumeProgram(balanced);
      final before = stateOf(c);
      expect(await n.startOrResumeProgram(balanced), isTrue);
      expect(stateOf(c), before);
    });

    group('markSessionCompleted', () {
      test('records completion with player session ID', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        final ok = await n.markSessionCompleted(
          programId: balanced,
          plannedSessionId: 'balanced_foundations_w1_s1',
          playerSessionId: 'player_1',
          completedAt: DateTime.utc(2026, 10, 1),
        );
        expect(ok, isTrue);
        final p = stateOf(c).progressFor(balanced)!;
        expect(p.completions.single,
            const TypeMatcher<AdaptiveProgramSessionCompletion>());
        expect(p.completions.single.playerSessionId, 'player_1');
        expect(p.completions.single.completedAt, DateTime.utc(2026, 10, 1));
        expect(p.updatedAt, DateTime.utc(2026, 10, 1));
        expect(n.completedCount(balanced), 1);
      });

      test('idempotent for duplicate planned session', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'balanced_foundations_w1_s1',
              playerSessionId: 'player_1',
            ),
            isTrue);
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'balanced_foundations_w1_s1',
              playerSessionId: 'player_other',
            ),
            isTrue);
        expect(n.completedCount(balanced), 1);
        expect(stateOf(c).progressFor(balanced)!.completions.length, 1);
      });

      test('idempotent for duplicate Player session callback', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        await n.markSessionCompleted(
          programId: balanced,
          plannedSessionId: 'balanced_foundations_w1_s1',
          playerSessionId: 'player_1',
        );
        // Same Player session reported again (even for another planned id).
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'balanced_foundations_w1_s1',
              playerSessionId: 'player_1',
            ),
            isTrue);
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'balanced_foundations_w1_s2',
              playerSessionId: 'player_1',
            ),
            isTrue);
        expect(n.completedCount(balanced), 1);
      });

      test('out-of-order completion allowed; next is first incomplete', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        await n.markSessionCompleted(
          programId: balanced,
          plannedSessionId: 'balanced_foundations_w2_s1',
          playerSessionId: 'player_a',
        );
        expect(n.completedCount(balanced), 1);
        expect(n.firstIncompleteSession(balanced)!.id,
            'balanced_foundations_w1_s1');
        await n.markSessionCompleted(
          programId: balanced,
          plannedSessionId: 'balanced_foundations_w1_s1',
          playerSessionId: 'player_b',
        );
        expect(n.firstIncompleteSession(balanced)!.id,
            'balanced_foundations_w1_s2');
        final status = n.statusFor(balanced)!;
        expect(status.statusOfId('balanced_foundations_w2_s1'),
            AdaptiveProgramSessionStatus.completed);
        expect(status.statusOfId('balanced_foundations_w1_s2'),
            AdaptiveProgramSessionStatus.next);
        expect(status.statusOfId('balanced_foundations_w1_s3'),
            AdaptiveProgramSessionStatus.planned);
        expect(status.currentWeek, 1);
      });

      test('unknown program or session is rejected', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        expect(
            await n.markSessionCompleted(
              programId: 'nope',
              plannedSessionId: 'nope_w1_s1',
              playerSessionId: 'p',
            ),
            isFalse);
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'strength_foundations_w1_s1',
              playerSessionId: 'p',
            ),
            isFalse);
        expect(
            await n.markSessionCompleted(
              programId: balanced,
              plannedSessionId: 'balanced_foundations_w1_s1',
              playerSessionId: '',
            ),
            isFalse);
        expect(n.completedCount(balanced), 0);
      });

      test('completing without prior start initialises progress', () async {
        final c = await makeContainer();
        final n = notifier(c);
        final ok = await n.markSessionCompleted(
          programId: mobility,
          plannedSessionId: 'mobility_movement_w1_s1',
          playerSessionId: 'p1',
        );
        expect(ok, isTrue);
        expect(stateOf(c).progressFor(mobility)!.startedAt, now);
        expect(n.completedCount(mobility), 1);
        // Does not silently change the active program.
        expect(stateOf(c).activeProgramId, isNull);
      });

      test('fully complete program and count never exceeds total', () async {
        final c = await makeContainer();
        final n = notifier(c);
        await n.startOrResumeProgram(balanced);
        final def = AdaptiveProgramCatalog.byId(balanced)!;
        var i = 0;
        for (final s in def.sessions) {
          await n.markSessionCompleted(
            programId: balanced,
            plannedSessionId: s.id,
            playerSessionId: 'player_${i++}',
          );
        }
        // Extra attempts do nothing.
        await n.markSessionCompleted(
          programId: balanced,
          plannedSessionId: def.sessions.first.id,
          playerSessionId: 'player_extra',
        );
        expect(n.completedCount(balanced), def.totalSessionCount);
        expect(n.isProgramComplete(balanced), isTrue);
        expect(n.firstIncompleteSession(balanced), isNull);
        final status = n.statusFor(balanced)!;
        expect(status.completionLabel, '12 of 12 workouts completed');
        expect(status.completionFraction, 1.0);
        expect(status.currentWeek, def.weekCount);
      });
    });

    test('restart clears only program progress; active and history untouched',
        () async {
      final c = await makeContainer(
        initial: {WorkoutHistoryStorage.key: '[{"id":"h1"}]'},
      );
      final n = notifier(c);
      await n.startOrResumeProgram(balanced);
      await n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: 'balanced_foundations_w1_s1',
        playerSessionId: 'p1',
      );
      await n.startOrResumeProgram(mobility);
      await n.markSessionCompleted(
        programId: mobility,
        plannedSessionId: 'mobility_movement_w1_s1',
        playerSessionId: 'p2',
      );
      expect(n.completedCount(balanced), 1);
      expect(n.completedCount(mobility), 1);

      final later = DateTime.utc(2026, 11, 1);
      final ok = await n.restartProgram(balanced, now: later);
      expect(ok, isTrue);
      expect(n.completedCount(balanced), 0);
      expect(stateOf(c).progressFor(balanced)!.startedAt, later);
      expect(stateOf(c).progressFor(balanced)!.completions, isEmpty);
      // Other program's progress and the active pointer are untouched.
      expect(n.completedCount(mobility), 1);
      expect(stateOf(c).activeProgramId, mobility);
      // M11 history untouched.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WorkoutHistoryStorage.key), '[{"id":"h1"}]');
      expect(await n.restartProgram('nope'), isFalse);
    });

    test('status helpers return null/defaults for unknown program', () async {
      final c = await makeContainer();
      final n = notifier(c);
      expect(n.statusFor('nope'), isNull);
      expect(n.completedCount('nope'), 0);
      expect(n.firstIncompleteSession('nope'), isNull);
      expect(n.isProgramComplete('nope'), isFalse);
      expect(n.progressFor('nope'), isNull);
    });

    test('storage failure preserves previous state and returns false',
        () async {
      final existing = AdaptiveProgramsState(
        activeProgramId: balanced,
        progressByProgram: {
          balanced: AdaptiveProgramProgress.fresh(
              programId: balanced, startedAt: now),
        },
      );
      final failing = AdaptiveProgramsStorage(
        writeString: (prefs, key, value) async => false,
      );
      final c = await makeContainer(
        initial: {
          AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(existing),
        },
        storage: failing,
      );
      final n = notifier(c);
      expect(stateOf(c), existing);

      expect(await n.switchActiveProgram(mobility), isFalse);
      expect(stateOf(c), existing);

      expect(
          await n.markSessionCompleted(
            programId: balanced,
            plannedSessionId: 'balanced_foundations_w1_s1',
            playerSessionId: 'p1',
          ),
          isFalse);
      expect(stateOf(c), existing);

      expect(await n.restartProgram(balanced), isFalse);
      expect(stateOf(c), existing);
    });

    test('storage exception preserves previous state and returns false',
        () async {
      final throwing = AdaptiveProgramsStorage(
        writeString: (prefs, key, value) async => throw StateError('disk'),
      );
      final c = await makeContainer(storage: throwing);
      final n = notifier(c);
      expect(await n.startOrResumeProgram(balanced), isFalse);
      expect(stateOf(c), AdaptiveProgramsState.empty);
    });

    test('loaded state from prefs is picked up', () async {
      final existing = AdaptiveProgramsState(
        activeProgramId: mobility,
        progressByProgram: {
          mobility: AdaptiveProgramProgress(
            programId: mobility,
            startedAt: now,
            updatedAt: now,
            completions: [
              AdaptiveProgramSessionCompletion(
                plannedSessionId: 'mobility_movement_w1_s1',
                playerSessionId: 'p1',
                completedAt: now,
              ),
            ],
          ),
        },
      );
      final c = await makeContainer(initial: {
        AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(existing),
      });
      expect(stateOf(c), existing);
      expect(notifier(c).activeDefinition!.id, mobility);
      expect(notifier(c).completedCount(mobility), 1);
      await notifier(c).refresh();
      expect(stateOf(c), existing);
    });
  });
}
