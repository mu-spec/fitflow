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
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
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
  return const UserFitnessProfile(
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

WorkoutPlan createPlan() {
  final user = createUserProfile();
  final cap = createFullProfile(CapabilityLevel.level3);
  return WorkoutGenerator.generateCatalog(
    WorkoutGenerationContext(userProfile: user, capabilityProfile: cap),
  )!;
}

void main() {
  group('Completion', () {
    test('final Cooldown set -> completed', () {
      final plan = createPlan();
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
      controller.dispose();
    });

    test('completedSets == totalSets', () {
      final plan = createPlan();
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

      expect(controller.state.completedSets, controller.state.totalSets);
      controller.dispose();
    });

    testWidgets('Workout complete visible', (tester) async {
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

      for (int i = 0; i < 300; i++) {
        if (find.text('Workout complete').evaluate().isNotEmpty) break;
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip rest').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip rest'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip transition').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip transition'));
          await tester.pumpAndSettle();
        } else if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        } else if (find.text('Start cooldown').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start cooldown'));
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('Workout complete'), findsOneWidget);
    });

    testWidgets('truthful exercise/set data shown', (tester) async {
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

      for (int i = 0; i < 300; i++) {
        if (find.text('Workout complete').evaluate().isNotEmpty) break;
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip rest').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip rest'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip transition').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip transition'));
          await tester.pumpAndSettle();
        } else if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        } else if (find.text('Start cooldown').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start cooldown'));
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.textContaining('Exercises'), findsOneWidget);
      expect(find.textContaining('Sets'), findsOneWidget);
      expect(find.textContaining('Target duration'), findsOneWidget);
    });

    testWidgets('no calories/XP/streak/fake history', (tester) async {
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

      for (int i = 0; i < 300; i++) {
        if (find.text('Workout complete').evaluate().isNotEmpty) break;
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip rest').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip rest'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip transition').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip transition'));
          await tester.pumpAndSettle();
        } else if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        } else if (find.text('Start cooldown').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start cooldown'));
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.textContaining('calories', findRichText: true), findsNothing);
      expect(find.textContaining('Calories'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('streak', findRichText: true), findsNothing);
      expect(find.textContaining('Streak'), findsNothing);
    });

    testWidgets('Done returns Home', (tester) async {
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

      for (int i = 0; i < 300; i++) {
        if (find.text('Workout complete').evaluate().isNotEmpty) break;
        if (find.text('Set complete').evaluate().isNotEmpty) {
          await tester.tap(find.text('Set complete'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip rest').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip rest'));
          await tester.pumpAndSettle();
        } else if (find.text('Skip transition').evaluate().isNotEmpty) {
          await tester.tap(find.text('Skip transition'));
          await tester.pumpAndSettle();
        } else if (find.text('Continue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();
        } else if (find.text('Start cooldown').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start cooldown'));
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.text('Workout complete'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should be back on home, which shows "Your adaptive workout" or "FITFLOW"
      expect(find.text('Your adaptive workout').evaluate().isNotEmpty || find.text('FITFLOW').evaluate().isNotEmpty, true);
    });
  });
}
