import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/presentation/widgets/skill_tree_node_card.dart';
import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_tree_family_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_trees_screen.dart';
import 'package:fitflow/features/workouts/state/exercise_skill_tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

ExerciseSkillTreeCatalog _catalog({
  bool includeBench = true,
  bool includeCapability = true,
}) {
  return ExerciseSkillTreeResolver.resolve(
    exercises: ExerciseCatalog.all,
    userProfile: skillTreeUserProfile(
      equipment: includeBench ? const {WorkoutEquipment.bench} : const {},
    ),
    capabilityProfile: includeCapability
        ? skillTreeCapabilityProfile(
            levels: const {MovementPattern.push: CapabilityLevel.level2},
          )
        : CapabilityProfile.fromMap(const {}),
  );
}

GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.skillTrees,
        builder: (context, state) => const SkillTreesScreen(),
        routes: [
          GoRoute(
            path: ':familyId',
            builder: (context, state) => SkillTreeFamilyScreen(
              familyId: state.pathParameters['familyId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.exerciseLibrary}/:exerciseId',
        builder: (context, state) => ExerciseDetailScreen(
          exerciseId: state.pathParameters['exerciseId']!,
        ),
      ),
    ],
  );
}

Widget _app({
  required GoRouter router,
  required ExerciseSkillTreeCatalog catalog,
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
}) {
  return ProviderScope(
    overrides: [exerciseSkillTreeCatalogProvider.overrideWithValue(catalog)],
    child: MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
    ),
  );
}

void main() {
  group('Skill trees overview widgets', () {
    testWidgets(
        'shows compact title and introduction with explanations in details',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Exercise skill trees'), findsOneWidget);
      expect(
        find.text(
            'See how exercise variations progress from easier to harder.'),
        findsOneWidget,
      );
      expect(
          find.textContaining(
              'It does not mean every easier exercise is mastered.'),
          findsNothing);
      await tester.tap(find.text('Push-Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progression'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(
              'It does not mean every easier exercise is mastered.'),
          findsOneWidget);
    });

    testWidgets(
        'rows show actual family, steps, movement level and representative photo',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Push-Up'), findsOneWidget);
      expect(find.textContaining('Push'), findsWidgets);
      expect(find.textContaining('6 steps'), findsOneWidget);
      final photos = tester
          .widgetList<FitFlowExerciseImage>(find.byType(FitFlowExerciseImage))
          .toList();
      expect(photos.map((photo) => photo.exerciseId),
          _catalog().trees.map((tree) => tree.easiest.exercise.id));
      for (final photo in photos) {
        expect(photo.width / photo.height, closeTo(4 / 3, .001));
      }
      expect(find.text('Squat'), findsWidgets);
      expect(find.text('Glute Bridge'), findsWidgets);
    });

    testWidgets(
        'detail disclosure retains endpoints and independent fit counts',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Your Push level: Basic'), findsOneWidget);
      expect(find.text('3 fit your current level'), findsNothing);
      await tester.tap(find.text('Push-Up'));
      await tester.pumpAndSettle();
      expect(find.text('3 fit your current level'), findsNothing);
      await tester.tap(find.text('Progression'));
      await tester.pumpAndSettle();
      expect(find.text('Wall Push-Up \u2192 Diamond Push-Up'), findsOneWidget);
      expect(find.text('3 fit your current level'), findsOneWidget);
      expect(find.text('3 above your current level'), findsOneWidget);
      expect(find.text('6 fit your current setup'), findsOneWidget);
    });

    testWidgets('tapping a family card opens its family detail route',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Push-Up'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeFamilyScreen), findsOneWidget);
      expect(find.text('Your Push level: Basic'), findsOneWidget);
    });

    testWidgets('does not present mastery, completion, or unlock labels',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      for (final forbidden in [
        'Mastered',
        'Completed',
        'Passed',
        'Unlocked',
        'Locked',
        'Achieved',
        'Failed',
        'Ready to advance',
      ]) {
        expect(find.text(forbidden), findsNothing);
      }
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('overview remains usable at 320 pixels wide', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);

      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Exercise skill trees'), findsOneWidget);
      expect(find.text('Push-Up'), findsOneWidget);
    });

    testWidgets('overview handles a tablet width and 1.5 text scale',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(),
          textScaler: TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Exercise skill trees'), findsOneWidget);
    });

    testWidgets('overview is safe in both light and dark themes',
        (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final router = _router(initialLocation: AppRoutes.skillTrees);
        await tester.pumpWidget(
          _app(
            router: router,
            catalog: _catalog(),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Push-Up'), findsOneWidget);
        router.dispose();
      }
    });

    testWidgets('missing capability is described without guessed fit counts',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(includeCapability: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Movement level unavailable'), findsWidgets);
      expect(
        find.textContaining(RegExp(r'^\d+ fit your current level$')),
        findsNothing,
      );
      expect(
        find.textContaining(RegExp(r'^\d+ above your current level$')),
        findsNothing,
      );
    });
  });

  group('Skill-tree family detail widgets', () {
    testWidgets('explicit branches remain distinct from sorted step order',
        (tester) async {
      final catalog = ExerciseSkillTreeResolver.resolve(
        exercises: [
          skillTreeExercise(
              id: 'pushup_wall',
              name: 'Wall',
              familyId: 'branch',
              rank: 1,
              harderId: 'pushup_knee'),
          skillTreeExercise(
              id: 'pushup_incline',
              name: 'Incline',
              familyId: 'branch',
              rank: 2,
              harderId: 'pushup_knee'),
          skillTreeExercise(
              id: 'pushup_knee',
              name: 'Knee',
              familyId: 'branch',
              rank: 3,
              easierId: 'pushup_wall'),
        ],
        userProfile: null,
        capabilityProfile: null,
      );
      final router =
          _router(initialLocation: AppRoutes.skillTreeFamily('branch'));
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: catalog));
      await tester.pumpAndSettle();

      final cards = find.byType(SkillTreeNodeCard);
      expect(
          tester
              .widgetList<SkillTreeNodeCard>(cards)
              .map((card) => card.node.exercise.id),
          ['pushup_wall', 'pushup_incline', 'pushup_knee']);
      for (final index in [0, 1]) {
        expect(
            find.descendant(
                of: cards.at(index),
                matching: find.text('Harder variation: Knee')),
            findsOneWidget);
      }
      expect(
          find.descendant(
              of: cards.at(2), matching: find.text('Easier variation: Wall')),
          findsOneWidget);
      expect(find.text('Harder variation: Incline'), findsNothing);
      expect(find.text('Movement level unavailable'), findsNWidgets(4));
      expect(find.text('Setup details unavailable'), findsNWidgets(3));
    });

    testWidgets('shows ordered nodes with step numbering and difficulty levels',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      for (var step = 1; step <= 6; step++) {
        expect(find.text('Step $step of 6'), findsOneWidget);
      }
      final nodes =
          tester.widgetList<SkillTreeNodeCard>(find.byType(SkillTreeNodeCard));
      expect(
          nodes.map((card) => card.node.exercise.id),
          _catalog()
              .treeForFamilyId('pushup')!
              .nodes
              .map((node) => node.exercise.id));
      expect(
          tester
              .widgetList<FitFlowExerciseImage>(
                  find.byType(FitFlowExerciseImage))
              .map((image) => image.exerciseId),
          nodes.map((card) => card.node.exercise.id));
      expect(find.text('Wall Push-Up'), findsOneWidget);
      expect(find.text('Incline Push-Up'), findsOneWidget);
      expect(find.text('Knee Push-Up'), findsOneWidget);
      expect(find.text('Standard Push-Up'), findsOneWidget);
      expect(find.text('Decline Push-Up'), findsOneWidget);
      expect(find.text('Diamond Push-Up'), findsOneWidget);
      expect(find.text('Just starting'), findsWidgets);
      expect(find.text('Basic'), findsWidgets);
      expect(find.text('Your Push level: Basic'), findsOneWidget);
      expect(
        find.text(
          'This pathway shows exercise difficulty and setup fit, not exercise mastery.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows level-fit and setup-fit status as readable text',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Fits your current level'), findsNWidgets(3));
      expect(find.text('Above your current level'), findsNWidgets(3));
      expect(find.text('Fits your setup'), findsNWidgets(6));
      expect(find.text('Equipment: No equipment'), findsWidgets);
      expect(find.text('Reps'), findsWidgets);
    });

    testWidgets('setup conflicts remain separate from above-level status',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(includeBench: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Above your current level'), findsNWidgets(3));
      expect(find.text('Needs setup change'), findsNWidgets(2));
      expect(find.text('Needs different equipment'), findsNWidgets(2));
      expect(find.text('Fits your setup'), findsNWidgets(4));
    });

    testWidgets('missing movement capability remains unavailable',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(includeCapability: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Push level: Basic'), findsNothing);
      expect(find.text('Movement level unavailable'), findsNWidgets(7));
      expect(find.text('Fits your current level'), findsNothing);
      expect(find.text('Above your current level'), findsNothing);
    });

    testWidgets('View exercise opens the existing Exercise Detail route',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      final viewExercise = find.text('View exercise').first;
      await tester.scrollUntilVisible(viewExercise, 240, maxScrolls: 10);
      await tester.tap(viewExercise);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      expect(find.text('Wall Push-Up'), findsWidgets);
      expect(find.text('Progression'), findsOneWidget);
    });

    testWidgets('unknown family shows a safe not-found route and back action',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('not_in_catalog'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Skill tree not found'), findsOneWidget);
      await tester.tap(find.text('Back to Skill Trees'));
      await tester.pumpAndSettle();
      expect(find.text('Exercise skill trees'), findsOneWidget);
    });

    testWidgets(
        'family screen remains safe at narrow width and 2x text scale in dark mode',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(),
          brightness: Brightness.dark,
          textScaler: TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Exercise skill trees'), findsNothing);
      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('family screen remains safe at tablet width in dark theme',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _app(
          router: router,
          catalog: _catalog(),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your Push level: Basic'), findsOneWidget);
    });

    testWidgets('family nodes do not show locks, completion, or mastery labels',
        (tester) async {
      final router = _router(
        initialLocation: AppRoutes.skillTreeFamily('pushup'),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      for (final forbidden in [
        'Mastered',
        'Completed',
        'Passed',
        'Unlocked',
        'Locked',
        'Achieved',
        'Failed',
        'Ready to advance',
      ]) {
        expect(find.text(forbidden), findsNothing);
      }
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });
  });
}
