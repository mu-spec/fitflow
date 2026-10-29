import 'dart:ui' as ui;

import 'package:fitflow/core/design/media/exercise_animation.dart';
import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'open_exercise_figures_test.dart' as frames;
import 'player_animation_pilot_test.dart' as fixtures;

const lottieIds = ['jumping_jacks', 'pushup_wide'];
const webpDurations = {
  'squat_bodyweight': 2500,
  'squat_partial': 2800,
  'squat_tempo': 5200,
  'squat_pulse': 1440,
};

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('all four squat variants are bundled, animated and timed',
      (tester) async {
    await tester.runAsync(() async {
      for (final entry in webpDurations.entries) {
        final asset = ExerciseAnimationRegistry.assetFor(entry.key)!;
        expect(
            asset, 'assets/animations/illustrated_athletes/${entry.key}.webp');
        final bytes = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        try {
          expect(codec.frameCount, greaterThan(1), reason: entry.key);
          expect(codec.repetitionCount, -1, reason: entry.key);
          final durations = <int>[];
          for (var i = 0; i < codec.frameCount; i++) {
            final frame = await codec.getNextFrame();
            expect(frame.image.width, 480);
            expect(frame.image.height, 480);
            durations.add(frame.duration.inMilliseconds);
            frame.image.dispose();
          }
          expect(durations.reduce((a, b) => a + b), entry.value);
          if (entry.key == 'squat_tempo') {
            final pauseIndex =
                durations.indexWhere((duration) => duration >= 1000);
            expect(pauseIndex, greaterThan(0));
            final descent =
                durations.take(pauseIndex).fold<int>(0, (a, b) => a + b);
            final ascent =
                durations.skip(pauseIndex + 1).fold<int>(0, (a, b) => a + b);
            expect(descent, inInclusiveRange(2900, 3000));
            expect(ascent, inInclusiveRange(1000, 1250));
          }
        } finally {
          codec.dispose();
        }
      }
    });
  });

  for (final id in lottieIds) {
    testWidgets('$id loads its actual offline Lottie in hero and thumbnail',
        (tester) async {
      final asset = ExerciseAnimationRegistry.assetFor(id)!;
      expect(asset, 'assets/animations/illustrated_athletes/$id.json');
      final composition =
          await tester.runAsync(() => AssetLottie(asset).load());
      expect(composition, isNotNull);
      expect(composition!.bounds.width, 720);
      expect(composition.bounds.height, 720);
      expect(composition.duration, greaterThan(Duration.zero));
      if (id == 'jumping_jacks') {
        expect(composition.images, isNotEmpty);
        expect(
            composition.images.values
                .every((image) => image.loadedImage != null),
            isTrue,
            reason: 'The embedded shoe image must load without the network');
      }
      await tester.pumpWidget(fixtures.host(Column(children: [
        FitFlowExerciseImage.hero(exerciseId: id, width: 240, height: 180),
        FitFlowExerciseImage.thumbnail(exerciseId: id, width: 56, height: 56),
      ])));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ExerciseAnimation), findsNWidgets(2));
      expect(find.byType(Lottie), findsNWidgets(2));
      for (final lottie in tester.widgetList<Lottie>(find.byType(Lottie))) {
        expect(lottie.composition, same(composition));
        expect(lottie.animate, isTrue);
        expect(lottie.repeat, isTrue);
      }
      await tester.pumpWidget(fixtures
          .host(FitFlowExerciseImage.hero(exerciseId: id), reduced: true));
      await tester.pump();
      expect(find.byType(Lottie), findsNothing);
      expect(find.byType(FitFlowMediaImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'slim bodyweight squat renders in both sizes and honors reduced motion',
      (tester) async {
    const id = 'squat_bodyweight';
    await tester.pumpWidget(fixtures.host(const Column(children: [
      FitFlowExerciseImage.hero(exerciseId: id, width: 240, height: 180),
      FitFlowExerciseImage.thumbnail(exerciseId: id, width: 56, height: 56),
    ])));
    await frames.pumpFrames(tester);
    expect(find.byType(ExerciseAnimation), findsNWidgets(2));
    expect(find.byKey(ValueKey(ExerciseAnimationRegistry.assetFor(id)!)),
        findsNWidgets(2));
    expect(find.byType(Lottie), findsNothing);
    await tester.pumpWidget(fixtures
        .host(const FitFlowExerciseImage.hero(exerciseId: id), reduced: true));
    await tester.pump();
    expect(find.byType(FitFlowMediaImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final id in ['squat_partial', 'squat_bodyweight']) {
    testWidgets('$id follows player pause without controlling workout',
        (tester) async {
      final controller = WorkoutPlayerController(
          plan: fixtures.plan(id), autoStartTimer: false);
      addTearDown(controller.dispose);
      Future<void> show() async {
        await tester.pumpWidget(fixtures
            .host(WorkoutPlayerExerciseCenter(state: controller.state)));
        await frames.pumpFrames(tester);
      }

      await show();
      final ready = controller.state;
      await frames.expectFrameToAdvance(tester, id);
      expect(controller.state, same(ready));
      controller.beginWorkout();
      await show();
      final state = controller.state;
      await frames.expectFrameToAdvance(tester, id);
      expect(controller.state, same(state));
      controller.pause();
      await show();
      final frozen = frames.currentFrame(tester, id).clone();
      await frames.pumpFrames(tester);
      expect(frames.currentFrame(tester, id).isCloneOf(frozen), isTrue);
      frozen.dispose();
      expect(controller.state.isPaused, isTrue);
      controller.resume();
      await show();
      await frames.expectFrameToAdvance(tester, id);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final inactive = frames.currentFrame(tester, id).clone();
      await frames.pumpFrames(tester);
      expect(frames.currentFrame(tester, id).isCloneOf(inactive), isTrue);
      inactive.dispose();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('isometric exercises use bundled single-frame athlete poses',
      (tester) async {
    const ids = [
      'plank_forearm',
      'plank_knee',
      'wall_sit',
      'hollow_hold',
      'single_leg_stand',
      'hip_flexor_stretch',
      'childs_pose',
      'hamstring_stretch_standing',
      'dead_hang_pullup_bar',
    ];
    await tester.runAsync(() async {
      for (final id in ids) {
        final asset = ExerciseAnimationRegistry.assetFor(id)!;
        expect(asset, 'assets/animations/illustrated_athletes/$id.webp');
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        try {
          expect(codec.frameCount, 1, reason: id);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 480, reason: id);
          expect(frame.image.height, 480, reason: id);
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      }
    });
    await tester.pumpWidget(fixtures.host(const FitFlowExerciseImage.hero(
        exerciseId: 'plank_forearm', width: 240, height: 180)));
    await frames.pumpFrames(tester);
    expect(
        find.byKey(
            ValueKey(ExerciseAnimationRegistry.assetFor('plank_forearm')!)),
        findsOneWidget);
    await tester.pumpWidget(fixtures.host(
        const FitFlowExerciseImage.hero(exerciseId: 'plank_forearm'),
        reduced: true));
    await tester.pump();
    expect(find.byType(FitFlowMediaImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('superman includes the written one-second pause', (tester) async {
    await tester.runAsync(() async {
      final data = await rootBundle
          .load(ExerciseAnimationRegistry.assetFor('superman')!);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      try {
        final durations = <int>[];
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          durations.add(frame.duration.inMilliseconds);
          frame.image.dispose();
        }
        expect(durations.any((ms) => ms >= 1000), isTrue);
      } finally {
        codec.dispose();
      }
    });
  });
}
