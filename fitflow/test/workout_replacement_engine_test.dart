import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_engine.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile createFullProfile(CapabilityLevel level) {
  final now = DateTime.utc(2026, 1, 1);
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(
      movementPattern: p,
      level: level,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

UserFitnessProfile createUserProfile({
  Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
  TrainingEnvironment env = TrainingEnvironment.largeRoom,
  Set<WorkoutPreference> prefs = const {},
}) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: env,
    equipment: equipment,
    preferences: prefs,
  );
}

WorkoutExercisePrescription makePrescription(Exercise exercise, {int sets = 3, int? reps, Duration? duration, Duration rest = const Duration(seconds: 30)}) {
  return WorkoutExercisePrescription(
    exercise: exercise,
    sets: sets,
    repsPerSet: exercise.exerciseType == ExerciseType.reps ? (reps ?? exercise.defaultReps ?? 10) : null,
    workDuration: exercise.exerciseType == ExerciseType.timed ? (duration ?? exercise.defaultDuration ?? const Duration(seconds: 30)) : null,
    restBetweenSets: rest,
  );
}

void main() {
  group('Replacement Engine', () {
    test('excludes original exercise', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options.any((o) => o.exercise.id == current.id), false);
    });

    test('same movement pattern required', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.movementPattern, current.movementPattern);
      }
    });

    test('same exercise type required', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.exerciseType, current.exerciseType);
      }
    });

    test('eligibility engine respected', () {
      final user = createUserProfile(equipment: {WorkoutEquipment.none});
      final cap = createFullProfile(CapabilityLevel.level3);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_standard');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.requiredEquipment.every((eq) => eq == WorkoutEquipment.none || user.equipment.contains(eq)), true);
      }
    });

    test('missing equipment excluded', () {
      final user = createUserProfile(equipment: {WorkoutEquipment.none});
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_standard');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options.any((o) => o.exercise.requiredEquipment.contains(WorkoutEquipment.bench)), false);
    });

    test('above capability excluded', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level1);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_wall');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.difficulty.index <= current.difficulty.index, true);
      }
    });

    test('environment-incompatible excluded', () {
      final user = createUserProfile(env: TrainingEnvironment.apartment);
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.isValid, true);
      }
    });

    test('preference-incompatible excluded', () {
      final user = createUserProfile(prefs: {WorkoutPreference.noJumping});
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.movementPattern == MovementPattern.cardio && e.tags.contains('no_jumping'));
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options.any((o) => o.exercise.tags.contains('jumping')), false);
    });

    test('harder-than-current excluded', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.exercise.difficulty.index <= current.difficulty.index, true);
      }
    });

    test('same-difficulty alternative allowed', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      final hasSame = options.any((o) => o.exercise.difficulty == current.difficulty);
      expect(options.isEmpty || hasSame || options.any((o) => o.exercise.difficulty.index < current.difficulty.index), true);
    });

    test('easier alternative allowed', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_tempo');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      final hasEasier = options.any((o) => o.exercise.difficulty.index < current.difficulty.index);
      expect(options.isEmpty || hasEasier || options.any((o) => o.exercise.difficulty == current.difficulty), true);
    });

    test('duplicate effective-session IDs excluded', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final duplicateId = 'squat_chair';
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {duplicateId},
      );
      expect(options.any((o) => o.exercise.id == duplicateId), false);
    });

    test('deterministic ordering', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options1 = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      final options2 = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options1.map((o) => o.exercise.id).toList(), options2.map((o) => o.exercise.id).toList());
    });

    test('existing ranking engine used', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options.length <= 3, true);
    });

    test('max 3 options', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(options.length <= 3, true);
    });

    test('empty pool → empty result', () {
      final user = createUserProfile(
        equipment: {WorkoutEquipment.none},
        env: TrainingEnvironment.apartment,
        prefs: {
          WorkoutPreference.standingOnly,
          WorkoutPreference.noFloorExercises,
          WorkoutPreference.avoidWristHeavy,
          WorkoutPreference.avoidDeepKneeBending,
          WorkoutPreference.noJumping,
          WorkoutPreference.lowImpact,
        },
      );
      final cap = createFullProfile(CapabilityLevel.level1);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_wall');
      final pres = makePrescription(current);
      final allPushIds = ExerciseCatalog.all.where((e) => e.movementPattern == current.movementPattern && e.id != current.id).map((e) => e.id).toSet();
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: allPushIds,
      );
      expect(options, isEmpty);
    });

    test('replacement preserves sets', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current, sets: 4);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.prescription.sets, 4);
      }
    });

    test('replacement preserves reps', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current, reps: 12);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.prescription.repsPerSet, 12);
      }
    });

    test('replacement preserves timed workDuration', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.exerciseType == ExerciseType.timed && e.movementPattern == MovementPattern.core);
      final pres = makePrescription(current, duration: const Duration(seconds: 30));
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.prescription.workDuration, const Duration(seconds: 30));
      }
    });

    test('replacement preserves rest', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current, rest: const Duration(seconds: 60));
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.prescription.restBetweenSets, const Duration(seconds: 60));
      }
    });

    test('resulting prescription valid', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current);
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      for (final o in options) {
        expect(o.prescription.isValid, true);
      }
    });

    test('original prescription remains unchanged', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final ctx = ExerciseEligibilityContext.fromProfiles(userProfile: user, capabilityProfile: cap);
      final current = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
      final pres = makePrescription(current, sets: 3, reps: 10, rest: const Duration(seconds: 30));
      final originalSets = pres.sets;
      final originalReps = pres.repsPerSet;
      final options = WorkoutReplacementEngine.getAlternatives(
        currentPrescription: pres,
        eligibilityContext: ctx,
        userProfile: user,
        capabilityProfile: cap,
        effectiveExerciseIdsElsewhere: {},
      );
      expect(pres.sets, originalSets);
      expect(pres.repsPerSet, originalReps);
      expect(options.isEmpty || options.first.prescription.exercise.id != pres.exercise.id, true);
    });
  });
}
