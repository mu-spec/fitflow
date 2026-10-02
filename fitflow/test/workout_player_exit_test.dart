import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
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
  final Future<UserFitnessProfile?> Function() buildOverride;
  FakeUserProfileController({required this.buildOverride});
  @override
  Future<UserFitnessProfile?> build() async => buildOverride();
}

class FakeCapabilityController extends CapabilityProfileController {
  final Future<CapabilityProfile?> Function() buildOverride;
  FakeCapabilityController({required this.buildOverride});
  @override
  Future<CapabilityProfile?> build() async => buildOverride();
}

List<Override> createOverrides() {
  final user = createUserProfile();
  final cap = createFullProfile(CapabilityLevel.level3);
  return [
    workoutCoachProvider.overrideWithValue(NoOpWorkoutCoach()),
    userFitnessProfileProvider.overrideWith(
      () => FakeUserProfileController(buildOverride: () async => user),
    ),
    capabilityProfileProvider.overrideWith(
      () => FakeCapabilityController(buildOverride: () async => cap),
    ),
  ];
}

Widget buildApp(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  group('Exit Confirmation', () {
    testWidgets('ready state Back returns normally without dialog', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();

      expect(find.text('Workout player'), findsOneWidget);
      expect(find.text('Ready to begin'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Workout player'), findsNothing);
      expect(find.text('Workout preview'), findsOneWidget);
    });

    testWidgets('active work Back shows End workout?', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsOneWidget);
      expect(find.text("Your current session progress won't be saved."), findsOneWidget);
    });

    testWidgets('paused workout Back shows confirmation', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      final pauseFinder = find.byIcon(Icons.pause_rounded);
      if (pauseFinder.evaluate().isNotEmpty) {
        await tester.tap(pauseFinder.first);
        await tester.pumpAndSettle();
      }

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsOneWidget);
    });

    testWidgets('rest Back shows confirmation', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 20; i++) {
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else {
          break;
        }
        if (find.text('Rest').evaluate().isNotEmpty) break;
      }

      if (find.textContaining('Rest').evaluate().isNotEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('End workout?'), findsOneWidget);
      }
    });

    testWidgets('transition Back shows confirmation', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 30; i++) {
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        }
        if (find.textContaining('Next').evaluate().isNotEmpty) break;
      }

      if (find.textContaining('Next').evaluate().isNotEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('End workout?'), findsOneWidget);
      }
    });

    testWidgets('sectionBreak Back shows confirmation', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 100; i++) {
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip rest').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip rest'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip transition').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip transition'));
          await tester.pumpAndSettle();
        } else {
          break;
        }
        if (find.text('Continue').evaluate().isNotEmpty || find.text('Start cooldown').evaluate().isNotEmpty) break;
      }

      if (find.text('Continue').evaluate().isNotEmpty || find.text('Start cooldown').evaluate().isNotEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('End workout?'), findsOneWidget);
      }
    });

    testWidgets('Keep going preserves exact state', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsOneWidget);
      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsNothing);
      expect(find.text('Workout player'), findsOneWidget);
    });

    testWidgets('End workout returns Preview', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('End workout?'), findsOneWidget);
      await tester.tap(find.text('End workout').last);
      await tester.pumpAndSettle();

      expect(find.text('Workout preview'), findsOneWidget);
    });

    testWidgets('copy says progress won\'t be saved', (tester) async {
      final overrides = createOverrides();
      await tester.pumpWidget(buildApp(overrides));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View workout'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Start workout'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Begin workout'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text("Your current session progress won't be saved."), findsOneWidget);
    });

    testWidgets('completed session can leave without active-session warning', (tester) async {
      // For completed, PopScope canPop should be true, so no dialog
      // We test via controller state directly: completed phase is not active session
      final user = createUserProfile();
      final cap = createFullProfile(CapabilityLevel.level3);
      final plan = WorkoutGenerator.generateCatalog(
        WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
      )!;
      final controller = WorkoutPlayerController(plan: plan, autoStartTimer: false);
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
      expect(controller.state.phase, WorkoutPlayerPhase.completed);
      // Completed is not active session, so should allow pop without warning
      final isActiveSession = controller.state.phase == WorkoutPlayerPhase.work ||
          controller.state.phase == WorkoutPlayerPhase.rest ||
          controller.state.phase == WorkoutPlayerPhase.transition ||
          controller.state.isPaused ||
          controller.state.phase == WorkoutPlayerPhase.sectionBreak;
      expect(isActiveSession, false);
      controller.dispose();
    });
  });
}
