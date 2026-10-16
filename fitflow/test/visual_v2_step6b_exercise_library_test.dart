import 'dart:ui' show Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  List<Exercise>? exercises,
}) async {
  _setView(tester, size);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Theme(
          data: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          child: ExerciseLibraryScreen(exercisesForTest: exercises),
        ),
      ),
    ),
  );
  await tester.pump();
}

String _countText(int count) =>
    englishAppLocalizations().trainingExerciseCount(count);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('real catalog rows use Step 6A media and preserve count/order',
      (tester) async {
    addTearDown(tester.view.reset);
    await _pumpLibrary(tester);

    expect(find.text(_countText(88)), findsOneWidget);
    final visibleRows = tester
        .widgetList<ExerciseListTile>(find.byType(ExerciseListTile))
        .toList();
    expect(visibleRows, isNotEmpty);
    expect(visibleRows.length, lessThan(ExerciseCatalog.all.length));
    expect(
      visibleRows.take(5).map((row) => row.exercise.id),
      [
        'pushup_wall',
        'pushup_incline',
        'pushup_knee',
        'pushup_standard',
        'pushup_decline',
      ],
    );

    final mediaWidgets = tester.widgetList<FitFlowV2ExerciseMedia>(
        find.byType(FitFlowV2ExerciseMedia));
    expect(mediaWidgets.length, visibleRows.length);
    expect(
      mediaWidgets.first.descriptor,
      FitFlowV2ExerciseVisualDescriptor.fromExercise(
          visibleRows.first.exercise),
    );
    expect(
      find.descendant(
        of: find.byType(FitFlowV2ExerciseMedia).first,
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('exercise_library_search')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(ExerciseListTile).first).height,
      greaterThanOrEqualTo(48),
    );

    final forbiddenMetrics = RegExp(
      r'calories|kcal|fitness score|intensity score|popularity|effectiveness|rating|%+',
      caseSensitive: false,
    );
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final value = text.data ?? text.textSpan?.toPlainText() ?? '';
      expect(forbiddenMetrics.hasMatch(value), isFalse, reason: value);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('search stays immediate, clearable, and submits with keyboard',
      (tester) async {
    addTearDown(tester.view.reset);
    await _pumpLibrary(tester);

    final search = find.byKey(const ValueKey('exercise_library_search'));
    await tester.tap(search);
    await tester.enterText(search, 'wall push-up');
    await tester.pump();

    final results = applyExerciseLibraryFilter(
      ExerciseCatalog.all,
      const ExerciseLibraryFilter(searchQuery: 'wall push-up'),
    );
    expect(results.map((exercise) => exercise.id), ['pushup_wall']);
    expect(find.text(_countText(results.length)), findsOneWidget);
    expect(find.byKey(const ValueKey('pushup_wall')), findsOneWidget);
    expect(find.text('Standard Push-Up'), findsNothing);
    expect(tester.getSize(find.byTooltip('Clear search')).height,
        greaterThanOrEqualTo(48));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text(_countText(88)), findsOneWidget);
    expect(find.text('Wall Push-Up'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick and sheet filters retain behavior and selected semantics',
      (tester) async {
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await _pumpLibrary(tester, size: const Size(320, 700));

    final horizontalFilters = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .where((scroll) => scroll.scrollDirection == Axis.horizontal);
    expect(horizontalFilters, isNotEmpty);
    await tester.ensureVisible(find.text('Quiet'));

    final noEquipmentChip = find.widgetWithText(FilterChip, 'No equipment');
    expect(tester.getSize(noEquipmentChip).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(noEquipmentChip);
    await tester.tap(noEquipmentChip);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    final quickChip = tester.widget<FilterChip>(noEquipmentChip);
    expect(quickChip.selected, isTrue);
    expect(quickChip.showCheckmark, isTrue);
    expect(quickChip.materialTapTargetSize, MaterialTapTargetSize.padded);

    final quickResults = applyExerciseLibraryFilter(
      ExerciseCatalog.all,
      const ExerciseLibraryFilter(noEquipment: true),
    );
    expect(find.text(_countText(quickResults.length)), findsOneWidget);
    expect(
      tester.getSize(find.byType(OutlinedButton).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(find.widgetWithText(
              TextButton, englishAppLocalizations().trainingClearFilters))
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Movement Pattern'), findsOneWidget);
    expect(
      tester
          .getSize(find.widgetWithText(
              FilledButton, englishAppLocalizations().trainingDone))
          .height,
      greaterThanOrEqualTo(48),
    );
    final pushChip = find.widgetWithText(FilterChip, 'Push').last;
    expect(tester.getSize(pushChip).height, greaterThanOrEqualTo(48));
    await tester.tap(pushChip);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(tester.widget<FilterChip>(pushChip).selected, isTrue);
    expect(tester.widget<FilterChip>(pushChip).showCheckmark, isTrue);
    expect(
      tester
          .getSemantics(pushChip)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final combinedResults = applyExerciseLibraryFilter(
      ExerciseCatalog.all,
      const ExerciseLibraryFilter(
        noEquipment: true,
        movementPatterns: {MovementPattern.push},
      ),
    );
    expect(find.text(_countText(combinedResults.length)), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('empty catalog and no-results states keep existing actions',
      (tester) async {
    addTearDown(tester.view.reset);
    await _pumpLibrary(tester, exercises: const []);
    final l10n = englishAppLocalizations();
    expect(find.text(l10n.trainingCatalogEmpty), findsOneWidget);
    expect(find.text(l10n.trainingCatalogEmptyHelp), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise_library_search')), findsNothing);

    await _pumpLibrary(tester);
    final search = find.byKey(const ValueKey('exercise_library_search'));
    await tester.enterText(search, 'not-a-real-exercise');
    await tester.pump();
    expect(find.text(l10n.trainingNoResults), findsOneWidget);
    expect(find.text(l10n.trainingNoResultsHelp), findsOneWidget);
    final clearSearchButton =
        find.widgetWithText(FilledButton, l10n.clearSearch);
    expect(tester.getSize(clearSearchButton).height, greaterThanOrEqualTo(48));
    await tester.tap(find.text(l10n.clearSearch));
    await tester.pump();
    expect(find.text(_countText(88)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow at phone, tablet, and landscape sizes',
      (tester) async {
    addTearDown(tester.view.reset);
    const sizes = [
      Size(320, 700),
      Size(390, 844),
      Size(600, 900),
      Size(840, 1000),
      Size(900, 320),
    ];

    for (final size in sizes) {
      await _pumpLibrary(tester, size: size);
      expect(
          find.byKey(const ValueKey('exercise_library_search')), findsOneWidget,
          reason: '$size');
      expect(find.text('Filters'), findsOneWidget, reason: '$size');
      expect(find.text(_countText(88)), findsOneWidget, reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('2x text retains scroll access and minimum control targets',
      (tester) async {
    addTearDown(tester.view.reset);
    await _pumpLibrary(
      tester,
      size: const Size(320, 700),
      textScale: 2,
    );

    final search = find.byKey(const ValueKey('exercise_library_search'));
    expect(search, findsOneWidget);
    expect(tester.getSize(search).height, greaterThanOrEqualTo(48));
    final filterButton = find.widgetWithText(OutlinedButton, 'Filters');
    expect(tester.getSize(filterButton).height, greaterThanOrEqualTo(48));
    expect(find.byType(ExerciseListTile), findsWidgets);
    await tester.ensureVisible(filterButton);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Light and Dark themes render intentionally', (tester) async {
    addTearDown(tester.view.reset);
    await _pumpLibrary(tester, brightness: Brightness.light);
    expect(find.byType(FitFlowV2ExerciseMedia), findsWidgets);
    expect(
      Theme.of(tester
              .element(find.byKey(const ValueKey('exercise_library_search'))))
          .brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);

    await _pumpLibrary(tester, brightness: Brightness.dark);
    expect(
      Theme.of(tester
              .element(find.byKey(const ValueKey('exercise_library_search'))))
          .brightness,
      Brightness.dark,
    );
    expect(find.byType(FitFlowV2ExerciseMedia), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('row tap still pushes the existing Exercise Detail route',
      (tester) async {
    addTearDown(tester.view.reset);
    _setView(tester, const Size(390, 844));
    final router = AppRouter.create(initialLocation: AppRoutes.exerciseLibrary);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final row = find.byKey(const ValueKey('pushup_wall'));
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Wall Push-Up'), findsWidgets);
    expect(find.text('Default Prescription'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
