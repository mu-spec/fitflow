import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// M21 Part 1 §12/§24: performance work must not change generator semantics.
///
/// For representative M20 contexts, independent generations must produce
/// byte-identical canonical plan snapshots: same section exercise IDs, same
/// sets/reps/durations/rest, same budget target, same ordering.
void main() {
  final anchorDate = DateTime.utc(2026, 10, 2);

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
    TrainingEnvironment environment = TrainingEnvironment.normalHome,
    Set<WorkoutEquipment> equipment = const {WorkoutEquipment.none},
    Set<WorkoutPreference> preferences = const {},
    WorkoutDuration duration = WorkoutDuration.twentyMinutes,
  }) {
    return UserFitnessProfile(
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.regularTraining,
      workoutDuration: duration,
      environment: environment,
      equipment: equipment,
      preferences: preferences,
    );
  }

  /// Canonical, comparable snapshot of a generated plan.
  List<String> snapshot(WorkoutPlan plan) {
    final lines = <String>[];
    void section(String label, List prescriptions) {
      for (final p in prescriptions) {
        lines.add(
          '$label:${p.exercise.id}|sets=${p.sets}|reps=${p.repsPerSet}'
          '|work=${p.workDuration?.inSeconds}|rest=${p.restBetweenSets.inSeconds}',
        );
      }
    }

    section('warmup', plan.warmup.exercises);
    section('main', plan.main.exercises);
    section('cooldown', plan.cooldown.exercises);
    lines.add('budget=${plan.timeBudget.target.inSeconds}');
    return lines;
  }

  void expectDeterministic(String label, WorkoutPlan? first, WorkoutPlan? second) {
    expect(first, isNotNull, reason: '$label must remain viable');
    expect(second, isNotNull, reason: '$label must remain viable');
    expect(snapshot(second!), snapshot(first!),
        reason: '$label generation must be identical across independent runs');
  }

  test('standard no-equipment home is deterministic', () {
    final context = WorkoutGenerationContext(
      userProfile: userProfile(),
      capabilityProfile: profileAtLevel(CapabilityLevel.level3),
    );
    expectDeterministic(
      'standard no-equipment home',
      WorkoutGenerator.generateCatalog(context),
      WorkoutGenerator.generateCatalog(context),
    );
  });

  test('dumbbell-equipped home is deterministic', () {
    final context = WorkoutGenerationContext(
      userProfile: userProfile(
        equipment: const {
          WorkoutEquipment.none,
          WorkoutEquipment.dumbbells,
        },
      ),
      capabilityProfile: profileAtLevel(CapabilityLevel.level4),
    );
    expectDeterministic(
      'dumbbell-equipped home',
      WorkoutGenerator.generateCatalog(context),
      WorkoutGenerator.generateCatalog(context),
    );
  });

  test('apartment with no jumping is deterministic', () {
    final context = WorkoutGenerationContext(
      userProfile: userProfile(
        environment: TrainingEnvironment.apartment,
        preferences: const {WorkoutPreference.noJumping},
      ),
      capabilityProfile: profileAtLevel(CapabilityLevel.level3),
    );
    expectDeterministic(
      'apartment no-jumping',
      WorkoutGenerator.generateCatalog(context),
      WorkoutGenerator.generateCatalog(context),
    );
  });

  test('standing-only preference is deterministic (plan or truthful issue)',
      () {
    // Standing-only may truthfully fail generation (cooldown content is
    // floor-based). The contract here is determinism: independent runs must
    // agree, whether both produce a plan or both report no plan.
    final context = WorkoutGenerationContext(
      userProfile: userProfile(
        preferences: const {WorkoutPreference.standingOnly},
      ),
      capabilityProfile: profileAtLevel(CapabilityLevel.level3),
    );
    final first = WorkoutGenerator.generateCatalog(context);
    final second = WorkoutGenerator.generateCatalog(context);
    if (first == null) {
      expect(second, isNull,
          reason: 'standing-only outcome must be deterministic');
      return;
    }
    expectDeterministic('standing-only', first, second);
  });

  test('Program generation context is deterministic', () {
    final definition = AdaptiveProgramCatalog.byId(
      AdaptiveProgramCatalog.balancedFoundationsId,
    )!;
    final session = definition.sessions.first;
    final profile = userProfile();
    final capability = profileAtLevel(CapabilityLevel.level2);

    final first = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: profile,
      capabilityProfile: capability,
    );
    final second = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: profile,
      capabilityProfile: capability,
    );

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expectDeterministic('program session', first.plan, second.plan);
  });
}
