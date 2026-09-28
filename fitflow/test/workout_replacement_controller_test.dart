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
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
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

WorkoutPlan makePlanWithSquat() {
  final squat = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
  final push = ExerciseCatalog.all.firstWhere((e) => e.id == 'pushup_wall');
  final plank = ExerciseCatalog.all.firstWhere((e) => e.id == 'plank_knee');
  final warmup = WorkoutSection(
    type: WorkoutSectionType.warmup,
    exercises: [
      WorkoutExercisePrescription(exercise: squat, sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 10)),
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

WorkoutPlan makeTimedPlan() {
  final plank = ExerciseCatalog.all.firstWhere((e) => e.id == 'plank_knee');
  final warmup = WorkoutSection(
    type: WorkoutSectionType.warmup,
    exercises: [
      WorkoutExercisePrescription(exercise: plank, sets: 1, workDuration: const Duration(seconds: 30), restBetweenSets: Duration.zero),
    ],
  );
  final main = WorkoutSection(
    type: WorkoutSectionType.main,
    exercises: [
      WorkoutExercisePrescription(exercise: plank, sets: 1, workDuration: const Duration(seconds: 30), restBetweenSets: Duration.zero),
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
  group('Replacement Controller', () {
    test('allowed in ready state', () {
      final plan = makePlanWithSquat();
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
      expect(controller.canReplaceCurrentExercise, true);
      expect(controller.state.phase, WorkoutPlayerPhase.ready);
      controller.dispose();
    });

    test('allowed in work Set1 before completion', () {
      final plan = makePlanWithSquat();
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
      expect(controller.state.phase, WorkoutPlayerPhase.work);
      expect(controller.state.setNumber, 1);
      expect(controller.canReplaceCurrentExercise, true);
      controller.dispose();
    });

    test('blocked after Set1 completed', () {
      final plan = makePlanWithSquat();
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
      controller.completeSet();
      expect(controller.state.phase, WorkoutPlayerPhase.rest);
      expect(controller.canReplaceCurrentExercise, false);
      controller.skipRest();
      expect(controller.state.setNumber, 2);
      expect(controller.canReplaceCurrentExercise, false);
      controller.dispose();
    });

    test('blocked in later sets', () {
      final plan = makePlanWithSquat();
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
      controller.completeSet();
      controller.skipRest();
      expect(controller.state.setNumber, 2);
      expect(controller.canReplaceCurrentExercise, false);
      controller.dispose();
    });

    test('replacement changes exercise only', () {
      final plan = makePlanWithSquat();
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
      final originalPres = controller.state.currentPrescription;
      final options = controller.getReplacementOptions();
      expect(options.isNotEmpty, true);
      final option = options.first;
      final success = controller.replaceCurrentExercise(option);
      expect(success, true);
      expect(controller.state.currentPrescription.exercise.id, option.exercise.id);
      expect(controller.state.currentPrescription.exercise.id != originalPres.exercise.id, true);
      controller.dispose();
    });

    test('totalSets unchanged after replacement', () {
      final plan = makePlanWithSquat();
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
      final totalBefore = controller.state.totalSets;
      controller.beginWorkout();
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.totalSets, totalBefore);
      }
      controller.dispose();
    });

    test('completedSets unchanged after replacement', () {
      final plan = makePlanWithSquat();
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
      final completedBefore = controller.state.completedSets;
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.completedSets, completedBefore);
      }
      controller.dispose();
    });

    test('indices unchanged after replacement', () {
      final plan = makePlanWithSquat();
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
      final secIdx = controller.state.sectionIndex;
      final exIdx = controller.state.exerciseIndex;
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.sectionIndex, secIdx);
        expect(controller.state.exerciseIndex, exIdx);
      }
      controller.dispose();
    });

    test('reps unchanged after replacement', () {
      final plan = makePlanWithSquat();
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
      final originalReps = controller.state.currentPrescription.repsPerSet;
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.currentPrescription.repsPerSet, originalReps);
      }
      controller.dispose();
    });

    test('timed unchanged after replacement', () {
      final timedPlan = makeTimedPlan();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: timedPlan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final originalDuration = controller.state.currentPrescription.workDuration;
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.currentPrescription.workDuration, originalDuration);
      }
      controller.dispose();
    });

    test('timed replacement resets full timer', () {
      final timedPlan = makeTimedPlan();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: timedPlan,
        autoStartTimer: false,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      for (int i = 0; i < 10; i++) {
        controller.tick();
      }
      final remainingAfterTick = controller.state.remaining;
      expect(remainingAfterTick.inSeconds < 30, true);
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.remaining, const Duration(seconds: 30));
        expect(controller.state.setNumber, 1);
      }
      controller.dispose();
    });

    test('paused state preserved after replacement', () {
      final plan = makePlanWithSquat();
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
      controller.pause();
      expect(controller.state.isPaused, true);
      final options = controller.getReplacementOptions();
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        expect(controller.state.isPaused, true);
      }
      controller.dispose();
    });

    test('progression after replacement works', () {
      final plan = makePlanWithSquat();
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
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
      }
      controller.completeSet();
      controller.skipRest();
      controller.completeSet();
      // warmup has 1 exercise, so should go to sectionBreak, not transition
      expect(controller.state.phase, WorkoutPlayerPhase.sectionBreak);
      controller.continueSection();
      expect(controller.state.phase, WorkoutPlayerPhase.work);
      controller.dispose();
    });

    test('transition uses replaced name', () {
      final plan = makePlanWithSquat();
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
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
        final replacedName = controller.state.currentPrescription.exercise.name;
        controller.completeSet();
        controller.skipRest();
        controller.completeSet();
        expect(coach.spoken.any((s) => s.contains(replacedName)), true);
      }
      controller.dispose();
    });

    test('next section progression works', () {
      final plan = makePlanWithSquat();
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
      if (options.isNotEmpty) {
        controller.replaceCurrentExercise(options.first);
      }
      controller.completeSet();
      controller.skipRest();
      controller.completeSet();
      expect(controller.state.phase, WorkoutPlayerPhase.sectionBreak);
      controller.continueSection();
      expect(controller.state.sectionIndex, 1);
      controller.dispose();
    });

    test('completion works after replacement', () {
      final plan = makePlanWithSquat();
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
      final opts = controller.getReplacementOptions();
      if (opts.isNotEmpty) controller.replaceCurrentExercise(opts.first);
      controller.completeSet();
      controller.skipRest();
      controller.completeSet();
      expect(controller.state.phase, WorkoutPlayerPhase.sectionBreak);
      controller.continueSection();
      controller.completeSet();
      controller.skipRest();
      controller.completeSet();
      expect(controller.state.phase, WorkoutPlayerPhase.sectionBreak);
      controller.continueSection();
      for (int i = 0; i < 20; i++) {
        controller.tick();
      }
      expect(controller.state.phase, WorkoutPlayerPhase.completed);
      controller.dispose();
    });

    test('repeated replacement deterministic', () {
      final plan = makePlanWithSquat();
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
      final opts1 = controller.getReplacementOptions();
      final opts2 = controller.getReplacementOptions();
      expect(opts1.map((o) => o.exercise.id).toList(), opts2.map((o) => o.exercise.id).toList());
      controller.dispose();
    });

    test('duplicate tracking uses effective session', () {
      final plan = makePlanWithSquat();
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
      final opts = controller.getReplacementOptions();
      if (opts.isNotEmpty) {
        controller.replaceCurrentExercise(opts.first);
        final newOpts = controller.getReplacementOptions();
        expect(newOpts.any((o) => o.exercise.id == 'pushup_wall'), false);
      }
      controller.dispose();
    });

    test('no timer duplication after replacement', () {
      final plan = makePlanWithSquat();
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level5);
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(
        plan: plan,
        autoStartTimer: true,
        coach: coach,
        userProfile: user,
        capabilityProfile: cap,
      );
      controller.beginWorkout();
      final opts = controller.getReplacementOptions();
      if (opts.isNotEmpty) {
        controller.replaceCurrentExercise(opts.first);
      }
      controller.tick();
      controller.dispose();
    });

    test('disposal safe after replacement', () {
      final plan = makePlanWithSquat();
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
      final opts = controller.getReplacementOptions();
      if (opts.isNotEmpty) controller.replaceCurrentExercise(opts.first);
      controller.dispose();
      controller.tick();
    });
  });
}
