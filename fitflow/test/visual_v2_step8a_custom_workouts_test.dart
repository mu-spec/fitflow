import 'dart:ui' show SemanticsAction;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

const _workoutId = 'custom_step8a_0';
const _workoutName = 'Step 8A Strength';
const _playerRouteLabel = 'STEP8A_PLAYER_ROUTE';

final _targetViewports = <({Size size, double textScale, bool dark})>[
  (size: const Size(320, 700), textScale: 1, dark: false),
  (size: const Size(390, 844), textScale: 1, dark: true),
  (size: const Size(600, 900), textScale: 1, dark: false),
  (size: const Size(840, 1000), textScale: 1, dark: true),
  (size: const Size(900, 320), textScale: 1, dark: false),
  (size: const Size(320, 700), textScale: 2, dark: true),
];

CustomWorkoutTemplate _sampleWorkout({String name = _workoutName}) {
  final createdAt = DateTime.utc(2026, 10, 1);
  return CustomWorkoutTemplate(
    id: _workoutId,
    name: name,
    targetDuration: WorkoutDuration.fifteenMinutes,
    createdAt: createdAt,
    updatedAt: createdAt,
    warmup: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'march_in_place',
        sets: 1,
        workDuration: const Duration(seconds: 20),
        restBetweenSets: Duration.zero,
      ),
    ],
    main: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'squat_bodyweight',
        sets: 2,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 30),
      ),
    ],
    cooldown: [
      CustomWorkoutExerciseEntry(
        exerciseId: 'cobra_stretch',
        sets: 1,
        workDuration: const Duration(seconds: 20),
        restBetweenSets: Duration.zero,
      ),
    ],
  );
}

GoRouter _customWorkoutRouter({required String initialLocation}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home stub'))),
        ),
        GoRoute(
          path: AppRoutes.workouts,
          builder: (context, state) => const WorkoutsScreen(),
          routes: [
            GoRoute(
              path: 'custom/new',
              builder: (context, state) => const CustomWorkoutBuilderScreen(),
            ),
            GoRoute(
              path: 'custom/:workoutId',
              builder: (context, state) => CustomWorkoutDetailScreen(
                workoutId: state.pathParameters['workoutId']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => CustomWorkoutBuilderScreen(
                    workoutId: state.pathParameters['workoutId']!,
                  ),
                ),
                GoRoute(
                  path: 'player',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text(_playerRouteLabel)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

Future<GoRouter> _pumpCustomFlow(
  WidgetTester tester, {
  required String initialLocation,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  bool reducedMotion = true,
  List<CustomWorkoutTemplate> workouts = const [],
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  if (workouts.isNotEmpty) {
    await const CustomWorkoutStorage().saveAll(workouts);
  }

  final router = _customWorkoutRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: programOverrides(),
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: MaterialApp.router(
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) =>
              SystemMotionTheme(child: child ?? const SizedBox.shrink()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('empty state meaning and create/validation flow are preserved',
      (tester) async {
    await _pumpCustomFlow(
      tester,
      initialLocation: AppRoutes.workouts,
    );

    expect(find.text('No custom workouts yet'), findsOneWidget);
    expect(
      find.text('Build your own workout with exercises from your library.'),
      findsOneWidget,
    );
    final create = find.widgetWithText(FilledButton, 'Create workout');
    expect(create, findsOneWidget);
    await tester.ensureVisible(create);
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(find.byType(CustomWorkoutBuilderScreen), findsOneWidget);
    expect(find.text('Workout name'), findsOneWidget);
    expect(find.text('Target duration'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Cool-down'), findsOneWidget);
    expect(find.text('Add exercise'), findsNWidgets(3));

    final save = find.widgetWithText(FilledButton, 'Create workout');
    expect(save, findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('saved workout presentation, launch, edit/save, and delete flow',
      (tester) async {
    final router = await _pumpCustomFlow(
      tester,
      initialLocation: AppRoutes.workouts,
      workouts: [_sampleWorkout()],
    );

    expect(find.text(_workoutName), findsOneWidget);
    expect(find.text('No custom workouts yet'), findsNothing);
    expect(find.byType(FitFlowExerciseImage), findsOneWidget);
    final listArt = find.byType(FitFlowExerciseImage).first;
    expect(
      find.descendant(of: listArt, matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );

    final view = find.widgetWithText(FilledButton, 'View');
    await tester.ensureVisible(view);
    await tester.tap(view);
    await tester.pumpAndSettle();

    expect(find.byType(CustomWorkoutDetailScreen), findsOneWidget);
    expect(find.text(_workoutName), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Cool-down'), findsOneWidget);
    expect(find.byType(FitFlowV2ExerciseMedia), findsNWidgets(3));

    final start = find.widgetWithText(FilledButton, 'Start');
    await tester.ensureVisible(start);
    expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text(_playerRouteLabel), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    final edit = find.widgetWithText(OutlinedButton, 'Edit');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    expect(find.byType(CustomWorkoutBuilderScreen), findsOneWidget);
    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Step 8A Edited');
    final saveChanges = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(saveChanges);
    expect(tester.getSize(saveChanges).height, greaterThanOrEqualTo(48));
    await tester.tap(saveChanges);
    await tester.pumpAndSettle();

    expect(find.byType(CustomWorkoutDetailScreen), findsOneWidget);
    expect(find.text('Step 8A Edited'), findsOneWidget);
    final persisted = await const CustomWorkoutStorage().loadAll();
    expect(persisted.single.id, _workoutId);
    expect(persisted.single.name, 'Step 8A Edited');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete custom workout?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(find.text('No custom workouts yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'picker, photos, prescription, order and remove controls stay clear',
      (tester) async {
    await _pumpCustomFlow(
      tester,
      initialLocation: AppRoutes.customWorkoutEdit(_workoutId),
      workouts: [_sampleWorkout()],
    );
    final semantics = tester.ensureSemantics();

    final builderContext =
        tester.element(find.byType(CustomWorkoutBuilderScreen));
    expect(
      SystemMotion.duration(builderContext, const Duration(milliseconds: 250)),
      Duration.zero,
    );

    final mainSection = find.byKey(const Key('custom-workout-section-main'));
    final addMain = find.descendant(
      of: mainSection,
      matching: find.text('Add exercise'),
    );
    await tester.ensureVisible(addMain);
    await tester.tap(addMain);
    await tester.pumpAndSettle();

    final firstExerciseTile = find.byType(ListTile).first;
    expect(firstExerciseTile, findsOneWidget);
    final tile = tester.widget<ListTile>(firstExerciseTile);
    expect(tile.onTap, isNotNull);
    final tileSemantics = tester.getSemantics(firstExerciseTile);
    expect(tileSemantics.flagsCollection.isButton, isTrue);
    expect(
      tileSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    final exerciseName = (tile.title! as Text).data!;
    final pickerArtwork = find.descendant(
      of: firstExerciseTile,
      matching: find.byType(FitFlowExerciseImage),
    );
    expect(pickerArtwork, findsOneWidget);
    final photo = tester.widget<FitFlowExerciseImage>(pickerArtwork);
    expect(ExerciseCatalog.byIdMap[photo.exerciseId]!.name, exerciseName);
    expect(photo.width, photo.height);
    final search = find.byType(TextField).last;
    await tester.enterText(search, 'no matching exercise 123');
    await tester.pumpAndSettle();
    expect(find.text('No exercises found'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Bodyweight Squat'), findsNothing);
    expect(
      find.descendant(
        of: pickerArtwork,
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(firstExerciseTile).height, greaterThanOrEqualTo(48));

    await tester.tap(firstExerciseTile);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: mainSection, matching: find.text(exerciseName)),
      findsOneWidget,
    );
    final moveUp = find.descendant(
      of: mainSection,
      matching: find.byTooltip('Move up'),
    );
    final moveDown = find.descendant(
      of: mainSection,
      matching: find.byTooltip('Move down'),
    );
    expect(moveUp, findsNWidgets(2));
    expect(moveDown, findsNWidgets(2));
    expect(tester.getSize(moveUp.last).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(moveUp.last)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    final removeButton = find
        .descendant(
          of: mainSection,
          matching: find.widgetWithText(TextButton, 'Remove'),
        )
        .first;
    expect(
      tester
          .getSemantics(removeButton)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    // Edit the newly-added canonical exercise through its existing editor.
    final editButtons = find.descendant(
      of: mainSection,
      matching: find.widgetWithText(TextButton, 'Edit'),
    );
    await tester.tap(editButtons.last);
    await tester.pumpAndSettle();
    expect(find.text('Edit $exerciseName'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Rest seconds'), findsOneWidget);
    expect(find.textContaining('Preview:'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Reorder the added entry, then remove it without changing stored IDs.
    await tester.tap(moveUp.last);
    await tester.pumpAndSettle();
    final selectedY = tester
        .getTopLeft(
          find.descendant(of: mainSection, matching: find.text(exerciseName)),
        )
        .dy;
    final squatY = tester
        .getTopLeft(
          find.descendant(
            of: mainSection,
            matching: find.text('Bodyweight Squat'),
          ),
        )
        .dy;
    expect(selectedY, lessThan(squatY));

    final removeButtons = find.descendant(
      of: mainSection,
      matching: find.widgetWithText(TextButton, 'Remove'),
    );
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: mainSection, matching: find.text(exerciseName)),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField).first, 'Step 8A Reordered');
    final saveChanges = find.widgetWithText(FilledButton, 'Save changes');
    await tester.ensureVisible(saveChanges);
    await tester.tap(saveChanges);
    await tester.pumpAndSettle();
    expect(find.text('Step 8A Reordered'), findsOneWidget);

    final saved = (await const CustomWorkoutStorage().loadAll()).single;
    expect(saved.id, _workoutId);
    expect(saved.main.map((entry) => entry.exerciseId), ['squat_bodyweight']);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
      'narrow large-text picker adds exercise and preserves discard handling',
      (tester) async {
    await _pumpCustomFlow(tester,
        initialLocation: AppRoutes.workouts,
        size: const Size(320, 700),
        textScale: 2,
        dark: true);
    final create = find.widgetWithText(FilledButton, 'Create workout');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    // This isolated router bypasses onboarding, which normally loads both
    // profiles before entering the builder.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomWorkoutBuilderScreen)));
    await container.read(userFitnessProfileProvider.future);
    await container.read(capabilityProfileProvider.future);
    final mainSection = find.byKey(const Key('custom-workout-section-main'));
    final add =
        find.descendant(of: mainSection, matching: find.text('Add exercise'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField).last, 'Bodyweight Squat');
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, 'Bodyweight Squat');
    await tester.scrollUntilVisible(tile, 150,
        scrollable: find
            .descendant(
                of: find.byType(DraggableScrollableSheet),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: mainSection, matching: find.text('Bodyweight Squat')),
        findsOneWidget);
    final photo = tester.widget<FitFlowExerciseImage>(find.descendant(
        of: mainSection, matching: find.byType(FitFlowExerciseImage)));
    expect(photo.exerciseId, 'squat_bodyweight');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomWorkoutBuilderScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutsScreen), findsOneWidget);
    expect(await const CustomWorkoutStorage().loadAll(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final timed in [false, true]) {
    testWidgets(
        'prescription validation and save retain IDs with keyboard timed=$timed',
        (tester) async {
      await _pumpCustomFlow(tester,
          initialLocation: AppRoutes.customWorkoutEdit(_workoutId),
          workouts: [_sampleWorkout()],
          size: const Size(320, 700),
          textScale: 2,
          dark: timed);
      final section = find
          .byKey(Key('custom-workout-section-${timed ? 'warmup' : 'main'}'));
      final edit = find.descendant(
          of: section, matching: find.widgetWithText(TextButton, 'Edit'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final fields = find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextField));
      final save = find.widgetWithText(FilledButton, 'Save');
      Future<void> enter(int index, String value) async {
        await tester.ensureVisible(fields.at(index));
        await tester.enterText(fields.at(index), value);
        await tester.pumpAndSettle();
      }

      expect(find.text(timed ? 'Work seconds' : 'Reps'), findsOneWidget);
      expect(find.text(timed ? 'Reps' : 'Work seconds'), findsNothing);
      await enter(0, '0');
      expect(find.text('Sets must be 1..10'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await enter(0, '3');
      await enter(1, timed ? '4' : '0');
      expect(
          find.text(timed ? 'Work must be 5..300 sec' : 'Reps must be 1..100'),
          findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await enter(1, timed ? '45' : '12');
      await enter(2, '301');
      expect(find.text('Rest must be 0..300 sec'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await enter(2, '25');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      final saveChanges = find.widgetWithText(FilledButton, 'Save changes');
      await tester.ensureVisible(saveChanges);
      await tester.tap(saveChanges);
      await tester.pumpAndSettle();
      final stored = (await const CustomWorkoutStorage().loadAll()).single;
      expect(stored.id, _workoutId);
      expect(stored.createdAt, _sampleWorkout().createdAt);
      expect(
          stored.warmup.map((entry) => entry.exerciseId), ['march_in_place']);
      expect(
          stored.main.map((entry) => entry.exerciseId), ['squat_bodyweight']);
      expect(
          stored.cooldown.map((entry) => entry.exerciseId), ['cobra_stretch']);
      final edited = timed ? stored.warmup.single : stored.main.single;
      expect(edited.sets, 3);
      expect(edited.restBetweenSets, const Duration(seconds: 25));
      expect(edited.workDuration, timed ? const Duration(seconds: 45) : null);
      expect(edited.repsPerSet, timed ? null : 12);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('overview, builder and detail handle target viewports and themes',
      (tester) async {
    final fixture = _sampleWorkout();

    for (final viewport in _targetViewports) {
      await _pumpCustomFlow(
        tester,
        initialLocation: AppRoutes.workouts,
        size: viewport.size,
        textScale: viewport.textScale,
        dark: viewport.dark,
        workouts: [fixture],
      );
      expect(find.text(_workoutName), findsOneWidget);
      final view = find.widgetWithText(FilledButton, 'View');
      await tester.ensureVisible(view);
      expect(tester.getSize(view).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull, reason: 'overview $viewport');

      final workoutCard = find.byKey(ValueKey('workouts_custom_${fixture.id}'));
      final overviewScaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(WorkoutsScreen),
          matching: find.byType(Scaffold),
        ),
      );
      final overviewContext = tester.element(workoutCard);
      expect(
        overviewScaffold.backgroundColor,
        FitFlowVisualV2.of(overviewContext).page,
      );
      if (viewport.size.width == 840) {
        expect(tester.getSize(workoutCard).width, lessThanOrEqualTo(840));
      }

      await _pumpCustomFlow(
        tester,
        initialLocation: AppRoutes.customWorkoutEdit(_workoutId),
        size: viewport.size,
        textScale: viewport.textScale,
        dark: viewport.dark,
        workouts: [fixture],
      );
      expect(find.byType(CustomWorkoutBuilderScreen), findsOneWidget);
      final builderContext =
          tester.element(find.byType(CustomWorkoutBuilderScreen));
      final builderScaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(CustomWorkoutBuilderScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        builderScaffold.backgroundColor,
        FitFlowVisualV2.of(builderContext).page,
      );
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('Cool-down'), findsOneWidget);
      final add = find.text('Add exercise').first;
      await tester.ensureVisible(add);
      final saveChanges = find.widgetWithText(FilledButton, 'Save changes');
      await tester.ensureVisible(saveChanges);
      expect(tester.getSize(saveChanges).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull, reason: 'builder $viewport');
      if (viewport.size.width == 840) {
        expect(
          tester.getSize(find.byType(TextField).first).width,
          lessThanOrEqualTo(800),
        );
      }

      await _pumpCustomFlow(
        tester,
        initialLocation: AppRoutes.customWorkoutDetail(_workoutId),
        size: viewport.size,
        textScale: viewport.textScale,
        dark: viewport.dark,
        workouts: [fixture],
      );
      expect(find.byType(CustomWorkoutDetailScreen), findsOneWidget);
      expect(find.text(_workoutName), findsOneWidget);
      final detailContext =
          tester.element(find.byType(CustomWorkoutDetailScreen));
      final detailScaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(CustomWorkoutDetailScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        detailScaffold.backgroundColor,
        FitFlowVisualV2.of(detailContext).page,
      );
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Main'), findsOneWidget);
      expect(find.text('Cool-down'), findsOneWidget);
      final start = find.widgetWithText(FilledButton, 'Start');
      await tester.ensureVisible(start);
      expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull, reason: 'detail $viewport');
      if (viewport.size.width == 840) {
        final summary = find.byType(FitFlowV2InfoSurface).first;
        expect(tester.getSize(summary).width, lessThanOrEqualTo(760));
      }
    }
  });
}
