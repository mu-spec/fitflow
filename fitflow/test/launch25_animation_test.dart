import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 25 active exercises have valid motion files and matching posters',
      () async {
    final ids =
        ExerciseCatalog.all.where((e) => e.active).map((e) => e.id).toSet();
    expect(ids.length, 25);
    expect(ExerciseAnimationRegistry.assets.keys.toSet(), ids);
    for (final id in ids) {
      final bytes =
          await rootBundle.load(ExerciseAnimationRegistry.assetFor(id)!);
      final composition =
          await LottieComposition.fromBytes(bytes.buffer.asUint8List());
      expect(composition.duration, greaterThan(Duration.zero), reason: id);
      final drawable = LottieDrawable(composition);
      for (final progress in [0.0, .25, .5, .75]) {
        drawable.setProgress(progress);
        final recorder = ui.PictureRecorder();
        drawable.draw(Canvas(recorder), const Rect.fromLTWH(0, 0, 240, 240),
            fit: BoxFit.contain);
        final picture = recorder.endRecording();
        final image = picture.toImageSync(240, 240);
        expect(image.width, 240, reason: id);
        image.dispose();
        picture.dispose();
      }
      expect(
          (await rootBundle.load(ExerciseAnimationRegistry.posterFor(id)!))
              .lengthInBytes,
          greaterThan(1000));
    }
  });
  test('supplied military push-up composition is unchanged', () {
    expect(
        File('assets/animations/launch25/pushup_standard.json')
            .readAsBytesSync(),
        File('assets/animations/pushup.json').readAsBytesSync());
  });
  testWidgets('pause and reduced motion retain the character artwork',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: FitFlowExerciseImage.hero(
                exerciseId: 'pushup_knee', animate: false))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final lottie = find.byType(Lottie);
    if (lottie.evaluate().isNotEmpty) {
      expect(tester.widget<Lottie>(lottie).animate, false);
    }
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
                body: FitFlowExerciseImage.hero(exerciseId: 'pushup_knee')))));
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        contains('launch25/pushup_knee_poster.png'));
    expect(tester.takeException(), isNull);
  });
}
