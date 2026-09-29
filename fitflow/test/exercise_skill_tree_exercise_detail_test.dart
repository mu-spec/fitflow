import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
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

void main() {
  testWidgets('family exercise keeps progression and shows full-tree action',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseDetailScreen(exerciseId: 'pushup_standard'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progression'), findsOneWidget);
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Knee Push-Up'), findsOneWidget);
    expect(find.text('Standard Push-Up'), findsWidgets);
    expect(find.text('Decline Push-Up'), findsOneWidget);
    expect(find.text('View full skill tree'), findsOneWidget);
  });

  testWidgets('standalone exercise has no full-tree action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseDetailScreen(exerciseId: 'pushup_pike'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progression'), findsNothing);
    expect(find.text('View full skill tree'), findsNothing);
  });

  testWidgets('full-tree action uses the canonical family route',
      (tester) async {
    final catalog = ExerciseSkillTreeResolver.resolve(
      exercises: ExerciseCatalog.all,
      userProfile: skillTreeUserProfile(),
      capabilityProfile: skillTreeCapabilityProfile(
        levels: const {MovementPattern.push: CapabilityLevel.level3},
      ),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.exerciseDetail('pushup_standard'),
      routes: [
        GoRoute(
          path: '${AppRoutes.exerciseLibrary}/:exerciseId',
          builder: (context, state) => ExerciseDetailScreen(
            exerciseId: state.pathParameters['exerciseId']!,
          ),
        ),
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseSkillTreeCatalogProvider.overrideWithValue(catalog)
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fullTreeAction =
        find.widgetWithText(OutlinedButton, 'View full skill tree');
    await tester.scrollUntilVisible(fullTreeAction, 260, maxScrolls: 20);
    expect(tester.widget<OutlinedButton>(fullTreeAction).onPressed, isNotNull);
    await tester.tap(fullTreeAction);
    await tester.pumpAndSettle();

    expect(AppRoutes.skillTreeFamily('pushup'), '/workouts/skill-trees/pushup');
    expect(find.byType(SkillTreeFamilyScreen), findsOneWidget);
    expect(find.text('Your Push level: Level 3'), findsOneWidget);
  });
}
