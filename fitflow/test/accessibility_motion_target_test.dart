import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/adaptive_program_test_helpers.dart';

WorkoutPlan _plan() {
  WorkoutExercisePrescription timed(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: 1,
      repsPerSet: null,
      workDuration: const Duration(seconds: 12),
      restBetweenSets: Duration.zero,
    );
  }

  return WorkoutPlan(
    warmup: WorkoutSection(
      type: WorkoutSectionType.warmup,
      exercises: [timed('march_in_place')],
    ),
    main: WorkoutSection(
      type: WorkoutSectionType.main,
      exercises: [timed('squat_bodyweight')],
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reduced motion shortens route transitions without removing them for others',
      () {
    expect(
      const FitFlowPageTransitionsBuilder(reducedMotion: true).transitionDuration,
      Duration.zero,
    );
    expect(
      const FitFlowPageTransitionsBuilder().transitionDuration,
      greaterThan(Duration.zero),
    );
  });

  testWidgets('reduced motion reaches the next screen immediately and stays tappable',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => SystemMotionTheme(child: child!),
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: FilledButton(
                        onPressed: () => taps++,
                        child: const Text('Arrived'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Arrived'), findsOneWidget);
    await tester.tap(find.text('Arrived'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player pause and library clear-search targets are at least 48px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plan = _plan();
    await tester.pumpWidget(
      ProviderScope(
        overrides: programOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: WorkoutPlayerSessionView(
            plan: plan,
            sessionMode: WorkoutSessionMode.standard,
            sessionOrigin: WorkoutSessionOrigin.adaptive,
          ),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkoutPlayerSessionView)),
    );
    container.read(workoutPlayerControllerProvider(plan).notifier).beginWorkout();
    await tester.pump();

    final pause = tester.getRect(find.byTooltip('Pause workout'));
    expect(pause.width, greaterThanOrEqualTo(SystemMotion.minTouchTarget));
    expect(pause.height, greaterThanOrEqualTo(SystemMotion.minTouchTarget));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ExerciseLibraryScreen(),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pump();
    final clear = tester.getRect(find.byTooltip('Clear search'));
    expect(clear.width, greaterThanOrEqualTo(SystemMotion.minTouchTarget));
    expect(clear.height, greaterThanOrEqualTo(SystemMotion.minTouchTarget));
    expect(tester.takeException(), isNull);
  });
}
