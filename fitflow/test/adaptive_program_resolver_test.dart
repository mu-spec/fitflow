import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_generation_profile.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

void main() {
  final balanced = AdaptiveProgramCatalog.balancedFoundations;
  final w1s1 = balanced.sessionById('balanced_foundations_w1_s1')!; // general
  final w1s3 = balanced.sessionById('balanced_foundations_w1_s3')!; // endurance

  UserFitnessProfile richProfile() => UserFitnessProfile(
        goal: FitnessGoal.buildMuscle,
        experience: ExperienceLevel.regularTraining,
        workoutDuration: WorkoutDuration.twentyMinutes,
        environment: TrainingEnvironment.largeRoom,
        equipment: {WorkoutEquipment.chair, WorkoutEquipment.exerciseMat},
        preferences: {WorkoutPreference.noJumping},
      );

  group('AdaptiveProgramGenerationProfile', () {
    test('overrides only goal and preserves everything else', () {
      final current = richProfile();
      final temp = AdaptiveProgramGenerationProfile.forSession(
        current: current,
        session: w1s3,
      );
      expect(temp.goal, FitnessGoal.improveEndurance);
      expect(temp.experience, current.experience);
      expect(temp.workoutDuration, current.workoutDuration);
      expect(temp.environment, current.environment);
      expect(temp.equipment, current.equipment);
      expect(temp.preferences, current.preferences);
      // Original profile untouched.
      expect(current.goal, FitnessGoal.buildMuscle);
      // Returned collections are unmodifiable copies.
      expect(() => temp.equipment.add(WorkoutEquipment.bench),
          throwsUnsupportedError);
      expect(() => temp.preferences.add(WorkoutPreference.lowImpact),
          throwsUnsupportedError);
    });
  });

  group('AdaptiveProgramWorkoutResolver', () {
    test('returns a valid plan for every session of every program', () {
      final profile = skillTreeUserProfile();
      final cap = skillTreeCapabilityProfile();
      for (final def in AdaptiveProgramCatalog.all) {
        for (final session in def.sessions) {
          final res = AdaptiveProgramWorkoutResolver.resolve(
            definition: def,
            session: session,
            userProfile: profile,
            capabilityProfile: cap,
          );
          expect(res.isSuccess, isTrue, reason: session.id);
          expect(res.plan!.isValid, isTrue, reason: session.id);
          expect(res.issue, isNull);
          expect(res.session, session);
        }
      }
    });

    test('uses the existing WorkoutGenerator with Standard mode', () {
      final profile = skillTreeUserProfile();
      final cap = skillTreeCapabilityProfile();
      final res = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s3,
        userProfile: profile,
        capabilityProfile: cap,
      );
      final expectedContext = WorkoutGenerationContext(
        userProfile: AdaptiveProgramGenerationProfile.forSession(
            current: profile, session: w1s3),
        capabilityProfile: cap,
        sessionMode: WorkoutSessionMode.standard,
      );
      final expected = WorkoutGenerator.generateCatalog(expectedContext);
      expect(res.context!.sessionMode, WorkoutSessionMode.standard);
      expect(res.context!.capabilityProfile, cap);
      expect(res.plan, expected);
      expect(res.plan!.timeBudget.target,
          Duration(minutes: profile.workoutDuration.minutes));
    });

    test('goal override is temporary and observable; profile unchanged', () {
      final profile = skillTreeUserProfile(); // goal = generalFitness
      final cap = skillTreeCapabilityProfile();
      final general = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: profile,
        capabilityProfile: cap,
      );
      final endurance = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s3,
        userProfile: profile,
        capabilityProfile: cap,
      );
      expect(general.generationProfile.goal, FitnessGoal.generalFitness);
      expect(endurance.generationProfile.goal, FitnessGoal.improveEndurance);
      // Different session goals produce different plans from the same profile.
      expect(general.plan, isNot(equals(endurance.plan)));
      // Real profile never mutated.
      expect(profile.goal, FitnessGoal.generalFitness);
      expect(endurance.generationProfile, isNot(same(profile)));
    });

    test('duration, environment, equipment and preferences are preserved', () {
      final profile = richProfile();
      final cap = skillTreeCapabilityProfile();
      final res = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: profile,
        capabilityProfile: cap,
      );
      final gp = res.generationProfile;
      expect(gp.workoutDuration, WorkoutDuration.twentyMinutes);
      expect(gp.environment, TrainingEnvironment.largeRoom);
      expect(gp.equipment,
          {WorkoutEquipment.chair, WorkoutEquipment.exerciseMat});
      expect(gp.preferences, {WorkoutPreference.noJumping});
      expect(gp.experience, ExperienceLevel.regularTraining);
      expect(res.context!.effectiveWorkoutDuration,
          WorkoutDuration.twentyMinutes);
    });

    test('M12 Low Energy / Comeback do not affect program plans', () {
      final profile = skillTreeUserProfile();
      final cap = skillTreeCapabilityProfile();
      final res = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: profile,
        capabilityProfile: cap,
      );
      final temp = AdaptiveProgramGenerationProfile.forSession(
          current: profile, session: w1s1);
      final lowEnergy = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(
          userProfile: temp,
          capabilityProfile: cap,
          sessionMode: WorkoutSessionMode.lowEnergy,
        ),
      );
      final comeback = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(
          userProfile: temp,
          capabilityProfile: cap,
          sessionMode: WorkoutSessionMode.comeback,
        ),
      );
      final standard = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(
          userProfile: temp,
          capabilityProfile: cap,
          sessionMode: WorkoutSessionMode.standard,
        ),
      );
      // Sanity: modes really do change generator output in this setup.
      expect(standard, isNot(equals(lowEnergy)));
      expect(standard, isNot(equals(comeback)));
      // Resolver always equals Standard.
      expect(res.plan, standard);
    });

    test('deterministic across repeated calls', () {
      final profile = richProfile();
      final cap = skillTreeCapabilityProfile();
      final a = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s3,
        userProfile: profile,
        capabilityProfile: cap,
      );
      final b = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s3,
        userProfile: profile,
        capabilityProfile: cap,
      );
      expect(a.plan, b.plan);
      expect(a.plan!.allExercises.map((e) => e.id).toList(),
          b.plan!.allExercises.map((e) => e.id).toList());
    });

    test('current capability is used and a change alters future resolution',
        () {
      final profile = skillTreeUserProfile();
      final cap3 = skillTreeCapabilityProfile();
      final cap1 = skillTreeCapabilityProfile(
        levels: const {
          MovementPattern.push: CapabilityLevel.level1,
          MovementPattern.squat: CapabilityLevel.level1,
        },
      );
      final a = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: profile,
        capabilityProfile: cap3,
      );
      final b = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: profile,
        capabilityProfile: cap1,
      );
      expect(a.isSuccess && b.isSuccess, isTrue);
      expect(a.plan, isNot(equals(b.plan)));
      expect(a.context!.capabilityProfile, cap3);
      expect(b.context!.capabilityProfile, cap1);
    });

    test('a changed profile alters future resolution', () {
      final cap = skillTreeCapabilityProfile();
      final short = skillTreeUserProfile();
      final longer = UserFitnessProfile(
        goal: short.goal,
        experience: short.experience,
        workoutDuration: WorkoutDuration.thirtyMinutes,
        environment: short.environment,
      );
      final a = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: short,
        capabilityProfile: cap,
      );
      final b = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: longer,
        capabilityProfile: cap,
      );
      expect(a.plan!.timeBudget.target, const Duration(minutes: 15));
      expect(b.plan!.timeBudget.target, const Duration(minutes: 30));
      expect(a.plan, isNot(equals(b.plan)));
    });

    test('no automatic duration increase by week', () {
      final profile = richProfile();
      final cap = skillTreeCapabilityProfile();
      final strength = AdaptiveProgramCatalog.strengthFoundations;
      for (final session in strength.sessions) {
        final res = AdaptiveProgramWorkoutResolver.resolve(
          definition: strength,
          session: session,
          userProfile: profile,
          capabilityProfile: cap,
        );
        expect(res.plan!.timeBudget.target, const Duration(minutes: 20),
            reason: session.id);
      }
    });

    test('truthful failure when no valid plan exists', () {
      final restrictive = UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.fifteenMinutes,
        environment: TrainingEnvironment.apartment,
        equipment: const {WorkoutEquipment.none},
        preferences: WorkoutPreference.values.toSet(),
      );
      final res = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: w1s1,
        userProfile: restrictive,
        capabilityProfile: skillTreeCapabilityProfile(),
      );
      expect(res.isSuccess, isFalse);
      expect(res.plan, isNull);
      expect(res.issue, AdaptiveProgramWorkoutIssue.noValidPlan);
      expect(res.issue!.message,
          "This program workout can't be generated with your current setup.");
      expect(res.context, isNotNull);
    });

    test('session from another program is rejected truthfully', () {
      final foreign = AdaptiveProgramCatalog.strengthFoundations.sessions.first;
      final res = AdaptiveProgramWorkoutResolver.resolve(
        definition: balanced,
        session: foreign,
        userProfile: skillTreeUserProfile(),
        capabilityProfile: skillTreeCapabilityProfile(),
      );
      expect(res.isSuccess, isFalse);
      expect(res.issue, AdaptiveProgramWorkoutIssue.sessionNotInProgram);
      expect(res.plan, isNull);
      expect(res.context, isNull);
    });
  });
}
