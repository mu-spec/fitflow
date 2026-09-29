import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_screen.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class FakeUserProfileController extends UserFitnessProfileController {
  final UserFitnessProfile profile;
  FakeUserProfileController(this.profile);
  @override
  Future<UserFitnessProfile?> build() async => profile;
}

class FakeCapabilityController extends CapabilityProfileController {
  final CapabilityProfile profile;
  FakeCapabilityController(this.profile);
  @override
  Future<CapabilityProfile?> build() async => profile;
}

void main() {
  group('Player session mode', () {
    testWidgets('player shows mode chip for low energy', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WorkoutPlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Low Energy'), findsWidgets);
    });

    testWidgets('player stable plan not change when mode changes mid-session', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WorkoutPlayerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Change mode after player started – should still show original stable mode
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.standard);
      await tester.pumpAndSettle();
      // Player should still show Low Energy chip because stable mode captured at init
      expect(find.text('Low Energy'), findsWidgets);
    });
  });
}
