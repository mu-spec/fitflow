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
import 'package:fitflow/features/workouts/presentation/widgets/skill_tree_family_card.dart';
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
    testWidgets('shows title, supporting copy, and truthful note',
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
        find.text(
          'Your movement level helps show which exercises fit your current level. '
          'It does not mean every easier exercise is mastered.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'cards show family, movement, steps, and easiest-to-hardest names',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      expect(find.text('Push-Up'), findsOneWidget);
      expect(find.text('Push'), findsWidgets);
      expect(find.text('6 steps'), findsOneWidget);
      expect(find.text('Wall Push-Up  →  Diamond Push-Up'), findsOneWidget);
      expect(find.text('Squat'), findsWidgets);
      expect(find.text('Glute Bridge'), findsWidgets);
    });

    testWidgets('overview shows movement capability and independent fit counts',
        (tester) async {
      final router = _router(initialLocation: AppRoutes.skillTrees);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router: router, catalog: _catalog()));
      await tester.pumpAndSettle();

      final pushCard = find.ancestor(
        of: find.text('Your Push level: Level 2'),
        matching: find.byType(SkillTreeFamilyCard),
      );
      expect(pushCard, findsOneWidget);
      expect(
        find.descendant(
          of: pushCard,
          matching: find.text('3 fit your current level'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pushCard,
          matching: find.text('3 above your current level'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pushCard,
          matching: find.text('6 fit your current setup'),
        ),
        findsOneWidget,
      );
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
      expect(find.text('Your Push level: Level 2'), findsOneWidget);
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
      expect(find.text('Wall Push-Up'), findsOneWidget);
      expect(find.text('Incline Push-Up'), findsOneWidget);
      expect(find.text('Knee Push-Up'), findsOneWidget);
      expect(find.text('Standard Push-Up'), findsOneWidget);
      expect(find.text('Decline Push-Up'), findsOneWidget);
      expect(find.text('Diamond Push-Up'), findsOneWidget);
      expect(find.text('Level 1'), findsWidgets);
      expect(find.text('Level 2'), findsWidgets);
      expect(find.text('Your Push level: Level 2'), findsOneWidget);
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
      expect(find.text('Equipment: No equipment required'), findsWidgets);
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

      expect(find.text('Your Push level: Level 2'), findsNothing);
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

    testWidgets('family screen remains safe at narrow width and 1.5 text scale',
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
          textScaler: TextScaler.linear(1.5),
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
      expect(find.text('Your Push level: Level 2'), findsOneWidget);
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
