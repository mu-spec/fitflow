import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_engine.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile profileAt(CapabilityLevel level) {
  final now = DateTime.utc(2026, 1, 1);
  return CapabilityProfile.fromMap({
    for (final pattern in CapabilityProfile.trainablePatterns)
      pattern: MovementCapability(
        movementPattern: pattern,
        level: level,
        source: CapabilitySource.initialAssessment,
        updatedAt: now,
      ),
  });
}

UserFitnessProfile userProfile({
  Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
  TrainingEnvironment environment = TrainingEnvironment.largeRoom,
}) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: environment,
    equipment: equipment,
    preferences: const {},
  );
}

Exercise mobilityExercise({
  required String id,
  required String name,
  required Set<MuscleGroup> primaryMuscles,
  Set<MuscleGroup> secondaryMuscles = const {},
  Set<String> tags = const {'bodyweight', 'mobility'},
  ExerciseDifficulty difficulty = ExerciseDifficulty.level1,
  ExerciseType exerciseType = ExerciseType.timed,
  Set<WorkoutEquipment> requiredEquipment = const {WorkoutEquipment.none},
  SpaceRequirement spaceRequirement = SpaceRequirement.small,
  NoiseLevel noiseLevel = NoiseLevel.quiet,
  ExercisePosition bodyPosition = ExercisePosition.standing,
}) {
  return Exercise(
    id: id,
    name: name,
    movementPattern: MovementPattern.mobility,
    difficulty: difficulty,
    primaryMuscles: primaryMuscles,
    secondaryMuscles: secondaryMuscles,
    requiredEquipment: requiredEquipment,
    bodyPosition: bodyPosition,
    impactLevel: ImpactLevel.low,
    noiseLevel: noiseLevel,
    spaceRequirement: spaceRequirement,
    wristLoad: JointLoad.none,
    kneeLoad: JointLoad.none,
    exerciseType: exerciseType,
    defaultReps: exerciseType == ExerciseType.reps ? 8 : null,
    defaultDuration:
        exerciseType == ExerciseType.timed ? const Duration(seconds: 30) : null,
    defaultRest: const Duration(seconds: 15),
    tags: tags,
  );
}

WorkoutExercisePrescription prescribe(
  Exercise exercise, {
  int sets = 2,
  int? reps,
  Duration? duration,
  Duration rest = const Duration(seconds: 20),
}) {
  return WorkoutExercisePrescription(
    exercise: exercise,
    sets: sets,
    repsPerSet: exercise.exerciseType == ExerciseType.reps
        ? (reps ?? exercise.defaultReps)
        : null,
    workDuration: exercise.exerciseType == ExerciseType.timed
        ? (duration ?? exercise.defaultDuration)
        : null,
    restBetweenSets: rest,
  );
}

List<WorkoutReplacementOption> alternatives({
  required WorkoutExercisePrescription current,
  required UserFitnessProfile user,
  required CapabilityProfile capability,
  List<Exercise>? catalog,
  Set<String> elsewhere = const {},
}) {
  return WorkoutReplacementEngine.getAlternatives(
    currentPrescription: current,
    eligibilityContext: ExerciseEligibilityContext.fromProfiles(
      userProfile: user,
      capabilityProfile: capability,
    ),
    userProfile: user,
    capabilityProfile: capability,
    effectiveExerciseIdsElsewhere: elsewhere,
    catalog: catalog,
  );
}

void main() {
  final permissiveUser = userProfile();
  final fullCapability = profileAt(CapabilityLevel.level5);

  group('A/B mobility pattern is not same movement focus', () {
    test('Arm Circles does not resolve to Hip Flexor Stretch', () {
      final current = ExerciseCatalog.byId('arm_circles')!;
      final options = alternatives(
        current: prescribe(current),
        user: permissiveUser,
        capability: fullCapability,
      );

      expect(
        options.map((option) => option.exercise.id),
        isNot(contains('hip_flexor_stretch')),
      );
      expect(options, isEmpty,
          reason:
              'no shoulder-mobility peer exists; do not invent same movement focus');
    });

    test(
        'Arm Circles does not resolve to Standing Hamstring Stretch '
        'merely because both are mobility', () {
      final current = ExerciseCatalog.byId('arm_circles')!;
      final options = alternatives(
        current: prescribe(current),
        user: permissiveUser,
        capability: fullCapability,
      );

      expect(
        options.map((option) => option.exercise.id),
        isNot(contains('hamstring_stretch_standing')),
      );
    });

    test('secondary-muscle overlap and generic stretch tags do not match', () {
      final armCircles = ExerciseCatalog.byId('arm_circles')!;
      final options = alternatives(
        current: prescribe(armCircles),
        user: permissiveUser,
        capability: fullCapability,
        catalog: [
          armCircles,
          ExerciseCatalog.byId('childs_pose')!,
          ExerciseCatalog.byId('hip_flexor_stretch')!,
          ExerciseCatalog.byId('hamstring_stretch_standing')!,
          ExerciseCatalog.byId('cobra_stretch')!,
        ],
      );

      expect(options, isEmpty);
    });

    test('static_stretch alone does not bridge different joints', () {
      final hip = mobilityExercise(
        id: 'hip_only',
        name: 'Hip Only',
        primaryMuscles: {MuscleGroup.hipFlexors},
        tags: {'bodyweight', 'static_stretch', 'mobility'},
      );
      final hamstring = mobilityExercise(
        id: 'hamstring_only',
        name: 'Hamstring Only',
        primaryMuscles: {MuscleGroup.hamstrings},
        tags: {'bodyweight', 'static_stretch', 'mobility'},
      );

      final options = alternatives(
        current: prescribe(hip),
        user: permissiveUser,
        capability: fullCapability,
        catalog: [hip, hamstring],
      );

      expect(options, isEmpty);
    });
  });

  group('C relevant same-purpose replacements stay selectable', () {
    test('Hip Flexor Stretch can still resolve to Figure-Four Stretch', () {
      final current = ExerciseCatalog.byId('hip_flexor_stretch')!;
      final options = alternatives(
        current:
            prescribe(current, sets: 3, duration: const Duration(seconds: 25)),
        user: permissiveUser,
        capability: fullCapability,
      );
      final ids = options.map((option) => option.exercise.id).toList();

      expect(ids, contains('figure_four_stretch'));
      expect(ids, isNot(contains('arm_circles')));
      expect(ids, isNot(contains('hamstring_stretch_standing')));
      for (final option in options) {
        expect(option.reasons,
            contains(WorkoutReplacementReason.sameMovementFocus));
        expect(option.exercise.movementPattern, MovementPattern.mobility);
        expect(option.exercise.exerciseType, ExerciseType.timed);
      }
    });

    test('a shoulder-mobility peer is selected when the catalog has one', () {
      final current = ExerciseCatalog.byId('arm_circles')!;
      final shoulderPeer = mobilityExercise(
        id: 'shoulder_opener',
        name: 'Shoulder Opener',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'bodyweight', 'mobility', 'warmup', 'shoulder_mobility'},
      );
      final hip = ExerciseCatalog.byId('hip_flexor_stretch')!;
      final hamstring = ExerciseCatalog.byId('hamstring_stretch_standing')!;

      final options = alternatives(
        current: prescribe(current),
        user: permissiveUser,
        capability: fullCapability,
        catalog: [current, shoulderPeer, hip, hamstring],
      );

      expect(options.map((option) => option.exercise.id), ['shoulder_opener']);
      expect(
        options.single.reasons,
        contains(WorkoutReplacementReason.sameMovementFocus),
      );
    });

    test('warmup and cooldown roles do not share movement focus', () {
      final current = ExerciseCatalog.byId('arm_circles')!;
      final cooldownShoulders = mobilityExercise(
        id: 'cooldown_shoulder_stretch',
        name: 'Cooldown Shoulder Stretch',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'bodyweight', 'shoulder_mobility', 'cooldown'},
      );

      final options = alternatives(
        current: prescribe(current),
        user: permissiveUser,
        capability: fullCapability,
        catalog: [current, cooldownShoulders],
      );

      expect(options, isEmpty);
    });
  });

  group('D equipment filtering still applies', () {
    test('a same-focus candidate is excluded without its equipment', () {
      final current = mobilityExercise(
        id: 'arm_circles_bodyweight',
        name: 'Arm Circles',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility', 'warmup'},
      );
      final banded = mobilityExercise(
        id: 'banded_shoulder_circles',
        name: 'Banded Shoulder Circles',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility', 'warmup'},
        requiredEquipment: {WorkoutEquipment.resistanceBands},
      );
      final user = userProfile(equipment: {WorkoutEquipment.none});

      final options = alternatives(
        current: prescribe(current),
        user: user,
        capability: fullCapability,
        catalog: [current, banded],
      );

      expect(options, isEmpty);
    });

    test('the same candidate is selectable when equipment is available', () {
      final current = mobilityExercise(
        id: 'arm_circles_bodyweight',
        name: 'Arm Circles',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility', 'warmup'},
      );
      final banded = mobilityExercise(
        id: 'banded_shoulder_circles',
        name: 'Banded Shoulder Circles',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility', 'warmup'},
        requiredEquipment: {WorkoutEquipment.resistanceBands},
      );
      final user = userProfile(
        equipment: {
          WorkoutEquipment.none,
          WorkoutEquipment.resistanceBands,
        },
      );

      final options = alternatives(
        current: prescribe(current),
        user: user,
        capability: fullCapability,
        catalog: [current, banded],
      );

      expect(options.map((option) => option.exercise.id),
          ['banded_shoulder_circles']);
    });
  });

  group('E capability filtering still applies', () {
    test('above-capability same-focus candidates are excluded', () {
      final current = mobilityExercise(
        id: 'shoulder_flow',
        name: 'Shoulder Flow',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        difficulty: ExerciseDifficulty.level3,
      );
      final easy = mobilityExercise(
        id: 'easy_shoulder',
        name: 'Easy Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        difficulty: ExerciseDifficulty.level1,
      );
      final harder = mobilityExercise(
        id: 'harder_shoulder',
        name: 'Harder Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        difficulty: ExerciseDifficulty.level2,
      );

      final options = alternatives(
        current: prescribe(current),
        user: permissiveUser,
        capability: profileAt(CapabilityLevel.level1),
        catalog: [current, easy, harder],
      );

      expect(options.map((option) => option.exercise.id), ['easy_shoulder']);
    });
  });

  group('F environment, noise, and space eligibility still apply', () {
    test(
        'apartment excludes a same-focus candidate that needs more space '
        'or makes more noise', () {
      final current = mobilityExercise(
        id: 'quiet_shoulder',
        name: 'Quiet Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
      );
      final mediumSpace = mobilityExercise(
        id: 'wide_shoulder',
        name: 'Wide Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        spaceRequirement: SpaceRequirement.medium,
      );
      final moderateNoise = mobilityExercise(
        id: 'noisy_shoulder',
        name: 'Noisy Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        noiseLevel: NoiseLevel.moderate,
      );
      final apartment = userProfile(environment: TrainingEnvironment.apartment);

      final crowded = alternatives(
        current: prescribe(current),
        user: apartment,
        capability: fullCapability,
        catalog: [current, mediumSpace],
      );
      final noisy = alternatives(
        current: prescribe(current),
        user: apartment,
        capability: fullCapability,
        catalog: [current, moderateNoise],
      );

      expect(crowded, isEmpty);
      expect(noisy, isEmpty);
    });

    test('a quiet small-space peer remains selectable in an apartment', () {
      final current = mobilityExercise(
        id: 'quiet_shoulder',
        name: 'Quiet Shoulder',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
      );
      final peer = mobilityExercise(
        id: 'quiet_shoulder_peer',
        name: 'Quiet Shoulder Peer',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility'},
        spaceRequirement: SpaceRequirement.small,
        noiseLevel: NoiseLevel.quiet,
      );

      final options = alternatives(
        current: prescribe(current),
        user: userProfile(environment: TrainingEnvironment.hotel),
        capability: fullCapability,
        catalog: [current, peer],
      );

      expect(
          options.map((option) => option.exercise.id), ['quiet_shoulder_peer']);
    });
  });

  group('G workload is preserved', () {
    test('sets, duration, and rest copy from the current prescription', () {
      final current = ExerciseCatalog.byId('arm_circles')!;
      final peer = mobilityExercise(
        id: 'shoulder_opener',
        name: 'Shoulder Opener',
        primaryMuscles: {MuscleGroup.shoulders},
        tags: {'shoulder_mobility', 'warmup'},
        difficulty: ExerciseDifficulty.level1,
      );
      final prescription = prescribe(
        current,
        sets: 4,
        duration: const Duration(seconds: 45),
        rest: const Duration(seconds: 12),
      );

      final option = alternatives(
        current: prescription,
        user: permissiveUser,
        capability: fullCapability,
        catalog: [current, peer],
      ).single;

      expect(option.prescription.sets, 4);
      expect(option.prescription.workDuration, const Duration(seconds: 45));
      expect(option.prescription.restBetweenSets, const Duration(seconds: 12));
      expect(option.prescription.repsPerSet, isNull);
      expect(option.reasons, contains(WorkoutReplacementReason.keepsWorkload));
    });
  });

  group('H non-mobility replacement behavior is unchanged', () {
    test('squat replacements still require the squat pattern and type', () {
      final current = ExerciseCatalog.byId('squat_bodyweight')!;
      final options = alternatives(
        current: prescribe(current, sets: 3, reps: 10),
        user: permissiveUser,
        capability: fullCapability,
      );

      expect(options, isNotEmpty);
      expect(options.length, lessThanOrEqualTo(3));
      for (final option in options) {
        expect(option.exercise.id, isNot(current.id));
        expect(option.exercise.movementPattern, MovementPattern.squat);
        expect(option.exercise.exerciseType, ExerciseType.reps);
        expect(
          option.exercise.difficulty.index <= current.difficulty.index,
          isTrue,
        );
        expect(option.reasons,
            contains(WorkoutReplacementReason.sameMovementFocus));
        expect(option.prescription.sets, 3);
        expect(option.prescription.repsPerSet, 10);
      }
    });

    test('push replacements still require the push pattern and type', () {
      final current = ExerciseCatalog.byId('pushup_standard')!;
      final options = alternatives(
        current: prescribe(current),
        user: userProfile(equipment: {WorkoutEquipment.none}),
        capability: profileAt(CapabilityLevel.level3),
      );

      expect(options, isNotEmpty);
      for (final option in options) {
        expect(option.exercise.movementPattern, MovementPattern.push);
        expect(option.exercise.exerciseType, current.exerciseType);
        expect(
          option.exercise.difficulty.index <= ExerciseDifficulty.level3.index,
          isTrue,
        );
      }
    });
  });
}
