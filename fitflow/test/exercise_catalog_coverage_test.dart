import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/quality/exercise_catalog_coverage_report.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise syntheticExercise({
  required String id,
  MovementPattern? pattern = MovementPattern.push,
  ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
  Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
  ExerciseType type = ExerciseType.timed,
}) {
  return Exercise(
    id: id,
    name: id,
    movementPattern: pattern,
    difficulty: difficulty,
    impactLevel: ImpactLevel.low,
    noiseLevel: NoiseLevel.quiet,
    spaceRequirement: SpaceRequirement.small,
    bodyPosition: ExercisePosition.standing,
    wristLoad: JointLoad.none,
    kneeLoad: JointLoad.none,
    requiredEquipment: equipment,
    exerciseType: type,
    defaultDuration:
        type == ExerciseType.timed ? const Duration(seconds: 30) : null,
    defaultReps: type == ExerciseType.reps ? 10 : null,
    defaultRest: const Duration(seconds: 30),
    primaryMuscles: const {MuscleGroup.chest},
    tags: const {'bodyweight'},
    active: true,
  );
}

void main() {
  group('production catalog coverage', () {
    final result = ExerciseCatalogCoverageReport.generate();

    test('production exercise catalog has no release-blocking coverage gaps',
        () {
      if (result.hasReleaseBlockingGaps) {
        fail('Release-blocking coverage gaps found:\n${result.describe()}');
      }
    });

    test('reports every trainable pattern in canonical order', () {
      expect(
        result.patternSummaries.map((s) => s.pattern).toList(),
        CapabilityProfile.trainablePatterns,
      );
    });

    test('every trainable pattern has active exercises', () {
      for (final summary in result.patternSummaries) {
        expect(summary.activeCount, greaterThan(0),
            reason: summary.pattern.name);
      }
    });

    test('capability distribution maps through fromExerciseDifficulty only',
        () {
      for (final summary in result.patternSummaries) {
        // Capability counts must equal difficulty counts level-for-level.
        for (final level in CapabilityLevel.values) {
          final difficulty = level.toExerciseDifficulty();
          expect(
            summary.capabilityDistribution[level] ?? 0,
            summary.difficultyDistribution[difficulty] ?? 0,
            reason: '${summary.pattern.name} ${level.name}',
          );
          // Mapping must be the canonical one (identity).
          expect(CapabilityLevel.fromExerciseDifficulty(difficulty), level);
        }
      }
    });

    test('warmup and cooldown sections are viable', () {
      expect(result.warmupCount, greaterThan(0));
      expect(result.cooldownCount, greaterThan(0));
    });

    test('no-equipment home setup has trainable candidates', () {
      expect(result.noEquipmentTrainableCount, greaterThan(10));
    });

    test('informational gaps remain non-blocking', () {
      // Level-1 lunge absence is a design choice (squat covers beginners);
      // it must stay informational, never blocking.
      for (final diagnostic in result.informational) {
        expect(diagnostic.isReleaseBlocking, isFalse);
      }
    });

    test('describe() is actionable', () {
      final text = result.describe();
      expect(text, contains('push'));
      expect(text, contains('active='));
    });
  });

  group('capability assessment anchors', () {
    test('every assessment example resolves to an active exercise', () {
      final byName = {
        for (final e in ExerciseCatalog.all.where((e) => e.active))
          e.name.toLowerCase(): e,
      };
      for (final item in CapabilityAssessmentCatalog.all) {
        for (final example in item.examples) {
          final resolved = byName[example.toLowerCase()];
          expect(resolved, isNotNull,
              reason: '${item.movementPattern.name}: "$example"');
          expect(resolved!.active, isTrue, reason: example);
          expect(resolved.difficulty, isA<ExerciseDifficulty>(),
              reason: example);
        }
      }
    });

    test('assessment catalog structural validation stays clean', () {
      expect(CapabilityAssessmentCatalog.validate(), isEmpty);
    });
  });

  group('gap detection on synthetic catalogs', () {
    test('empty trainable pattern is release-blocking', () {
      final catalog = <Exercise>[];
      for (final pattern in CapabilityProfile.trainablePatterns) {
        if (pattern == MovementPattern.balance) continue;
        catalog.add(syntheticExercise(
          id: 'ex_${pattern.name}',
          pattern: pattern,
        ));
        catalog.add(syntheticExercise(
          id: 'ex_${pattern.name}_2',
          pattern: pattern,
        ));
      }
      catalog.add(syntheticExercise(
        id: 'warmup',
        pattern: MovementPattern.warmup,
      ));
      catalog.add(syntheticExercise(
        id: 'cooldown',
        pattern: MovementPattern.cooldown,
      ));

      final result = ExerciseCatalogCoverageReport.generate(catalog: catalog);
      expect(result.hasReleaseBlockingGaps, isTrue);
      expect(
        result.releaseBlockingGaps.map((d) => d.code),
        contains('pattern.no_exercises'),
      );
      final gap = result.releaseBlockingGaps
          .firstWhere((d) => d.code == 'pattern.no_exercises');
      expect(gap.pattern, MovementPattern.balance);
      expect(gap.message, contains('balance'));
    });

    test('single-exercise pattern is release-blocking', () {
      final catalog = <Exercise>[];
      for (final pattern in CapabilityProfile.trainablePatterns) {
        catalog.add(syntheticExercise(id: 'a_${pattern.name}', pattern: pattern));
        if (pattern != MovementPattern.glute) {
          catalog.add(syntheticExercise(id: 'b_${pattern.name}', pattern: pattern));
        }
      }
      catalog.add(syntheticExercise(id: 'warmup', pattern: MovementPattern.warmup));
      catalog.add(syntheticExercise(id: 'cooldown', pattern: MovementPattern.cooldown));

      final result = ExerciseCatalogCoverageReport.generate(catalog: catalog);
      final codes = result.releaseBlockingGaps.map((d) => d.code).toList();
      expect(codes, contains('pattern.single_exercise'));
      expect(
        result.releaseBlockingGaps
            .firstWhere((d) => d.code == 'pattern.single_exercise')
            .pattern,
        MovementPattern.glute,
      );
    });

    test('missing warmup/cooldown is release-blocking', () {
      final catalog = <Exercise>[
        for (final pattern in CapabilityProfile.trainablePatterns)
          syntheticExercise(id: 'a_${pattern.name}', pattern: pattern),
        for (final pattern in CapabilityProfile.trainablePatterns)
          syntheticExercise(id: 'b_${pattern.name}', pattern: pattern),
      ];
      final result = ExerciseCatalogCoverageReport.generate(catalog: catalog);
      final codes = result.releaseBlockingGaps.map((d) => d.code).toList();
      expect(codes, contains('section.no_warmup'));
      expect(codes, contains('section.no_cooldown'));
    });

    test('no no-equipment candidates is release-blocking', () {
      final catalog = <Exercise>[
        for (final pattern in CapabilityProfile.trainablePatterns)
          syntheticExercise(
            id: 'a_${pattern.name}',
            pattern: pattern,
            equipment: const {WorkoutEquipment.bench},
          ),
        for (final pattern in CapabilityProfile.trainablePatterns)
          syntheticExercise(
            id: 'b_${pattern.name}',
            pattern: pattern,
            equipment: const {WorkoutEquipment.bench},
          ),
        syntheticExercise(id: 'warmup', pattern: MovementPattern.warmup,
            equipment: const {WorkoutEquipment.bench}),
        syntheticExercise(id: 'cooldown', pattern: MovementPattern.cooldown,
            equipment: const {WorkoutEquipment.bench}),
      ];
      final result = ExerciseCatalogCoverageReport.generate(catalog: catalog);
      final codes = result.releaseBlockingGaps.map((d) => d.code).toList();
      expect(codes, contains('setup.no_equipment_candidates'));
    });
  });
}
