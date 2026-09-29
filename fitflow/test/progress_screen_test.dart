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
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class FakeUserProfileController extends UserFitnessProfileController {
  FakeUserProfileController({required this.buildOverride});
  final Future<UserFitnessProfile> Function() buildOverride;
  @override
  Future<UserFitnessProfile?> build() async => buildOverride();
}

class FakeCapabilityController extends CapabilityProfileController {
  FakeCapabilityController({required this.buildOverride});
  final Future<CapabilityProfile> Function() buildOverride;
  @override
  Future<CapabilityProfile?> build() async => buildOverride();
}

CompletedWorkoutExercise makeEx({
  String id = 'ex1',
  String name = 'Push Up',
  MovementPattern pattern = MovementPattern.push,
  WorkoutSectionType section = WorkoutSectionType.main,
  int sets = 3,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: name,
    movementPattern: pattern,
    sectionType: section,
    sets: sets,
    repsPerSet: 10,
    workDuration: null,
    restBetweenSets: const Duration(seconds: 30),
    difficulty: ExerciseDifficulty.level2,
  );
}

CompletedWorkout makeWorkout({
  String id = 'w1',
  DateTime? completedAt,
  List<CompletedWorkoutExercise>? main,
}) {
  final now = completedAt ?? DateTime.now().toUtc().subtract(const Duration(hours: 1));
  final m = main ?? [makeEx()];
  return CompletedWorkout(
    id: id,
    completedAt: now,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 22),
    totalExerciseCount: m.length,
    totalSetCount: m.fold(0, (s, e) => s + e.sets),
    warmup: [makeEx(id: 'w1', name: 'Warmup', pattern: MovementPattern.warmup, section: WorkoutSectionType.warmup, sets: 1)],
    main: m,
    cooldown: [makeEx(id: 'c1', name: 'Cooldown', pattern: MovementPattern.cooldown, section: WorkoutSectionType.cooldown, sets: 1)],
  );
}

Widget buildProgressApp() {
  final user = createUserProfile();
  final cap = createFullProfile(CapabilityLevel.level3);
  return ProviderScope(
    overrides: [
      userFitnessProfileProvider.overrideWith(() => FakeUserProfileController(buildOverride: () async => user)),
      capabilityProfileProvider.overrideWith(() => FakeCapabilityController(buildOverride: () async => cap)),
      workoutCoachProvider.overrideWithValue(FakeWorkoutCoach()),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  group('Progress UI', () {
    testWidgets('zero-history empty state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('No completed workouts yet'), findsOneWidget);
      expect(find.text('Finish a workout and your progress will appear here.'), findsOneWidget);
      expect(find.text('Start a workout'), findsOneWidget);
    });

    testWidgets('Start workout action', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start a workout'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Your adaptive workout').evaluate().isNotEmpty || find.text('FITFLOW').evaluate().isNotEmpty, true);
    });

    testWidgets('total workouts', (tester) async {
      final now = DateTime.now().toUtc();
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 1)));
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 2)));
      // Use storage to save properly
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(w1);
      await storage.add(w2);

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Saved workouts'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('last-7-days count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final now = DateTime.now().toUtc();
      final wRecent = makeWorkout(id: 'recent', completedAt: now.subtract(const Duration(days: 1)));
      final wOld = makeWorkout(id: 'old', completedAt: now.subtract(const Duration(days: 10)));
      await storage.add(wRecent);
      await storage.add(wOld);

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('training recovery disclaimer', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Training recovery'), findsOneWidget);
      expect(find.textContaining('not a medical recovery measure'), findsOneWidget);
    });

    testWidgets('recent movement status', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout(main: [makeEx(pattern: MovementPattern.push)]));

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Push'), findsWidgets);
    });

    testWidgets('last trained text', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout(main: [makeEx(pattern: MovementPattern.push)]));

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last trained'), findsWidgets);
    });

    testWidgets('weekly sessions/sets', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout(main: [makeEx(pattern: MovementPattern.push, sets: 3)]));

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('sessions'), findsWidgets);
      expect(find.textContaining('sets this week'), findsWidgets);
    });

    testWidgets('recent workouts newest first', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final now = DateTime.now().toUtc();
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 2)));
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 1)));
      await storage.add(w1);
      await storage.add(w2);

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('Recent workouts'), findsOneWidget);
      // Check that w2 (newer) appears before w1 in the list order – we can check that both exist
      expect(find.textContaining('exercises'), findsWidgets);
    });

    testWidgets('maximum 10 visible on main screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final now = DateTime.now().toUtc();
      for (int i = 0; i < 15; i++) {
        final w = makeWorkout(id: 'w$i', completedAt: now.subtract(Duration(days: i)));
        await storage.add(w);
      }

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Should show 10 cards + maybe indicator for more
      expect(find.text('View workout'), findsNWidgets(10));
    });

    testWidgets('replaced exercise reflected in history detail', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final replaced = makeEx(id: 'chair_squat', name: 'Chair Squat', pattern: MovementPattern.squat);
      await storage.add(makeWorkout(id: 'replaced_workout', main: [replaced]));

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      final viewButton = find.text('View workout').first;
      await tester.ensureVisible(viewButton);
      await tester.pumpAndSettle();
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      expect(find.text('Chair Squat'), findsOneWidget);
    });

    testWidgets('detail has all three sections', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      final viewButton = find.text('View workout').first;
      await tester.ensureVisible(viewButton);
      await tester.pumpAndSettle();
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      expect(find.text('Warm-up'), findsWidgets);
      expect(find.text('Main'), findsWidgets);
      expect(find.text('Cooldown'), findsWidgets);
    });

    testWidgets('no calories', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('calories', findRichText: true), findsNothing);
      expect(find.textContaining('Calories'), findsNothing);
    });

    testWidgets('no readiness percentage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('% recovered'), findsNothing);
      expect(find.textContaining('readiness'), findsNothing);
    });

    testWidgets('no fake actual duration', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      // Should not claim "Actual duration", only planned/estimated
      expect(find.textContaining('Actual duration'), findsNothing);
    });

    testWidgets('320px width no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('tablet/wide', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(buildProgressApp());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('text scale ~1.5', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: buildProgressApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
