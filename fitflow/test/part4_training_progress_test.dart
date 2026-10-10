import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'dart:ui' show Tristate;
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_detail_screen.dart';
import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recent_workouts.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_tree_family_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_trees_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'progress_screen_test.dart' as fixtures;

class _History extends WorkoutHistoryController {
  _History(this.records, {this.fail = false});
  final List<CompletedWorkout> records;
  final bool fail;
  @override
  Future<List<CompletedWorkout>> build() async {
    if (fail) throw StateError('INTERNAL_STORAGE_DIAGNOSTIC');
    return records;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool reduced = false,
  List<CompletedWorkout>? history,
  bool historyError = false,
  bool custom = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  SharedPreferences.setMockInitialValues({});
  if (custom) {
    await const CustomWorkoutStorage().saveAll([
      CustomWorkoutTemplate(
        id: 'custom-part4',
        name: 'A comfortably paced workout with a deliberately long name',
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place',
              sets: 1,
              workDuration: const Duration(seconds: 20),
              restBetweenSets: Duration.zero)
        ],
        main: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'squat_bodyweight',
              sets: 2,
              repsPerSet: 10,
              restBetweenSets: const Duration(seconds: 30))
        ],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch',
              sets: 1,
              workDuration: const Duration(seconds: 20),
              restBetweenSets: Duration.zero)
        ],
      )
    ]);
  }
  await tester.pumpWidget(ProviderScope(
      overrides: [
        ...programOverrides(),
        workoutHistoryProvider.overrideWith(() =>
            _History(history ?? [fixtures.makeWorkout()], fail: historyError)),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
            ),
            child: child!),
        home: Scaffold(body: child),
      )));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String title) async {
  final finder = find.widgetWithText(ExpansionTile, title).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester
      .tap(find.descendant(of: finder, matching: find.text(title)).first);
  await tester.pumpAndSettle();
}

void main() {
  const sizes = [
    Size(320, 700),
    Size(390, 844),
    Size(430, 900),
    Size(600, 800),
    Size(900, 800),
    Size(900, 320)
  ];
  for (final brightness in Brightness.values) {
    for (final size in sizes) {
      testWidgets(
          'Part4 2x ${brightness.name} ${size.width}x${size.height}: all reading surfaces',
          (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final screens = <Widget>[
          const WorkoutsScreen(),
          const CustomWorkoutDetailScreen(workoutId: 'custom-part4'),
          const ProgramsOverviewScreen(),
          ProgramDetailScreen(programId: AdaptiveProgramCatalog.all.first.id),
          const ExerciseLibraryScreen(),
          const ExerciseDetailScreen(exerciseId: 'pushup_standard'),
          const SkillTreesScreen(),
          const SkillTreeFamilyScreen(familyId: 'pushup'),
          const ProgressScreen(),
          const ProgressHistoryDetailScreen(sessionId: 'w1'),
        ];
        for (final screen in screens) {
          await _pump(tester, screen,
              size: size,
              scale: 2,
              brightness: brightness,
              reduced: true,
              custom: true);
          expect(tester.takeException(), isNull,
              reason: '${screen.runtimeType} initial');
          if (screen is CustomWorkoutDetailScreen) {
            expect(
                find.text(
                    'A comfortably paced workout with a deliberately long name'),
                findsOneWidget);
            expect(find.textContaining('level2'), findsNothing);
            expect(find.text('Start'), findsOneWidget);
          }
          if (screen is ExerciseLibraryScreen) {
            expect(find.byType(ExerciseListTile).evaluate().length,
                lessThan(ExerciseCatalog.all.length));
          }
          if (screen is ExerciseDetailScreen) {
            await _open(tester, 'Default Prescription');
            await _open(tester, 'Exercise characteristics');
          }
          if (screen is ProgressScreen) {
            expect(find.byType(FitFlowStat), findsNWidgets(3));
            expect(find.byType(ProgressActivityChart), findsNothing);
            await _open(tester, 'Training trends');
            await _open(tester, 'Current movement levels');
            await _open(tester, 'Training recovery');
          }
          expect(tester.takeException(), isNull,
              reason: '${screen.runtimeType} disclosed');
        }
      });
    }
  }

  testWidgets(
      'library keeps query through keyboard, combined filters and clear; lazy rows',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await _pump(tester, const ExerciseLibraryScreen(), reduced: true);
    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller;
    await tester.enterText(find.byType(TextField), 'Push-Up');
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller,
        same(controller));
    expect(controller!.text, 'Push-Up');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('No equipment'));
    await tester.tap(find.text('No equipment'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Push-Up');
    final quick = tester
        .widget<FilterChip>(find.widgetWithText(FilterChip, 'No equipment'));
    expect(quick.selected, isTrue);
    expect(quick.chipAnimationStyle!.selectAnimation!.duration, Duration.zero);
    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Push-Up');
    await tester.scrollUntilVisible(find.byType(TextField), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(find.text('88 exercises'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets('disclosure is native and respects reduced motion=$reduced',
        (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pump(tester, const ProgressScreen(), reduced: reduced);
      final tile = tester.widget<ExpansionTile>(
          find.widgetWithText(ExpansionTile, 'Training trends'));
      expect(tile.expansionAnimationStyle!.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 200));
      expect(find.byType(ProgressActivityChart), findsNothing);
      await _open(tester, 'Training trends');
      expect(find.byType(ProgressActivityChart), findsOneWidget);
      expect(find.textContaining('Current 7 days · 1 workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'history show more exposes real records without reordering or invented origins',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final records = List.generate(
        13,
        (i) => fixtures.makeWorkout(
            id: 'saved-$i',
            completedAt: DateTime.now().subtract(Duration(days: i, hours: 1))));
    await _pump(tester,
        SingleChildScrollView(child: ProgressRecentWorkouts(history: records)));
    expect(find.text('Completed workout'), findsNWidgets(10));
    await tester.ensureVisible(find.text('Show more workouts'));
    await tester.tap(find.text('Show more workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Completed workout'), findsNWidgets(13));
    expect(find.text('Show more workouts'), findsNothing);
    expect(find.textContaining('Estimated duration: 22 minutes'),
        findsNWidgets(13));
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    final dates = tiles.map((t) => (t.title as Text).data).toList();
    expect(dates.toSet().length, 13);
    expect(find.textContaining('Program workout'), findsNothing);
    expect(records.first.id, 'saved-0');
    expect(records.last.id, 'saved-12');
  });

  testWidgets(
      'empty Progress has one training action and no invented dashboard',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pump(tester, const ProgressScreen(),
        history: [], size: const Size(320, 700), scale: 2);
    expect(find.text('Finish a workout and your progress will appear here.'),
        findsOneWidget);
    expect(
        find.widgetWithText(FilledButton, 'Start a workout'), findsOneWidget);
    expect(find.byType(FitFlowStat), findsNothing);
    expect(find.byType(TrainingDisclosure), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'chart exact text equivalents and zero values use unchanged engine buckets',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final now = DateTime.utc(2026, 10, 10);
    final records = [
      fixtures.makeWorkout(completedAt: now.subtract(const Duration(days: 1)))
    ];
    final analytics =
        TrainingAnalyticsEngine.calculate(history: records, now: now);
    final before = records.single.toJson();
    await _pump(
        tester,
        SingleChildScrollView(
            child: ProgressActivityChart(analytics: analytics)),
        size: const Size(320, 700),
        scale: 2);
    expect(find.textContaining('0 workouts'), findsNWidgets(7));
    expect(find.textContaining('1 workout'), findsOneWidget);
    final bars = tester
        .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator))
        .toList();
    expect(bars.map((b) => b.value), [0, 0, 0, 0, 0, 0, 0, 1]);
    await tester.tap(find.text('Sets'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 main sets'), findsOneWidget);
    expect(records.single.toJson(), before);
    expect(tester.takeException(), isNull);
  });
  testWidgets('history errors are sanitized and retry has a native 48dp target',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pump(tester, const ProgressScreen(), historyError: true);
    expect(find.text('Could not load workout history.'), findsOneWidget);
    expect(find.textContaining('INTERNAL_STORAGE_DIAGNOSTIC'), findsNothing);
    final retry = find.widgetWithText(TextButton, 'Retry');
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('No completed workouts yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'native library selection and heading semantics remain actionable',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final semantics = tester.ensureSemantics();
    try {
      await _pump(tester, const ExerciseLibraryScreen(), reduced: true);
      final chip = find.widgetWithText(FilterChip, 'No equipment');
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      expect(
          tester
              .getSemantics(chip)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(chip).flagsCollection.isSelected,
          Tristate.isTrue);
      final filters = find.widgetWithText(OutlinedButton, 'Filters (1)');
      expect(tester.getSize(filters).height, greaterThanOrEqualTo(48));
      expect(
          tester
              .getSemantics(filters)
              .getSemanticsData()
              .hasAction(SemanticsAction.focus),
          isTrue);
      await tester.tap(filters);
      await tester.pumpAndSettle();
      expect(find.text('Movement Pattern'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('level2'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets(
      'advanced human labels retain AND filtering, active count, query and clear-all',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pump(tester, const ExerciseLibraryScreen(), reduced: true);
    await tester.enterText(find.byType(TextField), 'push');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'No equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Filters (1)'));
    await tester.pumpAndSettle();
    final push = find.widgetWithText(FilterChip, 'Push');
    await tester.ensureVisible(push);
    await tester.tap(push);
    await tester.pumpAndSettle();
    final basic = find.widgetWithText(FilterChip, 'Basic');
    await tester.ensureVisible(basic);
    await tester.tap(basic);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(basic).selected, isTrue);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final expected = applyExerciseLibraryFilter(
        ExerciseCatalog.all.where((e) => e.active).toList(),
        const ExerciseLibraryFilter(
          searchQuery: 'push',
          noEquipment: true,
          difficulties: {ExerciseDifficulty.level2},
          movementPatterns: {MovementPattern.push},
        ));
    expect(expected, isNotEmpty);
    expect(find.text('Filters (3)'), findsOneWidget);
    expect(find.text('Push · Basic'), findsOneWidget);
    expect(
        find.text(
            '${expected.length} ${expected.length == 1 ? 'exercise' : 'exercises'}'),
        findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'push');
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('88 exercises'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
