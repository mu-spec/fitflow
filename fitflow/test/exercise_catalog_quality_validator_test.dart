import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/quality/exercise_catalog_quality_validator.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a fully valid reps exercise; tests override exactly one aspect to
/// prove the matching quality rule fires.
Exercise buildExercise({
  String id = 'sample_pushup',
  String name = 'Sample Push-Up',
  String? shortDescription = 'A sample pressing movement for tests.',
  Set<MuscleGroup>? primaryMuscles,
  Set<MuscleGroup>? secondaryMuscles,
  MovementPattern? movementPattern = MovementPattern.push,
  ExerciseDifficulty difficulty = ExerciseDifficulty.level2,
  Set<WorkoutEquipment>? requiredEquipment,
  ExercisePosition? bodyPosition = ExercisePosition.floor,
  ImpactLevel impactLevel = ImpactLevel.low,
  NoiseLevel noiseLevel = NoiseLevel.quiet,
  SpaceRequirement spaceRequirement = SpaceRequirement.small,
  JointLoad wristLoad = JointLoad.moderate,
  JointLoad kneeLoad = JointLoad.low,
  ExerciseType exerciseType = ExerciseType.reps,
  int? defaultReps = 8,
  Duration? defaultDuration,
  Duration? defaultRest = const Duration(seconds: 45),
  String? progressionFamilyId,
  int progressionRank = 0,
  String? easierVariationId,
  String? harderVariationId,
  List<String>? instructions,
  List<String>? commonMistakes,
  String? breathingGuidance = 'Inhale while lowering; exhale while pressing.',
  Set<String>? tags,
  bool active = true,
}) {
  return Exercise(
    id: id,
    name: name,
    shortDescription: shortDescription,
    primaryMuscles: primaryMuscles ?? {MuscleGroup.chest},
    secondaryMuscles: secondaryMuscles ?? {MuscleGroup.triceps},
    movementPattern: movementPattern,
    difficulty: difficulty,
    requiredEquipment: requiredEquipment ?? {WorkoutEquipment.none},
    bodyPosition: bodyPosition,
    impactLevel: impactLevel,
    noiseLevel: noiseLevel,
    spaceRequirement: spaceRequirement,
    wristLoad: wristLoad,
    kneeLoad: kneeLoad,
    exerciseType: exerciseType,
    defaultReps: defaultReps,
    defaultDuration: defaultDuration,
    defaultRest: defaultRest,
    progressionFamilyId: progressionFamilyId,
    progressionRank: progressionRank,
    easierVariationId: easierVariationId,
    harderVariationId: harderVariationId,
    instructions: instructions ??
        const [
          'Set your hands shoulder-width apart.',
          'Lower your chest with control.',
          'Press back to the start.',
        ],
    commonMistakes: commonMistakes ??
        const [
          'Sagging the lower back',
          'Flaring the elbows wide',
        ],
    breathingGuidance: breathingGuidance,
    tags: tags ?? const {'bodyweight'},
    active: active,
  );
}

CatalogQualityReport validateOne(Exercise exercise) =>
    ExerciseCatalogQualityValidator.validate([exercise]);

List<String> errorRules(CatalogQualityReport report) =>
    report.errors.map((d) => d.rule).toList();

List<String> warningRules(CatalogQualityReport report) =>
    report.warnings.map((d) => d.rule).toList();

void main() {
  group('clean fixtures', () {
    test('valid standalone exercise produces zero diagnostics', () {
      final report = validateOne(buildExercise());
      expect(report.diagnostics, isEmpty, reason: report.describe());
    });

    test('valid linked family produces zero diagnostics', () {
      final easy = buildExercise(
        id: 'push_easy',
        progressionFamilyId: 'push',
        progressionRank: 1,
        harderVariationId: 'push_hard',
        difficulty: ExerciseDifficulty.level1,
      );
      final hard = buildExercise(
        id: 'push_hard',
        progressionFamilyId: 'push',
        progressionRank: 2,
        easierVariationId: 'push_easy',
        difficulty: ExerciseDifficulty.level3,
      );
      final report = ExerciseCatalogQualityValidator.validate([easy, hard]);
      expect(report.diagnostics, isEmpty, reason: report.describe());
    });
  });

  group('id rules', () {
    test('malformed ids are flagged', () {
      for (final badId in ['Pushup', 'push up', '_push', 'push_', 'push__up']) {
        final report = validateOne(buildExercise(id: badId));
        expect(errorRules(report), contains('id.format'), reason: badId);
      }
    });

    test('duplicate ids are flagged once per id', () {
      final report = ExerciseCatalogQualityValidator.validate([
        buildExercise(),
        buildExercise(),
      ]);
      expect(errorRules(report).where((r) => r == 'id.unique'), hasLength(1));
    });
  });

  group('content rules', () {
    test('missing description is an error', () {
      final report = validateOne(buildExercise(shortDescription: ''));
      expect(errorRules(report), contains('description.present'));
    });

    test('multi-sentence description warns', () {
      final report = validateOne(buildExercise(
        shortDescription: 'A pressing move. It is done on the floor.',
      ));
      expect(warningRules(report), contains('description.one_sentence'));
    });

    test('empty primary muscles is an error', () {
      final report = validateOne(buildExercise(primaryMuscles: {}));
      expect(errorRules(report), contains('muscles.primary_not_empty'));
    });

    test('primary/secondary overlap is an error', () {
      final report = validateOne(buildExercise(
        primaryMuscles: {MuscleGroup.chest},
        secondaryMuscles: {MuscleGroup.chest},
      ));
      expect(errorRules(report), contains('muscles.no_overlap'));
    });

    test('empty instructions are an error; one step warns', () {
      expect(
        errorRules(validateOne(buildExercise(instructions: const []))),
        contains('instructions.not_empty'),
      );
      expect(
        warningRules(validateOne(
            buildExercise(instructions: const ['Only one step here.']))),
        contains('instructions.step_count'),
      );
    });

    test('empty mistakes are an error; vague wording warns', () {
      expect(
        errorRules(validateOne(buildExercise(commonMistakes: const []))),
        contains('mistakes.not_empty'),
      );
      expect(
        warningRules(validateOne(buildExercise(
          commonMistakes: const ['Using bad form', 'Rushing the reps'],
        ))),
        contains('mistakes.concrete'),
      );
    });

    test('missing breathing is an error; encouraged breath-hold warns', () {
      expect(
        errorRules(validateOne(buildExercise(breathingGuidance: ''))),
        contains('breathing.present'),
      );
      expect(
        warningRules(validateOne(
            buildExercise(breathingGuidance: 'Hold your breath for power.'))),
        contains('breathing.no_breath_hold'),
      );
      // Guidance telling users NOT to hold their breath must stay clean.
      expect(
        validateOne(buildExercise(
          breathingGuidance: 'Breathe steadily; do not hold your breath.',
        )).diagnostics,
        isEmpty,
      );
    });
  });

  group('prescription rules', () {
    test('reps exercise without reps is an error', () {
      final report =
          validateOne(buildExercise(defaultReps: null));
      expect(errorRules(report), contains('prescription.reps_positive'));
    });

    test('timed exercise needs a positive duration', () {
      final report = validateOne(buildExercise(
        exerciseType: ExerciseType.timed,
        defaultReps: null,
        defaultDuration: null,
      ));
      expect(errorRules(report), contains('prescription.duration_positive'));
    });

    test('conflicting prescription metadata is an error', () {
      expect(
        errorRules(validateOne(buildExercise(
          defaultDuration: const Duration(seconds: 20),
        ))),
        contains('prescription.type_conflict'),
      );
      expect(
        errorRules(validateOne(buildExercise(
          exerciseType: ExerciseType.timed,
          defaultDuration: const Duration(seconds: 20),
          defaultReps: 5,
        ))),
        contains('prescription.type_conflict'),
      );
    });

    test('missing defaultRest is an error; zero rest warns', () {
      expect(
        errorRules(validateOne(buildExercise(defaultRest: null))),
        contains('prescription.rest_present'),
      );
      expect(
        warningRules(validateOne(buildExercise(defaultRest: Duration.zero))),
        contains('prescription.rest_zero'),
      );
    });

    test('outlier values warn', () {
      expect(
        warningRules(validateOne(buildExercise(defaultReps: 100))),
        contains('prescription.reps_outlier'),
      );
      expect(
        warningRules(validateOne(buildExercise(
          exerciseType: ExerciseType.timed,
          defaultReps: null,
          defaultDuration: const Duration(minutes: 10),
        ))),
        contains('prescription.duration_outlier'),
      );
    });
  });

  group('equipment rules', () {
    test('none coexisting with real equipment is an error', () {
      final report = validateOne(buildExercise(
        requiredEquipment: {WorkoutEquipment.none, WorkoutEquipment.chair},
      ));
      expect(errorRules(report), contains('equipment.none_conflict'));
    });

    test('empty equipment warns', () {
      final report = validateOne(buildExercise(requiredEquipment: {}));
      expect(warningRules(report), contains('equipment.empty'));
    });

    test('name mentioning equipment that is not required warns', () {
      final report = validateOne(buildExercise(
        name: 'Chair Dip',
        requiredEquipment: {WorkoutEquipment.none},
      ));
      expect(warningRules(report), contains('equipment.name_mismatch'));
    });
  });

  group('metadata consistency', () {
    test('jumping-tagged low impact is an error', () {
      final report = validateOne(buildExercise(
        tags: {'jumping'},
        impactLevel: ImpactLevel.low,
      ));
      expect(errorRules(report), contains('impact.jumping_not_low'));
    });

    test('jumping-tagged quiet warns', () {
      final report = validateOne(buildExercise(
        tags: {'jumping'},
        impactLevel: ImpactLevel.high,
        noiseLevel: NoiseLevel.quiet,
      ));
      expect(warningRules(report), contains('noise.jumping_not_quiet'));
    });
  });

  group('tag rules', () {
    test('malformed tags are flagged', () {
      for (final badTag in ['Jumping', 'jumping jack', ' jumping']) {
        final report = validateOne(buildExercise(tags: {badTag}));
        expect(errorRules(report), contains('tag.format'), reason: badTag);
      }
    });
  });

  group('health claim rules', () {
    test('claim phrases are flagged as whole words', () {
      final report = validateOne(buildExercise(
        shortDescription: 'A movement that cures back pain.',
      ));
      expect(errorRules(report), contains('claims.unsupported'));
    });

    test('benign words like "secure" do not trip the cure rule', () {
      final report = validateOne(buildExercise(
        instructions: const [
          'Secure a stable chair against a wall.',
          'Lower with control.',
          'Press back up.',
        ],
      ));
      expect(
        report.diagnostics.where((d) => d.rule == 'claims.unsupported'),
        isEmpty,
      );
    });
  });

  group('asset rules', () {
    test('blank assetPath is an error; null is fine', () {
      final report = validateOne(buildExercise());
      expect(
        report.diagnostics.where((d) => d.rule.startsWith('asset.')),
        isEmpty,
      );
    });
  });

  group('progression family rules', () {
    Exercise familyMember({
      required String id,
      required int rank,
      String? easier,
      String? harder,
      ExerciseDifficulty difficulty = ExerciseDifficulty.level2,
      MovementPattern pattern = MovementPattern.push,
    }) {
      return buildExercise(
        id: id,
        progressionFamilyId: 'test_family',
        progressionRank: rank,
        easierVariationId: easier,
        harderVariationId: harder,
        difficulty: difficulty,
        movementPattern: pattern,
      );
    }

    test('rank zero inside a family is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 0),
      ]);
      expect(errorRules(report), contains('progression.rank_positive'));
    });

    test('duplicate ranks inside a family are an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1),
        familyMember(id: 'b', rank: 1),
      ]);
      expect(errorRules(report), contains('progression.ranks_unique'));
    });

    test('self-link is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, harder: 'a'),
      ]);
      expect(errorRules(report), contains('progression.no_self_link'));
    });

    test('unresolvable link is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, harder: 'missing_exercise'),
      ]);
      expect(errorRules(report), contains('progression.harder_resolves'));
    });

    test('cross-family link is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, harder: 'outsider'),
        buildExercise(
          id: 'outsider',
          progressionFamilyId: 'other_family',
          progressionRank: 1,
        ),
      ]);
      expect(errorRules(report), contains('progression.harder_same_family'));
    });

    test('wrong rank direction is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 2, harder: 'b'),
        familyMember(id: 'b', rank: 1, easier: 'a'),
      ]);
      expect(errorRules(report), contains('progression.harder_rank_higher'));
      expect(errorRules(report), contains('progression.easier_rank_lower'));
    });

    test('non-reciprocal link is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, harder: 'b'),
        familyMember(id: 'b', rank: 2), // no easier link back
      ]);
      expect(errorRules(report), contains('progression.reciprocal'));
    });

    test('harder-chain cycle is an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, harder: 'b'),
        familyMember(id: 'b', rank: 2, harder: 'a'),
      ]);
      expect(errorRules(report), contains('progression.no_cycles'));
    });

    test('mixed movement patterns in one family are an error', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(id: 'a', rank: 1, pattern: MovementPattern.push,
            harder: 'b'),
        familyMember(
          id: 'b',
          rank: 2,
          pattern: MovementPattern.squat,
          easier: 'a',
        ),
      ]);
      expect(errorRules(report), contains('progression.family_pattern'));
    });

    test('difficulty regressing along the ladder warns', () {
      final report = ExerciseCatalogQualityValidator.validate([
        familyMember(
          id: 'a',
          rank: 1,
          harder: 'b',
          difficulty: ExerciseDifficulty.level3,
        ),
        familyMember(
          id: 'b',
          rank: 2,
          easier: 'a',
          difficulty: ExerciseDifficulty.level1,
        ),
      ]);
      expect(
        warningRules(report),
        contains('progression.difficulty_direction'),
      );
    });

    test('standalone exercise with a link warns', () {
      final report = ExerciseCatalogQualityValidator.validate([
        buildExercise(id: 'lonely', harderVariationId: 'other'),
        buildExercise(id: 'other'),
      ]);
      expect(warningRules(report), contains('progression.standalone_link'));
    });
  });

  group('report shape', () {
    test('diagnostics carry id, rule, and actionable message', () {
      final report = validateOne(buildExercise(shortDescription: ''));
      final diagnostic = report.errors
          .firstWhere((d) => d.rule == 'description.present');
      expect(diagnostic.exerciseId, 'sample_pushup');
      expect(diagnostic.message, isNotEmpty);
      expect(diagnostic.isError, isTrue);
      expect(report.describe(), contains('sample_pushup'));
      expect(report.describe(), contains('description.present'));
    });
  });
}
