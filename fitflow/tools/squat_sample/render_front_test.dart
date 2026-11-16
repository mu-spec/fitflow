import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('render corrected candidates throughout their motion', () async {
    final output = Directory('build/front-squat-review/frames');
    output.createSync(recursive: true);
    final files = Directory('build/front-squat-review').listSync()
        .whereType<File>().where((f) => (f.path.endsWith('squat.json') || f.path.endsWith('reference.json'))).toList();
    expect(files, hasLength(2), reason: 'Both the source and candidate must render');
    for (final file in files) {
      final id = file.uri.pathSegments.last.replaceAll('.json', '');
      final composition = await LottieComposition.fromBytes(file.readAsBytesSync());
      // Direct composition parsing does not decode embedded raster shoe assets.
      // Load them here so review images represent the actual in-app character.
      for (final asset in composition.images.values) {
        if (asset.fileName.startsWith('data:image/')) {
          final codec = await ui.instantiateImageCodec(
              base64Decode(asset.fileName.split(',').last));
          asset.loadedImage = (await codec.getNextFrame()).image;
          codec.dispose();
        }
      }
      final drawable = LottieDrawable(composition);
      for (var frame = 0; frame < 24; frame++) {
        drawable.setProgress(frame / 24);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
        drawable.draw(canvas, const Rect.fromLTWH(0, 0, 360, 360), fit: BoxFit.contain);
        final picture = recorder.endRecording();
        final image = picture.toImageSync(360, 360);
        File('${output.path}/${id}_$frame.png').writeAsBytesSync(
            (await image.toByteData(format: ui.ImageByteFormat.png))!
                .buffer.asUint8List());
        image.dispose();
        picture.dispose();
        if (id == 'squat' && frame == 12) {
          final posterRecorder = ui.PictureRecorder();
          final posterCanvas = Canvas(posterRecorder);
          posterCanvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
          drawable.draw(posterCanvas, const Rect.fromLTWH(0, 0, 720, 720),
              fit: BoxFit.contain);
          final posterPicture = posterRecorder.endRecording();
          final poster = posterPicture.toImageSync(720, 720);
          File('build/front-squat-review/squat_poster.png').writeAsBytesSync(
              (await poster.toByteData(format: ui.ImageByteFormat.png))!
                  .buffer.asUint8List());
          poster.dispose();
          posterPicture.dispose();
        }
      }
      for (final asset in composition.images.values) {
        asset.loadedImage?.dispose();
      }
    }
  });
}
