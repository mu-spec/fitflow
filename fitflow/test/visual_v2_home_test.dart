import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/home/presentation/widgets/home_flow_motif.dart';
import 'package:fitflow/features/home/presentation/widgets/home_workout_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/part6_quality_helpers.dart' as qa;

void main() {
  for (final size in qa.part6Sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('V2 Home $size dark=$dark scale=$scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          await qa.seedPart6();
          final router = await qa.part6Route(tester, AppRoutes.home,
              dark: dark, scale: scale);
          expect(find.byType(HomeWorkoutHeroCard), findsOneWidget);
          expect(find.byType(HomeFlowMotif), findsOneWidget);
          final hero = tester.element(find.byType(HomeWorkoutHeroCard));
          final v = FitFlowVisualV2.of(hero);
          double contrast(Color a, Color b) {
            final l = [a.computeLuminance(), b.computeLuminance()]..sort();
            return (l.last + .05) / (l.first + .05);
          }

          for (final background in [v.heroStart, v.heroEnd]) {
            expect(contrast(v.onHero, background), greaterThanOrEqualTo(4.5));
            expect(contrast(v.action, background), greaterThanOrEqualTo(4.5));
            expect(contrast(v.heroSecondary, background),
                greaterThanOrEqualTo(4.5));
          }
          expect(contrast(v.onAction, v.action), greaterThanOrEqualTo(4.5));
          final cta = find.widgetWithText(FilledButton, 'View workout');
          await tester.ensureVisible(cta);
          await tester.pumpAndSettle();
          expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
          expect(cta.hitTestable(), findsOneWidget);
          expect(find.byType(FitFlowV2Tag), findsWidgets);
          final setup = find.text('Your setup and workout preferences');
          await tester.ensureVisible(setup);
          await tester.tap(setup);
          await tester.pumpAndSettle();
          expect(find.text('Equipment'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
        });
      }
    }
  }
  test('movement artwork only repaints when its colors change', () {
    const a = HomeFlowPainter(Colors.green, Colors.white);
    expect(a.shouldRepaint(a), isFalse);
    expect(a.shouldRepaint(const HomeFlowPainter(Colors.teal, Colors.white)),
        isTrue);
  });
}
