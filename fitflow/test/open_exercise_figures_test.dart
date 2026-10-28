import 'dart:ui' as ui;

import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_animation_pilot_test.dart' as fixtures;

const addedIds = [
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
];

Finder animation(String id) =>
    find.byKey(ValueKey(ExerciseAnimationRegistry.assetFor(id)!));

Future<void> pumpFrames(WidgetTester tester, {int count = 16}) async {
  // Real engine decoding needs wall-clock time as well as the test frame clock.
  // Never pumpAndSettle a deliberately looping asset.
  for (var i = 0; i < count; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

ui.Image currentFrame(WidgetTester tester, String id) => tester
    .widget<RawImage>(
        find.descendant(of: animation(id), matching: find.byType(RawImage)))
    .image!;

Future<void> expectFrameToAdvance(WidgetTester tester, String id) async {
  final before = currentFrame(tester, id).clone();
  var advanced = false;
  try {
    // Don't compare after one fixed interval: image decoding is asynchronous
    // and a complete loop can return to the same frame under a loaded runner.
    for (var i = 0; i < 40 && !advanced; i++) {
      await pumpFrames(tester, count: 1);
      advanced = !currentFrame(tester, id).isCloneOf(before);
    }
    expect(advanced, isTrue, reason: '$id should resume on-screen');
  } finally {
    before.dispose();
  }
}

void main() {
  setUp(() {
    // Do not carry an animated image's timestamps across reset test clocks.
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  });

  testWidgets('all selected figures are bundled, looping, decodable WebPs',
      (tester) async {
    await tester.runAsync(() async {
      for (final id in addedIds) {
        expect(ExerciseCatalog.byId(id), isNotNull, reason: id);
        final asset = ExerciseAnimationRegistry.assetFor(id);
        expect(asset, 'assets/animations/open_exercise_figures/$id.webp');
        final bytes = await rootBundle.load(asset!);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        try {
          expect(codec.frameCount, greaterThan(1), reason: id);
          expect(codec.repetitionCount, -1, reason: id);
          final frame = await codec.getNextFrame();
          try {
            expect(frame.image.width, 480, reason: id);
            expect(frame.image.height, 480, reason: id);
            expect(frame.duration, greaterThan(Duration.zero), reason: id);
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
    });
  });

  testWidgets('tempo squat retains its slow descent, pause and faster rise',
      (tester) async {
    await tester.runAsync(() async {
      final path = ExerciseAnimationRegistry.assetFor('squat_tempo')!;
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      try {
        final durations = <int>[];
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          durations.add(frame.duration.inMilliseconds);
          frame.image.dispose();
        }
        expect(durations.length, 30);
        expect(durations.take(15).reduce((a, b) => a + b), 3000);
        expect(durations[15], 1000);
        expect(durations.skip(16).reduce((a, b) => a + b), 994);
      } finally {
        codec.dispose();
      }
    });
  });

  testWidgets('figure uses the shared hero and thumbnail with photo fallback',
      (tester) async {
    const id = 'dead_bug';
    final semantics = tester.ensureSemantics();
    for (final dark in [false, true]) {
      await tester.pumpWidget(fixtures.host(
          const Column(children: [
            FitFlowExerciseImage.hero(
                exerciseId: id,
                width: 240,
                height: 180,
                decorative: false,
                semanticLabel: 'Dead bug demonstration'),
            FitFlowExerciseImage.thumbnail(
                exerciseId: id, width: 56, height: 56),
          ]),
          dark: dark));
      await pumpFrames(tester);
      expect(animation(id), findsNWidgets(2));
      expect(tester.getSize(animation(id).first), const Size(240, 180));
      expect(tester.getSize(animation(id).last), const Size(56, 56));
      expect(find.bySemanticsLabel('Dead bug demonstration'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(fixtures
        .host(const FitFlowExerciseImage.hero(exerciseId: id), reduced: true));
    await tester.pump();
    expect(animation(id), findsNothing);
    expect(find.byType(FitFlowMediaImage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('timed high-knees demonstration does not change session time',
      (tester) async {
    const id = 'high_knees';
    final controller =
        WorkoutPlayerController(plan: fixtures.plan(id), autoStartTimer: false);
    addTearDown(controller.dispose);

    Future<void> show() async {
      await tester.pumpWidget(
          fixtures.host(WorkoutPlayerExerciseCenter(state: controller.state)));
      await pumpFrames(tester);
    }

    controller.beginWorkout();
    expect(controller.state.isTimedExercise, isTrue);
    await show();
    final remaining = controller.state.remaining;
    await expectFrameToAdvance(tester, id);
    expect(controller.state.remaining, remaining,
        reason: 'The demonstration must not tick the workout timer');

    controller.tick();
    expect(controller.state.remaining, remaining - const Duration(seconds: 1));
    controller.pause();
    await show();
    final paused = controller.state;
    await pumpFrames(tester);
    controller.tick();
    expect(controller.state, same(paused));
    controller.resume();
    final secondsLeft = controller.state.remaining.inSeconds;
    for (var i = 0; i < secondsLeft; i++) {
      controller.tick();
    }
    await show();
    expect(controller.state.remaining, Duration.zero);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'figure follows player pause, lifecycle and rest without timing it',
      (tester) async {
    const id = 'bridge_glute';
    final controller =
        WorkoutPlayerController(plan: fixtures.plan(id), autoStartTimer: false);
    addTearDown(controller.dispose);

    Future<void> show() async {
      await tester.pumpWidget(
          fixtures.host(WorkoutPlayerExerciseCenter(state: controller.state)));
      await pumpFrames(tester);
    }

    Future<void> expectFrozen() async {
      final before = currentFrame(tester, id).clone();
      final state = controller.state;
      try {
        await pumpFrames(tester);
        expect(currentFrame(tester, id).isCloneOf(before), isTrue);
        expect(controller.state, same(state));
      } finally {
        before.dispose();
      }
    }

    await show();
    final ready = controller.state;
    await expectFrameToAdvance(tester, id);
    expect(controller.state, same(ready));
    controller.beginWorkout();
    controller.pause();
    await show();
    await expectFrozen();
    controller.resume();
    await show();
    await expectFrameToAdvance(tester, id);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await expectFrozen();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await show();
    await expectFrameToAdvance(tester, id);
    controller.completeSet();
    await show();
    await expectFrozen();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
