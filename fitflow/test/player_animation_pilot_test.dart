import 'package:lottie/lottie.dart';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
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

// The original painter is no longer selected by the player. March uses the
// same registered athlete as the library, while retaining the old Ready/pause
// behavior and keeping the workout clock independent of the visual loop.
Finder marchImage() =>
    find.byKey(ValueKey(ExerciseAnimationRegistry.assetFor('march_in_place')!));

Future<void> pumpImageFrames(WidgetTester tester, {int count = 16}) async {
  for (var i = 0; i < count; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

double marchFrame(WidgetTester tester) => tester
    .widget<RawLottie>(
        find.descendant(of: marchImage(), matching: find.byType(RawLottie)))
    .progress;

Future<void> expectMarchAdvance(WidgetTester tester) async {
  final frame = marchFrame(tester);
  await pumpImageFrames(tester, count: 4);
  expect(marchFrame(tester), isNot(frame));
}

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('march uses the shared athlete and retains player phase behavior',
      (tester) async {
    final controller = WorkoutPlayerController(
        plan: plan('march_in_place'), autoStartTimer: false);
    addTearDown(controller.dispose);
    Future<void> show() async {
      await tester.pumpWidget(
          host(WorkoutPlayerExerciseCenter(state: controller.state)));
      await pumpImageFrames(tester);
    }

    Future<void> frozen() async {
      final frame = marchFrame(tester);
      final state = controller.state;
      await pumpImageFrames(tester);
      expect(marchFrame(tester), frame);
      expect(controller.state, same(state));
    }

    await show();
    expect(marchImage(), findsOneWidget);
    expect(controller.state.phase, WorkoutPlayerPhase.ready);
    await frozen();
    controller.beginWorkout();
    await show();
    final state = controller.state;
    await expectMarchAdvance(tester);
    expect(controller.state, same(state));
    controller.pause();
    await show();
    await frozen();
    controller.resume();
    await show();
    await expectMarchAdvance(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await frozen();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await show();
    if (controller.state.isTimedExercise) {
      final seconds = controller.state.remaining.inSeconds;
      for (var i = 0; i < seconds; i++) {
        controller.tick();
      }
    } else {
      controller.completeSet();
    }
    await show();
    await frozen();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('march reduced motion keeps the matching character poster',
      (tester) async {
    final controller = WorkoutPlayerController(
        plan: plan('march_in_place'), autoStartTimer: false);
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(
        WorkoutPlayerExerciseCenter(state: controller.state),
        reduced: true));
    await tester.pump();
    expect(find.byType(FitFlowExerciseImage), findsOneWidget);
    expect(marchImage(), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        ExerciseAnimationRegistry.posterFor('march_in_place'));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('march layout $size dark=$dark scale=$scale',
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
              tester.getRect(find.byKey(const ValueKey('v2_player_media')));
          expect(bounds.width / bounds.height, closeTo(4 / 3, .001));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
