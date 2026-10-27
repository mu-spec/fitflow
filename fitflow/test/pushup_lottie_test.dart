import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/pushup_lottie_demonstration.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'player_animation_pilot_test.dart' as fixtures;

Future<void> loadPushup(WidgetTester tester) async {
  final provider = AssetLottie('assets/animations/pushup.json');
  final composition = await tester.runAsync(() => provider.load());
  expect(composition!.bounds.width, 720);
  expect(composition.bounds.height, 720);
  expect(composition.duration.inMilliseconds, greaterThan(2000));
}

void main() {
  testWidgets('actual push-up asset loops and respects pause and lifecycle',
      (tester) async {
    await loadPushup(tester);
    final controller = WorkoutPlayerController(
        plan: fixtures.plan('pushup_standard'), autoStartTimer: false);
    addTearDown(controller.dispose);
    Future<void> show() async {
      await tester.pumpWidget(
          fixtures.host(WorkoutPlayerExerciseCenter(state: controller.state)));
      await tester.pump();
    }

    await show();
    expect(find.byType(PushupLottieDemonstration), findsOneWidget);
    final animation = tester.widget<Lottie>(find.byType(Lottie));
    expect(animation.composition, isNotNull);
    expect(animation.repeat, isTrue);
    expect(animation.animate, isTrue);
    expect(animation.fit, BoxFit.contain);
    final size = tester.getSize(find.byType(PushupLottieDemonstration));
    expect(size.width / size.height, closeTo(4 / 3, .001));
    controller.beginWorkout();
    await show();
    final session = controller.state;
    await tester.pump(const Duration(seconds: 3));
    expect(controller.state, session,
        reason: 'Animation never counts reps or advances the session');
    controller.pause();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    controller.resume();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    controller.completeSet();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unmapped variations and reduced motion keep exact photos',
      (tester) async {
    for (final id in [
      'pushup_wall',
      'pushup_knee',
      'pushup_incline',
      'pushup_standard'
    ]) {
      final controller = WorkoutPlayerController(
          plan: fixtures.plan(id), autoStartTimer: false);
      await tester.pumpWidget(fixtures.host(
          WorkoutPlayerExerciseCenter(state: controller.state),
          reduced: id != 'pushup_wall'));
      expect(find.byType(PushupLottieDemonstration), findsNothing);
      expect(
          tester
              .widget<FitFlowExerciseImage>(find.byType(FitFlowExerciseImage))
              .exerciseId,
          id);
      controller.dispose();
    }
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('push-up layout $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await loadPushup(tester);
          final controller = WorkoutPlayerController(
              plan: fixtures.plan('pushup_standard'), autoStartTimer: false);
          addTearDown(controller.dispose);
          await tester.pumpWidget(fixtures.host(
              WorkoutPlayerExerciseCenter(state: controller.state),
              dark: dark,
              scale: scale));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(Lottie), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
