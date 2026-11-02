import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_body_focus.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_list_tile.dart';
import 'package:fitflow/features/workouts/presentation/widgets/skill_tree_node_card.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/features/home/presentation/home_theme.dart';
import 'package:fitflow/features/workout_preview/presentation/preview_theme.dart';
import 'package:fitflow/features/workout_player/presentation/player_theme.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/adaptive_program_test_helpers.dart';

Future<void> pumpWorkspace(WidgetTester tester, Widget screen,
    {double scale = 1, bool dark = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: programOverrides(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('primary buttons remain black and white in every scoped theme',
      (tester) async {
    for (final dark in [false, true]) {
      for (final wrap in <Widget Function(Widget)>[
        (child) => child,
        (child) => HomeTheme(child: child),
        (child) => WorkoutsTheme(child: child),
        (child) => PreviewTheme(child: child),
        (child) => PlayerTheme(child: child),
      ]) {
        await pumpWorkspace(
            tester,
            wrap(Scaffold(
                body: FilledButton(
                    onPressed: () {}, child: const Text('Action')))),
            dark: dark);
        final style = Theme.of(tester.element(find.byType(FilledButton)))
            .filledButtonTheme
            .style!;
        expect(style.backgroundColor!.resolve({}), Colors.black);
        expect(style.foregroundColor!.resolve({}), Colors.white);
      }
    }
  });

  testWidgets('family selection survives switching between library tabs',
      (tester) async {
    await pumpWorkspace(
        tester, const ExerciseLibraryScreen(initialSkills: true));
    final squat = find.widgetWithText(ChoiceChip, 'Squat');
    await tester.tap(squat);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Exercises'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Skill paths'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(squat).selected, isTrue);
  });

  testWidgets('quick filters remain available in the filter sheet',
      (tester) async {
    await pumpWorkspace(tester, const ExerciseLibraryScreen());
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'No equipment').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Clear filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('body groups use primary targets and keep every exercise in All', () {
    final push = ExerciseCatalog.byId('pushup_standard')!;
    expect(ExerciseBodyFocus.chest.matches(push), isTrue);
    expect(ExerciseBodyFocus.arms.matches(push), isTrue);
    expect(ExerciseBodyFocus.legs.matches(push), isFalse);
    expect(ExerciseCatalog.all.every(ExerciseBodyFocus.all.matches), isTrue);
    expect(
        ExerciseBodyFocus.legs
            .matches(ExerciseCatalog.byId('squat_bodyweight')!),
        isTrue);
  });

  testWidgets(
      'body category and search intersect; guide closes back to selection',
      (tester) async {
    await pumpWorkspace(tester, const ExerciseLibraryScreen());
    final chest = find.byKey(const ValueKey('body_focus_chest'));
    await reveal(tester, chest);
    await tester.tap(chest);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('exercise_library_search')), 'Wall');
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseListTile), findsOneWidget);
    await tester.tap(find.text('Wall Push-Up'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(find.text('How to Perform'), findsOneWidget);
    expect(find.text('Common Mistakes'), findsNothing);
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    expect(tester.widget<ChoiceChip>(chest).selected, isTrue);
    expect(find.text('Wall'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('skill paths expand in place at large text dark=$dark',
        (tester) async {
      await pumpWorkspace(
          tester, const ExerciseLibraryScreen(initialSkills: true),
          scale: 2, dark: dark);
      tester.view.physicalSize = const Size(320, 700);
      await tester.pumpAndSettle();
      final first = find.byType(SkillTreeNodeCard).first;
      final tile =
          find.descendant(of: first, matching: find.byType(ExpansionTile));
      await reveal(tester, tile);
      await tester
          .tap(find.descendant(of: tile, matching: find.text('Wall Push-Up')));
      await tester.pumpAndSettle();
      final view = find.widgetWithText(FilledButton, 'View exercise');
      await reveal(tester, view);
      await tester.tap(view);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Close').last);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Workouts uses uncropped portrait and removes helper subtitles',
      (tester) async {
    await pumpWorkspace(tester, const WorkoutsScreen());
    final image = tester
        .widget<Image>(find.byKey(const Key('workouts_program_portrait')));
    expect(image.fit, BoxFit.contain);
    expect(find.text('Plans for your level and setup.'), findsNothing);
    expect(find.text('Choose exercises for your own workout.'), findsNothing);
    expect(find.text('Browse exercises'), findsOneWidget);
    final create = find.widgetWithText(FilledButton, 'Create workout');
    final theme = Theme.of(tester.element(create));
    expect(theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
        Colors.black);
    expect(theme.filledButtonTheme.style!.foregroundColor!.resolve({}),
        Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'inline prescription validates, saves, and persists without dialog',
      (tester) async {
    final now = DateTime.utc(2026, 11, 2);
    final workout = CustomWorkoutTemplate(
      id: 'workspace',
      name: 'My workout',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
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
    );
    await const CustomWorkoutStorage().saveAll([workout]);
    final router = GoRouter(initialLocation: '/edit', routes: [
      GoRoute(
          path: '/edit',
          builder: (_, __) =>
              const CustomWorkoutBuilderScreen(workoutId: 'workspace')),
      GoRoute(
          path: AppRoutes.customWorkoutDetail('workspace'),
          builder: (_, __) => const Scaffold(body: Text('Saved workout'))),
    ]);
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        overrides: programOverrides(),
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        )));
    await tester.pumpAndSettle();
    final main = find.byKey(const Key('custom-workout-section-main'));
    final edit = find.descendant(of: main, matching: find.text('Edit'));
    await reveal(tester, edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final sets = find.widgetWithText(TextField, 'Sets');
    await reveal(tester, sets);
    await tester.enterText(sets, '0');
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(sets, '3');
    await tester.pumpAndSettle();
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saveWorkout = find.widgetWithText(FilledButton, 'Save changes');
    await reveal(tester, saveWorkout);
    await tester.tap(saveWorkout);
    await tester.pumpAndSettle();
    expect(find.text('Saved workout'), findsOneWidget);
    final persisted = await const CustomWorkoutStorage().findById('workspace');
    expect(persisted!.main.single.sets, 3);
    expect(persisted.main.single.repsPerSet, 10);
    expect(persisted.warmup, workout.warmup);
    expect(persisted.cooldown, workout.cooldown);
    expect(tester.takeException(), isNull);
  });
}
