import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

UserFitnessProfile createUserProfile({
  WorkoutDuration duration = WorkoutDuration.twentyMinutes,
}) {
  return UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: duration,
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

class FakeHistoryController extends WorkoutHistoryController {
  final List<CompletedWorkout> fakeHistory;
  FakeHistoryController(this.fakeHistory);
  @override
  Future<List<CompletedWorkout>> build() async => fakeHistory;
}

CompletedWorkout makeWorkout(DateTime completedAt) {
  return CompletedWorkout(
    id: 'w_${completedAt.millisecondsSinceEpoch}',
    completedAt: completedAt,
    totalExerciseCount: 5,
    totalSetCount: 10,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 18),
    warmup: const <CompletedWorkoutExercise>[],
    main: const <CompletedWorkoutExercise>[],
    cooldown: const <CompletedWorkoutExercise>[],
  );
}

Widget buildHome({
  required List<Override> overrides,
  GoRouter? router,
}) {
  final home = const HomeScreen();
  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      home: home,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Home Session Mode UI', () {
    testWidgets('shows current mode Standard by default', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.text('Standard'), findsWidgets);
      expect(find.text('Adjust'), findsOneWidget);
    });

    testWidgets('shows Adjust control', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.text("Today's workout"), findsWidgets);
      expect(find.text('Adjust'), findsOneWidget);
    });

    testWidgets('tapping Adjust opens bottom sheet with options', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust'));
      await tester.pumpAndSettle();
      expect(find.text("Choose today's workout"), findsOneWidget);
      expect(find.text('Standard'), findsWidgets);
      expect(find.text('Low Energy'), findsWidgets);
      expect(find.text('Comeback'), findsWidgets);
      expect(find.text('Your normal adaptive workout'), findsOneWidget);
      expect(find.text('A shorter, easier workout for today'), findsOneWidget);
      expect(find.text('A gentler return workout after time away'), findsOneWidget);
      expect(find.text("This doesn't change your movement levels"), findsWidgets);
    });

    testWidgets('selecting Low Energy updates mode indicator', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Low Energy').last);
      await tester.pumpAndSettle();
      expect(find.text('Low Energy'), findsWidgets);
    });

    testWidgets('hero shows effective duration for low energy', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile(duration: WorkoutDuration.thirtyMinutes))),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
          workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 30 -> 20 for low energy
      expect(find.textContaining('20 min target'), findsOneWidget);
    });

    testWidgets('hero shows effective duration for comeback', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile(duration: WorkoutDuration.fortyFiveMinutes))),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
          workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('15 min target'), findsOneWidget);
    });

    testWidgets('comeback suggestion shows when >=14 days', (tester) async {
      final now = DateTime.now();
      final history = [makeWorkout(now.subtract(const Duration(days: 15)))];
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController(history)),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.textContaining('Returning after some time away?'), findsOneWidget);
      expect(find.text('Use Comeback'), findsOneWidget);
    });

    testWidgets('comeback suggestion not shown when <14 days', (tester) async {
      final now = DateTime.now();
      final history = [makeWorkout(now.subtract(const Duration(days: 5)))];
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController(history)),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.textContaining('Returning after some time away?'), findsNothing);
    });

    testWidgets('comeback suggestion not shown when no history', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.textContaining('Returning after some time away?'), findsNothing);
    });

    testWidgets('Use Comeback action sets mode to comeback', (tester) async {
      final now = DateTime.now();
      final history = [makeWorkout(now.subtract(const Duration(days: 20)))];
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
          workoutHistoryProvider.overrideWith(() => FakeHistoryController(history)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.standard);
      await tester.ensureVisible(find.text('Use Comeback'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Comeback'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.comeback);
    });

    testWidgets('temporary badge shows for low energy', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
          capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
          workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
        ],
      );
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Temporary for this workout'), findsWidgets);
    });

    testWidgets('no temporary badge for standard', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.text('Temporary for this workout'), findsNothing);
    });

    testWidgets('manual comeback always available via sheet even without suggestion', (tester) async {
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController([])),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adjust'));
      await tester.pumpAndSettle();
      expect(find.text('Comeback'), findsWidgets);
    });

    testWidgets('suggestion copy exact wording', (tester) async {
      final now = DateTime.now();
      final history = [makeWorkout(now.subtract(const Duration(days: 14)))];
      final overrides = [
        userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(createUserProfile())),
        capabilityProfileProvider.overrideWith(() => FakeCapabilityController(createFullProfile(CapabilityLevel.level3))),
        workoutHistoryProvider.overrideWith(() => FakeHistoryController(history)),
      ];
      await tester.pumpWidget(buildHome(overrides: overrides));
      await tester.pumpAndSettle();
      expect(find.text('Returning after some time away? Comeback gives you a shorter, gentler session without changing your movement levels.'), findsOneWidget);
    });
  });
}
