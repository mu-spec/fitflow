import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
void main() {
 test('render character review', () async {
  for (final file in Directory('.dart_tool/orange_character').listSync().whereType<File>().where((f)=>f.path.endsWith('.json'))) {
   final c=await LottieComposition.fromBytes(file.readAsBytesSync());
   final d=LottieDrawable(c);
   for (var i=0;i<4;i++) {
    d.setProgress(i/4);
    final r=ui.PictureRecorder();final canvas=Canvas(r);
    canvas.drawColor(const Color(0xfff5f5f5),BlendMode.src);
    d.draw(canvas,const Rect.fromLTWH(0,0,480,480),fit:BoxFit.contain);
    final p=r.endRecording();final im=p.toImageSync(480,480);
    File('${file.path}.$i.png').writeAsBytesSync((await im.toByteData(format:ui.ImageByteFormat.png))!.buffer.asUint8List());
    im.dispose();p.dispose();
   }
  }
 });
}
