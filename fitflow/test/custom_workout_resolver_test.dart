import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

UserFitnessProfile _defaultUserProfile() {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.completelyNew,
    workoutDuration: WorkoutDuration.fifteenMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
  );
}

CapabilityProfile _defaultCapabilityProfile() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final pattern in CapabilityProfile.trainablePatterns) {
    map[pattern] = MovementCapability(
      movementPattern: pattern,
      level: CapabilityLevel.level3,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

CapabilityProfile _lowSquatProfile() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final pattern in CapabilityProfile.trainablePatterns) {
    map[pattern] = MovementCapability(
      movementPattern: pattern,
      level: pattern == MovementPattern.squat ? CapabilityLevel.level1 : CapabilityLevel.level3,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

CustomWorkoutTemplate _validTemplate({
  List<CustomWorkoutExerciseEntry>? warmup,
  List<CustomWorkoutExerciseEntry>? main,
  List<CustomWorkoutExerciseEntry>? cooldown,
  WorkoutDuration target = WorkoutDuration.fifteenMinutes,
}) {
  final now = DateTime.now().toUtc();
  return CustomWorkoutTemplate(
    id: 'custom_1_0',
    name: 'Valid',
    targetDuration: target,
    createdAt: now,
    updatedAt: now,
    warmup: warmup ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'march_in_place',
            sets: 1,
            workDuration: const Duration(seconds: 30),
            restBetweenSets: const Duration(seconds: 15),
          )
        ],
    main: main ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'squat_bodyweight',
            sets: 2,
            repsPerSet: 10,
            restBetweenSets: const Duration(seconds: 30),
          )
        ],
    cooldown: cooldown ??
        [
          CustomWorkoutExerciseEntry(
            exerciseId: 'cobra_stretch',
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: const Duration(seconds: 0),
          )
        ],
  );
}

void main() {
  final catalogById = {for (final Exercise e in ExerciseCatalog.all) e.id: e};

  group('CustomWorkoutPlanResolver', () {
    test('valid template returns WorkoutPlan', () {
      final template = _validTemplate();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNotNull);
      expect(res.issues, isEmpty);
      expect(res.isValid, true);
    });

    test('sections preserved', () {
      final template = _validTemplate();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.warmup.exerciseCount, 1);
      expect(res.plan!.main.exerciseCount, 1);
      expect(res.plan!.cooldown.exerciseCount, 1);
    });

    test('target duration preserved', () {
      final template = _validTemplate(target: WorkoutDuration.thirtyMinutes);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.targetDuration.inMinutes, template.targetDuration.minutes);
    });

    test('reps preserved', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 3,
        repsPerSet: 12,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.main.exercises.first.repsPerSet, 12);
      expect(res.plan!.main.exercises.first.sets, 3);
    });

    test('timed preserved', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'march_in_place',
        sets: 2,
        workDuration: const Duration(seconds: 45),
        restBetweenSets: const Duration(seconds: 15),
      );
      final template = _validTemplate(warmup: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.warmup.exercises.first.workDuration!.inSeconds, 45);
    });

    test('rest preserved', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 2,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 60),
      );
      final template = _validTemplate(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.main.exercises.first.restBetweenSets.inSeconds, 60);
    });

    test('order preserved', () {
      final warmup = [
        CustomWorkoutExerciseEntry(
            exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero),
        CustomWorkoutExerciseEntry(
            exerciseId: 'arm_circles', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero),
      ];
      final template = _validTemplate(warmup: warmup);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan!.warmup.exercises[0].exercise.id, 'march_in_place');
      expect(res.plan!.warmup.exercises[1].exercise.id, 'arm_circles');
    });

    test('missing exercise returns issue', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'nonexistent',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.contains('not found')), true);
    });

    test('inactive exercise returns issue', () {
      final inactiveEx = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final inactiveCopy = Exercise(
        id: inactiveEx.id,
        name: inactiveEx.name,
        movementPattern: inactiveEx.movementPattern,
        difficulty: inactiveEx.difficulty,
        impactLevel: inactiveEx.impactLevel,
        noiseLevel: inactiveEx.noiseLevel,
        spaceRequirement: inactiveEx.spaceRequirement,
        wristLoad: inactiveEx.wristLoad,
        kneeLoad: inactiveEx.kneeLoad,
        exerciseType: inactiveEx.exerciseType,
        defaultReps: inactiveEx.defaultReps,
        defaultDuration: inactiveEx.defaultDuration,
        defaultRest: inactiveEx.defaultRest,
        active: false,
      );
      final modifiedCatalog = Map<String, Exercise>.from(catalogById);
      modifiedCatalog[inactiveCopy.id] = inactiveCopy;

      final template = _validTemplate();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: modifiedCatalog,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.contains('no longer available')), true);
    });

    test('wrong section returns issue', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(warmup: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.contains('does not belong')), true);
    });

    test('above capability returns issue', () {
      final template = _validTemplate();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _lowSquatProfile(),
      );
      // squat_bodyweight level2, capability level1 -> above capability
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.contains('not eligible')), true);
    });

    test('missing equipment returns issue', () {
      final userProfile = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none},
      );
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'pushup_incline',
        sets: 1,
        repsPerSet: 8,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile,
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
    });

    test('environment returns issue via eligibility', () {
      final userProfile = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: {WorkoutEquipment.none, WorkoutEquipment.bench, WorkoutEquipment.chair, WorkoutEquipment.towel},
      );
      final entry2 = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_split_bulgarian',
        sets: 1,
        repsPerSet: 6,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(main: [entry2]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile,
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
    });

    test('preference returns issue placeholder does not crash', () {
      final userProfile = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none, WorkoutEquipment.bench, WorkoutEquipment.chair, WorkoutEquipment.towel},
        preferences: {WorkoutPreference.noFloorExercises},
      );
      final template = _validTemplate();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: userProfile,
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan != null || res.issues.isNotEmpty, true);
    });

    test('duplicate returns invalid', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template = _validTemplate(main: [entry, entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.contains('Duplicate')), true);
    });

    test('original profile not mutated', () {
      final capabilityProfile = _defaultCapabilityProfile();
      final originalCapCount = capabilityProfile.capabilities.length;
      final template = _validTemplate();
      CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: capabilityProfile,
      );
      expect(capabilityProfile.capabilities.length, originalCapCount);
    });

    test('deterministic same inputs same output', () {
      final template = _validTemplate();
      final res1 = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      final res2 = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res1.plan!.allPrescriptions.length, res2.plan!.allPrescriptions.length);
      expect(res1.plan!.allPrescriptions[0].exercise.id, res2.plan!.allPrescriptions[0].exercise.id);
    });

    test('over-target still valid if plan valid', () {
      final uniqueMain = [
        CustomWorkoutExerciseEntry(
            exerciseId: 'squat_bodyweight', sets: 3, repsPerSet: 15, restBetweenSets: const Duration(seconds: 60)),
        CustomWorkoutExerciseEntry(
            exerciseId: 'pushup_standard', sets: 3, repsPerSet: 10, restBetweenSets: const Duration(seconds: 60)),
        CustomWorkoutExerciseEntry(
            exerciseId: 'lunge_reverse', sets: 3, repsPerSet: 8, restBetweenSets: const Duration(seconds: 60)),
        CustomWorkoutExerciseEntry(
            exerciseId: 'bridge_glute', sets: 3, repsPerSet: 12, restBetweenSets: const Duration(seconds: 60)),
        CustomWorkoutExerciseEntry(
            exerciseId: 'bird_dog', sets: 3, repsPerSet: 8, restBetweenSets: const Duration(seconds: 60)),
      ];
      final template = _validTemplate(main: uniqueMain, target: WorkoutDuration.fifteenMinutes);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalogById,
        userFitnessProfile: _defaultUserProfile(),
        capabilityProfile: _defaultCapabilityProfile(),
      );
      expect(res.plan, isNotNull);
      expect(res.plan!.isValid, true);
    });
  });
}
