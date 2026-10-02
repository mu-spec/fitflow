import 'dart:async';

import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const balanced = 'balanced_foundations';
  const mobility = 'mobility_movement';
  const s1 = 'balanced_foundations_w1_s1';
  const s2 = 'balanced_foundations_w1_s2';
  const s3 = 'balanced_foundations_w1_s3';
  final now = DateTime.utc(2026, 10, 2, 8);

  Future<ProviderContainer> containerFor(AdaptiveProgramsStorage storage) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        adaptiveProgramsStorageProvider.overrideWithValue(storage),
        adaptiveProgramsClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.read(adaptiveProgramsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return container;
  }

  AdaptiveProgramsController notifier(ProviderContainer container) =>
      container.read(adaptiveProgramsControllerProvider.notifier);

  test('concurrent different completions both survive', () async {
    final writes = <String>[];
    final storage = AdaptiveProgramsStorage(
      writeString: (prefs, key, value) async {
        writes.add(value);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return prefs.setString(key, value);
      },
    );
    final container = await containerFor(storage);
    final n = notifier(container);

    final first = n.markSessionCompleted(
      programId: balanced,
      plannedSessionId: s1,
      playerSessionId: 'player-a',
      completedAt: now,
    );
    final second = n.markSessionCompleted(
      programId: balanced,
      plannedSessionId: s2,
      playerSessionId: 'player-b',
      completedAt: now.add(const Duration(minutes: 1)),
    );
    expect(await Future.wait([first, second]), [true, true]);

    final progress = container
        .read(adaptiveProgramsControllerProvider)
        .value!
        .progressFor(balanced)!;
    expect(progress.completedSessionIds, {s1, s2});
    expect(writes, hasLength(2));
    expect(writes.last, contains(s1));
    expect(writes.last, contains(s2));
    expect(
      (await storage.load()).progressFor(balanced)!.completedSessionIds,
      {s1, s2},
    );
  });

  test('duplicate concurrent completion is counted once', () async {
    final storage = AdaptiveProgramsStorage(
      writeString: (prefs, key, value) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return prefs.setString(key, value);
      },
    );
    final container = await containerFor(storage);
    final n = notifier(container);

    final samePlanned = await Future.wait([
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s1,
        playerSessionId: 'player-a',
      ),
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s1,
        playerSessionId: 'player-b',
      ),
    ]);
    expect(samePlanned, [true, true]);
    expect(
      container
          .read(adaptiveProgramsControllerProvider)
          .value!
          .progressFor(balanced)!
          .completions,
      hasLength(1),
    );

    final samePlayer = await Future.wait([
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s2,
        playerSessionId: 'player-shared',
      ),
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s3,
        playerSessionId: 'player-shared',
      ),
    ]);
    expect(samePlayer, [true, true]);
    final completions = container
        .read(adaptiveProgramsControllerProvider)
        .value!
        .progressFor(balanced)!
        .completions;
    expect(completions.where((c) => c.playerSessionId == 'player-shared'),
        hasLength(1));
    expect(
      (await storage.load()).progressFor(balanced)!.completions.length,
      completions.length,
    );
  });

  test('restart then completion and switch then completion are deterministic',
      () async {
    final storage = const AdaptiveProgramsStorage();
    final container = await containerFor(storage);
    final n = notifier(container);
    expect(await n.startOrResumeProgram(balanced), isTrue);

    final restartThenComplete = await Future.wait([
      n.restartProgram(balanced, now: now),
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s1,
        playerSessionId: 'after-restart',
        completedAt: now.add(const Duration(minutes: 5)),
      ),
    ]);
    expect(restartThenComplete, [true, true]);
    final afterRestart = container
        .read(adaptiveProgramsControllerProvider)
        .value!
        .progressFor(balanced)!;
    expect(afterRestart.completedSessionIds, {s1});
    expect(afterRestart.startedAt, now);

    final switchThenComplete = await Future.wait([
      n.switchActiveProgram(mobility, now: now),
      n.markSessionCompleted(
        programId: balanced,
        plannedSessionId: s2,
        playerSessionId: 'with-switch',
      ),
    ]);
    expect(switchThenComplete, [true, true]);
    final state = container.read(adaptiveProgramsControllerProvider).value!;
    expect(state.activeProgramId, mobility);
    expect(state.progressFor(balanced)!.completedSessionIds, {s1, s2});
    expect(state.progressFor(mobility), isNotNull);
    expect((await storage.load()), state);
  });

  test('queued operation still runs after a failed write', () async {
    var failNext = true;
    final storage = AdaptiveProgramsStorage(
      writeString: (prefs, key, value) async {
        if (failNext) {
          failNext = false;
          return false;
        }
        return prefs.setString(key, value);
      },
    );
    final container = await containerFor(storage);
    final n = notifier(container);

    final failed = n.markSessionCompleted(
      programId: balanced,
      plannedSessionId: s1,
      playerSessionId: 'lost',
    );
    final queued = n.markSessionCompleted(
      programId: balanced,
      plannedSessionId: s2,
      playerSessionId: 'kept',
    );
    expect(await failed, isFalse);
    expect(await queued, isTrue);

    final state = container.read(adaptiveProgramsControllerProvider).value!;
    expect(state.progressFor(balanced)!.completedSessionIds, {s2});
    expect(state, isNot(AdaptiveProgramsState.empty));
    expect(await storage.load(), state);
  });

  test('mutation finishing after disposal does not throw', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final storage = AdaptiveProgramsStorage(
      writeString: (prefs, key, value) async {
        if (!started.isCompleted) started.complete();
        await gate.future;
        return prefs.setString(key, value);
      },
    );
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        adaptiveProgramsStorageProvider.overrideWithValue(storage),
        adaptiveProgramsClockProvider.overrideWithValue(() => now),
      ],
    );
    container.read(adaptiveProgramsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final pending = container
        .read(adaptiveProgramsControllerProvider.notifier)
        .startOrResumeProgram(balanced);
    await started.future;
    container.dispose();
    gate.complete();
    await expectLater(pending, completion(isTrue));
    expect((await storage.load()).activeProgramId, balanced);
  });
}
