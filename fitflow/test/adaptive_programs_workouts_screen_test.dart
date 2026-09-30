import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/programs/presentation/widgets/workouts_program_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 1);

  Future<void> pumpWorkouts(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    final router = programTestRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(
      router: router,
      overrides: overrides,
    ));
    await tester.pumpAndSettle();
  }

  group('Workouts screen – programs integration', () {
    testWidgets('real Programs entry replaces old placeholder', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester, overrides: programOverrides());

      expect(find.text('Programs'), findsOneWidget);
      expect(
          find.text(
              'Adaptive multi-week workouts built around your current level and setup.'),
          findsOneWidget);
      expect(find.text('Structured multi-week training plans.'), findsNothing);
      expect(find.byType(ProgramsEntryRow), findsOneWidget);
    });

    testWidgets('Library, Custom and Skill Trees entries remain', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester, overrides: programOverrides());
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Exercise skill trees'), findsOneWidget);
      expect(find.text('Create custom workout'), findsOneWidget);
      expect(find.text('Custom workouts'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('recommended card uses exact goal mapping', (tester) async {
      const cases = {
        FitnessGoal.generalFitness: 'Balanced Foundations',
        FitnessGoal.buildStrength: 'Strength Foundations',
        FitnessGoal.buildMuscle: 'Strength Foundations',
        FitnessGoal.loseWeight: 'Endurance Builder',
        FitnessGoal.improveEndurance: 'Endurance Builder',
        FitnessGoal.improveMobility: 'Mobility & Movement',
        FitnessGoal.stayActive: 'Stay Active Starter',
      };
      for (final entry in cases.entries) {
        SharedPreferences.setMockInitialValues({});
        // Dispose the previous ProviderScope so new overrides take effect.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpWorkouts(tester,
            overrides:
                programOverrides(profile: programTestProfile(goal: entry.key)));
        expect(find.text('Recommended program'), findsOneWidget,
            reason: entry.key.name);
        expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
        expect(find.text('Matches your selected goal'), findsOneWidget);
        expect(find.text('View program'), findsOneWidget);
        // Weeks / sessions per week shown.
        expect(find.textContaining('sessions/week'), findsWidgets);
        // No superlative claims.
        expect(find.textContaining('Best'), findsNothing);
        expect(find.textContaining('Optimal'), findsNothing);
        expect(find.textContaining('Guaranteed'), findsNothing);
      }
    });

    testWidgets('recommended card asks to complete profile when missing',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester,
          overrides: programOverrides(includeProfile: false));
      expect(
          find.text(
              'Complete your profile to see a program matched to your selected goal.'),
          findsOneWidget);
      expect(find.text('Matches your selected goal'), findsNothing);
    });

    testWidgets('View program navigates to the recommended detail', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester,
          overrides: programOverrides(
              profile: programTestProfile(goal: FitnessGoal.improveMobility)));
      await tester.tap(find.text('View program'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
      expect(find.text('Mobility & Movement'), findsWidgets);
    });

    testWidgets('Programs entry opens overview', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester, overrides: programOverrides());
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramsOverviewScreen), findsOneWidget);
      expect(find.text('Adaptive programs'), findsOneWidget);
    });

    testWidgets('no active card when nothing is active', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpWorkouts(tester, overrides: programOverrides());
      expect(find.text('Active program'), findsNothing);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('active card shows factual progress and structural week',
        (tester) async {
      final state = AdaptiveProgramsState(
        activeProgramId: 'balanced_foundations',
        progressByProgram: {
          'balanced_foundations': AdaptiveProgramProgress(
            programId: 'balanced_foundations',
            // startedAt long ago must NOT influence displayed week.
            startedAt: DateTime.utc(2020, 1, 1),
            updatedAt: t0,
            completions: [
              for (var i = 1; i <= 3; i++)
                AdaptiveProgramSessionCompletion(
                  plannedSessionId: 'balanced_foundations_w1_s$i',
                  playerSessionId: 'p$i',
                  completedAt: t0,
                ),
              AdaptiveProgramSessionCompletion(
                plannedSessionId: 'balanced_foundations_w2_s1',
                playerSessionId: 'p4',
                completedAt: t0,
              ),
            ],
          ),
        },
      );
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(state)});
      await pumpWorkouts(tester, overrides: programOverrides());

      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('Balanced Foundations'), findsWidgets);
      expect(find.text('4 of 12 completed'), findsOneWidget);
      expect(find.textContaining('Week 2 • Next: Week 2 • Session 2'),
          findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
      expect(find.text('Week 2 • Session 2'), findsOneWidget);
    });

    testWidgets('active card for a complete program routes to detail',
        (tester) async {
      final completions = <AdaptiveProgramSessionCompletion>[];
      var i = 0;
      for (var w = 1; w <= 4; w++) {
        for (var s = 1; s <= 3; s++) {
          completions.add(AdaptiveProgramSessionCompletion(
            plannedSessionId: 'stay_active_starter_w${w}_s$s',
            playerSessionId: 'p${i++}',
            completedAt: t0,
          ));
        }
      }
      final state = AdaptiveProgramsState(
        activeProgramId: 'stay_active_starter',
        progressByProgram: {
          'stay_active_starter': AdaptiveProgramProgress(
            programId: 'stay_active_starter',
            startedAt: t0,
            updatedAt: t0,
            completions: completions,
          ),
        },
      );
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(state)});
      await pumpWorkouts(tester, overrides: programOverrides());
      expect(find.text('12 of 12 completed'), findsOneWidget);
      expect(find.text('Program complete'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
    });

    testWidgets('active card reflects controller state changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final router = programTestRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(programTestApp(
        router: router,
        overrides: programOverrides(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsNothing);

      final element = tester.element(find.byType(ActiveProgramCard));
      final ProviderContainer container = ProviderScope.containerOf(element);
      await container
          .read(adaptiveProgramsControllerProvider.notifier)
          .startOrResumeProgram('endurance_builder');
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('0 of 16 completed'), findsOneWidget);
    });

    testWidgets('renders at 320px and text scale 1.5 without overflow',
        (tester) async {
      final state = AdaptiveProgramsState(
        activeProgramId: 'strength_foundations',
        progressByProgram: {
          'strength_foundations': AdaptiveProgramProgress.fresh(
              programId: 'strength_foundations', startedAt: t0),
        },
      );
      SharedPreferences.setMockInitialValues(
          {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(state)});
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final router = programTestRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(programTestApp(
        router: router,
        overrides: programOverrides(),
        textScale: 1.5,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('Active program'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('route helpers are consistent', (tester) async {
      expect(AppRoutes.programs, '/workouts/programs');
      expect(AppRoutes.programDetail('balanced_foundations'),
          '/workouts/programs/balanced_foundations');
      expect(
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
          '/workouts/programs/balanced_foundations/session/balanced_foundations_w1_s1');
    });
  });
}
