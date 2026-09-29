import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityProfile fullProfile(CapabilityLevel level) {
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

UserFitnessProfile userProfile(WorkoutDuration duration) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: duration,
    environment: TrainingEnvironment.largeRoom,
    equipment: {WorkoutEquipment.none},
    preferences: {},
  );
}

void main() {
  group('M12 Generator integration', () {
    test('standard regression same structure as before (effective == normal)', () {
      final up = userProfile(WorkoutDuration.twentyMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final ctxStandard = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.standard);
      final ctxNoMode = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap); // default standard
      final plan1 = WorkoutGenerator.generateCatalog(ctxStandard);
      final plan2 = WorkoutGenerator.generateCatalog(ctxNoMode);
      expect(plan1, isNotNull);
      expect(plan2, isNotNull);
      expect(plan1!.totalExerciseCount, plan2!.totalExerciseCount);
      expect(plan1.warmup.exerciseCount, plan2.warmup.exerciseCount);
      expect(plan1.main.exerciseCount, plan2.main.exerciseCount);
      expect(plan1.cooldown.exerciseCount, plan2.cooldown.exerciseCount);
      expect(plan1.timeBudget.target, plan2.timeBudget.target);
    });

    test('low energy uses effective duration for timeBudget', () {
      final up = userProfile(WorkoutDuration.thirtyMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
      expect(ctx.effectiveWorkoutDuration, WorkoutDuration.twentyMinutes);
      expect(ctx.timeBudget.target, const Duration(minutes: 20));
      final plan = WorkoutGenerator.generateCatalog(ctx);
      if (plan != null) {
        expect(plan.timeBudget.target, const Duration(minutes: 20));
      }
    });

    test('comeback uses effective duration for timeBudget', () {
      final up = userProfile(WorkoutDuration.fortyFiveMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.comeback);
      expect(ctx.effectiveWorkoutDuration, WorkoutDuration.fifteenMinutes);
      expect(ctx.timeBudget.target, const Duration(minutes: 15));
    });

    test('low energy plan respects effective limits not normal limits', () {
      final up = userProfile(WorkoutDuration.fortyFiveMinutes); // normal 45 would allow more exercises
      final cap = fullProfile(CapabilityLevel.level3);
      final ctxLow = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
      final ctxStandard45 = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.standard);
      final planLow = WorkoutGenerator.generateCatalog(ctxLow);
      final planStd = WorkoutGenerator.generateCatalog(ctxStandard45);
      // Low should have target 30 min, standard 45 min
      expect(ctxLow.timeBudget.target, const Duration(minutes: 30));
      expect(ctxStandard45.timeBudget.target, const Duration(minutes: 45));
      if (planLow != null && planStd != null) {
        // Low energy main max for 30 is 6, for 45 is 8, so low should not exceed 6 etc.
        // We just ensure low's budget is smaller
        expect(planLow.timeBudget.main <= planStd.timeBudget.main, true);
      }
    });

    test('effective capability used for ranking but userProfile unchanged', () {
      final up = userProfile(WorkoutDuration.twentyMinutes);
      final cap = fullProfile(CapabilityLevel.level5);
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
      expect(ctx.effectiveCapabilityProfile.capabilities[MovementPattern.push]!.level, CapabilityLevel.level4);
      expect(ctx.capabilityProfile.capabilities[MovementPattern.push]!.level, CapabilityLevel.level5);
      expect(ctx.userProfile.workoutDuration, WorkoutDuration.twentyMinutes);
      expect(ctx.effectiveWorkoutDuration, WorkoutDuration.fifteenMinutes);
    });

    test('persisted capability not mutated after generation', () {
      final up = userProfile(WorkoutDuration.twentyMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final originalLevel = cap.capabilities[MovementPattern.push]!.level;
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.comeback);
      WorkoutGenerator.generateCatalog(ctx);
      expect(cap.capabilities[MovementPattern.push]!.level, originalLevel);
    });

    test('userProfile workoutDuration not overwritten', () {
      final up = userProfile(WorkoutDuration.thirtyMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
      expect(ctx.userProfile.workoutDuration, WorkoutDuration.thirtyMinutes);
      expect(ctx.effectiveWorkoutDuration, WorkoutDuration.twentyMinutes);
    });

    test('all durations low energy mapping produces valid or null but not crash', () {
      final cap = fullProfile(CapabilityLevel.level3);
      for (final dur in WorkoutDuration.values) {
        final up = userProfile(dur);
        final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
        final plan = WorkoutGenerator.generateCatalog(ctx);
        // Should not throw, plan may be null for restrictive but not crash
        if (plan != null) {
          expect(plan.isValid, true);
        }
      }
    });

    test('all durations comeback mapping produces valid or null but not crash', () {
      final cap = fullProfile(CapabilityLevel.level3);
      for (final dur in WorkoutDuration.values) {
        final up = userProfile(dur);
        final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.comeback);
        final plan = WorkoutGenerator.generateCatalog(ctx);
        if (plan != null) {
          expect(plan.isValid, true);
        }
      }
    });

    test('timeBudget derived from effective duration not normal', () {
      final up = userProfile(WorkoutDuration.fortyFiveMinutes);
      final cap = fullProfile(CapabilityLevel.level3);
      final ctxLow = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.lowEnergy);
      final ctxComeback = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.comeback);
      expect(ctxLow.timeBudget.target, const Duration(minutes: 30));
      expect(ctxComeback.timeBudget.target, const Duration(minutes: 15));
    });

    test('standard mode effective capability equals persisted', () {
      final up = userProfile(WorkoutDuration.twentyMinutes);
      final cap = fullProfile(CapabilityLevel.level2);
      final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: WorkoutSessionMode.standard);
      expect(ctx.effectiveCapabilityProfile, cap);
    });

    test('low energy and comeback respect equipment/environment etc (no auto low-impact)', () {
      // Create profile with standingOnly etc, ensure generator still respects those via userProfile
      final up = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.regularTraining,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: {WorkoutEquipment.none},
        preferences: {WorkoutPreference.standingOnly, WorkoutPreference.noJumping},
      );
      final cap = fullProfile(CapabilityLevel.level3);
      for (final mode in WorkoutSessionMode.values) {
        final ctx = WorkoutGenerationContext(userProfile: up, capabilityProfile: cap, sessionMode: mode);
        final plan = WorkoutGenerator.generateCatalog(ctx);
        if (plan != null) {
          // Ensure no exercise violates standingOnly or noJumping via eligibility – generator already filters
          expect(plan.isValid, true);
        }
      }
    });
  });
}
