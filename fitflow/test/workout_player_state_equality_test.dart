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

WorkoutPlan createPlan() {
  final user = createUserProfile();
  final cap = createFullProfile(CapabilityLevel.level3);
  return WorkoutGenerator.generateCatalog(
    WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
  )!;
}

void main() {
  group('WorkoutPlayerState equality includes previousPhaseBeforePause', () {
    test('states differing only in previousPhaseBeforePause are not equal', () {
      final plan = createPlan();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);
      controller.beginWorkout();
      controller.pause();
      final pausedState = controller.state;
      final altered = pausedState.copyWith(
        previousPhaseBeforePause: WorkoutPlayerPhase.rest,
      );
      expect(pausedState == altered, false);
      expect(pausedState.previousPhaseBeforePause != altered.previousPhaseBeforePause, true);
      controller.dispose();
    });

    test('states differing only in voiceEnabled are not equal', () {
      final plan = createPlan();
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);
      final state1 = controller.state;
      final state2 = state1.copyWith(voiceEnabled: !state1.voiceEnabled);
      expect(state1 == state2, false);
      expect(state1.voiceEnabled != state2.voiceEnabled, true);
      controller.dispose();
    });
  });
}
