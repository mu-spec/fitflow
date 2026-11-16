import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('render selected next pair through complete loops', () async {
    const dir = 'build/next-pair-review';
    Directory('$dir/frames').createSync(recursive: true);
    const selection = String.fromEnvironment('PRESS_PREVIEW', defaultValue: 'all');
    expect(['all', 'lunge_reverse', 'pushup_pike'], contains(selection));
    for (final id in ['lunge_reverse', 'pushup_pike'].where(
        (id) => selection == 'all' || selection == id)) {
      final c = await LottieComposition.fromBytes(File('$dir/$id.json').readAsBytesSync());
      for (final asset in c.images.values) {
        final codec = await ui.instantiateImageCodec(base64Decode(asset.fileName.split(',').last));
        asset.loadedImage = (await codec.getNextFrame()).image;
        codec.dispose();
      }
      final count = 40;
      expect(c.duration.inMilliseconds, closeTo(id == 'lunge_reverse' ? 5360 : 2680, 2));
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
        if (frame == (10)) {
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
