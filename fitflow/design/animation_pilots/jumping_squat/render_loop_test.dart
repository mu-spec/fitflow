import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('repaired jump loop renders and closes without expressions', () async {
    final source = File('design/animation_pilots/jumping_squat/jump_squat_loop.json');
    final composition = await LottieComposition.fromBytes(source.readAsBytesSync());
    expect(composition.bounds.width, 720);
    expect(composition.bounds.height, 720);
    final drawable = LottieDrawable(composition);
    final out = Directory('.dart_tool/jumping_squat_loop')..createSync(recursive: true);
    final poses = <int, List<int>>{};
    for (var frame = 0; frame <= 50; frame++) {
      drawable.setProgress(frame / 50);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
      drawable.draw(canvas, const Rect.fromLTWH(0, 0, 360, 360), fit: BoxFit.contain);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(360, 360);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      File('${out.path}/frame_$frame.png').writeAsBytesSync(bytes);
      if (frame == 0 || frame == 25 || frame == 50) poses[frame] = bytes;
      image.dispose();
      picture.dispose();
    }
    expect(poses[0], poses[50]);
    expect(poses[0], isNot(poses[25]));
    expect(composition.duration, const Duration(seconds: 2));
  });
}
