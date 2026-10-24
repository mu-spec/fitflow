import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recent_workouts.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'helpers/backup_test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/part6_quality_helpers.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Progress routes $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          await seedPart6();
          final router = await part6Route(tester, AppRoutes.progress,
              dark: dark, scale: scale);
          addTearDown(router.dispose);
          final history = find.byType(ProgressRecentWorkouts);
          // Use a current real-shaped record with seconds, not an all-zero
          // summary from the older backup fixtures, for above-fold geometry.
          final fixture = backupWorkout('current-dashboard',
              DateTime.now().toUtc().subtract(const Duration(hours: 1)));
          final current = CompletedWorkout(
              id: fixture.id,
              completedAt: fixture.completedAt,
              targetDuration: const Duration(minutes: 30),
              estimatedDuration: const Duration(minutes: 27, seconds: 23),
              totalExerciseCount: fixture.totalExerciseCount,
              totalSetCount: fixture.totalSetCount,
              warmup: fixture.warmup,
              main: fixture.main,
              cooldown: fixture.cooldown);
          expect(
              await ProviderScope.containerOf(tester.element(history))
                  .read(workoutHistoryProvider.notifier)
                  .addWorkout(current),
              isTrue);
          await tester.pumpAndSettle();
          expect(find.text('27m 23s'), findsOneWidget);
          final contentTheme = Theme.of(tester.element(history));
          expect(contentTheme.scaffoldBackgroundColor,
              dark ? const Color(0xFF202526) : const Color(0xFFF3F4EE));
          expect(contentTheme.colorScheme.primary,
              dark ? const Color(0xFFD4E779) : const Color(0xFF526515));
          // Opt-in content styling leaves the approved navigation theme alone.
          expect(
              Theme.of(tester.element(find.byType(NavigationBar)))
                  .colorScheme
                  .primary,
              (dark ? AppTheme.dark : AppTheme.light).colorScheme.primary);
          expect(find.byType(ProgressActivityChart), findsOneWidget);
          expect(find.text('7-day comparison'), findsNothing);
          if (scale == 1) {
            // The complete eight-bar chart is visible immediately, above tabs.
            final lastBar = find.byKey(const Key('progress_bar_7'));
            expect(
                tester.getBottomRight(lastBar).dy + 40,
                lessThanOrEqualTo(
                    tester.getTopLeft(find.byType(NavigationBar)).dy));
            expect(tester.getTopLeft(find.text('Current 7 days')).dy,
                greaterThanOrEqualTo(24));
          }
          final row = find
              .descendant(of: history, matching: find.byType(ListTile))
              .first;
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(row.hitTestable(), findsOneWidget);
          await tester.tap(row);
          await tester.pumpAndSettle();
          expect(find.byType(ProgressHistoryDetailScreen), findsOneWidget);
          final detail = find.descendant(
              of: find.byType(ProgressHistoryDetailScreen),
              matching: find.byType(Scaffold));
          expect(tester.widget<Scaffold>(detail).backgroundColor,
              contentTheme.scaffoldBackgroundColor);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          final chart = find.byType(ProgressActivityChart);
          expect(
              find.descendant(
                  of: chart, matching: find.byType(LinearProgressIndicator)),
              findsNWidgets(8));
          final sets = find.widgetWithText(ChoiceChip, 'Sets');
          await tester.ensureVisible(sets);
          await tester.pumpAndSettle();
          await tester.tap(sets);
          await tester.pumpAndSettle();
          expect(tester.widget<ChoiceChip>(sets).selected, isTrue);
          final dates = find.byKey(const Key('progress_period_dates'));
          await tester.ensureVisible(find.text('Period dates'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Period dates'));
          await tester.pumpAndSettle();
          expect(find.textContaining(' – '), findsNWidgets(8));
          expect(dates, findsOneWidget);
          await tester.ensureVisible(find.text('Period dates'));
          await tester.tap(find.text('Period dates'));
          await tester.pumpAndSettle();
          final details = find.text('Details, movement levels & recovery');
          await tester.ensureVisible(details);
          await tester.pumpAndSettle();
          await tester.tap(details);
          await tester.pumpAndSettle();
          for (final title in [
            '7-day comparison',
            'Current movement levels',
            'Training recovery'
          ]) {
            expect(find.text(title), findsOneWidget);
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Planned time is not elapsed workout time.'),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
