import 'dart:ui' as ui;

import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_animation_pilot_test.dart' as fixtures;

const ids = ['pushup_pike', 'squat_goblet_dumbbell'];

Finder animation(String id) =>
    find.byKey(ValueKey(ExerciseAnimationRegistry.assetFor(id)!));

Future<void> decodeFrames(WidgetTester tester) async {
  // Let the engine decode actual WebP frames, then drive Flutter's frame clock.
  // Do not pumpAndSettle an intentionally looping animation.
  for (var i = 0; i < 16; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

ui.Image currentFrame(WidgetTester tester, String id) => tester
    .widget<RawImage>(
        find.descendant(of: animation(id), matching: find.byType(RawImage)))
    .image!;

void main() {
  for (final id in ids) {
    testWidgets('$id bundled loop preserves full frame and source duration',
        (tester) async {
      await tester.runAsync(() async {
        final bytes =
            await rootBundle.load(ExerciseAnimationRegistry.assetFor(id)!);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        try {
          expect(codec.frameCount, greaterThan(1));
          expect(codec.frameCount,
              lessThanOrEqualTo(id == 'pushup_pike' ? 96 : 152));
          expect(codec.repetitionCount, -1);
          var milliseconds = 0;
          for (var i = 0; i < codec.frameCount; i++) {
            final frame = await codec.getNextFrame();
            expect(frame.image.width, 480);
            expect(frame.image.height, 480);
            milliseconds += frame.duration.inMilliseconds;
            frame.image.dispose();
          }
          expect(milliseconds, id == 'pushup_pike' ? 3200 : 5067);
        } finally {
          codec.dispose();
        }
      });
    });

    testWidgets(
        '$id shared hero/thumb retain layout, semantics and reduced motion',
        (tester) async {
      final semantics = tester.ensureSemantics();
      for (final dark in [false, true]) {
        await tester.pumpWidget(fixtures.host(
            Column(children: [
              FitFlowExerciseImage.hero(
                exerciseId: id,
                width: 240,
                height: 180,
                decorative: false,
                semanticLabel: '$id demonstration',
              ),
              FitFlowExerciseImage.thumbnail(
                  exerciseId: id, width: 56, height: 56),
            ]),
            dark: dark));
        await decodeFrames(tester);
        expect(animation(id), findsNWidgets(2));
        expect(find.bySemanticsLabel('$id demonstration'), findsOneWidget);
        expect(tester.getSize(animation(id).first), const Size(240, 180));
        expect(tester.getSize(animation(id).last), const Size(56, 56));
        for (final image in tester.widgetList<Image>(animation(id))) {
          expect(image.fit, BoxFit.contain);
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(fixtures
          .host(FitFlowExerciseImage.hero(exerciseId: id), reduced: true));
      await tester.pump();
      expect(animation(id), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    });

    testWidgets(
        '$id Player freezes frames on pause/rest/background without changing session',
        (tester) async {
      final controller = WorkoutPlayerController(
          plan: fixtures.plan(id), autoStartTimer: false);
      addTearDown(controller.dispose);
      Future<void> show() async {
        await tester.pumpWidget(fixtures
            .host(WorkoutPlayerExerciseCenter(state: controller.state)));
        await decodeFrames(tester);
      }

      Future<void> assertFrozen() async {
        final frame = currentFrame(tester, id).clone();
        final state = controller.state;
        await decodeFrames(tester);
        expect(currentFrame(tester, id).isCloneOf(frame), isTrue);
        expect(controller.state, same(state));
        frame.dispose();
      }

      await show();
      final ready = controller.state;
      final first = currentFrame(tester, id).clone();
      await decodeFrames(tester);
      expect(currentFrame(tester, id).isCloneOf(first), isFalse);
      first.dispose();
      expect(controller.state, same(ready));
      controller.beginWorkout();
      controller.pause();
      await show();
      await assertFrozen();
      controller.resume();
      await show();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await assertFrozen();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await show();
      final resumed = currentFrame(tester, id).clone();
      await decodeFrames(tester);
      expect(currentFrame(tester, id).isCloneOf(resumed), isFalse);
      resumed.dispose();
      controller.completeSet();
      await show();
      await assertFrozen();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('raster clips in scrollable sections load only when visible',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      controller: scroll,
      child: const Column(children: [
        FitFlowExerciseImage.thumbnail(exerciseId: 'pushup_pike'),
        SizedBox(height: 1200),
        FitFlowExerciseImage.thumbnail(exerciseId: 'squat_goblet_dumbbell'),
        SizedBox(height: 700),
      ]),
    ))));
    await decodeFrames(tester);
    expect(animation('pushup_pike'), findsOneWidget);
    expect(animation('squat_goblet_dumbbell'), findsNothing);
    scroll.jumpTo(1200);
    await decodeFrames(tester);
    expect(animation('pushup_pike'), findsNothing);
    expect(animation('squat_goblet_dumbbell'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
