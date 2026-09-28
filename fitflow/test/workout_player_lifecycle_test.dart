import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
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
  return const UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.largeRoom,
    equipment: {WorkoutEquipment.none},
    preferences: {},
  );
}

void main() {
  group('Lifecycle auto-pause', () {
    test('active timed work background -> paused', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.completed) {
        if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
          break;
        }
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          controller.completeSet();
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
        expect(controller.state.isPaused, false);
        controller.pauseForLifecycle();
        expect(controller.state.isPaused, true);
        expect(coach.stopCalls, greaterThan(0));
      }
      controller.dispose();
    });

    test('countdown freezes when paused', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.completed) {
        if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
          break;
        }
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          controller.completeSet();
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
        final before = controller.state.remaining;
        controller.pauseForLifecycle();
        controller.tick();
        controller.tick();
        expect(controller.state.remaining, before);
      }
      controller.dispose();
    });

    test('app resume does not auto-resume', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.completed) {
        if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
          break;
        }
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          controller.completeSet();
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.work) {
        controller.pauseForLifecycle();
        expect(controller.state.isPaused, true);
        expect(controller.state.isPaused, true);
      }
      controller.dispose();
    });

    test('explicit Resume continues same remaining duration', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.completed) {
        if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
          break;
        }
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          controller.completeSet();
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isTimedExercise) {
        final before = controller.state.remaining;
        controller.pauseForLifecycle();
        expect(controller.state.isPaused, true);
        controller.resume();
        expect(controller.state.isPaused, false);
        expect(controller.state.remaining, before);
      }
      controller.dispose();
    });

    test('active rest background -> paused', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.rest) {
        if (controller.state.phase == WorkoutPlayerPhase.completed) break;
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero &&
                controller.state.phase == WorkoutPlayerPhase.work) {
              controller.tick();
            }
          }
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.rest) {
        expect(controller.state.isPaused, false);
        controller.pauseForLifecycle();
        expect(controller.state.isPaused, true);
      }
      controller.dispose();
    });

    test('active transition background -> paused', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 300 && controller.state.phase != WorkoutPlayerPhase.transition) {
        if (controller.state.phase == WorkoutPlayerPhase.completed) break;
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero &&
                controller.state.phase == WorkoutPlayerPhase.work) {
              controller.tick();
            }
          }
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.transition) {
        controller.pauseForLifecycle();
        expect(controller.state.isPaused, true);
      }
      controller.dispose();
    });

    test('lifecycle pause calls coach.stop()', () {
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      if (controller.state.phase == WorkoutPlayerPhase.work) {
        controller.pauseForLifecycle();
        expect(coach.stopCalls, greaterThan(0));
      }
      controller.dispose();
    });
  });
}
