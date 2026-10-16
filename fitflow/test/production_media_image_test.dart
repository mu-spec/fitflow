import 'dart:ui' as ui;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MissingBundle extends CachingAssetBundle {
  _MissingBundle({this.bytes});
  final ByteData? bytes;
  final requests = <String>[];
  @override
  Future<ByteData> load(String key) async {
    requests.add(key);
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    }
    if (bytes != null) return bytes!;
    throw FlutterError('Test missing asset: $key');
  }
}

Widget _host(Widget child, _MissingBundle bundle, {bool dark = true}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        body: DefaultAssetBundle(bundle: bundle, child: Center(child: child)),
      ),
    );

void main() {
  testWidgets('unknown ID shows neutral fallback and never requests a photo',
      (tester) async {
    final bundle = _MissingBundle();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(
          const Column(mainAxisSize: MainAxisSize.min, children: [
            FitFlowExerciseImage.thumbnail(exerciseId: 'unknown'),
            Text('Existing exercise name'),
          ]),
          bundle));
      expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(bundle.requests, isEmpty);
      expect(find.bySemanticsLabel('Existing exercise name'), findsOneWidget);
      expect(find.bySemanticsLabel('unknown'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
        'missing known asset retains dimensions and caller semantics ($dark)',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final bundle = _MissingBundle();
        await tester.pumpWidget(_host(
            const FitFlowExerciseImage.hero(
              exerciseId: 'pushup_wall',
              decorative: false,
              semanticLabel: 'Wall Push-Up',
            ),
            bundle,
            dark: dark));
        final before = tester.getSize(find.byType(FitFlowExerciseImage));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('fitflow_media_placeholder')),
            findsOneWidget);
        expect(tester.getSize(find.byType(FitFlowExerciseImage)), before);
        expect(before, const Size(320, 240));
        expect(find.bySemanticsLabel('Wall Push-Up'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(bundle.requests.where((p) => p.endsWith('.webp')).toSet(),
            {'assets/images/exercises/hero/pushup_wall.webp'});
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('thumbnail uses a bounded decode and never loads heroes',
      (tester) async {
    final bundle = _MissingBundle();
    await tester.pumpWidget(_host(
        const FitFlowExerciseImage.thumbnail(
          exerciseId: 'pushup_knee',
        ),
        bundle));
    await tester.pumpAndSettle();
    final provider =
        tester.widget<Image>(find.byType(Image)).image as ResizeImage;
    expect(provider.width, lessThanOrEqualTo(256));
    expect(provider.height, lessThanOrEqualTo(256));
    expect((provider.imageProvider as AssetImage).assetName,
        'assets/images/exercises/thumb/pushup_knee.webp');
    expect(bundle.requests.any((p) => p.contains('/hero/')), isFalse);
    expect(
        tester.getSize(find.byType(FitFlowExerciseImage)), const Size(72, 72));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'changing ID changes the provider without retaining the old photo',
      (tester) async {
    final bundle = _MissingBundle();
    for (final id in ['pushup_wall', 'squat_chair']) {
      await tester
          .pumpWidget(_host(FitFlowExerciseImage.hero(exerciseId: id), bundle));
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.key, ValueKey('assets/images/exercises/hero/$id.webp'));
      expect(image.gaplessPlayback, isFalse);
    }
    await tester.pumpWidget(
        _host(const FitFlowExerciseImage.hero(exerciseId: 'unknown'), bundle));
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('program media uses exact ID and neutral fallback',
      (tester) async {
    final bundle = _MissingBundle();
    await tester.pumpWidget(_host(
        const FitFlowProgramImage(programId: 'balanced_foundations'), bundle));
    await tester.pumpAndSettle();
    expect(bundle.requests,
        contains('assets/images/programs/balanced_foundations.webp'));
    expect(find.byKey(const ValueKey('fitflow_media_placeholder')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decoded decorative media adds no duplicate accessible identity',
      (tester) async {
    // In-memory codec fixture only; no production image or fake photo is saved.
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.green, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(4, 4);
      try {
        return await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
        picture.dispose();
      }
    });
    final bundle = _MissingBundle(bytes: bytes);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(
          const Column(mainAxisSize: MainAxisSize.min, children: [
            FitFlowExerciseImage.thumbnail(
                exerciseId: 'pushup_wall', semanticLabel: 'Must not announce'),
            Text('Wall Push-Up'),
          ]),
          bundle));
      // Explicitly finish decoding outside the test's fake async clock.
      final provider = tester.widget<Image>(find.byType(Image)).image;
      await tester.runAsync(
          () => precacheImage(provider, tester.element(find.byType(Image))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fitflow_media_placeholder')),
          findsNothing);
      expect(find.bySemanticsLabel('Wall Push-Up'), findsOneWidget);
      expect(find.bySemanticsLabel('Must not announce'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('corrupt image bytes show neutral fallback without an exception',
      (tester) async {
    final bundle = _MissingBundle(bytes: ByteData(8));
    await tester.pumpWidget(_host(
        const FitFlowExerciseImage.hero(exerciseId: 'pushup_wall'), bundle));
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.runAsync(() => precacheImage(
        provider, tester.element(find.byType(Image)),
        onError: (_, __) {}));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fitflow_media_placeholder')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
