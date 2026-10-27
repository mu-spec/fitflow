import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('inspect supplied jumping squat without enabling it in the app', () async {
    final source = File('design/animation_pilots/jumping_squat/source.json');
    final composition = await LottieComposition.fromBytes(source.readAsBytesSync());
    expect(composition.bounds.width, 720);
    expect(composition.bounds.height, 720);
    final drawable = LottieDrawable(composition);
    final out = Directory('.dart_tool/jumping_squat_review')..createSync(recursive: true);
    for (var frame = 0; frame < 33; frame++) {
      drawable.setProgress(frame / 33);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
      drawable.draw(canvas, const Rect.fromLTWH(0, 0, 360, 360), fit: BoxFit.contain);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(360, 360);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      File('${out.path}/frame_$frame.png').writeAsBytesSync(bytes);
      image.dispose();
      picture.dispose();
    }
  });
}
