import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/home/presentation/widgets/home_workout_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/part6_quality_helpers.dart' as qa;

void main() {
  setUpAll(() async {
    // Use already-installed SDK fonts for optional human-readable captures.
    // Ordinary widget tests retain Flutter's standard test font.
    final fonts = Platform.environment['FITFLOW_HOME_CAPTURE_FONTS'];
    if (Platform.environment['FITFLOW_HOME_CAPTURE_DIR'] == null ||
        fonts == null) {
      return;
    }
    final regular = File('$fonts/roboto-regular.ttf').readAsBytesSync();
    await ui.loadFontFromList(regular, fontFamily: 'Roboto');
    await ui.loadFontFromList(regular, fontFamily: 'Ahem');
    for (final weight in ['medium', 'bold']) {
      final bytes = File('$fonts/roboto-$weight.ttf').readAsBytesSync();
      await ui.loadFontFromList(bytes, fontFamily: 'Roboto');
      await ui.loadFontFromList(bytes, fontFamily: 'Ahem');
    }
    await ui.loadFontFromList(
        File('$fonts/materialicons-regular.otf').readAsBytesSync(),
        fontFamily: 'MaterialIcons');
  });
  for (final size in qa.part6Sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('V2 Home $size dark=$dark scale=$scale', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          await qa.seedPart6();
          final router = AppRouter.create(initialLocation: AppRoutes.home);
          await tester.pumpWidget(RepaintBoundary(
            key: const ValueKey('home_capture'),
            child: qa.part6Host(router: router, dark: dark, scale: scale),
          ));
          await tester.pumpAndSettle();
          expect(find.byType(HomeWorkoutHeroCard), findsOneWidget);
          final workout = tester
              .widget<HomeWorkoutHeroCard>(find.byType(HomeWorkoutHeroCard))
              .plan;
          final photo = tester.widget<FitFlowExerciseImage>(
              find.byKey(const ValueKey('home_workout_photo')));
          expect(photo.exerciseId, workout.main.exercises.first.exercise.id);
          expect(
              photo.semanticLabel, workout.main.exercises.first.exercise.name);
          expect(photo.decorative, isFalse);
          expect(ExerciseMediaRegistry.lookup(photo.exerciseId), isNotNull);
          if ((size == const Size(390, 844) && scale == 1) ||
              (size == const Size(320, 700) && scale == 2 && dark)) {
            await captureHome(tester,
                'home_${size.width.toInt()}_${dark ? 'dark' : 'light'}_${scale}x');
          }
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
          if (size == const Size(320, 700) && scale == 2 && dark) {
            await captureHome(tester, 'home_320_dark_2.0x_action');
          }
          expect(find.byType(FitFlowV2Tag), findsWidgets);
          final setup = find.text('Your setup and workout preferences');
          await tester.ensureVisible(setup);
          await tester.tap(setup);
          await tester.pumpAndSettle();
          expect(find.text('Equipment'), findsOneWidget);
          if (size == const Size(390, 844) && scale == 1) {
            await tester.ensureVisible(find.text('Equipment'));
            await tester.pumpAndSettle();
            await captureHome(
                tester, 'home_390_${dark ? 'dark' : 'light'}_setup');
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
        });
      }
    }
  }
  testWidgets('photo follows mode changes and Library action keeps its route',
      (tester) async {
    await qa.seedPart6();
    final router = await qa.part6Route(tester, AppRoutes.home);
    await tester.ensureVisible(find.text('Adjust'));
    await tester.tap(find.text('Adjust'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low Energy').last);
    await tester.pumpAndSettle();
    final hero =
        tester.widget<HomeWorkoutHeroCard>(find.byType(HomeWorkoutHeroCard));
    final photo =
        tester.widget<FitFlowExerciseImage>(find.byType(FitFlowExerciseImage));
    expect(photo.exerciseId, hero.plan.main.exercises.first.exercise.id);
    expect(find.text('Temporary for this workout'), findsOneWidget);
    final browse = find.text('Browse exercises');
    await tester.ensureVisible(browse);
    await tester.tap(browse);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.exerciseLibrary);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
}

// Optional local captures using the same RenderRepaintBoundary tooling as
// visual_v2_preview_player_test.dart; no golden files or shipped fixtures.
Future<void> captureHome(WidgetTester tester, String name) async {
  final directory = Platform.environment['FITFLOW_HOME_CAPTURE_DIR'];
  if (directory == null) return;
  final photo = find.descendant(
      of: find.byKey(const ValueKey('home_workout_photo')),
      matching: find.byType(Image));
  if (photo.evaluate().isNotEmpty) {
    final image = tester.widget<Image>(photo);
    await tester
        .runAsync(() => precacheImage(image.image, tester.element(photo)));
    await tester.pumpAndSettle();
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('home_capture')));
  final image = boundary.toImageSync();
  final bytes = await tester
      .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
  image.dispose();
  final file = File('$directory/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}
