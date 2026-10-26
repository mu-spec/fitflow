import 'dart:async';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/presentation/workout_preparation_view.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/part6_quality_helpers.dart' as qa;

class PendingSplashProfile extends UserFitnessProfileController {
  @override
  Future<UserFitnessProfile?> build() =>
      Completer<UserFitnessProfile?>().future;
}

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Splash branding $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(qa.part6Host(
              dark: dark,
              scale: scale,
              extra: [
                userFitnessProfileProvider
                    .overrideWith(PendingSplashProfile.new)
              ],
              child: const SplashScreen()));
          await tester.pump();
          expect(find.text('Home Workout'), findsOneWidget);
          expect(find.text('Workouts that adapt to you.'), findsOneWidget);
          final icon = tester.widget<Image>(find.byType(Image));
          expect((icon.image as AssetImage).assetName,
              'assets/images/branding/home_workout_icon.png');
          final initialSize = tester.getSize(find.byType(Image));
          expect(initialSize, const Size(156, 156));
          await tester.pump(const Duration(seconds: 2));
          expect(tester.getSize(find.byType(Image)), initialSize,
              reason: 'Brand must not grow after its first Flutter frame');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
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
            expect(tester.getCenter(ring).dx, closeTo(size.width / 2, .5));
            final group =
                find.ancestor(of: ring, matching: find.byType(Column)).first;
            final bounds = tester.getRect(group);
            if (bounds.height <= size.height - 96) {
              expect(bounds.center.dy, closeTo(size.height / 2, .5));
            } else {
              // Large text can exceed the safe viewport and must scroll.
              await tester.ensureVisible(find.text('Preparing your workout'));
              expect(find.text('Preparing your workout').hitTestable(),
                  findsOneWidget);
            }
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
