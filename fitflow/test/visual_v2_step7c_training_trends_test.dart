import 'dart:ui' show Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_consistency.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_period_comparison.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
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

TrainingAnalytics _fixtureAnalytics() => TrainingAnalyticsEngine.calculate(
      history: [
        _workout(
          id: 'week-8',
          daysAgo: 52,
          main: [
            _exercise(
                id: 'week-8-push', pattern: MovementPattern.push, sets: 2),
          ],
        ),
        _workout(
          id: 'week-7-a',
          daysAgo: 45,
          main: [
            _exercise(
                id: 'week-7-a-push', pattern: MovementPattern.push, sets: 1),
          ],
        ),
        _workout(
          id: 'week-7-b',
          daysAgo: 44,
          main: [
            _exercise(
                id: 'week-7-b-push', pattern: MovementPattern.push, sets: 2),
          ],
        ),
        _workout(
          id: 'week-5',
          daysAgo: 31,
          main: [
            _exercise(
                id: 'week-5-push', pattern: MovementPattern.push, sets: 4),
          ],
        ),
        _workout(
          id: 'week-4',
          daysAgo: 24,
          main: [
            _exercise(
                id: 'week-4-push', pattern: MovementPattern.push, sets: 3),
          ],
        ),
        _workout(
          id: 'previous-a',
          daysAgo: 10,
          main: [
            _exercise(
                id: 'previous-a-push', pattern: MovementPattern.push, sets: 2),
          ],
        ),
        _workout(
          id: 'previous-b',
          daysAgo: 9,
          main: [
            _exercise(
                id: 'previous-b-push', pattern: MovementPattern.push, sets: 3),
          ],
        ),
        _workout(
          id: 'current',
          daysAgo: 1,
          main: [
            _exercise(
                id: 'current-push', pattern: MovementPattern.push, sets: 2),
          ],
        ),
      ],
      now: _now,
    );

Widget _chartApp(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  bool disableAnimations = false,
}) =>
    MaterialApp(
      theme: theme ?? AppTheme.light,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: appChild!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

void _expectBarValues(
  WidgetTester tester,
  List<int> values,
) {
  final maxValue =
      values.fold<int>(0, (max, value) => value > max ? value : max);
  final bars = tester.widgetList<LinearProgressIndicator>(
    find.byType(LinearProgressIndicator),
  );
  expect(bars.length, 8);
  for (var i = 0; i < values.length; i++) {
    expect(
      bars.elementAt(i).value,
      maxValue == 0 ? 0 : values[i] / maxValue,
      reason: 'bucket $i must stay proportional to its engine value',
    );
  }
}

void main() {
  group('Visual V2 Step 7C — Training Trends', () {
    testWidgets('keeps all eight engine buckets and truthful proportional bars',
        (tester) async {
      final analytics = _fixtureAnalytics();
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _chartApp(ProgressActivityChart(analytics: analytics)),
        );
        await tester.pumpAndSettle();

        expect(analytics.trendBuckets, hasLength(8));
        final context = tester.element(find.byType(ProgressActivityChart));
        final l = context.l10n;
        final labels = analytics.trendBuckets.map((bucket) {
          final period = bucket.isCurrent
              ? l.trainingCurrentPeriod
              : l.trainingWeeksAgo(
                  analytics.trendBuckets.length - 1 - bucket.index,
                );
          return '$period · ${l.trainingActivityCount(bucket.workoutCount)}';
        }).toList();

        for (var i = 0; i < labels.length; i++) {
          expect(find.text(labels[i]), findsOneWidget);
          if (i > 0) {
            expect(
              tester.getTopLeft(find.text(labels[i - 1])).dy,
              lessThan(tester.getTopLeft(find.text(labels[i])).dy),
              reason: 'engine bucket order must remain oldest to current',
            );
          }

          final bucket = analytics.trendBuckets[i];
          final range =
              '${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), bucket.start)} – ${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), bucket.end)}';
          expect(find.text(range), findsOneWidget);
        }
        _expectBarValues(tester, [1, 2, 0, 1, 1, 0, 2, 1]);

        final workoutsChip =
            find.widgetWithText(ChoiceChip, l.trainingWorkouts);
        final setsChip = find.widgetWithText(ChoiceChip, l.trainingSets);
        expect(tester.getSize(workoutsChip).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(setsChip).height, greaterThanOrEqualTo(48));
        final workoutsSemantics =
            tester.getSemantics(workoutsChip).getSemanticsData();
        expect(workoutsSemantics.hasAction(SemanticsAction.tap), isTrue);
        expect(workoutsSemantics.flagsCollection.isSelected, Tristate.isTrue);

        await tester.tap(setsChip);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(setsChip).selected, isTrue);
        final setLabels = analytics.trendBuckets.map((bucket) {
          final period = bucket.isCurrent
              ? l.trainingCurrentPeriod
              : l.trainingWeeksAgo(
                  analytics.trendBuckets.length - 1 - bucket.index,
                );
          return '$period · ${l.trainingActivitySets(bucket.mainSetCount)}';
        }).toList();
        for (final label in setLabels) {
          expect(find.text(label), findsOneWidget);
        }
        _expectBarValues(tester, [2, 3, 0, 4, 3, 0, 5, 2]);

        await tester.tap(workoutsChip);
        await tester.pumpAndSettle();
        FocusScope.of(context).requestFocus();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(workoutsChip).selected, isTrue);

        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('period comparison keeps source values and signed deltas',
        (tester) async {
      final analytics = _fixtureAnalytics();
      await tester.pumpWidget(
        _chartApp(ProgressPeriodComparison(analytics: analytics)),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ProgressPeriodComparison));
      expect(find.text('Compared with previous 7 days'), findsOneWidget);
      expect(
          find.text(
              'Previous 7 days: [now - 14 days, now - 7 days). Current: [now - 7 days, now].'),
          findsOneWidget);

      expect(find.text('Prev: 2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.text(
          FitFlowLocaleFormat.formatWorkoutDelta(
            context.l10n,
            analytics.workoutDelta,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Prev: 5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('-3 Main sets'), findsOneWidget);
      expect(find.text('Prev: 40 min'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('-20 min planned'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsNWidgets(3));
      expect(find.textContaining('%'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('four-week consistency keeps each activity state textual',
        (tester) async {
      final analytics = _fixtureAnalytics();
      await tester.pumpWidget(
        _chartApp(ProgressConsistency(analytics: analytics)),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ProgressConsistency));
      final l = context.l10n;
      expect(find.text('Training consistency'), findsOneWidget);
      expect(find.text('3 of 4 recent weeks'), findsOneWidget);
      expect(find.text('Weeks with at least one completed workout.'),
          findsOneWidget);
      expect(
          find.text('Based on last 28 days divided into four 7-day periods.'),
          findsOneWidget);
      expect(find.text(l.trainingWeeksAgo(3)), findsOneWidget);
      expect(find.text(l.trainingActivityCount(1)), findsNWidgets(2));
      expect(find.text(l.trainingWeeksAgo(2)), findsOneWidget);
      expect(find.text(l.trainingActivityCount(0)), findsOneWidget);
      expect(find.text(l.trainingWeeksAgo(1)), findsOneWidget);
      expect(find.text(l.trainingCurrentPeriod), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty trend stays at zero and keeps its no-activity message',
        (tester) async {
      final analytics = TrainingAnalyticsEngine.calculate(
        history: const [],
        now: _now,
      );
      await tester.pumpWidget(
        _chartApp(ProgressActivityChart(analytics: analytics)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No workouts in last 8 weeks.'), findsOneWidget);
      _expectBarValues(tester, List<int>.filled(8, 0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('choice-chip state change honors reduced motion',
        (tester) async {
      final analytics = _fixtureAnalytics();
      await tester.pumpWidget(
        _chartApp(
          ProgressActivityChart(analytics: analytics),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final setsChip = find.widgetWithText(ChoiceChip, 'Sets');
      final chip = tester.widget<ChoiceChip>(setsChip);
      expect(
        chip.chipAnimationStyle!.selectAnimation?.duration,
        Duration.zero,
      );
      await tester.tap(setsChip);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(setsChip).selected, isTrue);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
