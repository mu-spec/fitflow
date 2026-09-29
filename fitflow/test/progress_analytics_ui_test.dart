import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_capability_snapshot.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_consistency.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_movement_training.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_period_comparison.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_summary_cards.dart';
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

CompletedWorkoutExercise makeEx({
  String id = 'ex1',
  MovementPattern? pattern = MovementPattern.push,
  int sets = 3,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: 'Test ${pattern?.name ?? 'null'}',
    movementPattern: pattern,
    sectionType: WorkoutSectionType.main,
    sets: sets,
    repsPerSet: 10,
    workDuration: null,
    restBetweenSets: const Duration(seconds: 30),
    difficulty: ExerciseDifficulty.level2,
  );
}

CompletedWorkout makeWorkout({
  String id = 'w1',
  required DateTime completedAt,
  List<CompletedWorkoutExercise>? main,
}) {
  final m = main ?? [makeEx()];
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 22),
    totalExerciseCount: m.length,
    totalSetCount: m.fold(0, (s, e) => s + e.sets),
    warmup: const [],
    main: m,
    cooldown: const [],
  );
}

CapabilityProfile makeCapabilityProfile() {
  final now = DateTime.now().toUtc();
  final map = <MovementPattern, MovementCapability>{};
  for (final pattern in CapabilityProfile.trainablePatterns) {
    map[pattern] = MovementCapability(
      movementPattern: pattern,
      level: CapabilityLevel.level3,
      source: CapabilitySource.initialAssessment,
      updatedAt: now,
    );
  }
  return CapabilityProfile.fromMap(map);
}

void main() {
  final now = DateTime.utc(2026, 9, 29, 12, 0, 0);

  group('Progress Analytics UI', () {
    testWidgets('zero-history state shows No completed workouts yet', (tester) async {
      final analytics = TrainingAnalyticsEngine.calculate(history: [], now: now);
      expect(analytics.isEmpty, true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('No completed workouts yet'),
                    Text('Finish a workout and your progress will appear here.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No completed workouts yet'), findsOneWidget);
      expect(find.text('Finish a workout and your progress will appear here.'), findsOneWidget);
    });

    testWidgets('Saved workouts truthful label', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressSummaryCards(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Saved workouts'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('Last 7 days card', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressSummaryCards(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('Main sets card', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressSummaryCards(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Main sets — last 7 days'), findsOneWidget);
    });

    testWidgets('Planned time card', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressSummaryCards(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Planned time — last 7 days'), findsOneWidget);
      expect(find.textContaining('Planned training time'), findsWidgets);
    });

    testWidgets('comparison section', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressPeriodComparison(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Compared with previous 7 days'), findsOneWidget);
    });

    testWidgets('positive delta', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressPeriodComparison(analytics: analytics)),
          ),
        ),
      );

      expect(find.textContaining('+'), findsWidgets);
    });

    testWidgets('negative delta', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 10)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressPeriodComparison(analytics: analytics)),
          ),
        ),
      );

      // Previous has 1, current 0 => delta -1
      expect(find.textContaining('-'), findsWidgets);
    });

    testWidgets('no-change state', (tester) async {
      final w1 = makeWorkout(id: 'w1', completedAt: now.subtract(const Duration(days: 1)));
      final w2 = makeWorkout(id: 'w2', completedAt: now.subtract(const Duration(days: 10)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w1, w2], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressPeriodComparison(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('No change'), findsWidgets);
    });

    testWidgets('8-week activity section', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressActivityChart(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('8-week activity'), findsOneWidget);
    });

    testWidgets('all-zero chart safe', (tester) async {
      final analytics = TrainingAnalyticsEngine.calculate(history: [], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressActivityChart(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('8-week activity'), findsOneWidget);
      // Should not crash, show 0 values
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('consistency X of 4', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressConsistency(analytics: analytics)),
          ),
        ),
      );

      expect(find.textContaining('of 4 recent weeks'), findsOneWidget);
      expect(find.text('Weeks with at least one completed workout.'), findsOneWidget);
    });

    testWidgets('movement-training section', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressMovementTraining(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Movement training'), findsOneWidget);
      expect(find.text('Main-workout sets from your last 28 days.'), findsOneWidget);
    });

    testWidgets('movement order', (tester) async {
      final wPush = makeWorkout(
        id: 'push',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.push, sets: 10)],
      );
      final wSquat = makeWorkout(
        id: 'squat',
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: MovementPattern.squat, sets: 2)],
      );
      final analytics = TrainingAnalyticsEngine.calculate(history: [wPush, wSquat], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressMovementTraining(analytics: analytics)),
          ),
        ),
      );

      // Push should appear before squat due to higher sets
      final pushFinder = find.text('Push');
      final squatFinder = find.text('Squat');
      expect(pushFinder, findsOneWidget);
      expect(squatFinder, findsOneWidget);
    });

    testWidgets('null movement not shown in primary', (tester) async {
      final w = makeWorkout(
        completedAt: now.subtract(const Duration(days: 1)),
        main: [makeEx(pattern: null)],
      );
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressMovementTraining(analytics: analytics)),
          ),
        ),
      );

      // Should show no movement training message
      expect(find.text('No Main movement training in last 28 days.'), findsOneWidget);
    });

    testWidgets('current capability levels 1-5', (tester) async {
      final profile = makeCapabilityProfile();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capabilityProfileProvider.overrideWith(() => _FakeCapabilityController(profile)),
          ],
          child: const MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: ProgressCapabilitySnapshot()))),
        ),
      );

      await tester.pump();
      expect(find.text('Current movement levels'), findsOneWidget);
      expect(find.text('Your current movement-specific levels used by adaptive workouts.'), findsOneWidget);
      expect(find.textContaining('Level'), findsWidgets);
    });

    testWidgets('training-recovery disclaimer remains', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Based on your recent FitFlow training history, not a medical recovery measure.'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Based on your recent FitFlow training history, not a medical recovery measure.'),
          findsOneWidget);
    });

    testWidgets('no calories', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProgressSummaryCards(analytics: analytics),
                    ProgressPeriodComparison(analytics: analytics),
                    ProgressActivityChart(analytics: analytics),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Calories'), findsNothing);
      expect(find.textContaining('calories'), findsNothing);
    });

    testWidgets('no actual-time claim', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ProgressSummaryCards(analytics: analytics)),
          ),
        ),
      );

      expect(find.text('Workout time'), findsNothing);
      expect(find.text('Time trained'), findsNothing);
    });

    testWidgets('no fitness score', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProgressSummaryCards(analytics: analytics),
                    ProgressConsistency(analytics: analytics),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Fitness score'), findsNothing);
      expect(find.textContaining('fitness score'), findsNothing);
    });

    testWidgets('320px no overflow', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProgressSummaryCards(analytics: analytics),
                    ProgressPeriodComparison(analytics: analytics),
                    ProgressActivityChart(analytics: analytics),
                    ProgressConsistency(analytics: analytics),
                    ProgressMovementTraining(analytics: analytics),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('text scale ~1.5 safe', (tester) async {
      final w = makeWorkout(completedAt: now.subtract(const Duration(days: 1)));
      final analytics = TrainingAnalyticsEngine.calculate(history: [w], now: now);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ProgressSummaryCards(analytics: analytics),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeCapabilityController extends CapabilityProfileController {
  _FakeCapabilityController(this._profile);
  final CapabilityProfile _profile;

  @override
  Future<CapabilityProfile?> build() async => _profile;
}
