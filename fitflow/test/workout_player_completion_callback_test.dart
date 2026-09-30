import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/exercise_skill_tree_fixtures.dart';

class _FailingHistoryController extends WorkoutHistoryController {
  int attempts = 0;
  @override
  Future<bool> addWorkout(CompletedWorkout workout) async {
    attempts++;
    return false;
  }
}

/// Shared Player completion callback semantics (M16 Part 2) plus completion
/// copy regressions for every origin.
void main() {
  late WorkoutPlan plan;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
      userProfile: programTestProfile(),
      capabilityProfile: skillTreeCapabilityProfile(),
    ))!;
  });

  Future<ProviderContainer> pumpView(
    WidgetTester tester, {
    required WorkoutSessionOrigin origin,
    WorkoutSessionMode mode = WorkoutSessionMode.standard,
    WorkoutCompletionCallback? onCompleted,
    VoidCallback? onDone,
    List<Override> extra = const [],
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...programOverrides(),
        workoutCoachProvider.overrideWithValue(FakeWorkoutCoach()),
        ...extra,
      ],
      child: MaterialApp(
        home: WorkoutPlayerSessionView(
          plan: plan,
          sessionMode: mode,
          sessionOrigin: origin,
          onWorkoutCompleted: onCompleted,
          onDone: onDone,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
        tester.element(find.byType(WorkoutPlayerSessionView)));
  }

  Future<List<CompletedWorkout>> history() async =>
      WorkoutHistoryStorage(await SharedPreferences.getInstance()).load();

  Future<void> rebuildSeveralTimes(WidgetTester tester, WorkoutPlayerController c) async {
    for (var i = 0; i < 5; i++) {
      c.toggleVoice();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  group('completion callback', () {
    testWidgets('fires exactly once, only when phase becomes completed, with session ID + snapshot',
        (tester) async {
      final calls = <WorkoutPlayerCompletion>[];
      await pumpView(tester, origin: WorkoutSessionOrigin.program, onCompleted: (c) async {
        calls.add(c);
        return true;
      });
      final controller = programPlayerController(tester);
      controller.beginWorkout();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, isEmpty, reason: 'must not fire before completion');

      await driveProgramPlayerToCompletion(tester, controller);
      expect(calls, hasLength(1));
      expect(calls.single.playerSessionId, controller.sessionId);
      expect(calls.single.completedWorkout.id, controller.sessionId);
      expect(calls.single.origin, WorkoutSessionOrigin.program);
      expect(identical(calls.single.plan, plan), isTrue);
      expect(calls.single.completedWorkout.main.length, plan.main.exerciseCount);

      await rebuildSeveralTimes(tester, controller);
      expect(calls, hasLength(1), reason: 'rebuilds must not repeat a successful callback');
      expect(await history(), hasLength(1));
    });

    testWidgets('Done does not fire the callback again', (tester) async {
      var calls = 0;
      var done = 0;
      await pumpView(
        tester,
        origin: WorkoutSessionOrigin.program,
        onCompleted: (_) async {
          calls++;
          return true;
        },
        onDone: () => done++,
      );
      final controller = programPlayerController(tester);
      await driveProgramPlayerToCompletion(tester, controller);
      expect(calls, 1);
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(done, 1);
      expect(calls, 1);
    });

    testWidgets('false result lets a later rebuild retry; success then stops',
        (tester) async {
      var calls = 0;
      var succeed = false;
      await pumpView(tester, origin: WorkoutSessionOrigin.program, onCompleted: (_) async {
        calls++;
        return succeed;
      });
      final controller = programPlayerController(tester);
      await driveProgramPlayerToCompletion(tester, controller);
      expect(calls, greaterThanOrEqualTo(1));
      final afterFirst = calls;
      // Still failing → each rebuild may retry (safe: idempotent consumer).
      controller.toggleVoice();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(calls, greaterThan(afterFirst));
      // Recover.
      succeed = true;
      controller.toggleVoice();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final settled = calls;
      await rebuildSeveralTimes(tester, controller);
      expect(calls, settled, reason: 'no further calls after success');
      // History is unaffected throughout: exactly one entry.
      expect(await history(), hasLength(1));
      expect(controller.state.phase, WorkoutPlayerPhase.completed);
    });

    testWidgets('throwing callback never crashes the Player and can retry',
        (tester) async {
      var calls = 0;
      var shouldThrow = true;
      await pumpView(tester, origin: WorkoutSessionOrigin.program, onCompleted: (_) async {
        calls++;
        if (shouldThrow) throw StateError('boom');
        return true;
      });
      final controller = programPlayerController(tester);
      await driveProgramPlayerToCompletion(tester, controller);
      expect(tester.takeException(), isNull);
      expect(find.text('Workout complete'), findsOneWidget);
      expect(calls, greaterThanOrEqualTo(1));
      shouldThrow = false;
      controller.toggleVoice();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final settled = calls;
      await rebuildSeveralTimes(tester, controller);
      expect(calls, settled);
      expect(await history(), hasLength(1));
    });

    testWidgets('history failure does not block the callback', (tester) async {
      final failing = _FailingHistoryController();
      var calls = 0;
      await pumpView(
        tester,
        origin: WorkoutSessionOrigin.program,
        onCompleted: (_) async {
          calls++;
          return true;
        },
        extra: [workoutHistoryProvider.overrideWith(() => failing)],
      );
      final controller = programPlayerController(tester);
      await driveProgramPlayerToCompletion(tester, controller);
      expect(failing.attempts, greaterThanOrEqualTo(1));
      expect(calls, 1);
      expect(await history(), isEmpty);
      expect(find.text('Workout complete'), findsOneWidget);
    });

    testWidgets('callback failure does not block or duplicate history', (tester) async {
      await pumpView(tester, origin: WorkoutSessionOrigin.program,
          onCompleted: (_) async => false);
      final controller = programPlayerController(tester);
      await driveProgramPlayerToCompletion(tester, controller);
      await rebuildSeveralTimes(tester, controller);
      expect(await history(), hasLength(1));
    });

    testWidgets('adaptive and custom sessions without a callback are unaffected',
        (tester) async {
      for (final origin in [WorkoutSessionOrigin.adaptive, WorkoutSessionOrigin.custom]) {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpView(tester, origin: origin);
        final controller = programPlayerController(tester);
        await driveProgramPlayerToCompletion(tester, controller);
        expect(find.text('Workout complete'), findsOneWidget);
        expect(await history(), hasLength(1));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('completion copy per origin', () {
    const oldCopy = 'Session progress is not saved in this version.';
    const newCopy = WorkoutPlayerCompletedView.historySavedCopy;

    testWidgets('adaptive Standard: Tune visible, new copy, old copy gone', (tester) async {
      await pumpView(tester, origin: WorkoutSessionOrigin.adaptive);
      await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
      expect(find.text(newCopy), findsOneWidget);
      expect(find.text(oldCopy), findsNothing);
      expect(find.text('Tune next workout'), findsOneWidget);
      expect(find.text('Program workout completed.'), findsNothing);
    });

    testWidgets('adaptive Low Energy: no Tune, temporary copy, new copy; Done resets mode',
        (tester) async {
      var done = false;
      final container = await pumpView(
        tester,
        origin: WorkoutSessionOrigin.adaptive,
        mode: WorkoutSessionMode.lowEnergy,
        onDone: () => done = true,
      );
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
      await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
      expect(find.text('Tune next workout'), findsNothing);
      expect(find.textContaining('temporary'), findsOneWidget);
      expect(find.text(newCopy), findsOneWidget);
      expect(find.text(oldCopy), findsNothing);
      // onDone path is consumer-owned; the default adaptive path resets the mode.
      // Verify the default reset via a view without onDone.
      expect(done, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      SharedPreferences.setMockInitialValues({});
      final c2 = await pumpView(tester,
          origin: WorkoutSessionOrigin.adaptive, mode: WorkoutSessionMode.lowEnergy);
      c2.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
      await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(c2.read(workoutSessionModeProvider), WorkoutSessionMode.standard);
    });

    testWidgets('custom: no Tune, protection copy, new copy', (tester) async {
      await pumpView(tester, origin: WorkoutSessionOrigin.custom);
      await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
      expect(find.text('Tune next workout'), findsNothing);
      expect(find.text("Custom workouts don't change your movement levels."), findsOneWidget);
      expect(find.text(newCopy), findsOneWidget);
      expect(find.text(oldCopy), findsNothing);
      expect(find.text('Custom workout'), findsWidgets);
    });

    testWidgets('program: Tune visible, program note, new copy; Home mode untouched',
        (tester) async {
      final container = await pumpView(tester, origin: WorkoutSessionOrigin.program);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
      await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
      expect(find.text('Tune next workout'), findsOneWidget);
      expect(find.text('Program workout completed.'), findsOneWidget);
      expect(find.text(newCopy), findsOneWidget);
      expect(find.text(oldCopy), findsNothing);
      expect(find.textContaining('temporary'), findsNothing);
      expect(find.text('Program workout'), findsWidgets);
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.comeback);
    });
  });
}
