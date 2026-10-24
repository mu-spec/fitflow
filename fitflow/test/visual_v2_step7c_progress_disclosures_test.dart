import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_capability_snapshot.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_consistency.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_movement_training.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_period_comparison.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recovery_section.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/recovery/training_recovery_engine.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 16, 12);

CompletedWorkoutExercise _exercise({
  required String id,
  required MovementPattern pattern,
  required int sets,
}) =>
    CompletedWorkoutExercise(
      exerciseId: id,
      exerciseName: 'Fixture ${pattern.label}',
      movementPattern: pattern,
      sectionType: WorkoutSectionType.main,
      sets: sets,
      repsPerSet: 10,
      restBetweenSets: const Duration(seconds: 30),
      difficulty: ExerciseDifficulty.level2,
    );

CompletedWorkout _workout({
  required String id,
  required int daysAgo,
  required List<CompletedWorkoutExercise> main,
}) =>
    CompletedWorkout(
      id: id,
      completedAt: _now.subtract(Duration(days: daysAgo)),
      targetDuration: const Duration(minutes: 30),
      estimatedDuration: const Duration(minutes: 20),
      totalExerciseCount: main.length,
      totalSetCount: main.fold(0, (total, exercise) => total + exercise.sets),
      warmup: const [],
      main: main,
      cooldown: const [],
    );

List<CompletedWorkout> _history() => [
      _workout(
        id: 'current-push',
        daysAgo: 1,
        main: [
          _exercise(id: 'push', pattern: MovementPattern.push, sets: 2),
        ],
      ),
      _workout(
        id: 'previous-squat',
        daysAgo: 10,
        main: [
          _exercise(id: 'squat', pattern: MovementPattern.squat, sets: 3),
        ],
      ),
      _workout(
        id: 'three-weeks-pull',
        daysAgo: 24,
        main: [
          _exercise(id: 'pull', pattern: MovementPattern.pull, sets: 4),
        ],
      ),
    ];

TrainingAnalytics _analytics() => TrainingAnalyticsEngine.calculate(
      history: _history(),
      now: _now,
    );

CapabilityProfile _profile() {
  final capabilities = <MovementPattern, MovementCapability>{
    for (final pattern in CapabilityProfile.trainablePatterns)
      pattern: MovementCapability(
        movementPattern: pattern,
        level: CapabilityLevel.level3,
        source: CapabilitySource.initialAssessment,
        updatedAt: _now,
      ),
  };
  return CapabilityProfile.fromMap(capabilities);
}

class _ProfileController extends CapabilityProfileController {
  _ProfileController(this.profile);

  final CapabilityProfile? profile;

  @override
  Future<CapabilityProfile?> build() async => profile;
}

Widget _allProgressSurfaces({
  required ThemeData theme,
  double textScale = 1,
}) {
  final history = _history();
  final analytics =
      TrainingAnalyticsEngine.calculate(history: history, now: _now);
  final recovery =
      TrainingRecoveryEngine.calculate(history: history, now: _now);

  return ProviderScope(
    overrides: [
      capabilityProfileProvider
          .overrideWith(() => _ProfileController(_profile())),
    ],
    child: MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProgressActivityChart(analytics: analytics),
                  const SizedBox(height: 24),
                  ProgressPeriodComparison(analytics: analytics),
                  const SizedBox(height: 24),
                  ProgressConsistency(analytics: analytics),
                  const SizedBox(height: 24),
                  ProgressMovementTraining(analytics: analytics),
                  const SizedBox(height: 24),
                  const ProgressCapabilitySnapshot(),
                  const SizedBox(height: 24),
                  ProgressRecoverySection(
                    recoveryStatuses: recovery,
                    now: _now,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _disclosuresApp({
  required CapabilityProfile? profile,
  required Widget child,
}) =>
    ProviderScope(
      overrides: [
        capabilityProfileProvider
            .overrideWith(() => _ProfileController(profile)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

void main() {
  group('Visual V2 Step 7C — Remaining Progress disclosures', () {
    testWidgets('keeps movement, capability, recovery values and order',
        (tester) async {
      final analytics = _analytics();
      final recovery = TrainingRecoveryEngine.calculate(
        history: _history(),
        now: _now,
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _disclosuresApp(
            profile: _profile(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressMovementTraining(analytics: analytics),
                const SizedBox(height: 24),
                const ProgressCapabilitySnapshot(),
                const SizedBox(height: 24),
                ProgressRecoverySection(
                  recoveryStatuses: recovery,
                  now: _now,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final movementLabels = [
          'Pull: 4 Main sets, 1 sessions, Last trained 24 days ago',
          'Squat: 3 Main sets, 1 sessions, Last trained 10 days ago',
          'Push: 2 Main sets, 1 sessions, Last trained yesterday',
        ];
        for (final label in movementLabels) {
          expect(find.bySemanticsLabel(label), findsOneWidget);
        }
        for (var i = 1; i < movementLabels.length; i++) {
          expect(
            tester.getTopLeft(find.bySemanticsLabel(movementLabels[i - 1])).dy,
            lessThan(
              tester.getTopLeft(find.bySemanticsLabel(movementLabels[i])).dy,
            ),
            reason: 'movement list order stays as supplied by the engine',
          );
        }
        expect(find.text('Movement training'), findsOneWidget);
        expect(find.text('2 sets'), findsOneWidget);
        expect(find.text('4 sets'), findsOneWidget);
        expect(find.text('3 sets'), findsOneWidget);
        expect(find.text('1 sessions'), findsNWidgets(3));
        expect(find.text('Last trained yesterday'), findsNWidgets(2));

        final capabilityFinder = find.byType(ProgressCapabilitySnapshot);
        final solidRows = find.descendant(
          of: capabilityFinder,
          matching: find.text('Solid'),
        );
        expect(solidRows,
            findsNWidgets(CapabilityProfile.trainablePatterns.length));
        final capabilityPositions = CapabilityProfile.trainablePatterns
            .map(
              (pattern) => tester
                  .getTopLeft(
                    find
                        .descendant(
                          of: capabilityFinder,
                          matching: find.text(pattern.label),
                        )
                        .first,
                  )
                  .dy,
            )
            .toList();
        for (var i = 1; i < capabilityPositions.length; i++) {
          expect(capabilityPositions[i - 1], lessThan(capabilityPositions[i]));
        }

        final recoveryFinder = find.byType(ProgressRecoverySection);
        expect(
          find.descendant(
            of: recoveryFinder,
            matching: find.text(
              'Time since each movement was trained in FitFlow, not a medical recovery measure.',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recoveryFinder,
            matching: find.text('Resting'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recoveryFinder,
            matching: find.text('More rested'),
          ),
          findsNWidgets(2),
        );
        expect(
          find.descendant(
            of: recoveryFinder,
            matching: find.text('1 sessions • 2 sets this week'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recoveryFinder,
            matching: find.text('0 sessions • 0 sets this week'),
          ),
          findsNWidgets(2),
        );
        expect(find.byType(Card), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('keeps the no-profile and no-recovery-history states',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _disclosuresApp(
            profile: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProgressCapabilitySnapshot(),
                const SizedBox(height: 24),
                ProgressRecoverySection(recoveryStatuses: const [], now: _now),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final l = tester.element(find.byType(ProgressCapabilitySnapshot)).l10n;
        expect(find.text(l.trainingMovementMissing), findsOneWidget);
        expect(
          find.text(
            'No recent training data. Complete workouts with different movements to see recovery.',
          ),
          findsOneWidget,
        );
        expect(
            find.text(
                'Time since each movement was trained in FitFlow, not a medical recovery measure.'),
            findsOneWidget);
        expect(find.byType(Card), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'changed Progress surfaces wrap safely across sizes, themes and large text',
        (tester) async {
      const sizes = [
        Size(320, 700),
        Size(390, 844),
        Size(600, 900),
        Size(840, 1000),
        Size(900, 320),
      ];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        for (final size in sizes) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            _allProgressSurfaces(theme: theme),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at $size in ${theme.brightness} theme',
          );
          expect(find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical), findsOneWidget);
        }
      }

      tester.view.physicalSize = const Size(320, 700);
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          _allProgressSurfaces(theme: theme, textScale: 2),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at 320×700 with 2× text in ${theme.brightness}',
        );
      }
    });
  });
}
