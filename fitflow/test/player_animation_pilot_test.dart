import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/pilot_exercise_demonstration.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutPlan plan(String id) {
  final prescription = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!)!;
  return WorkoutPlan(
      warmup: WorkoutSection(
          type: WorkoutSectionType.warmup, exercises: [prescription]),
      main: WorkoutSection(
          type: WorkoutSectionType.main, exercises: [prescription]),
      cooldown: WorkoutSection(
          type: WorkoutSectionType.cooldown, exercises: [prescription]),
      timeBudget:
          WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes));
}

Widget host(Widget child,
        {bool dark = false, double scale = 1, bool reduced = false}) =>
    MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale)),
            child: child!),
        home: WorkoutsTheme(
            child: Scaffold(
                body: SafeArea(
                    child: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: child))))));

PilotCharacterPainter painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const ValueKey('pilot_character_canvas')))
    .painter! as PilotCharacterPainter;

void main() {
  for (final id in ['march_in_place', 'squat_bodyweight']) {
    testWidgets('$id artwork follows work/pause without driving the session',
        (tester) async {
      final controller =
          WorkoutPlayerController(plan: plan(id), autoStartTimer: false);
      addTearDown(controller.dispose);
      Future<void> show() => tester.pumpWidget(
          host(WorkoutPlayerExerciseCenter(state: controller.state)));
      await show();
      expect(painter(tester).motion.value, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(painter(tester).motion.value, 0);
      expect(controller.state.phase, WorkoutPlayerPhase.ready);
      controller.beginWorkout();
      await show();
      await tester.pump();
      final session = controller.state;
      await tester.pump(const Duration(milliseconds: 600));
      expect(painter(tester).motion.value, greaterThan(0));
      expect(controller.state, session,
          reason: 'Artwork must not advance time, reps or sets');
      controller.pause();
      await show();
      final frozen = painter(tester).motion.value;
      await tester.pump(const Duration(seconds: 1));
      expect(painter(tester).motion.value, frozen);
      controller.resume();
      await show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(painter(tester).motion.value, greaterThan(frozen));
      if (controller.state.isTimedExercise) {
        final seconds = controller.state.remaining.inSeconds;
        for (var i = 0; i < seconds; i++) {
          controller.tick();
        }
      } else {
        controller.completeSet();
      }
      await show();
      expect(
          tester
              .widget<PilotExerciseDemonstration>(
                  find.byType(PilotExerciseDemonstration))
              .running,
          isFalse);
      final resting = painter(tester).motion.value;
      await tester.pump(const Duration(seconds: 1));
      expect(painter(tester).motion.value, resting);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'only exact pilot IDs animate; reduced motion keeps registered photos',
      (tester) async {
    for (final id in [
      'march_in_place',
      'squat_bodyweight',
      'arm_circles',
      'squat_partial'
    ]) {
      final controller =
          WorkoutPlayerController(plan: plan(id), autoStartTimer: false);
      for (final reduced in [false, true]) {
        await tester.pumpWidget(host(
            WorkoutPlayerExerciseCenter(state: controller.state),
            reduced: reduced));
        final animated = !reduced && PilotExerciseDemonstration.supports(id);
        expect(find.byType(PilotExerciseDemonstration),
            animated ? findsOneWidget : findsNothing);
        if (!animated) {
          expect(
              tester
                  .widget<FitFlowExerciseImage>(
                      find.byType(FitFlowExerciseImage))
                  .exerciseId,
              id);
        }
      }
      controller.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('visual loop freezes while backgrounded and under TickerMode',
      (tester) async {
    Widget scene(bool enabled) => host(TickerMode(
        enabled: enabled,
        child: const PilotExerciseDemonstration(
            exerciseId: 'march_in_place',
            running: true,
            width: 320,
            height: 240)));
    await tester.pumpWidget(scene(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final frozen = painter(tester).motion.value;
    await tester.pump(const Duration(seconds: 2));
    expect(painter(tester).motion.value, frozen);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(scene(false));
    final hidden = painter(tester).motion.value;
    await tester.pump(const Duration(seconds: 2));
    expect(painter(tester).motion.value, hidden);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('pilot layout $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          final controller = WorkoutPlayerController(
              plan: plan('march_in_place'), autoStartTimer: false);
          addTearDown(controller.dispose);
          await tester.pumpWidget(host(
              WorkoutPlayerExerciseCenter(state: controller.state),
              dark: dark,
              scale: scale));
          final bounds =
              tester.getRect(find.byType(PilotExerciseDemonstration));
          expect(bounds.width / bounds.height, closeTo(4 / 3, .001));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
