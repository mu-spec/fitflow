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
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise validRepsExercise() => Exercise(
        id: 'pushup_standard',
        name: 'Standard push-up',
        shortDescription: 'A classic chest and triceps bodyweight press.',
        primaryMuscles: const {MuscleGroup.chest, MuscleGroup.triceps},
        secondaryMuscles: const {MuscleGroup.shoulders, MuscleGroup.abs},
        movementPattern: MovementPattern.push,
        difficulty: ExerciseDifficulty.level2,
        requiredEquipment: const {},
        bodyPosition: ExercisePosition.floor,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.high,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.reps,
        defaultReps: 12,
        defaultRest: const Duration(seconds: 45),
        progressionFamilyId: 'pushup',
        progressionRank: 4,
        easierVariationId: 'pushup_knee',
        harderVariationId: 'pushup_decline',
        instructions: const [
          'Place hands shoulder-width apart.',
          'Lower your chest toward the floor.',
          'Push back up to the start.',
        ],
        commonMistakes: const ['Sagging hips'],
        breathingGuidance: 'Inhale down, exhale up.',
        tags: const {'bodyweight', 'chest'},
      );

  Exercise validTimedExercise() => Exercise(
        id: 'plank_standard',
        name: 'Standard plank',
        movementPattern: MovementPattern.core,
        difficulty: ExerciseDifficulty.level1,
        bodyPosition: ExercisePosition.floor,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.moderate,
        kneeLoad: JointLoad.none,
        primaryMuscles: const {MuscleGroup.abs},
        exerciseType: ExerciseType.timed,
        defaultDuration: const Duration(seconds: 30),
      );

  group('Exercise creation', () {
    test('creates a full reps-based exercise', () {
      final ex = validRepsExercise();

      expect(ex.id, 'pushup_standard');
      expect(ex.name, 'Standard push-up');
      expect(ex.shortDescription, contains('chest'));
      expect(ex.difficulty, ExerciseDifficulty.level2);
      expect(ex.defaultReps, 12);
      expect(ex.defaultRest, const Duration(seconds: 45));
      expect(ex.active, isTrue);
      expect(ex.instructions, hasLength(3));
      expect(ex.breathingGuidance, isNotEmpty);
      expect(ex.tags, contains('bodyweight'));
    });

    test('creates a timed exercise', () {
      final ex = validTimedExercise();

      expect(ex.exerciseType, ExerciseType.timed);
      expect(ex.defaultDuration, const Duration(seconds: 30));
      expect(ex.defaultReps, isNull);
    });

    test('uses typed enums for classification fields', () {
      final ex = validRepsExercise();

      expect(ex.movementPattern, MovementPattern.push);
      expect(ex.difficulty, ExerciseDifficulty.level2);
      expect(ex.bodyPosition, ExercisePosition.floor);
      expect(ex.impactLevel, ImpactLevel.low);
      expect(ex.noiseLevel, NoiseLevel.quiet);
      expect(ex.spaceRequirement, SpaceRequirement.small);
      expect(ex.wristLoad, JointLoad.high);
      expect(ex.kneeLoad, JointLoad.none);
    });
  });

  group('Equipment and muscles', () {
    test('reuses the WorkoutEquipment enum for required equipment', () {
      final ex = Exercise(
        id: 'dumbbell_press',
        name: 'Dumbbell press',
        difficulty: ExerciseDifficulty.level3,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.medium,
        wristLoad: JointLoad.moderate,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.reps,
        defaultReps: 10,
        requiredEquipment: const {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.bench,
        },
      );

      expect(ex.requiredEquipment, hasLength(2));
      expect(ex.requiredEquipment, contains(WorkoutEquipment.dumbbells));
      expect(ex.requiredEquipment, contains(WorkoutEquipment.bench));
    });

    test('stores primary and secondary muscles', () {
      final ex = validRepsExercise();

      expect(ex.primaryMuscles, contains(MuscleGroup.chest));
      expect(ex.primaryMuscles, contains(MuscleGroup.triceps));
      expect(ex.secondaryMuscles, contains(MuscleGroup.shoulders));
      expect(ex.secondaryMuscles, contains(MuscleGroup.abs));
    });
  });

  group('Progression relationships', () {
    test('stores family, rank, and easier/harder references', () {
      final ex = validRepsExercise();

      expect(ex.progressionFamilyId, 'pushup');
      expect(ex.progressionRank, 4);
      expect(ex.easierVariationId, 'pushup_knee');
      expect(ex.harderVariationId, 'pushup_decline');
    });
  });

  group('Immutability', () {
    test('collections are unmodifiable from outside the model', () {
      final ex = validRepsExercise();

      expect(() => ex.primaryMuscles.add(MuscleGroup.lats),
          throwsUnsupportedError);
      expect(() => ex.secondaryMuscles.add(MuscleGroup.lats),
          throwsUnsupportedError);
      expect(() => ex.requiredEquipment.add(WorkoutEquipment.bench),
          throwsUnsupportedError);
      expect(() => ex.instructions.add('extra'), throwsUnsupportedError);
      expect(() => ex.commonMistakes.add('extra'), throwsUnsupportedError);
      expect(() => ex.tags.add('extra'), throwsUnsupportedError);
    });
  });

  group('Validation', () {
    test('a valid reps exercise has no problems', () {
      expect(validRepsExercise().validate(), isEmpty);
      expect(validRepsExercise().isValid, isTrue);
    });

    test('a valid timed exercise has no problems', () {
      expect(validTimedExercise().validate(), isEmpty);
      expect(validTimedExercise().isValid, isTrue);
    });

    test('an empty id is invalid', () {
      final ex = Exercise(
        id: '',
        name: 'Plank',
        difficulty: ExerciseDifficulty.level1,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.timed,
        defaultDuration: const Duration(seconds: 20),
      );

      expect(ex.validate(), contains('id must not be empty'));
      expect(ex.isValid, isFalse);
    });

    test('an empty name is invalid', () {
      final ex = Exercise(
        id: 'plank_standard',
        name: '',
        difficulty: ExerciseDifficulty.level1,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.timed,
        defaultDuration: const Duration(seconds: 20),
      );

      expect(ex.validate(), contains('name must not be empty'));
      expect(ex.isValid, isFalse);
    });

    test('a negative progression rank is invalid', () {
      final ex = Exercise(
        id: 'pushup_standard',
        name: 'Standard push-up',
        difficulty: ExerciseDifficulty.level2,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.high,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.reps,
        defaultReps: 12,
        progressionRank: -1,
      );

      expect(ex.validate(), contains('progressionRank must not be negative'));
      expect(ex.isValid, isFalse);
    });

    test('a reps exercise without defaultReps is invalid', () {
      final ex = Exercise(
        id: 'pushup_standard',
        name: 'Standard push-up',
        difficulty: ExerciseDifficulty.level2,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.high,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.reps,
      );

      expect(
        ex.validate(),
        contains('a reps exercise requires a positive defaultReps'),
      );
      expect(ex.isValid, isFalse);
    });

    test('a timed exercise without defaultDuration is invalid', () {
      final ex = Exercise(
        id: 'plank_standard',
        name: 'Standard plank',
        difficulty: ExerciseDifficulty.level1,
        impactLevel: ImpactLevel.low,
        noiseLevel: NoiseLevel.quiet,
        spaceRequirement: SpaceRequirement.small,
        wristLoad: JointLoad.none,
        kneeLoad: JointLoad.none,
        exerciseType: ExerciseType.timed,
      );

      expect(
        ex.validate(),
        contains('a timed exercise requires a positive defaultDuration'),
      );
      expect(ex.isValid, isFalse);
    });
  });
}
