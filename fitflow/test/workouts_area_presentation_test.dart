import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_tree_family_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_trees_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/part6_quality_helpers.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Library controls and modal retain scoped contrast dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await seedPart6();
      final router = await part6Route(tester, AppRoutes.exerciseLibrary,
          dark: dark, scale: 2);
      addTearDown(router.dispose);
      final search = find.byType(TextField);
      final inputTheme = Theme.of(tester.element(search)).inputDecorationTheme;
      expect(inputTheme.fillColor,
          dark ? const Color(0xFF303737) : const Color(0xFFE4E8DD));
      expect(
          fitflowContrast(inputTheme.labelStyle!.color!, inputTheme.fillColor!),
          greaterThanOrEqualTo(4.5));
      // The shell remains under the user's original app theme.
      final navigationTheme =
          Theme.of(tester.element(find.byType(NavigationBar)));
      expect(navigationTheme.colorScheme.primary,
          (dark ? AppTheme.dark : AppTheme.light).colorScheme.primary);
      final filters = find.byType(OutlinedButton).first;
      await tester.ensureVisible(filters);
      await tester.pumpAndSettle();
      await tester.tap(filters);
      await tester.pumpAndSettle();
      final push = find.widgetWithText(FilterChip, 'Push').last;
      await tester.ensureVisible(push);
      await tester.pumpAndSettle();
      await tester.tap(push);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(push).selected, isTrue);
      final theme = Theme.of(tester.element(push));
      expect(theme.bottomSheetTheme.backgroundColor,
          dark ? const Color(0xFF202526) : const Color(0xFFF3F4EE));
      final label = DefaultTextStyle.of(tester
              .element(find.descendant(of: push, matching: find.text('Push'))))
          .style;
      expect(fitflowContrast(label.color!, theme.chipTheme.selectedColor!),
          greaterThanOrEqualTo(4.5));
      final done = find.widgetWithText(FilledButton, 'Done');
      await tester.ensureVisible(done);
      await tester.pumpAndSettle();
      expect(done.hitTestable(), findsOneWidget);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Workouts nested routes $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 18);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 18);
          addTearDown(tester.view.reset);
          await seedPart6();
          final exercise = ExerciseCatalog.all
              .firstWhere((e) => e.progressionFamilyId != null);
          final routes = <String, Type>{
            AppRoutes.programs: ProgramsOverviewScreen,
            AppRoutes.programDetail('balanced_foundations'):
                ProgramDetailScreen,
            AppRoutes.programSessionPreview(
                    'balanced_foundations', 'balanced_foundations_w1_s1'):
                ProgramSessionPreviewScreen,
            AppRoutes.customWorkoutNew: CustomWorkoutBuilderScreen,
            AppRoutes.customWorkoutDetail('TEST-custom'):
                CustomWorkoutDetailScreen,
            AppRoutes.customWorkoutEdit('TEST-custom'):
                CustomWorkoutBuilderScreen,
            AppRoutes.exerciseLibrary: ExerciseLibraryScreen,
            AppRoutes.exerciseDetail(exercise.id): ExerciseDetailScreen,
            AppRoutes.skillTrees: SkillTreesScreen,
            AppRoutes.skillTreeFamily(exercise.progressionFamilyId!):
                SkillTreeFamilyScreen,
          };
          for (final route in routes.entries) {
            final router =
                await part6Route(tester, route.key, dark: dark, scale: scale);
            final screen = find.byType(route.value);
            expect(screen, findsOneWidget, reason: route.key);
            final scaffold =
                find.descendant(of: screen, matching: find.byType(Scaffold));
            final context = tester.element(scaffold);
            final theme = Theme.of(context);
            expect(tester.widget<Scaffold>(scaffold).backgroundColor,
                dark ? const Color(0xFF202526) : const Color(0xFFF3F4EE),
                reason: route.key);
            expect(
                fitflowContrast(
                    theme.colorScheme.onSurface, theme.scaffoldBackgroundColor),
                greaterThanOrEqualTo(4.5));
            expect(find.byType(NavigationBar), findsOneWidget);
            if (route.value == ProgramSessionPreviewScreen) {
              final start = find.widgetWithText(FilledButton, 'Start workout');
              expect(start.hitTestable(), findsOneWidget);
              final about = find.byKey(const Key('program_session_about'));
              await tester.ensureVisible(about);
              await tester.pumpAndSettle();
              await tester.tap(about);
              await tester.pumpAndSettle();
              expect(
                  find.text('Session goal: General fitness'), findsOneWidget);
              expect(start.hitTestable(), findsOneWidget);
              expect(
                  tester.getBottomLeft(start).dy,
                  lessThanOrEqualTo(
                      tester.getTopLeft(find.byType(NavigationBar)).dy));
              expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
            }
            expect(tester.takeException(), isNull, reason: route.key);
            await tester.pumpWidget(const SizedBox.shrink());
            router.dispose();
          }
        });
      }
    }
  }
}
