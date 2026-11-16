/// Generic Lottie reviewer/poster renderer for the launch25 catalog.
///
/// Unlike the per-batch `tools/squat_sample/render_*_test.dart` scripts, this
/// one takes its inputs from `--dart-define`, so any single candidate can be
/// rendered without editing code:
///
///   flutter test tools/review/render_lottie_test.dart \
///     --dart-define=LOTTIE=build/inbox/dead_bug.json \
///     --dart-define=OUT=build/inbox \
///     --dart-define=POSTER_FRAME=10 \
///     --dart-define=FRAMES=32
///
/// Outputs (inside OUT):
///   frames/<name>_<i>.png   420x420 review frames, #f5f5f5 background
///   <name>_poster.png       720x720 poster, same frame convention the
///                           published launch25 posters use
///
/// Rendering is done with the same `lottie` package the app uses, so masks,
/// precomps and embedded image sequences resolve exactly as they do at
/// runtime. Nothing under assets/ is touched.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _lottiePath = String.fromEnvironment('LOTTIE');
const _outDir = String.fromEnvironment('OUT', defaultValue: 'build/inbox');
const _posterFrame = int.fromEnvironment('POSTER_FRAME', defaultValue: 10);
const _frameCount = int.fromEnvironment('FRAMES', defaultValue: 32);

void main() {
  test('render candidate lottie to review frames and a poster', () async {
    expect(_lottiePath, isNotEmpty,
        reason: 'pass --dart-define=LOTTIE=<path to .json>');
    final file = File(_lottiePath);
    expect(file.existsSync(), isTrue, reason: 'missing $_lottiePath');

    final name = file.uri.pathSegments.last.replaceAll(RegExp(r'\.json$'), '');
    final out = Directory(_outDir);
    Directory('${out.path}/frames').createSync(recursive: true);

    final composition =
        await LottieComposition.fromBytes(file.readAsBytesSync());

    // Resolve embedded base64 image sequences so frames/poster paint fully.
    for (final asset in composition.images.values) {
      final payload = asset.fileName.split(',').last;
      final codec = await ui.instantiateImageCodec(base64Decode(payload));
      asset.loadedImage = (await codec.getNextFrame()).image;
      codec.dispose();
    }

    final drawable = LottieDrawable(composition);
    for (var i = 0; i < _frameCount; i++) {
      drawable.setProgress(i / _frameCount);
      await _write(drawable, 420, 420, '${out.path}/frames/${name}_$i.png');
    }
    await _write(drawable, 720, 720, '${out.path}/${name}_poster.png',
        frame: _posterFrame);

    for (final asset in composition.images.values) {
      asset.loadedImage?.dispose();
    }

    // ignore: avoid_print
    print('LOTTIE_OK $name '
        'duration=${composition.duration.inMilliseconds}ms '
        'size=${composition.bounds.width}x${composition.bounds.height} '
        'poster=${out.path}/${name}_poster.png');
  });
}

Future<void> _write(
    LottieDrawable drawable, int size, int outSize, String path,
    {int? frame}) async {
  if (frame != null) {
    // Poster uses an absolute frame index, matching the publish scripts that
    // always grabbed frame 10 of the loop.
    drawable.setProgress(frame / 80);
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xfff5f5f5), BlendMode.src);
  drawable.draw(canvas, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      fit: BoxFit.contain);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(outSize, outSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}
