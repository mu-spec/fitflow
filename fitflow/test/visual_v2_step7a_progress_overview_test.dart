import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletedWorkout _workout({
  required String id,
  required DateTime completedAt,
  Duration? targetDuration,
  Duration? estimatedDuration,
  int totalExerciseCount = 2,
  int totalSetCount = 6,
}) {
  return CompletedWorkout(
    id: id,
    completedAt: completedAt,
    targetDuration: targetDuration,
    estimatedDuration: estimatedDuration,
    totalExerciseCount: totalExerciseCount,
    totalSetCount: totalSetCount,
    warmup: const [],
    main: const [],
    cooldown: const [],
  );
}

Future<void> _saveHistory(List<CompletedWorkout> workouts) async {
  final preferences = await SharedPreferences.getInstance();
  await WorkoutHistoryStorage(preferences).saveAll(workouts);
}

GoRouter _createRouter({
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return GoRouter(
    initialLocation: AppRoutes.progress,
    routes: [
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) {
          final media = MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          );
          return MediaQuery(
            data: media,
            child: const ProgressScreen(),
          );
        },
      ),
      GoRoute(
        path: '/progress/history/:sessionId',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('History detail: ${state.pathParameters['sessionId']}'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home destination')),
        ),
      ),
    ],
  );
}

Widget _buildApp(GoRouter router, {required ThemeData theme}) => ProviderScope(
      child: MaterialApp.router(
        theme: theme,
        routerConfig: router,
      ),
    );

void main() {
  final l = englishAppLocalizations();

  group('Visual V2 Step 7A — Progress Overview', () {
    testWidgets('empty state keeps its copy and start-workout destination',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final router = _createRouter();
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildApp(router, theme: AppTheme.light));
        await tester.pumpAndSettle();

        expect(find.text(l.yourProgress), findsOneWidget);
        expect(find.text(l.progressDeviceNote), findsOneWidget);
        expect(find.text(l.noCompletedWorkouts), findsOneWidget);
        expect(find.text(l.finishWorkoutHint), findsOneWidget);

        final emptyHeading =
            tester.getSemantics(find.text(l.noCompletedWorkouts));
        expect(
          emptyHeading.getSemanticsData().flagsCollection.isHeader,
          isTrue,
        );

        final startButton = find.widgetWithText(FilledButton, l.startAWorkout);
        expect(startButton, findsOneWidget);
        expect(tester.getSize(startButton).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .getSemantics(startButton)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );

        await tester.tap(startButton);
        await tester.pumpAndSettle();
        expect(find.text('Home destination'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('summary shows canonical counts and planned duration only',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await _saveHistory([
        _workout(
          id: 'current-10',
          completedAt: now.subtract(const Duration(hours: 1)),
          targetDuration: const Duration(minutes: 50),
          estimatedDuration: const Duration(minutes: 10),
        ),
        _workout(
          id: 'current-20',
          completedAt: now.subtract(const Duration(days: 1)),
          targetDuration: const Duration(minutes: 50),
          estimatedDuration: const Duration(minutes: 20),
        ),
        _workout(
          id: 'previous',
          completedAt: now.subtract(const Duration(days: 8)),
          targetDuration: const Duration(minutes: 99),
        ),
      ]);

      final router = _createRouter();
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildApp(router, theme: AppTheme.light));
        await tester.pumpAndSettle();

        expect(find.text(l.trainingSavedWorkouts), findsOneWidget);
        expect(find.text(l.trainingLast7), findsOneWidget);
        expect(find.text(l.trainingPlanned7), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text(l.minutes(30)), findsOneWidget);
        expect(find.text(l.trainingPlannedNote), findsOneWidget);
        expect(find.textContaining('Actual duration'), findsNothing);

        expect(find.bySemanticsLabel('${l.trainingSavedWorkouts} 3'),
            findsOneWidget);
        expect(find.bySemanticsLabel('${l.trainingLast7} 2'), findsOneWidget);
        expect(
          find.bySemanticsLabel('${l.trainingPlanned7} ${l.minutes(30)}'),
          findsOneWidget,
        );
        expect(
          tester
              .getSemantics(find.text(l.yourProgress))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('recent history stays bounded, ordered, and reveals ten more',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await _saveHistory([
        for (var i = 0; i < 100; i++)
          _workout(
            id: 'session-$i',
            completedAt: now.subtract(Duration(minutes: i)),
          ),
      ]);

      final router = _createRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_buildApp(router, theme: AppTheme.light));
      await tester.pumpAndSettle();

      final newest =
          find.byKey(const ValueKey('progress_recent_workout_session-0'));
      final next =
          find.byKey(const ValueKey('progress_recent_workout_session-1'));
      expect(newest, findsOneWidget);
      expect(next, findsOneWidget);
      expect(
          tester.getTopLeft(newest).dy, lessThan(tester.getTopLeft(next).dy));
      expect(find.byKey(const ValueKey('progress_recent_workout_session-9')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('progress_recent_workout_session-10')),
          findsNothing);
      expect(find.byKey(const ValueKey('progress_recent_workout_session-99')),
          findsNothing);
      expect(find.text(l.trainingHistoryMore), findsOneWidget);

      final moreButton = find.widgetWithText(TextButton, l.trainingHistoryMore);
      await tester.ensureVisible(moreButton);
      expect(tester.getSize(moreButton).height, greaterThanOrEqualTo(48));
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('progress_recent_workout_session-19')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('progress_recent_workout_session-20')),
          findsNothing);
      expect(find.byKey(const ValueKey('progress_recent_workout_session-99')),
          findsNothing);
      expect(find.text(l.trainingHistoryMore), findsOneWidget);
    });

    testWidgets('recent workout row keeps its tap and keyboard destinations',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await _saveHistory([
        _workout(id: 'keyboard-session', completedAt: now),
      ]);

      final router = _createRouter();
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildApp(router, theme: AppTheme.light));
        await tester.pumpAndSettle();

        final row = find.byKey(
          const ValueKey('progress_recent_workout_keyboard-session'),
        );
        expect(row, findsOneWidget);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .getSemantics(row)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('History detail: keyboard-session'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('light and dark overview fits the requested window sizes',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await _saveHistory([
        _workout(
          id: 'responsive-session',
          completedAt: now,
          estimatedDuration: const Duration(minutes: 38),
        ),
      ]);

      final router = _createRouter();
      addTearDown(router.dispose);
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
          await tester.pumpWidget(_buildApp(router, theme: theme));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${theme.brightness} theme at ${size.width}x${size.height}',
          );
        }
      }
    });

    testWidgets('2x text and reduced-motion disclosure remain usable',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await _saveHistory([
        _workout(id: 'large-text', completedAt: now),
      ]);

      final router = _createRouter(textScale: 2, disableAnimations: true);
      addTearDown(router.dispose);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(_buildApp(router, theme: AppTheme.dark));
      await tester.pumpAndSettle();
      expect(find.text(l.trainingPlannedNote), findsOneWidget);
      expect(find.text(l.trainingRecoveryDetails), findsOneWidget);
      expect(find.text('8-week activity'), findsNothing);
      expect(tester.takeException(), isNull);

      final trends = find.text(l.trainingTrends);
      await tester.ensureVisible(trends);
      await tester.tap(trends);
      await tester.pump();
      expect(find.text('8-week activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
