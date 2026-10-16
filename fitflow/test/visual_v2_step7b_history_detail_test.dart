import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletedWorkoutExercise _exercise({
  required String id,
  required String name,
  required MovementPattern? movementPattern,
  required WorkoutSectionType sectionType,
  required int sets,
  required int? repsPerSet,
  required Duration? workDuration,
  required Duration restBetweenSets,
  required ExerciseDifficulty difficulty,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: name,
    movementPattern: movementPattern,
    sectionType: sectionType,
    sets: sets,
    repsPerSet: repsPerSet,
    workDuration: workDuration,
    restBetweenSets: restBetweenSets,
    difficulty: difficulty,
  );
}

CompletedWorkout _storedWorkout({
  String id = 'stored-session',
  DateTime? completedAt,
  Duration? targetDuration = const Duration(minutes: 25),
  Duration? estimatedDuration = const Duration(minutes: 21),
  List<CompletedWorkoutExercise>? warmup,
  List<CompletedWorkoutExercise>? main,
  List<CompletedWorkoutExercise>? cooldown,
  int totalExerciseCount = 3,
  int totalSetCount = 6,
}) {
  return CompletedWorkout(
    id: id,
    completedAt: completedAt ?? DateTime.utc(2026, 10, 5, 13, 24),
    targetDuration: targetDuration,
    estimatedDuration: estimatedDuration,
    totalExerciseCount: totalExerciseCount,
    totalSetCount: totalSetCount,
    warmup: warmup ??
        [
          _exercise(
            id: 'stored-warmup',
            name: 'Stored March in Place',
            movementPattern: MovementPattern.warmup,
            sectionType: WorkoutSectionType.warmup,
            sets: 2,
            repsPerSet: null,
            workDuration: const Duration(seconds: 30),
            restBetweenSets: const Duration(seconds: 15),
            difficulty: ExerciseDifficulty.level1,
          ),
        ],
    main: main ??
        [
          _exercise(
            id: 'stored-main',
            name: 'Stored Chair Squat',
            movementPattern: MovementPattern.squat,
            sectionType: WorkoutSectionType.main,
            sets: 3,
            repsPerSet: 8,
            workDuration: null,
            restBetweenSets: const Duration(seconds: 45),
            difficulty: ExerciseDifficulty.level2,
          ),
        ],
    cooldown: cooldown ??
        [
          _exercise(
            id: 'stored-cooldown',
            name: 'Stored Seated Stretch',
            movementPattern: MovementPattern.cooldown,
            sectionType: WorkoutSectionType.cooldown,
            sets: 1,
            repsPerSet: null,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero,
            difficulty: ExerciseDifficulty.level1,
          ),
        ],
  );
}

Future<void> _saveHistory(List<CompletedWorkout> workouts) async {
  final preferences = await SharedPreferences.getInstance();
  final saved = await WorkoutHistoryStorage(preferences).saveAll(workouts);
  expect(saved, isTrue);
}

Widget _detailApp(
  String sessionId, {
  required ThemeData theme,
  double textScale = 1,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: ProgressHistoryDetailScreen(sessionId: sessionId),
    ),
  );
}

GoRouter _progressRouter() => GoRouter(
      initialLocation: AppRoutes.progress,
      routes: [
        GoRoute(
          path: AppRoutes.progress,
          builder: (context, state) => const ProgressScreen(),
          routes: [
            GoRoute(
              path: 'history/:sessionId',
              builder: (context, state) => ProgressHistoryDetailScreen(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
          ],
        ),
      ],
    );

Widget _navigationApp(GoRouter router) => ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );

void main() {
  final l = englishAppLocalizations();

  group('Visual V2 Step 7B — Workout History Detail', () {
    testWidgets('renders stored facts, sections, and exercise snapshots',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final workout = _storedWorkout();
      await _saveHistory([workout]);
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(
          _detailApp(workout.id, theme: AppTheme.light),
        );
        await tester.pumpAndSettle();

        expect(find.text(l.workoutDetail), findsOneWidget);
        expect(find.text(l.trainingHistoryCompleted), findsOneWidget);
        final detailContext =
            tester.element(find.byType(ProgressHistoryDetailScreen));
        expect(
          find.text(FitFlowLocaleFormat.formatDateTime(
            detailContext,
            workout.completedAt,
          )),
          findsOneWidget,
        );

        expect(find.text(l.trainingPlannedDuration), findsOneWidget);
        expect(find.text(l.minutes(25)), findsOneWidget);
        expect(find.text(l.trainingEstimatedDuration), findsOneWidget);
        expect(find.text(l.minutes(21)), findsOneWidget);
        expect(find.text(l.trainingTotalExercises), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text(l.trainingTotalSets), findsOneWidget);
        expect(find.text('6'), findsOneWidget);

        expect(find.text('Stored March in Place'), findsOneWidget);
        expect(find.text('Stored Chair Squat'), findsOneWidget);
        expect(find.text('Stored Seated Stretch'), findsOneWidget);
        expect(
          find.text('${l.patternWarmup} • ${l.assessmentChoice1}'),
          findsOneWidget,
        );
        expect(
          find.text('${l.patternSquat} • ${l.assessmentChoice2}'),
          findsOneWidget,
        );
        expect(
          find.text('${l.patternCooldown} • ${l.assessmentChoice1}'),
          findsOneWidget,
        );
        expect(
          find.text(l.trainingWorkloadTimed(2, l.seconds(30))),
          findsOneWidget,
        );
        expect(find.text(l.trainingWorkloadReps(3, 8)), findsOneWidget);
        expect(
          find.text(l.trainingWorkloadTimed(1, l.seconds(20))),
          findsOneWidget,
        );
        expect(find.text(l.trainingRest(l.seconds(15))), findsOneWidget);
        expect(find.text(l.trainingRest(l.seconds(45))), findsOneWidget);
        expect(find.text(l.trainingRest(l.seconds(0))), findsOneWidget);

        final warmupHeading = tester.getSemantics(find.text(l.flowWarmup));
        final mainHeading = tester.getSemantics(find.text(l.flowMain));
        final cooldownHeading = tester.getSemantics(find.text(l.flowCooldown));
        expect(
          tester
              .getSemantics(find.text(l.trainingHistoryCompleted))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        expect(
            warmupHeading.getSemanticsData().flagsCollection.isHeader, isTrue);
        expect(mainHeading.getSemanticsData().flagsCollection.isHeader, isTrue);
        expect(
          cooldownHeading.getSemanticsData().flagsCollection.isHeader,
          isTrue,
        );
        expect(
          tester.getTopLeft(find.text(l.flowWarmup)).dy,
          lessThan(tester.getTopLeft(find.text(l.flowMain)).dy),
        );
        expect(
          tester.getTopLeft(find.text(l.flowMain)).dy,
          lessThan(tester.getTopLeft(find.text(l.flowCooldown)).dy),
        );
        expect(
          tester.getTopLeft(find.text('Stored March in Place')).dy,
          lessThan(tester.getTopLeft(find.text('Stored Chair Squat')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Stored Chair Squat')).dy,
          lessThan(tester.getTopLeft(find.text('Stored Seated Stretch')).dy),
        );

        expect(
            find.textContaining('calories', findRichText: true), findsNothing);
        expect(find.textContaining('Calories'), findsNothing);
        expect(find.textContaining('score'), findsNothing);
        expect(find.textContaining('intensity'), findsNothing);
        expect(find.textContaining('recovery'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('null duration fallbacks and not-found state stay unchanged',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _saveHistory([
        _storedWorkout(
          id: 'without-durations',
          targetDuration: null,
          estimatedDuration: null,
          warmup: const [],
          main: const [],
          cooldown: const [],
          totalExerciseCount: 0,
          totalSetCount: 0,
        ),
      ]);

      await tester.pumpWidget(
        _detailApp('without-durations', theme: AppTheme.light),
      );
      await tester.pumpAndSettle();
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text(l.trainingNoExercises), findsNWidgets(3));

      await tester.pumpWidget(
        _detailApp('missing-session', theme: AppTheme.light),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.trainingHistoryMissing), findsOneWidget);
      expect(find.text(l.trainingHistoryMissingHelp), findsOneWidget);
      expect(find.text(l.trainingNoExercises), findsNothing);
      expect(find.text(l.startAWorkout), findsNothing);
      expect(find.text('Stored March in Place'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light and dark themes fit all requested viewport sizes',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final workout = _storedWorkout();
      await _saveHistory([workout]);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;

      const sizes = [
        Size(320, 700),
        Size(390, 844),
        Size(600, 900),
        Size(840, 1000),
        Size(900, 320),
      ];

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        for (final size in sizes) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(_detailApp(workout.id, theme: theme));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${theme.brightness} at ${size.width}x${size.height}',
          );
        }
      }

      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpWidget(
        _detailApp(workout.id, theme: AppTheme.dark, textScale: 2),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Stored Seated Stretch'));
      expect(find.text('Stored March in Place'), findsOneWidget);
      expect(find.text('Stored Chair Squat'), findsOneWidget);
      expect(find.text('Stored Seated Stretch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Progress row opens the existing detail route and Back returns',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final workout = _storedWorkout(
        completedAt: DateTime.now().toUtc(),
      );
      await _saveHistory([workout]);
      final router = _progressRouter();
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();

      try {
        await tester.pumpWidget(_navigationApp(router));
        await tester.pumpAndSettle();

        final historyRow = find.byKey(
          ValueKey<String>('progress_recent_workout_${workout.id}'),
        );
        await tester.ensureVisible(historyRow);
        await tester.tap(historyRow);
        await tester.pumpAndSettle();
        expect(find.byType(ProgressHistoryDetailScreen), findsOneWidget);
        expect(find.text(l.workoutDetail), findsOneWidget);

        final backTooltip = MaterialLocalizations.of(
          tester.element(find.byType(AppBar)),
        ).backButtonTooltip;
        final backButton = find.byTooltip(backTooltip);
        expect(backButton, findsOneWidget);
        expect(tester.getSize(backButton).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .getSemantics(backButton)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(ProgressHistoryDetailScreen), findsNothing);
        expect(historyRow, findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });
}
