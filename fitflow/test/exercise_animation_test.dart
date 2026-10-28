import 'package:fitflow/core/design/media/exercise_animation.dart';
import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'player_animation_pilot_test.dart' as fixtures;

void main() {
  test('only exact catalog movements receive animations', () {
    expect(
        ExerciseAnimationRegistry.assets.keys,
        unorderedEquals([
          'pushup_standard',
          'pushup_knee',
          'pushup_incline',
          'pushup_decline',
          'cobra_stretch',
          'lunge_forward',
          'squat_bodyweight',
          'pushup_pike',
          'squat_goblet_dumbbell',
          'pushup_wall',
          'squat_tempo',
          'squat_pulse',
          'bird_dog',
          'donkey_kick',
          'lunge_reverse',
          'good_morning',
          'hip_hinge',
          'hip_hinge_single_leg',
          'high_knees',
          'standing_knee_raise',
          'plank_reach',
          'march_in_place',
          'mountain_climber_standing',
          'squat_partial',
          'dead_bug',
          'bridge_glute',
          'bridge_single_leg',
          'jumping_jacks',
          'squat_split_static',
          'calf_raise',
          'reverse_crunch',
          'mountain_climbers',
          'bridge_march',
          'flutter_kicks',
          'leg_raise',
          'fast_feet',
          'row_bent_over_dumbbell',
          'squat_goblet_kettlebell',
        ]));
    for (final id in ExerciseAnimationRegistry.assets.keys) {
      expect(ExerciseCatalog.byId(id), isNotNull);
    }
    for (final id in [
      'lunge_curtsy',
      'lunge_lateral',
      'squat_sumo',
      'pushup_close_grip',
      'row_doorway',
      'burpee_low_impact',
      'deadlift_kettlebell',
      'unknown'
    ]) {
      expect(ExerciseAnimationRegistry.assetFor(id), isNull);
    }
  });

  for (final id in [
    'cobra_stretch',
    'lunge_forward',
    'pushup_knee',
    'pushup_incline',
    'pushup_decline',
    'squat_bodyweight'
  ]) {
    Future<LottieComposition> load(WidgetTester tester) async {
      final composition = await tester.runAsync(
          () => AssetLottie(ExerciseAnimationRegistry.assetFor(id)!).load());
      expect(composition!.bounds.width, 720);
      expect(composition.bounds.height, 720);
      expect(composition.duration, greaterThan(Duration.zero));
      if ([
        'pushup_knee',
        'pushup_incline',
        'pushup_decline',
        'squat_bodyweight'
      ].contains(id)) {
        expect(composition.duration, const Duration(milliseconds: 2500));
      }
      return composition;
    }

    testWidgets('$id uses its actual animation in hero and thumbnail',
        (tester) async {
      final composition = await load(tester);
      for (final dark in [false, true]) {
        await tester.pumpWidget(fixtures.host(
            Column(children: [
              FitFlowExerciseImage.hero(
                  exerciseId: id, width: 240, height: 180),
              FitFlowExerciseImage.thumbnail(
                  exerciseId: id, width: 56, height: 56),
            ]),
            dark: dark));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ExerciseAnimation), findsNWidgets(2));
        for (final lottie in tester.widgetList<Lottie>(find.byType(Lottie))) {
          expect(lottie.composition, same(composition));
          expect(lottie.repeat, isTrue);
          expect(lottie.animate, isTrue);
          expect(lottie.fit, BoxFit.contain);
        }
        expect(find.byType(Lottie), findsNWidgets(2));
        expect(tester.getSize(find.byType(ExerciseAnimation).last),
            const Size(56, 56));
      }
      await tester.pumpWidget(fixtures
          .host(FitFlowExerciseImage.hero(exerciseId: id), reduced: true));
      await tester.pump();
      expect(find.byType(Lottie), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$id Player preserves ready, pause, rest and session state',
        (tester) async {
      await load(tester);
      final controller = WorkoutPlayerController(
          plan: fixtures.plan(id), autoStartTimer: false);
      addTearDown(controller.dispose);
      Future<void> show() async {
        await tester.pumpWidget(fixtures
            .host(WorkoutPlayerExerciseCenter(state: controller.state)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await show();
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
      final ready = controller.state;
      await tester.pump(const Duration(seconds: 2));
      expect(controller.state, same(ready));
      controller.beginWorkout();
      await show();
      controller.pause();
      await show();
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
      final paused = controller.state;
      await tester.pump(const Duration(seconds: 2));
      expect(controller.state, same(paused));
      controller.resume();
      await show();
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      final duration = controller.state.currentPrescription.workDuration;
      if (duration != null) {
        for (var i = 0; i < duration.inSeconds; i++) {
          controller.tick();
        }
      } else {
        controller.completeSet();
      }
      await show();
      expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
