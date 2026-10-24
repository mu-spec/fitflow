import 'package:fitflow/app/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/part6_quality_helpers.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Compact facts and full-width program actions dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await seedPart6();
      final router =
          await part6Route(tester, AppRoutes.programs, dark: dark, scale: 2);
      addTearDown(router.dispose);
      expect(find.text('Not started'), findsNothing);
      expect(find.text('4 weeks • 3 sessions/week'), findsWidgets);
      await tester.tap(find.text('Balanced Foundations'));
      await tester.pumpAndSettle();
      expect(
          find.text('4 weeks • 3 sessions/week • 12 workouts'), findsOneWidget);
      for (final action in ['Start program', 'Continue']) {
        final button = find.widgetWithText(FilledButton, action);
        await tester.scrollUntilVisible(button, 180,
            scrollable: find.byType(Scrollable).last);
        await tester.pumpAndSettle();
        expect(tester.getSize(button).width, 312);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(button.hitTestable(), findsOneWidget);
        if (action == 'Start program') {
          await tester.tap(button);
          await tester.pumpAndSettle();
          // Detail builds only visible rows; bring its summary back into view.
          await tester.scrollUntilVisible(find.text('Active program'), -180,
              scrollable: find.byType(Scrollable).last);
          await tester.pumpAndSettle();
          expect(find.text('Active program'), findsOneWidget);
          expect(find.text('0 of 12 sessions'), findsOneWidget);
          expect(find.text('In progress'), findsNothing);
        }
      }
      // Returning to a neighboring route retains its existing bar sizing.
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Home')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0);
      expect(
          tester.widget<NavigationBar>(find.byType(NavigationBar)).height, 96);
      expect(tester.takeException(), isNull);
    });
  }
  for (final size in [const Size(360, 640), const Size(412, 915)]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Programs route labels fit $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          await seedPart6();
          for (final route in [
            AppRoutes.programs,
            AppRoutes.programDetail('balanced_foundations'),
            AppRoutes.programSessionPreview(
                'balanced_foundations', 'balanced_foundations_w1_s1'),
          ]) {
            final router =
                await part6Route(tester, route, dark: dark, scale: scale);
            final bar = find.byType(NavigationBar);
            expect(tester.widget<NavigationBar>(bar).selectedIndex, 1);
            for (final label in ['Home', 'Workouts', 'Progress', 'Profile']) {
              final text = find.descendant(of: bar, matching: find.text(label));
              final paragraph = tester.renderObject<RenderParagraph>(text);
              final boxes = paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: label.length));
              expect(paragraph.didExceedMaxLines, isFalse, reason: route);
              for (final box in boxes) {
                expect(
                    box.bottom, lessThanOrEqualTo(paragraph.size.height + .1),
                    reason: '$route: $label glyphs must not be clipped');
                expect(box.right, lessThanOrEqualTo(paragraph.size.width + .1));
              }
              expect(tester.getBottomLeft(text).dy,
                  lessThanOrEqualTo(size.height - 24),
                  reason: route);
              expect(text.hitTestable(), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            router.dispose();
          }
        });
      }
    }
  }
}
