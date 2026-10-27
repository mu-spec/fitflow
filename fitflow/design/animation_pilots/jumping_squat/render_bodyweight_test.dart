import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('grounded squat loop renders and closes', () async {
    final source =
        File('design/animation_pilots/jumping_squat/bodyweight_squat.json');
    expect(source.readAsBytesSync(),
        File('assets/animations/bodyweight_squat.json').readAsBytesSync());
    final document =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    final layers = document['assets'][0]['layers'] as List<dynamic>;
    bool animated(dynamic value) {
      if (value is Map) return value['a'] == 1 || value.values.any(animated);
      if (value is List) return value.any(animated);
      return false;
    }

    for (final footId in [2, 4]) {
      final foot = layers.singleWhere((dynamic l) => l['ind'] == footId);
      expect(foot['parent'], isNull);
      expect(animated(foot['ks']), isFalse,
          reason: 'Both planted feet stay fixed');
      expect(animated(foot['shapes']), isFalse);
    }
    expect(document['layers'][0]['tm'], isNull,
        reason: 'No unsupported looping expression');
    final composition =
        await LottieComposition.fromBytes(source.readAsBytesSync());
    expect(composition.bounds.width, 720);
    expect(composition.bounds.height, 720);
    final drawable = LottieDrawable(composition);
    final out = Directory('.dart_tool/bodyweight_squat_review')
      ..createSync(recursive: true);
    final poses = <int, List<int>>{};
    for (var frame = 0; frame <= 60; frame++) {
      drawable.setProgress(frame / 60);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
      drawable.draw(canvas, const Rect.fromLTWH(0, 0, 360, 360),
          fit: BoxFit.contain);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(360, 360);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      File('${out.path}/frame_$frame.png').writeAsBytesSync(bytes);
      if (frame == 0 || frame == 30 || frame == 60) poses[frame] = bytes;
      image.dispose();
      picture.dispose();
    }
    expect(poses[0], poses[60]);
    expect(poses[0], isNot(poses[30]));
    expect(composition.duration, const Duration(milliseconds: 2500));
  });
}
