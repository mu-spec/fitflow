import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
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
  group('Preview session mode', () {
    testWidgets('standard no badge', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WorkoutPreviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Temporary for this workout'), findsNothing);
    });

    testWidgets('low energy shows badge', (tester) async {
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
            home: const WorkoutPreviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Low Energy'), findsWidgets);
      expect(find.textContaining('Temporary for this workout'), findsWidgets);
    });

    testWidgets('comeback shows badge', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const WorkoutPreviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Comeback'), findsWidgets);
      expect(find.textContaining('Temporary for this workout'), findsWidgets);
    });

    testWidgets('preview uses same adapted inputs as home', (tester) async {
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
            home: const WorkoutPreviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Effective duration for 20 -> 15 for low energy
      expect(find.textContaining('15 min target'), findsWidgets);
    });
  });
}
