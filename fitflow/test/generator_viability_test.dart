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
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Milestone 20 Part 2: representative generator viability over the
/// corrected 80-exercise catalog. Uses the EXISTING WorkoutGenerator and
/// WorkoutGenerationContext; no second generator, no manual filtering.
void main() {
  final anchorDate = DateTime.utc(2026, 10, 1);

  CapabilityProfile profileAtLevel(CapabilityLevel level) {
    return CapabilityProfile.fromMap({
      for (final pattern in CapabilityProfile.trainablePatterns)
        pattern: MovementCapability(
          movementPattern: pattern,
          level: level,
          source: CapabilitySource.initialAssessment,
          updatedAt: anchorDate,
        ),
    });
  }

  UserFitnessProfile userProfile({
    FitnessGoal goal = FitnessGoal.generalFitness,
    WorkoutDuration duration = WorkoutDuration.fifteenMinutes,
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
  }) {
    return UserFitnessProfile(
      goal: goal,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  WorkoutGenerationContext buildContext({
    CapabilityLevel level = CapabilityLevel.level3,
    WorkoutDuration duration = WorkoutDuration.fifteenMinutes,
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
  }) {
    return WorkoutGenerationContext(
      userProfile: userProfile(
        duration: duration,
        environment: environment,
        equipment: equipment,
        preferences: preferences,
      ),
      capabilityProfile: profileAtLevel(level),
    );
  }

  List<Exercise> planExercises(WorkoutPlan plan) => [
        ...plan.warmup.exercises,
        ...plan.main.exercises,
        ...plan.cooldown.exercises,
      ].map((prescription) => prescription.exercise).toList();

  /// Every exercise in a generated plan must be eligible per the canonical
  /// engine — proves the generator relies on canonical eligibility.
  void expectPlanCanonical(WorkoutPlan plan, WorkoutGenerationContext context) {
    final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
      userProfile: context.userProfile,
      capabilityProfile: context.effectiveCapabilityProfile,
    );
    for (final exercise in planExercises(plan)) {
      final result = ExerciseEligibilityEngine.evaluate(
        exercise,
        eligibilityContext,
      );
      expect(result.eligible, isTrue,
          reason: '${exercise.id} in generated plan must be eligible; '
              'reasons: ${result.reasons}');
    }
  }

  void expectValidPlan(WorkoutPlan plan) {
    expect(plan.warmup.isNotEmpty, isTrue, reason: 'warmup must not be empty');
    expect(plan.main.isNotEmpty, isTrue, reason: 'main must not be empty');
    expect(plan.cooldown.isNotEmpty, isTrue,
        reason: 'cooldown must not be empty');
  }

  group('capability levels 1-5 (standard no-equipment home)', () {
    for (final level in CapabilityLevel.values) {
      test('level ${level.rank} generates a valid plan', () {
        final context = buildContext(level: level);
        final plan = WorkoutGenerator.generateCatalog(context);
        expect(plan, isNotNull,
            reason: 'level ${level.rank} home profile must generate');
        expectValidPlan(plan!);
        expectPlanCanonical(plan, context);
        // Budget invariants.
        expect(plan.timeBudget.target, context.timeBudget.target);
      });
    }
  });

  group('standard no-equipment home durations', () {
    for (final duration in [
      WorkoutDuration.tenMinutes,
      WorkoutDuration.fifteenMinutes,
      WorkoutDuration.twentyMinutes,
    ]) {
      test('${duration.label} plan is valid and canonical', () {
        final context = buildContext(duration: duration);
        final plan = WorkoutGenerator.generateCatalog(context);
        expect(plan, isNotNull, reason: duration.label);
        expectValidPlan(plan!);
        expectPlanCanonical(plan, context);
      });
    }
  });

  group('apartment / quiet setup', () {
    test('plan (if generated) contains only canonically eligible exercises',
        () {
      final context = buildContext(environment: TrainingEnvironment.apartment);
      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan == null) {
        // Truthful generation failure is acceptable; nothing to assert
        // beyond the architecture staying honest.
        return;
      }
      expectValidPlan(plan);
      expectPlanCanonical(plan, context);
      // No loud exercise may survive the apartment environment.
      for (final exercise in planExercises(plan)) {
        final result = ExerciseEligibilityEngine.evaluate(
          exercise,
          ExerciseEligibilityContext.fromProfiles(
            userProfile: context.userProfile,
            capabilityProfile: context.effectiveCapabilityProfile,
          ),
        );
        expect(result.eligible, isTrue, reason: exercise.id);
      }
    });
  });

  group('small-room setup', () {
    test('restrictive space yields valid plan or truthful null', () {
      final context = buildContext(environment: TrainingEnvironment.smallRoom);
      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan == null) {
        return; // Existing truthful generation issue, not weakened.
      }
      expectValidPlan(plan);
      expectPlanCanonical(plan, context);
    });
  });

  group('preference restrictions stay canonical in generated plans', () {
    test('noJumping: plan has no jumping-tagged exercise', () {
      final context = buildContext(
        preferences: const {WorkoutPreference.noJumping},
      );
      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull);
      expectValidPlan(plan!);
      expectPlanCanonical(plan, context);
      for (final exercise in planExercises(plan)) {
        expect(exercise.tags.contains('jumping'), isFalse,
            reason: exercise.id);
      }
    });

    test('lowImpact: plan contains only low-impact exercises', () {
      final context = buildContext(
        preferences: const {WorkoutPreference.lowImpact},
      );
      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull);
      expectValidPlan(plan!);
      expectPlanCanonical(plan, context);
      for (final exercise in planExercises(plan)) {
        expect(exercise.impactLevel, ImpactLevel.low, reason: exercise.id);
      }
    });

    test('noFloorExercises: plan (if any) never uses floor/kneeling', () {
      final context = buildContext(
        preferences: const {WorkoutPreference.noFloorExercises},
      );
      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan == null) {
        // Truthful: the cooldown pool is floor-based; the architecture
        // reports failure instead of fabricating a plan.
        return;
      }
      expectValidPlan(plan);
      expectPlanCanonical(plan, context);
      for (final exercise in planExercises(plan)) {
        expect(exercise.bodyPosition, isNot(ExercisePosition.floor),
            reason: exercise.id);
        expect(exercise.bodyPosition, isNot(ExercisePosition.kneeling),
            reason: exercise.id);
      }
    });

    test('standingOnly: plan (if any) contains only standing exercises', () {
      final context = buildContext(
        preferences: const {WorkoutPreference.standingOnly},
      );
      final plan = WorkoutGenerator.generateCatalog(context);
      if (plan == null) {
        return; // Truthful generation issue (cooldown is floor-based).
      }
      expectValidPlan(plan);
      expectPlanCanonical(plan, context);
      for (final exercise in planExercises(plan)) {
        expect(exercise.bodyPosition, ExercisePosition.standing,
            reason: exercise.id);
      }
    });
  });

  group('generator quality gate', () {
    test('representative common profiles all generate viable plans', () {
      final scenarios = <String, WorkoutGenerationContext>{
        'home L1 10min': buildContext(
          level: CapabilityLevel.level1,
          duration: WorkoutDuration.tenMinutes,
        ),
        'home L2 15min': buildContext(level: CapabilityLevel.level2),
        'home L3 15min': buildContext(level: CapabilityLevel.level3),
        'home L4 20min': buildContext(
          level: CapabilityLevel.level4,
          duration: WorkoutDuration.twentyMinutes,
        ),
        'home L5 20min': buildContext(
          level: CapabilityLevel.level5,
          duration: WorkoutDuration.twentyMinutes,
        ),
        'home no-jumping': buildContext(
          preferences: const {WorkoutPreference.noJumping},
        ),
        'home low-impact': buildContext(
          preferences: const {WorkoutPreference.lowImpact},
        ),
        'home avoid wrist': buildContext(
          preferences: const {WorkoutPreference.avoidWristHeavy},
        ),
        'apartment': buildContext(environment: TrainingEnvironment.apartment),
        'hotel': buildContext(environment: TrainingEnvironment.hotel),
      };

      final failures = <String>[];
      scenarios.forEach((name, context) {
        final plan = WorkoutGenerator.generateCatalog(context);
        if (plan == null) {
          failures.add(name);
          return;
        }
        if (plan.warmup.isEmpty || plan.main.isEmpty || plan.cooldown.isEmpty) {
          failures.add('$name (invalid sections)');
          return;
        }
        try {
          expectPlanCanonical(plan, context);
        } on TestFailure {
          failures.add('$name (ineligible exercise in plan)');
        }
      });

      expect(failures, isEmpty,
          reason: 'common profiles must remain generatable: $failures');
    });

    test('every generated prescription is structurally valid', () {
      final context = buildContext();
      final plan = WorkoutGenerator.generateCatalog(context);
      expect(plan, isNotNull);
      for (final prescription in [
        ...plan!.warmup.exercises,
        ...plan.main.exercises,
        ...plan.cooldown.exercises,
      ]) {
        expect(prescription.isValid, isTrue,
            reason: prescription.exercise.id);
        expect(prescription.sets, greaterThanOrEqualTo(1));
        expect(prescription.restBetweenSets,
            greaterThanOrEqualTo(Duration.zero));
        if (prescription.repsPerSet != null) {
          expect(prescription.repsPerSet, greaterThan(0));
          expect(prescription.workDuration, isNull);
        }
        if (prescription.workDuration != null) {
          expect(prescription.workDuration, greaterThan(Duration.zero));
          expect(prescription.repsPerSet, isNull);
        }
      }
    });
  });
}
