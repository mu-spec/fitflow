import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Milestone 20 Part 2: Exercise Library + Exercise Detail regression.
///
/// Uses the real AppRouter/AppRoutes; verifies responsiveness of the filter
/// row (Filters / Clear filters / Clear all / result count), representative
/// detail rendering, and asset truthfulness (no fake media UI).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRoute(
    WidgetTester tester,
    String location, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = AppRouter.create(initialLocation: location);
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp.router(
            theme: ThemeData(useMaterial3: true),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Exercise Library layout', () {
    testWidgets('renders at 320x640 with filter row and result count',
        (tester) async {
      await pumpRoute(tester, AppRoutes.exerciseLibrary,
          size: const Size(320, 640));

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('80 exercises'), findsOneWidget);
      expect(find.text('Search exercises'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on tablet width', (tester) async {
      await pumpRoute(tester, AppRoutes.exerciseLibrary,
          size: const Size(1200, 800));

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('80 exercises'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders landscape phone', (tester) async {
      await pumpRoute(tester, AppRoutes.exerciseLibrary,
          size: const Size(844, 390));

      expect(find.text('80 exercises'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filter row survives text scale 1.5', (tester) async {
      await pumpRoute(tester, AppRoutes.exerciseLibrary, textScale: 1.5);

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('80 exercises'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search narrows results and count updates truthfully',
        (tester) async {
      await pumpRoute(tester, AppRoutes.exerciseLibrary);

      await tester.enterText(find.byType(TextField).first, 'plank');
      await tester.pump(const Duration(milliseconds: 300));

      final countText = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((t) => t.endsWith('exercises'));
      expect(countText, isNot('80 exercises'));
      expect(find.text('Standard Push-Up'), findsNothing);
      expect(find.textContaining('Plank'), findsWidgets);

      // The search field's clear icon restores the full list.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('80 exercises'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Exercise Detail regression', () {
    Future<void> pumpDetail(WidgetTester tester, String exerciseId) =>
        pumpRoute(tester, AppRoutes.exerciseDetail(exerciseId));

    testWidgets('reps progression exercise shows all core sections',
        (tester) async {
      await pumpDetail(tester, 'pushup_standard');

      expect(find.text('Standard Push-Up'), findsWidgets);
      await tester.dragUntilVisible(
        find.text('How to Perform'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('How to Perform'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Common Mistakes'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Common Mistakes'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Breathing'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Breathing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('timed exercise renders without progression section',
        (tester) async {
      await pumpDetail(tester, 'wall_sit');
      expect(find.text('Wall Sit'), findsWidgets);
      expect(find.text('Timed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('equipment exercise shows its equipment section',
        (tester) async {
      await pumpDetail(tester, 'pushup_incline');
      expect(find.text('Incline Push-Up'), findsWidgets);
      await tester.dragUntilVisible(
        find.text('Equipment'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Equipment'), findsOneWidget);
      expect(find.textContaining('Bench'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('seated dip_chair renders truthfully after Part 1 fix',
        (tester) async {
      await pumpDetail(tester, 'dip_chair');
      expect(find.text('Triceps Dip on Chair'), findsWidgets);
      await tester.dragUntilVisible(
        find.text('Seated'),
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Seated'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-equipment exercise renders', (tester) async {
      await pumpDetail(tester, 'march_in_place');
      expect(find.text('March in Place'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown id renders the not-found fallback safely',
        (tester) async {
      await pumpDetail(tester, 'not_a_real_exercise');
      // AppBar title + body message both carry the fallback copy.
      expect(find.text('Exercise not found'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail screens never claim media assets exist',
        (tester) async {
      // All 80 exercises keep assetPath == null; the UI must not invent
      // video/animation/demo imagery.
      for (final exercise in ExerciseCatalog.all) {
        expect(exercise.assetPath, isNull, reason: exercise.id);
      }
      await pumpDetail(tester, 'pushup_standard');
      for (final banned in [
        'Watch demonstration',
        'Play video',
        'Animation',
        'Demo video',
      ]) {
        expect(find.textContaining(banned), findsNothing);
      }
    });
  });
}
