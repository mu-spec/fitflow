import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/core/design/media/exercise_media_spec.dart';
import 'package:fitflow/core/design/media/program_media_registry.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final assets = [
    for (final spec in ExerciseMediaRegistry.entries) ...spec.assets,
    for (final spec in ProgramMediaRegistry.entries) spec.cover,
  ];
  final missing = assets.where((a) => !File(a.path).existsSync()).toList();
  const requireAssets = bool.fromEnvironment('FITFLOW_REQUIRE_MEDIA_ASSETS');

  test('all 88 canonical IDs are explicitly covered with no duplicates', () {
    final ids = ExerciseMediaRegistry.entries.map((e) => e.exerciseId).toList();
    expect(ExerciseCatalog.all, hasLength(88));
    expect(ids, hasLength(88));
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.toSet(), ExerciseCatalog.all.map((e) => e.id).toSet());
    for (final exercise in ExerciseCatalog.all) {
      expect(
          ExerciseMediaRegistry.lookup(exercise.id)?.exerciseId, exercise.id);
      expect(ExerciseMediaRegistry.lookup(exercise.name), isNull);
    }
  });

  test('five existing programs have unique explicit covers', () {
    final ids = ProgramMediaRegistry.entries.map((e) => e.programId).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.toSet(), AdaptiveProgramCatalog.all.map((e) => e.id).toSet());
  });

  test('unknown, differently cased, and partial IDs never borrow media', () {
    for (final id in [
      '',
      'pushup',
      'PUSHUP_WALL',
      'pushup_wall ',
      '../pushup_wall'
    ]) {
      expect(ExerciseMediaRegistry.lookup(id), isNull);
    }
    expect(ProgramMediaRegistry.lookup('balanced'), isNull);
  });

  test('asset paths are unique local WebP exports with the agreed dimensions',
      () {
    expect(assets.map((e) => e.path).toSet(), hasLength(181));
    for (final spec in ExerciseMediaRegistry.entries) {
      expect(spec.thumbnail.path,
          'assets/images/exercises/thumb/${spec.exerciseId}.webp');
      expect(spec.hero.path,
          'assets/images/exercises/hero/${spec.exerciseId}.webp');
      expect(
          [spec.thumbnail.pixelWidth, spec.thumbnail.pixelHeight], [256, 256]);
      expect([spec.hero.pixelWidth, spec.hero.pixelHeight], [960, 720]);
      expect(spec.secondaryFrame, isNull);
    }
  });

  test('registry source has no feature imports, name matching, or domain logic',
      () {
    for (final name in ['exercise_media_registry', 'program_media_registry']) {
      final source =
          File('lib/core/design/media/$name.dart').readAsStringSync();
      expect(source, isNot(contains('features/')));
      expect(source,
          isNot(matches(r'\.(name|contains|startsWith|toLowerCase)\(')));
      expect(
          source,
          isNot(matches(
              r'\b(Random|MovementPattern|ExerciseDifficulty|Provider|NetworkImage)\b')));
    }
  });

  test('handoff inventory lists every expected image path', () {
    final inventory =
        File('docs/design/media/asset-handoff.md').readAsStringSync();
    for (final asset in assets) {
      expect(inventory, contains(asset.path));
    }
  });

  test('every supplied image is a valid WebP with the expected export size',
      () async {
    for (final asset in assets.where((a) => File(a.path).existsSync())) {
      await _validateImage(asset);
    }
  });

  // Explicitly pending in foundation-only work. The release gate removes the
  // skip and FAILS until all real photography is supplied and bundled.
  test(
      'RELEASE GATE: all declared thumbnails, heroes and covers exist and bundle',
      () async {
    expect(missing.map((a) => a.path).toList(), isEmpty,
        reason:
            'Photography delivery incomplete. See docs/design/media/asset-handoff.md');
    for (final asset in assets) {
      expect((await rootBundle.load(asset.path)).lengthInBytes, greaterThan(0));
      await _validateImage(asset);
    }
  },
      skip: !requireAssets && missing.isNotEmpty
          ? '${missing.length}/181 photos missing; run with --dart-define=FITFLOW_REQUIRE_MEDIA_ASSETS=true for the mandatory release gate'
          : false);
}

Future<void> _validateImage(FitFlowMediaAsset asset) async {
  final bytes = await File(asset.path).readAsBytes();
  expect(bytes.length, greaterThanOrEqualTo(12), reason: asset.path);
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: asset.path);
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP',
      reason: asset.path);
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    expect(codec.frameCount, 1, reason: 'Static images only: ${asset.path}');
    final frame = await codec.getNextFrame();
    try {
      expect(frame.image.width, asset.pixelWidth, reason: asset.path);
      expect(frame.image.height, asset.pixelHeight, reason: asset.path);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
