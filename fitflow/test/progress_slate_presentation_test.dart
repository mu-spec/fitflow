import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recent_workouts.dart';
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
          expect(find.byType(ProgressActivityChart), findsNothing);
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
          for (final title in [
            '8-week activity',
            '7-day comparison',
            'Training consistency',
            'Movement training',
            'Current movement levels',
            'Training recovery'
          ]) {
            final disclosure = find.widgetWithText(ExpansionTile, title);
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            expect(disclosure.hitTestable(), findsOneWidget);
            await tester.tap(find.text(title));
            await tester.pumpAndSettle();
            expect(find.text(title), findsOneWidget,
                reason: 'No duplicate $title heading');
            if (title == '8-week activity') {
              final chart = find.byType(ProgressActivityChart);
              expect(chart, findsOneWidget);
              expect(
                  find.descendant(
                      of: chart,
                      matching: find.byType(LinearProgressIndicator)),
                  findsNWidgets(8));
              final sets = find.widgetWithText(ChoiceChip, 'Sets');
              await tester.ensureVisible(sets);
              await tester.pumpAndSettle();
              await tester.tap(sets);
              await tester.pumpAndSettle();
              expect(tester.widget<ChoiceChip>(sets).selected, isTrue);
              final dates = find.byKey(const Key('progress_period_dates'));
              await tester.ensureVisible(dates);
              await tester.pumpAndSettle();
              await tester.tap(dates);
              await tester.pumpAndSettle();
              expect(find.textContaining(' – '), findsNWidgets(8));
            }
            expect(tester.takeException(), isNull, reason: title);
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            await tester.tap(find.text(title));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
