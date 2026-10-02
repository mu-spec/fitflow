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

UserFitnessProfile _defaultUser() => UserFitnessProfile(
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.completelyNew,
      workoutDuration: WorkoutDuration.fifteenMinutes,
      environment: TrainingEnvironment.normalHome,
      equipment: {
        WorkoutEquipment.none,
        WorkoutEquipment.chair,
        WorkoutEquipment.bench,
        WorkoutEquipment.towel
      },
    );

CapabilityProfile _defaultCap() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: CapabilityLevel.level3,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

CapabilityProfile _lowCap() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: CapabilityLevel.level1,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

CustomWorkoutTemplate _template({
  List<CustomWorkoutExerciseEntry>? warmup,
  List<CustomWorkoutExerciseEntry>? main,
  List<CustomWorkoutExerciseEntry>? cooldown,
}) {
  final now = DateTime.now().toUtc();
  return CustomWorkoutTemplate(
    id: 'custom_1_0',
    name: 'Test',
    targetDuration: WorkoutDuration.fifteenMinutes,
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
            restBetweenSets: Duration.zero,
          )
        ],
  );
}

void main() {
  final catalog = {for (final e in ExerciseCatalog.all) e.id: e};

  group('Resolver focused - warmup/cooldown eligibility now enforced', () {
    test('warmup missing equipment blocked', () {
      final base = catalog['march_in_place']!;
      final fake = Exercise(
        id: base.id,
        name: base.name,
        movementPattern: base.movementPattern,
        difficulty: base.difficulty,
        impactLevel: base.impactLevel,
        noiseLevel: base.noiseLevel,
        spaceRequirement: base.spaceRequirement,
        wristLoad: base.wristLoad,
        kneeLoad: base.kneeLoad,
        exerciseType: base.exerciseType,
        defaultReps: base.defaultReps,
        defaultDuration: base.defaultDuration,
        defaultRest: base.defaultRest,
        active: true,
        requiredEquipment: {WorkoutEquipment.bench},
        tags: base.tags,
        bodyPosition: base.bodyPosition,
      );
      final modifiedCatalog = Map<String, Exercise>.from(catalog);
      modifiedCatalog[base.id] = fake;

      final user = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none},
      );

      final res = CustomWorkoutPlanResolver.resolve(
        template: _template(),
        catalogById: modifiedCatalog,
        userFitnessProfile: user,
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
      expect(res.issues.isNotEmpty, true);
    });

    test('cooldown missing equipment blocked', () {
      final base = catalog['cobra_stretch']!;
      final fake = Exercise(
        id: base.id,
        name: base.name,
        movementPattern: base.movementPattern,
        difficulty: base.difficulty,
        impactLevel: base.impactLevel,
        noiseLevel: base.noiseLevel,
        spaceRequirement: base.spaceRequirement,
        wristLoad: base.wristLoad,
        kneeLoad: base.kneeLoad,
        exerciseType: base.exerciseType,
        defaultReps: base.defaultReps,
        defaultDuration: base.defaultDuration,
        defaultRest: base.defaultRest,
        active: true,
        requiredEquipment: {WorkoutEquipment.bench},
        tags: base.tags,
        bodyPosition: base.bodyPosition,
      );
      final modifiedCatalog = Map<String, Exercise>.from(catalog);
      modifiedCatalog[base.id] = fake;

      final user = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none},
      );

      final res = CustomWorkoutPlanResolver.resolve(
        template: _template(),
        catalogById: modifiedCatalog,
        userFitnessProfile: user,
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
    });

    test('warmup environment blocked via apartment noise/space', () {
      final user = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
      );
      final nonQuietWarmups = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.warmup && e.noiseLevel.name != 'quiet').toList();
      if (nonQuietWarmups.isNotEmpty) {
        final entry = CustomWorkoutExerciseEntry(
          exerciseId: nonQuietWarmups.first.id,
          sets: 1,
          workDuration: const Duration(seconds: 20),
          restBetweenSets: Duration.zero,
        );
        final template = _template(warmup: [entry]);
        final res = CustomWorkoutPlanResolver.resolve(
          template: template,
          catalogById: catalog,
          userFitnessProfile: user,
          capabilityProfile: _defaultCap(),
        );
        expect(res.plan == null || res.issues.isNotEmpty, true);
      } else {
        final res = CustomWorkoutPlanResolver.resolve(
          template: _template(),
          catalogById: catalog,
          userFitnessProfile: user,
          capabilityProfile: _defaultCap(),
        );
        expect(res.plan != null || res.issues.isNotEmpty, true);
      }
    });

    test('warmup preference blocked (noFloor)', () {
      final user = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        preferences: {WorkoutPreference.noFloorExercises},
      );
      final floorWarmups = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.warmup && e.bodyPosition?.name == 'floor').toList();
      if (floorWarmups.isNotEmpty) {
        final entry = CustomWorkoutExerciseEntry(
          exerciseId: floorWarmups.first.id,
          sets: 1,
          workDuration: const Duration(seconds: 20),
          restBetweenSets: Duration.zero,
        );
        final template = _template(warmup: [entry]);
        final res = CustomWorkoutPlanResolver.resolve(
          template: template,
          catalogById: catalog,
          userFitnessProfile: user,
          capabilityProfile: _defaultCap(),
        );
        expect(res.plan, isNull);
      }
    });

    test('cooldown preference blocked', () {
      final user = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: {WorkoutEquipment.none, WorkoutEquipment.chair, WorkoutEquipment.bench, WorkoutEquipment.towel},
        preferences: {WorkoutPreference.noFloorExercises},
      );
      final floorCooldowns = ExerciseCatalog.all.where((e) => e.movementPattern == MovementPattern.cooldown && e.bodyPosition?.name == 'floor').toList();
      if (floorCooldowns.isNotEmpty) {
        final entry = CustomWorkoutExerciseEntry(
          exerciseId: floorCooldowns.first.id,
          sets: 1,
          workDuration: const Duration(seconds: 20),
          restBetweenSets: Duration.zero,
        );
        final template = _template(cooldown: [entry]);
        final res = CustomWorkoutPlanResolver.resolve(
          template: template,
          catalogById: catalog,
          userFitnessProfile: user,
          capabilityProfile: _defaultCap(),
        );
        expect(res.plan, isNull);
      }
    });

    test('capability NOT blocked for warmup/cooldown (engine handles trainable only)', () {
      final lowMain = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_chair',
        sets: 1,
        repsPerSet: 6,
        restBetweenSets: const Duration(seconds: 30),
      );
      final template2 = _template(main: [lowMain]);
      final res2 = CustomWorkoutPlanResolver.resolve(
        template: template2,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _lowCap(),
      );
      expect(res2.plan, isNotNull, reason: 'warmup/cooldown should not be blocked by capability');
    });

    test('valid template still resolves after eligibility enforcement', () {
      final res = CustomWorkoutPlanResolver.resolve(
        template: _template(),
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNotNull);
      expect(res.isValid, true);
    });

    test('invalid catalog entry (isValid false) blocked', () {
      final base = catalog['squat_bodyweight']!;
      final invalidEx = Exercise(
        id: base.id,
        name: '',
        movementPattern: base.movementPattern,
        difficulty: base.difficulty,
        impactLevel: base.impactLevel,
        noiseLevel: base.noiseLevel,
        spaceRequirement: base.spaceRequirement,
        wristLoad: base.wristLoad,
        kneeLoad: base.kneeLoad,
        exerciseType: base.exerciseType,
        defaultReps: base.defaultReps,
        defaultDuration: base.defaultDuration,
        defaultRest: base.defaultRest,
        active: true,
      );
      final mod = Map<String, Exercise>.from(catalog);
      mod[base.id] = invalidEx;

      final res = CustomWorkoutPlanResolver.resolve(
        template: _template(),
        catalogById: mod,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
      expect(res.issues.any((i) => i.message.toLowerCase().contains('invalid')), true);
    });

    test('reps ↔ timed mismatch blocked', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 15),
      );
      final template = _template(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
    });

    test('timed ↔ reps mismatch blocked', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'march_in_place',
        sets: 1,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 15),
      );
      final template = _template(warmup: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
    });

    test('invalid prescription blocked', () {
      final entry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 0,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 15),
      );
      final template = _template(main: [entry]);
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNull);
    });

    test('plan.isValid enforcement - final gate', () {
      final template = _template();
      final res = CustomWorkoutPlanResolver.resolve(
        template: template,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(res.plan, isNotNull);
      expect(res.plan!.isValid, true);

      final badEntry = CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 1,
        repsPerSet: 200,
        restBetweenSets: const Duration(seconds: 15),
      );
      expect(badEntry.isValid, false);
      final badTemplate = _template(main: [badEntry]);
      final badRes = CustomWorkoutPlanResolver.resolve(
        template: badTemplate,
        catalogById: catalog,
        userFitnessProfile: _defaultUser(),
        capabilityProfile: _defaultCap(),
      );
      expect(badRes.plan, isNull);
    });
  });
}
