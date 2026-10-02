import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_plan_resolver.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M19 §27 — Active Player stability.
///
/// The Player is keyed by its FROZEN plan. A profile edit outside the Player
/// must never regenerate, reset, or migrate the active session — for
/// adaptive, program, and custom sessions alike. New settings apply to
/// future workouts only.
void main() {
  final testNow = DateTime.utc(2026, 9, 30, 12);

  CapabilityProfile maxCapability() {
    final at = DateTime.utc(2026, 9, 1, 10);
    return CapabilityProfile.fromMap({
      for (final pattern in CapabilityProfile.trainablePatterns)
        pattern: MovementCapability(
          movementPattern: pattern,
          level: CapabilityLevel.values.last,
          source: CapabilitySource.progression,
          updatedAt: at,
        ),
    });
  }

  UserFitnessProfile profileA() => UserFitnessProfile(
        goal: FitnessGoal.generalFitness,
        experience: ExperienceLevel.completelyNew,
        workoutDuration: WorkoutDuration.tenMinutes,
        environment: TrainingEnvironment.normalHome,
        equipment: const {WorkoutEquipment.none},
        preferences: const {},
      );

  /// The edit performed "somewhere in Settings" while the Player runs.
  UserFitnessProfile profileB(UserFitnessProfile current) => current.copyWith(
        goal: FitnessGoal.improveMobility,
        workoutDuration: WorkoutDuration.thirtyMinutes,
        environment: TrainingEnvironment.outdoor,
        equipment: const {WorkoutEquipment.resistanceBands},
        preferences: const {WorkoutPreference.lowImpact},
      );

  Future<ProviderContainer> seededContainer() async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        workoutCoachProvider.overrideWithValue(NoOpWorkoutCoach()),
      ],
    );
    // Safety net; tests also dispose in-body so the Player's countdown timer
    // is cancelled before the test framework checks for pending timers
    // (ProviderContainer.dispose is idempotent).
    addTearDown(container.dispose);
    await container
        .read(userFitnessProfileProvider.notifier)
        .saveProfile(profileA());
    // Sanity: the persisted profile is exactly profileA.
    final prefs = await SharedPreferences.getInstance();
    expect(UserFitnessProfileStorage(prefs).load(), profileA());
    return container;
  }

  /// Opens the shared Player for [plan], starts the session, and captures
  /// the in-flight state.
  (WorkoutPlayerController, WorkoutPlayerState) openAndStart(
    ProviderContainer container,
    WorkoutPlan plan,
  ) {
    // Keep the autoDispose family alive exactly like an on-screen Player.
    container.listen(workoutPlayerControllerProvider(plan), (_, __) {});
    final controller =
        container.read(workoutPlayerControllerProvider(plan).notifier);
    expect(controller.state.phase, WorkoutPlayerPhase.ready);
    controller.beginWorkout();
    expect(controller.state.phase, WorkoutPlayerPhase.work);
    return (controller, controller.state);
  }

  Future<void> editProfileWhilePlaying(ProviderContainer container) async {
    final current = container.read(userFitnessProfileProvider).value!;
    final saved = await container
        .read(userFitnessProfileProvider.notifier)
        .saveProfile(profileB(current));
    expect(saved, isTrue);
    expect(
      container.read(userFitnessProfileProvider).value!.goal,
      FitnessGoal.improveMobility,
    );
  }

  void expectSessionFrozen(
    ProviderContainer container,
    WorkoutPlan plan,
    WorkoutPlayerController controllerBefore,
    WorkoutPlayerState stateBefore,
  ) {
    // Same controller instance — nothing regenerated or reset the session.
    final controllerAfter =
        container.read(workoutPlayerControllerProvider(plan).notifier);
    expect(identical(controllerAfter, controllerBefore), isTrue);

    final stateAfter = controllerAfter.state;
    expect(stateAfter.phase, stateBefore.phase);
    expect(stateAfter.sectionIndex, stateBefore.sectionIndex);
    expect(stateAfter.exerciseIndex, stateBefore.exerciseIndex);
    expect(stateAfter.setNumber, stateBefore.setNumber);
    expect(stateAfter.completedSets, stateBefore.completedSets);
    expect(
      stateAfter.currentPrescription.exercise.id,
      stateBefore.currentPrescription.exercise.id,
    );
  }

  testWidgets('adaptive session stays frozen across a profile edit', (
    tester,
  ) async {
    final container = await seededContainer();
    final capability = maxCapability();

    final plan = WorkoutGenerator.generateCatalog(
      WorkoutGenerationContext(
        userProfile: container.read(userFitnessProfileProvider).value!,
        capabilityProfile: capability,
      ),
    )!;

    final (controller, stateBefore) = openAndStart(container, plan);
    await editProfileWhilePlaying(container);
    expectSessionFrozen(container, plan, controller, stateBefore);
    container.dispose(); // Cancels the session countdown timer.
  });

  testWidgets('program session stays frozen across a profile edit', (
    tester,
  ) async {
    final container = await seededContainer();
    final capability = maxCapability();

    final definition = AdaptiveProgramCatalog.byId(
      AdaptiveProgramCatalog.balancedFoundationsId,
    )!;
    final session = definition.weeks.first.sessions.first;
    final resolution = AdaptiveProgramWorkoutResolver.resolve(
      definition: definition,
      session: session,
      userProfile: container.read(userFitnessProfileProvider).value!,
      capabilityProfile: capability,
    );
    final plan = resolution.plan!;

    final (controller, stateBefore) = openAndStart(container, plan);
    await editProfileWhilePlaying(container);
    expectSessionFrozen(container, plan, controller, stateBefore);
    container.dispose(); // Cancels the session countdown timer.
  });

  testWidgets('custom session stays frozen across a profile edit', (
    tester,
  ) async {
    final container = await seededContainer();
    final capability = maxCapability();

    // A custom template built from real catalog exercises so the M13
    // resolver produces a valid plan.
    final mainExercise = ExerciseCatalog.all.firstWhere(
      (exercise) =>
          exercise.active &&
          exercise.requiredEquipment.contains(WorkoutEquipment.none) &&
          !exercise.tags.contains('jumping') &&
          CapabilityProfile.trainablePatterns
              .contains(exercise.movementPattern),
    );
    final template = CustomWorkoutTemplate(
      id: 'cw_active',
      name: 'Active session',
      targetDuration: WorkoutDuration.tenMinutes,
      createdAt: testNow.subtract(const Duration(days: 1)),
      updatedAt: testNow,
      warmup: const [
        CustomWorkoutExerciseEntry(
          exerciseId: 'march_in_place',
          sets: 1,
          workDuration: Duration(seconds: 30),
          restBetweenSets: Duration(seconds: 15),
        ),
      ],
      main: [
        CustomWorkoutExerciseEntry(
          exerciseId: mainExercise.id,
          sets: 2,
          repsPerSet: 8,
          restBetweenSets: const Duration(seconds: 30),
        ),
      ],
      cooldown: const [
        CustomWorkoutExerciseEntry(
          exerciseId: 'figure_four_stretch',
          sets: 1,
          workDuration: Duration(seconds: 30),
          restBetweenSets: Duration(seconds: 15),
        ),
      ],
    );
    final resolution = CustomWorkoutPlanResolver.resolve(
      template: template,
      catalogById: {
        for (final exercise in ExerciseCatalog.all) exercise.id: exercise,
      },
      userFitnessProfile: container.read(userFitnessProfileProvider).value!,
      capabilityProfile: capability,
    );
    final plan = resolution.plan!;

    final (controller, stateBefore) = openAndStart(container, plan);
    await editProfileWhilePlaying(container);
    expectSessionFrozen(container, plan, controller, stateBefore);
    container.dispose(); // Cancels the session countdown timer.
  });
}
