import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree_resolver.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/presentation/skill_trees_screen.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:fitflow/features/workouts/state/exercise_skill_tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/exercise_skill_tree_fixtures.dart';

void main() {
  testWidgets('Workouts screen keeps existing entries and opens skill trees',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final catalog = ExerciseSkillTreeResolver.resolve(
      exercises: ExerciseCatalog.all,
      userProfile: skillTreeUserProfile(),
      capabilityProfile: skillTreeCapabilityProfile(
        levels: const {MovementPattern.push: CapabilityLevel.level2},
      ),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.workouts,
      routes: [
        GoRoute(
          path: AppRoutes.workouts,
          builder: (context, state) => const WorkoutsScreen(),
          routes: [
            GoRoute(
              path: 'skill-trees',
              builder: (context, state) => const SkillTreesScreen(),
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

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Exercise skill trees'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('Custom workouts'), findsOneWidget);

    await tester.tap(find.text('Exercise skill trees'));
    await tester.pumpAndSettle();
    expect(find.byType(SkillTreesScreen), findsOneWidget);
  });
}
