import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

WorkoutPlan _plan({
  Duration work = const Duration(seconds: 3),
  Duration rest = const Duration(seconds: 2),
  int sets = 1,
}) {
  WorkoutExercisePrescription timed(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: sets,
      repsPerSet: null,
      workDuration: work,
      restBetweenSets: rest,
    );
  }

  WorkoutExercisePrescription reps(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: sets,
      repsPerSet: base.repsPerSet,
      workDuration: null,
      restBetweenSets: rest,
    );
  }

  return WorkoutPlan(
    warmup: WorkoutSection(
      type: WorkoutSectionType.warmup,
      exercises: [timed('march_in_place')],
    ),
    main: WorkoutSection(
      type: WorkoutSectionType.main,
      exercises: [reps('squat_bodyweight')],
    ),
    cooldown: WorkoutSection(
      type: WorkoutSectionType.cooldown,
      exercises: [timed('figure_four_stretch')],
    ),
    timeBudget: const WorkoutTimeBudget(
      target: Duration(minutes: 16),
      warmup: Duration(minutes: 2),
      main: Duration(minutes: 12),
      cooldown: Duration(minutes: 2),
    ),
  );
}

void _finish(WorkoutPlayerController controller) {
  var safety = 0;
  while (controller.state.phase != WorkoutPlayerPhase.completed &&
      safety < 200) {
    final state = controller.state;
    switch (state.phase) {
      case WorkoutPlayerPhase.ready:
        controller.beginWorkout();
        break;
      case WorkoutPlayerPhase.work:
        if (state.isRepsExercise) {
          for (var i = 0; i < 8; i++) {
            controller.completeSet();
          }
        } else {
          while (controller.state.phase == WorkoutPlayerPhase.work &&
              controller.state.remaining > Duration.zero) {
            controller.tick();
          }
          controller.tick();
        }
        break;
      case WorkoutPlayerPhase.rest:
        for (var i = 0; i < 4; i++) {
          controller.skipRest();
        }
        break;
      case WorkoutPlayerPhase.transition:
        for (var i = 0; i < 4; i++) {
          controller.skipTransition();
        }
        break;
      case WorkoutPlayerPhase.sectionBreak:
        controller.continueSection();
        break;
      case WorkoutPlayerPhase.completed:
        break;
    }
    safety++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pause/resume, lifecycle pause, and rapid completion stay single-timer',
      () {
    final coach = FakeWorkoutCoach();
    final controller = WorkoutPlayerController(
      plan: _plan(),
      coach: coach,
      autoStartTimer: true,
    );
    addTearDown(controller.dispose);

    controller.beginWorkout();
    expect(controller.hasActiveTimer, isTrue);
    for (var i = 0; i < 5; i++) {
      controller.pause();
      controller.pauseForLifecycle();
      expect(controller.hasActiveTimer, isFalse);
      controller.resume();
      controller.resume();
      expect(controller.hasActiveTimer, isTrue);
    }

    _finish(controller);
    expect(controller.state.phase, WorkoutPlayerPhase.completed);
    expect(controller.hasActiveTimer, isFalse);
    expect(
      coach.spoken.where((line) => line == 'Workout complete.'),
      hasLength(1),
    );
  });

  test('zero-duration phase completes without a timer or duplicate completion',
      () async {
    final coach = FakeWorkoutCoach();
    final controller = WorkoutPlayerController(
      plan: _plan(work: Duration.zero, rest: Duration.zero),
      coach: coach,
      autoStartTimer: true,
    );
    addTearDown(controller.dispose);

    controller.beginWorkout();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(controller.hasActiveTimer, isFalse);

    _finish(controller);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.phase, WorkoutPlayerPhase.completed);
    expect(controller.hasActiveTimer, isFalse);
    expect(
      coach.spoken.where((line) => line == 'Workout complete.'),
      hasLength(1),
    );
  });

  test('dispose during a timed phase cancels the timer and stops speech', () {
    final coach = FakeWorkoutCoach();
    final controller = WorkoutPlayerController(
      plan: _plan(),
      coach: coach,
    );
    controller.beginWorkout();
    final spoken = coach.spoken.length;
    expect(controller.hasActiveTimer, isTrue);

    controller.dispose();
    expect(controller.hasActiveTimer, isFalse);
    expect(coach.stopCalls, greaterThan(0));
    controller.tick();
    controller.beginWorkout();
    expect(coach.spoken, hasLength(spoken));
    expect(controller.hasActiveTimer, isFalse);
  });

  test('TTS failure does not block progression or completion', () {
    final controller = WorkoutPlayerController(
      plan: _plan(work: const Duration(seconds: 1), rest: Duration.zero),
      coach: ThrowingWorkoutCoach(),
      autoStartTimer: false,
    );
    addTearDown(controller.dispose);

    expect(() => controller.beginWorkout(), returnsNormally);
    _finish(controller);
    expect(controller.state.phase, WorkoutPlayerPhase.completed);
    expect(controller.hasActiveTimer, isFalse);
  });

  testWidgets('rapid completion records history and the callback once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final calls = <WorkoutPlayerCompletion>[];
    var done = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...programOverrides(),
          workoutCoachProvider.overrideWithValue(ThrowingWorkoutCoach()),
        ],
        child: MaterialApp(
          home: WorkoutPlayerSessionView(
            plan: _plan(work: const Duration(seconds: 1), rest: Duration.zero),
            sessionMode: WorkoutSessionMode.standard,
            sessionOrigin: WorkoutSessionOrigin.program,
            onWorkoutCompleted: (completion) async {
              calls.add(completion);
              return true;
            },
            onDone: () => done++,
          ),
        ),
      ),
    );
    await tester.pump();

    final view = tester.widget<WorkoutPlayerSessionView>(
      find.byType(WorkoutPlayerSessionView),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkoutPlayerSessionView)),
    );
    final controller =
        container.read(workoutPlayerControllerProvider(view.plan).notifier);
    _finish(controller);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(calls, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(WorkoutHistoryStorage(prefs).load(), hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.tap(find.text('Done'), warnIfMissed: false);
    await tester.pump();
    expect(done, 1);
    expect(calls, hasLength(1));
  });

  test('history failure does not erase an independent completion callback',
      () async {
    // Controller-level proof that a throwing history add is a false result
    // and does not itself complete a second subsystem. The session view keeps
    // the two hooks independent; this locks the history side of that contract.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        workoutHistoryStorageProvider.overrideWith(
          (ref) async => WorkoutHistoryStorage(
            prefs,
            writeString: (_, __) async => false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(workoutHistoryProvider.notifier);
    await container.read(workoutHistoryProvider.future);
    final saved = await controller.addWorkout(
      CompletedWorkout(
        id: 'h1',
        completedAt: DateTime.utc(2026, 10, 2),
        totalExerciseCount: 0,
        totalSetCount: 0,
        warmup: const [],
        main: const [],
        cooldown: const [],
      ),
    );
    expect(saved, isFalse);
    expect(container.read(workoutHistoryProvider).value, isEmpty);
    expect(WorkoutHistoryStorage(prefs).load(), isEmpty);
  });
}
