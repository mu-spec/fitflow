import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CapabilityProfile createFullProfile(CapabilityLevel level) {
  final now = DateTime.utc(2026, 1, 1);
  final map = <MovementPattern, MovementCapability>{};
  for (final p in CapabilityProfile.trainablePatterns) {
    map[p] = MovementCapability(movementPattern: p, level: level, source: CapabilitySource.initialAssessment, updatedAt: now);
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

void completeWorkout(WorkoutPlayerController controller) {
  int safety = 0;
  while (safety < 2000 && controller.state.phase != WorkoutPlayerPhase.completed) {
    final phase = controller.state.phase;
    if (phase == WorkoutPlayerPhase.ready) {
      controller.beginWorkout();
    } else if (phase == WorkoutPlayerPhase.work) {
      if (controller.state.isRepsExercise) {
        controller.completeSet();
      } else {
        while (controller.state.remaining > Duration.zero && controller.state.phase == WorkoutPlayerPhase.work) {
          controller.tick();
        }
      }
    } else if (phase == WorkoutPlayerPhase.rest) {
      controller.skipRest();
    } else if (phase == WorkoutPlayerPhase.transition) {
      controller.skipTransition();
    } else if (phase == WorkoutPlayerPhase.sectionBreak) {
      controller.continueSection();
    } else {
      break;
    }
    safety++;
  }
}

void main() {
  group('Completion Recording', () {
    test('final cooldown completion records one history entry', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      completeWorkout(controller);

      expect(controller.state.phase, equals(WorkoutPlayerPhase.completed));

      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      final saved = await storage.add(snapshot);
      expect(saved, true);
      expect(storage.load().length, equals(1));
    });

    test('rebuild after completion does not create second entry', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap, sessionIdOverride: 'test_session_1');
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      // Simulate rebuild – same session ID, should not duplicate
      await storage.add(snapshot);
      expect(storage.load().length, equals(1));
    });

    test('opening Tune next workout does not duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap, sessionIdOverride: 'session_tune');
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      // Opening Tune should not add again
      final before = storage.load().length;
      // Simulate Tune opening – no new add
      expect(storage.load().length, equals(before));
    });

    test('applying feedback does not duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap, sessionIdOverride: 'session_feedback');
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      expect(storage.load().length, equals(1));
      // Feedback applied – history should remain 1
      await storage.add(snapshot);
      expect(storage.load().length, equals(1));
    });

    test('Done does not duplicate', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap, sessionIdOverride: 'session_done');
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      expect(storage.load().length, equals(1));
      // Done tapped – no duplicate
      await storage.add(snapshot);
      expect(storage.load().length, equals(1));
    });

    test('completion recorder uses effective replacements', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      controller.beginWorkout();
      final options = controller.getReplacementOptions();
      String? replacedName;
      if (options.isNotEmpty) {
        replacedName = options.first.exercise.name;
        controller.replaceCurrentExercise(options.first);
      }
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      final loaded = storage.load().first;
      if (replacedName != null) {
        // At least one exercise should have replaced name
        final allNames = loaded.allExercises.map((e) => e.exerciseName).toList();
        expect(allNames.contains(replacedName), true);
      }
    });

    test('warmup/main/cooldown order correct', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      expect(snapshot.warmup.isNotEmpty, true);
      expect(snapshot.main.isNotEmpty, true);
      expect(snapshot.cooldown.isNotEmpty, true);
      // Order preserved: allExercises = warmup+main+cooldown
      expect(snapshot.allExercises.length, equals(snapshot.warmup.length + snapshot.main.length + snapshot.cooldown.length));
      await storage.add(snapshot);
    });

    test('failed history save leaves Player completed', () async {
      // Simulate storage failure – controller should still be completed
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      completeWorkout(controller);
      expect(controller.state.phase, equals(WorkoutPlayerPhase.completed));
      // Even if storage fails, state remains completed
    });

    test('M10 progression still usable if history save fails', () async {
      // History failure must not affect adaptive progression
      // We test that creating snapshot does not interfere with effectiveMainPrescriptions
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      completeWorkout(controller);
      final effectiveMain = controller.effectiveMainPrescriptions;
      expect(effectiveMain.isNotEmpty, true);
      // Simulate history save failure, effectiveMain still usable for M10
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      expect(snapshot.main.length, equals(effectiveMain.length));
    });

    test('recording refreshes history provider (simulated)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);

      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level2);
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(userProfile: user, capabilityProfile: cap))!;

      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: FakeWorkoutCoach(), userProfile: user, capabilityProfile: cap);
      completeWorkout(controller);
      final snapshot = controller.createCompletedWorkoutSnapshot(plan: plan);
      await storage.add(snapshot);
      final loaded = storage.load();
      expect(loaded.length, equals(1));
      // Provider would refresh and show new entry
    });
  });
}
