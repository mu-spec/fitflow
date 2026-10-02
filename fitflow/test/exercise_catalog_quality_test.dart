import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/quality/exercise_catalog_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Production-catalog quality gate (Milestone 20 Part 1).
///
/// The validator is exercised exhaustively with synthetic fixtures in
/// `exercise_catalog_quality_validator_test.dart`; these tests pin the
/// shipped catalog itself.
void main() {
  final catalog = ExerciseCatalog.all;

  test('production exercise catalog has zero quality errors', () {
    final report = ExerciseCatalogQualityValidator.validateCatalog();
    if (report.hasErrors) {
      // Actionable output: exercise id + rule + explanation per diagnostic.
      fail('Catalog quality errors found:\n${report.describe()}');
    }
  });

  test('production exercise catalog avoids avoidable warnings', () {
    final report = ExerciseCatalogQualityValidator.validateCatalog();
    expect(report.warnings, isEmpty, reason: report.describe());
  });

  test('exercise count reflects the M20 stabilization (80 + 8 meaningful equipment exercises)',
      () {
    // If this needs to change, the milestone report must explain why.
    expect(catalog, hasLength(88));
  });

  test('all exercise ids are unique and normalized snake_case', () {
    final ids = catalog.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    final snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
    for (final id in ids) {
      expect(snakeCase.hasMatch(id), isTrue, reason: id);
    }
  });

  test('all active exercises carry the required content', () {
    for (final e in catalog) {
      expect(e.active, isTrue, reason: e.id);
      expect(e.name.trim(), isNotEmpty, reason: e.id);
      expect(e.shortDescription?.trim() ?? '', isNotEmpty, reason: e.id);
      expect(e.primaryMuscles, isNotEmpty, reason: e.id);
      expect(e.instructions, isNotEmpty, reason: e.id);
      expect(e.commonMistakes, isNotEmpty, reason: e.id);
      expect(e.breathingGuidance?.trim() ?? '', isNotEmpty, reason: e.id);
      expect(
        e.primaryMuscles.intersection(e.secondaryMuscles),
        isEmpty,
        reason: e.id,
      );
    }
  });

  test('prescriptions are structurally valid and conflict-free', () {
    for (final e in catalog) {
      if (e.exerciseType == ExerciseType.reps) {
        expect(e.defaultReps, isNotNull, reason: e.id);
        expect(e.defaultReps, greaterThan(0), reason: e.id);
        expect(e.defaultDuration, isNull, reason: e.id);
      } else {
        expect(e.defaultDuration, isNotNull, reason: e.id);
        expect(e.defaultDuration, greaterThan(Duration.zero), reason: e.id);
        expect(e.defaultReps, isNull, reason: e.id);
      }
      expect(e.defaultRest, isNotNull, reason: e.id);
      expect(e.defaultRest, greaterThan(Duration.zero), reason: e.id);
    }
  });

  test('tags are normalized snake_case and equipment stays truthful', () {
    final snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
    for (final e in catalog) {
      for (final tag in e.tags) {
        expect(snakeCase.hasMatch(tag), isTrue, reason: '${e.id}: $tag');
      }
      expect(e.requiredEquipment, isNotEmpty, reason: e.id);
      // WorkoutEquipment.none must never coexist with real equipment.
      if (e.requiredEquipment.contains(WorkoutEquipment.none)) {
        expect(e.requiredEquipment, {WorkoutEquipment.none}, reason: e.id);
      }
    }
  });

  test('no exercise carries a fabricated asset path', () {
    // Milestone 20 Part 1 ships no media; assetPath must stay null.
    for (final e in catalog) {
      expect(e.assetPath, isNull, reason: e.id);
    }
  });

  test('catalog order is deterministic and unchanged', () {
    expect(catalog.first.id, 'pushup_wall');
    // Original 80 keep their stable order; the M20 stabilization appended
    // the eight equipment exercises after them.
    expect(catalog[79].id, 'figure_four_stretch');
    expect(catalog.last.id, 'scapular_pullup');
    expect(ExerciseCatalog.byId('pushup_standard'), isNotNull);
    expect(ExerciseCatalog.byId('not_a_real_exercise'), isNull);
  });
}
