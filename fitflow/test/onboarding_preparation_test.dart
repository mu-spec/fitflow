import 'package:fitflow/features/onboarding/presentation/workout_preparation_view.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/part6_quality_helpers.dart' as qa;

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
            'Preparation stages and retry $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          var retries = 0;
          Future<void> show(double progress, {bool failed = false}) async {
            await tester.pumpWidget(qa.part6Host(
                dark: dark,
                scale: scale,
                child: WorkoutsTheme(
                    child: WorkoutPreparationView(
                        progress: progress,
                        failed: failed,
                        onRetry: () => retries++))));
            await tester.pumpAndSettle();
          }

          for (final progress in [0.0, 1 / 3, 2 / 3, 1.0]) {
            await show(progress);
            final ring = find.byType(CircularProgressIndicator);
            expect(
                tester.widget<CircularProgressIndicator>(ring).value, progress);
            expect(tester.getSize(ring).width, tester.getSize(ring).height);
            expect(find.text('${(progress * 100).round()}%'), findsOneWidget);
            expect(find.text('Home Workout'), findsOneWidget);
            expect(find.byType(FilledButton), findsNothing);
            expect(tester.takeException(), isNull);
          }
          await show(1 / 3, failed: true);
          expect(
              find.text(
                  'Your choices are saved. We couldn’t prepare your workout. Try again.'),
              findsOneWidget);
          await tester.ensureVisible(find.text('Retry'));
          await tester.tap(find.text('Retry'));
          expect(retries, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
