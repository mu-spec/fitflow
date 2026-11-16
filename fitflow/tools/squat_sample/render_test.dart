import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('render complete comparison loops', () async {
    for (final entry in {
      'squat': 'build/squat-sample/squat_sample.json',
      'reference': 'assets/animations/pushup.json',
    }.entries) {
      final composition = await LottieComposition.fromBytes(File(entry.value).readAsBytesSync());
      final drawable = LottieDrawable(composition);
      for (var i = 0; i < 60; i++) {
        drawable.setProgress(i / 60);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        drawable.draw(canvas, const Rect.fromLTWH(0, 0, 600, 600), fit: BoxFit.contain);
        final picture = recorder.endRecording();
        final image = picture.toImageSync(600, 600);
        File('build/squat-sample/${entry.key}_$i.png').writeAsBytesSync(
            (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    }
  });
}
