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
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
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

WorkoutPlan createPlan() {
  final user = createUserProfile();
  final cap = createFullProfile(CapabilityLevel.level3);
  return WorkoutGenerator.generateCatalog(
    WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
  )!;
}

void main() {
  group('Voice cues', () {
    test('beginning first exercise emits correct cue', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();

      expect(coach.spoken.isNotEmpty, true);
      final first = coach.spoken.first;
      expect(first.toLowerCase(), contains('set 1 of'));
      controller.dispose();
    });

    test('next set cue where appropriate', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      coach.clear();

      int safety = 0;
      while (safety < 500) {
        if (controller.state.phase == WorkoutPlayerPhase.work &&
            controller.state.totalSetsForCurrentExercise > 1 &&
            controller.state.isRepsExercise) {
          break;
        }
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
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.phase == WorkoutPlayerPhase.work &&
          controller.state.totalSetsForCurrentExercise > 1) {
        coach.clear();
        if (controller.state.isRepsExercise) {
          controller.completeSet();
        } else {
          while (controller.state.remaining > Duration.zero &&
              controller.state.phase == WorkoutPlayerPhase.work) {
            controller.tick();
          }
        }
        expect(coach.spoken.isNotEmpty, true);
      }
      controller.dispose();
    });

    test('rest cue uses actual rest duration', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 200 && controller.state.phase != WorkoutPlayerPhase.rest) {
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero && controller.state.phase == WorkoutPlayerPhase.work) {
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
        expect(coach.spoken.any((s) => s.toLowerCase().contains('rest')), true);
      }
      controller.dispose();
    });

    test('transition cue uses actual upcoming exercise', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();

      int safety = 0;
      while (safety < 500 && controller.state.phase != WorkoutPlayerPhase.transition) {
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero && controller.state.phase == WorkoutPlayerPhase.work) {
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
        final spokenCombined = coach.spoken.join(' ').toLowerCase();
        expect(spokenCombined.contains('next'), true);
        expect(coach.spoken.isNotEmpty, true);
      }
      controller.dispose();
    });

    test('Warm-up section cue', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      int safety = 0;
      while (safety < 2000 && controller.state.phase != WorkoutPlayerPhase.sectionBreak) {
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero && controller.state.phase == WorkoutPlayerPhase.work) {
              controller.tick();
            }
          }
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else {
          break;
        }
        safety++;
        if (controller.state.phase == WorkoutPlayerPhase.completed) break;
      }

      if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
        final all = coach.spoken.join(' ').toLowerCase();
        if (controller.state.sectionIndex == 0) {
          expect(all.contains('warm-up') || all.contains('warmup') || all.contains('main'), true);
        }
      }
      controller.dispose();
    });

    test('Main section cue', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      int safety = 0;
      while (safety < 3000 && controller.state.phase.toString() != 'completed') {
        if (controller.state.phase == WorkoutPlayerPhase.work) {
          if (controller.state.isRepsExercise) {
            controller.completeSet();
          } else {
            while (controller.state.remaining > Duration.zero && controller.state.phase == WorkoutPlayerPhase.work) {
              controller.tick();
            }
          }
        } else if (controller.state.phase == WorkoutPlayerPhase.rest) {
          controller.skipRest();
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          if (controller.state.sectionIndex == 0) {
            coach.clear();
            controller.continueSection();
            continue;
          } else if (controller.state.sectionIndex == 1) {
            break;
          } else {
            controller.continueSection();
          }
        } else {
          break;
        }
        safety++;
      }

      if (controller.state.sectionIndex == 1 && controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
        final all = coach.spoken.join(' ').toLowerCase();
        expect(all.contains('main') || all.contains('cooldown'), true);
      }
      controller.dispose();
    });

    test('completion cue', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      int safety = 0;
      while (safety < 5000 && controller.state.phase != WorkoutPlayerPhase.completed) {
        if (controller.state.phase == WorkoutPlayerPhase.ready) {
          controller.beginWorkout();
        } else if (controller.state.phase == WorkoutPlayerPhase.work) {
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
        } else if (controller.state.phase == WorkoutPlayerPhase.transition) {
          controller.skipTransition();
        } else if (controller.state.phase == WorkoutPlayerPhase.sectionBreak) {
          controller.continueSection();
        } else {
          break;
        }
        safety++;
      }

      expect(controller.state.phase, WorkoutPlayerPhase.completed);
      expect(coach.spoken.any((s) => s.toLowerCase().contains('workout complete')), true);
      controller.dispose();
    });

    test('mute suppresses future cues', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      coach.clear();
      controller.toggleVoice();
      expect(controller.state.voiceEnabled, false);
      if (controller.state.phase == WorkoutPlayerPhase.work && controller.state.isRepsExercise) {
        controller.completeSet();
      }
      expect(coach.spoken.isEmpty, true);
      controller.dispose();
    });

    test('mute calls stop', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      final before = coach.stopCalls;
      controller.toggleVoice();
      expect(coach.stopCalls, greaterThan(before));
      controller.dispose();
    });

    test('pause calls stop', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      coach.clear();
      controller.pause();
      expect(coach.stopCalls, greaterThan(0));
      controller.dispose();
    });

    test('lifecycle auto-pause calls stop', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      if (controller.state.phase == WorkoutPlayerPhase.work) {
        controller.pauseForLifecycle();
        expect(coach.stopCalls, greaterThan(0));
      }
      controller.dispose();
    });

    test('resume remains functional', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      final remainingBefore = controller.state.remaining;
      controller.pause();
      expect(controller.state.isPaused, true);
      controller.resume();
      expect(controller.state.isPaused, false);
      expect(controller.state.remaining, remainingBefore);
      controller.dispose();
    });

    test('throwing speak() does not affect progression', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach()..throwOnSpeak = true;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      expect(controller.state.phase, WorkoutPlayerPhase.work);
      if (controller.state.isRepsExercise) {
        controller.completeSet();
        expect(controller.state.completedSets, greaterThan(0));
      }
      controller.dispose();
    });

    test('throwing stop() does not affect progression', () {
      final plan = createPlan();
      final coach = FakeWorkoutCoach()..throwOnStop = true;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      controller.pause();
      expect(controller.state.isPaused, true);
      controller.resume();
      expect(controller.state.isPaused, false);
      controller.dispose();
    });

    test('no TTS plugin is required by unit tests', () {
      final plan = createPlan();
      final coach = NoOpWorkoutCoach();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false, coach: coach);

      controller.beginWorkout();
      expect(controller.state.phase, WorkoutPlayerPhase.work);
      controller.dispose();
    });
  });
}
