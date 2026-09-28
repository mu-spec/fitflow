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
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';
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

UserFitnessProfile createUserProfile() {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.largeRoom,
    equipment: {WorkoutEquipment.none},
    preferences: {},
  );
}

WorkoutPlan makePlanWithLevel3Pushup() {
  // Use Level3 pushup as current: pushup_standard level3 has easier level2 and harder level4
  final pushStandard = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_standard');
  final squat = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
  final plank = ExerciseCatalog.all.firstWhere((e) => e.id == 'plank_knee');
  final warmup = WorkoutSection(
    type: WorkoutSectionType.warmup,
    exercises: [
      WorkoutExercisePrescription(exercise: pushStandard, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final main = WorkoutSection(
    type: WorkoutSectionType.main,
    exercises: [
      WorkoutExercisePrescription(exercise: squat, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final cooldown = WorkoutSection(
    type: WorkoutSectionType.cooldown,
    exercises: [
      WorkoutExercisePrescription(exercise: plank, sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero),
    ],
  );
  return WorkoutPlan(
    warmup: warmup,
    main: main,
    cooldown: cooldown,
    timeBudget: WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

WorkoutPlan makePlanWithLevel2Squat() {
  final squatBodyweight = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
  final push = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_wall');
  final plank = ExerciseCatalog.all.firstWhere((e) => e.id == 'plank_knee');
  final warmup = WorkoutSection(
    type: WorkoutSectionType.warmup,
    exercises: [
      WorkoutExercisePrescription(exercise: squatBodyweight, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final main = WorkoutSection(
    type: WorkoutSectionType.main,
    exercises: [
      WorkoutExercisePrescription(exercise: push, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final cooldown = WorkoutSection(
    type: WorkoutSectionType.cooldown,
    exercises: [
      WorkoutExercisePrescription(exercise: plank, sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero),
    ],
  );
  return WorkoutPlan(
    warmup: warmup,
    main: main,
    cooldown: cooldown,
    timeBudget: WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

WorkoutPlan makePlanWithLevel3Squat() {
  // For easier tests: squat_tempo level3 has easier level2
  final squatTempo = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_tempo');
  final push = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_wall');
  final plank = ExerciseCatalog.all.firstWhere((e) => e.id == 'plank_knee');
  final warmup = WorkoutSection(
    type: WorkoutSectionType.warmup,
    exercises: [
      WorkoutExercisePrescription(exercise: squatTempo, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final main = WorkoutSection(
    type: WorkoutSectionType.main,
    exercises: [
      WorkoutExercisePrescription(exercise: push, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
    ],
  );
  final cooldown = WorkoutSection(
    type: WorkoutSectionType.cooldown,
    exercises: [
      WorkoutExercisePrescription(exercise: plank, sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero),
    ],
  );
  return WorkoutPlan(
    warmup: warmup,
    main: main,
    cooldown: cooldown,
    timeBudget: WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

void main() {
  group('Difficulty Invariant Fix', () {
    test('fabricated harder option is rejected even within capability', () {
      final plan = makePlanWithLevel2Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final current = controller.state.currentPrescription;
      expect(current.exercise.difficulty, ExerciseDifficulty.level2);

      // Fabricate a harder option: Level3 squat tempo
      final harderCandidates = ExerciseCatalog.all.where((e) =>
          e.movementPattern == current.exercise.movementPattern &&
          e.exerciseType == current.exercise.exerciseType &&
          e.difficulty.index > current.exercise.difficulty.index &&
          e.id != current.exercise.id).toList();
      expect(harderCandidates.isNotEmpty, true, reason: 'Need harder candidate for test');
      final harder = harderCandidates.firstWhere((e) => e.difficulty == ExerciseDifficulty.level3, orElse: () => harderCandidates.first);

      final fabricatedPrescription = WorkoutExercisePrescription(
        exercise: harder,
        sets: current.sets,
        repsPerSet: current.repsPerSet,
        workDuration: current.workDuration,
        restBetweenSets: current.restBetweenSets,
      );
      final fabricatedOption = WorkoutReplacementOption(
        exercise: harder,
        prescription: fabricatedPrescription,
        reasons: const [WorkoutReplacementReason.sameMovementFocus],
      );

      final success = controller.replaceCurrentExercise(fabricatedOption);
      expect(success, false, reason: 'Harder option must be rejected');
      controller.dispose();
    });

    test('current exercise remains unchanged after rejection', () {
      final plan = makePlanWithLevel2Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final originalId = controller.state.currentPrescription.exercise.id;
      final current = controller.state.currentPrescription;
      final harder = ExerciseCatalog.all.firstWhere((e) =>
          e.movementPattern == current.exercise.movementPattern &&
          e.exerciseType == current.exercise.exerciseType &&
          e.difficulty.index > current.exercise.difficulty.index);
      final fabricatedPrescription = WorkoutExercisePrescription(
        exercise: harder,
        sets: current.sets,
        repsPerSet: current.repsPerSet,
        workDuration: current.workDuration,
        restBetweenSets: current.restBetweenSets,
      );
      final fabricatedOption = WorkoutReplacementOption(
        exercise: harder,
        prescription: fabricatedPrescription,
        reasons: const [WorkoutReplacementReason.sameMovementFocus],
      );
      controller.replaceCurrentExercise(fabricatedOption);
      expect(controller.state.currentPrescription.exercise.id, originalId);
      controller.dispose();
    });

    test('sets/reps/duration/rest remain unchanged after rejection', () {
      final plan = makePlanWithLevel2Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final original = controller.state.currentPrescription;
      final harder = ExerciseCatalog.all.firstWhere((e) =>
          e.movementPattern == original.exercise.movementPattern &&
          e.exerciseType == original.exercise.exerciseType &&
          e.difficulty.index > original.exercise.difficulty.index);
      final fabricatedPrescription = WorkoutExercisePrescription(
        exercise: harder,
        sets: original.sets,
        repsPerSet: original.repsPerSet,
        workDuration: original.workDuration,
        restBetweenSets: original.restBetweenSets,
      );
      final fabricatedOption = WorkoutReplacementOption(
        exercise: harder,
        prescription: fabricatedPrescription,
        reasons: const [WorkoutReplacementReason.sameMovementFocus],
      );
      controller.replaceCurrentExercise(fabricatedOption);
      final after = controller.state.currentPrescription;
      expect(after.sets, original.sets);
      expect(after.repsPerSet, original.repsPerSet);
      expect(after.workDuration, original.workDuration);
      expect(after.restBetweenSets, original.restBetweenSets);
      controller.dispose();
    });

    test('same-difficulty canonical option still succeeds', () {
      final plan = makePlanWithLevel3Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final options = controller.getReplacementOptions();
      // Find same difficulty option if exists
      final sameDiff = options.where((o) => o.exercise.difficulty == controller.state.currentPrescription.exercise.difficulty).toList();
      if (sameDiff.isNotEmpty) {
        final success = controller.replaceCurrentExercise(sameDiff.first);
        expect(success, true);
      } else {
        // If no same difficulty, at least easier should succeed (tested next)
        expect(options.isNotEmpty, true);
      }
      controller.dispose();
    });

    test('easier canonical option still succeeds', () {
      final plan = makePlanWithLevel3Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final options = controller.getReplacementOptions();
      final easier = options.where((o) => o.exercise.difficulty.index < controller.state.currentPrescription.exercise.difficulty.index).toList();
      expect(easier.isNotEmpty, true, reason: 'Should have at least one easier alternative for level3 squat');
      final success = controller.replaceCurrentExercise(easier.first);
      expect(success, true);
      expect(controller.state.currentPrescription.exercise.difficulty.index < ExerciseDifficulty.level3.index, true);
      controller.dispose();
    });

    test('after replacement, second replacement validated against CURRENT effective', () {
      final plan = makePlanWithLevel3Squat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final original = controller.state.currentPrescription;
      expect(original.exercise.difficulty, ExerciseDifficulty.level3);

      // First replace with Level2
      final options1 = controller.getReplacementOptions();
      final level2Options = options1.where((o) => o.exercise.difficulty == ExerciseDifficulty.level2).toList();
      expect(level2Options.isNotEmpty, true);
      final success1 = controller.replaceCurrentExercise(level2Options.first);
      expect(success1, true);
      expect(controller.state.currentPrescription.exercise.difficulty, ExerciseDifficulty.level2);

      // Now attempt to replace with Level3 (original) – should be rejected because Level3 > current Level2
      final level3Exercise = original.exercise; // Level3
      final currentAfter = controller.state.currentPrescription;
      final fabricatedPrescription = WorkoutExercisePrescription(
        exercise: level3Exercise,
        sets: currentAfter.sets,
        repsPerSet: currentAfter.repsPerSet,
        workDuration: currentAfter.workDuration,
        restBetweenSets: currentAfter.restBetweenSets,
      );
      final fabricatedOption = WorkoutReplacementOption(
        exercise: level3Exercise,
        prescription: fabricatedPrescription,
        reasons: const [WorkoutReplacementReason.sameMovementFocus],
      );
      final success2 = controller.replaceCurrentExercise(fabricatedOption);
      expect(success2, false, reason: 'Level3 should be rejected after current is Level2');
      expect(controller.state.currentPrescription.exercise.difficulty, ExerciseDifficulty.level2);
      controller.dispose();
    });
  });
}
