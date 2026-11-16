import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('render both standing variants through complete loops', () async {
    const dir = 'build/standing-pair-review';
    Directory('$dir/frames').createSync(recursive: true);
    for (final id in ['march_in_place', 'calf_raise']) {
      final c = await LottieComposition.fromBytes(File('$dir/$id.json').readAsBytesSync());
      for (final asset in c.images.values) {
        final codec = await ui.instantiateImageCodec(base64Decode(asset.fileName.split(',').last));
        asset.loadedImage = (await codec.getNextFrame()).image;
        codec.dispose();
      }
      final count = id == 'march_in_place' ? 48 : 60;
      expect(c.duration.inSeconds, id == 'march_in_place' ? 4 : 5);
      final d = LottieDrawable(c);
      for (var frame=0; frame<count; frame++) {
        d.setProgress(frame/count);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
        d.draw(canvas, const Rect.fromLTWH(0,0,420,420), fit: BoxFit.contain);
        final picture = recorder.endRecording();
        final image = picture.toImageSync(420,420);
        File('$dir/frames/${id}_$frame.png').writeAsBytesSync(
          (await image.toByteData(format:ui.ImageByteFormat.png))!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
        if (frame == (id == 'march_in_place' ? 12 : 28)) {
          final posterRecorder = ui.PictureRecorder();
          final posterCanvas = Canvas(posterRecorder);
          posterCanvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
          d.draw(posterCanvas, const Rect.fromLTWH(0,0,720,720),
              fit: BoxFit.contain);
          final posterPicture = posterRecorder.endRecording();
          final poster = posterPicture.toImageSync(720,720);
          File('$dir/${id}_poster.png').writeAsBytesSync(
              (await poster.toByteData(format:ui.ImageByteFormat.png))!
                  .buffer.asUint8List());
          poster.dispose();
          posterPicture.dispose();
        }
      }
      for (final asset in c.images.values) { asset.loadedImage?.dispose(); }
    }
  });
}
