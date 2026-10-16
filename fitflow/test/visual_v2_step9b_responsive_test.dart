import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/part6_quality_helpers.dart';

const _responsiveSizes = [
  Size(320, 700),
  Size(360, 800),
  Size(390, 844),
  Size(430, 932),
  Size(600, 900),
  Size(840, 1000),
  Size(1024, 768),
  Size(900, 320),
  Size(844, 390),
];

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<GoRouter> _openRoute(WidgetTester tester, String route) async {
  await seedPart6();
  final router = await part6Route(tester, route, scale: 2);
  addTearDown(router.dispose);
  return router;
}

Future<void> _reachAction(
  WidgetTester tester, {
  required Finder screen,
  required Finder action,
  required String context,
  required Size viewportSize,
  double minimumHeight = 48,
}) async {
  final scrollable =
      find.descendant(of: screen, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(action, 180, scrollable: scrollable);
  await tester.pumpAndSettle();
  expect(action, findsOneWidget, reason: context);
  expect(
    tester.getSize(action).height,
    greaterThanOrEqualTo(minimumHeight),
    reason: context,
  );
  final actionRect = tester.getRect(action);
  expect(actionRect.top, greaterThanOrEqualTo(0), reason: context);
  expect(
    actionRect.bottom,
    lessThanOrEqualTo(viewportSize.height),
    reason: context,
  );
  expect(tester.takeException(), isNull, reason: context);
}

void main() {
  group('Visual V2 Step 9B Program Session Preview matrix at 2x text', () {
    for (final size in _responsiveSizes) {
      testWidgets('Start remains reachable at $size', (tester) async {
        _setViewport(tester, size);
        final program = AdaptiveProgramCatalog.balancedFoundations;
        await _openRoute(
          tester,
          AppRoutes.programSessionPreview(
            program.id,
            program.sessions.first.id,
          ),
        );
        expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
        await _reachAction(
          tester,
          screen: find.byType(ProgramSessionPreviewScreen),
          action: find.widgetWithText(FilledButton, 'Start workout'),
          context: 'program preview Start at $size',
          viewportSize: size,
          minimumHeight: 56,
        );
        assertClean(tester, 'Program Session Preview at $size, 2x');
      });
    }
  });

  group('Visual V2 Step 9B short-landscape action reachability at 2x text', () {
    const size = Size(844, 390);

    testWidgets('Workout Preview keeps its primary action reachable',
        (tester) async {
      _setViewport(tester, size);
      await _openRoute(tester, AppRoutes.workoutPreview);
      expect(find.byType(WorkoutPreviewScreen), findsOneWidget);
      await _reachAction(
        tester,
        screen: find.byType(WorkoutPreviewScreen),
        action: find.byKey(const Key('preview_start')),
        context: 'workout preview Start',
        viewportSize: size,
      );
      assertClean(tester, 'Workout Preview at $size, 2x');
    });

    testWidgets('Custom Workout Builder keeps Save changes reachable',
        (tester) async {
      _setViewport(tester, size);
      await _openRoute(tester, AppRoutes.customWorkoutEdit('TEST-custom'));
      expect(find.byType(CustomWorkoutBuilderScreen), findsOneWidget);
      await _reachAction(
        tester,
        screen: find.byType(CustomWorkoutBuilderScreen),
        action: find.widgetWithText(FilledButton, 'Save changes'),
        context: 'custom workout builder Save changes',
        viewportSize: size,
      );
      assertClean(tester, 'Custom Workout Builder at $size, 2x');
    });
  });
}
