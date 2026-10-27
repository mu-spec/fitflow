import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

// Review rendering only. Not part of the app bundle or its normal test suite.
void main() {
  for (final variant in ['incline', 'decline']) {
  test('$variant renders its complete loop', () async {
    const dir = 'design/animation_pilots/pushup_variants';
    final bytes = File('$dir/pushup_$variant.json').readAsBytesSync();
    final composition = await LottieComposition.fromBytes(bytes);
    expect(composition.bounds.width, 720);
    expect(composition.bounds.height, 720);
    expect(composition.duration, const Duration(milliseconds: 2500));
    final drawable = LottieDrawable(composition);
    final out = Directory('.dart_tool/pushup_${variant}_frames')..createSync(recursive: true);
    final rendered = <int, List<int>>{};
    for (var frame = 0; frame <= 100; frame++) {
      drawable.setProgress(frame / 100);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
      drawable.draw(canvas, const Rect.fromLTWH(0, 0, 480, 480), fit: BoxFit.contain);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(480, 480);
      final encoded = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      File('${out.path}/frame_${frame.toString().padLeft(3, '0')}.png').writeAsBytesSync(encoded);
      if (frame == 0 || frame == 50 || frame == 100) rendered[frame] = encoded;
      image.dispose();
      picture.dispose();
    }
    expect(rendered[0], rendered[100], reason: 'The loop closes on the identical pose');
    expect(rendered[0], isNot(rendered[50]), reason: 'Midpoint is a distinct lowered pose');
  });
  }
}
