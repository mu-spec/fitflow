import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_generation_profile.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/exercise_skill_tree_fixtures.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 1);

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    List<Override>? overrides,
    double textScale = 1.0,
  }) async {
    final router = programTestRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(
      router: router,
      overrides: overrides ?? programOverrides(),
      textScale: textScale,
    ));
    await tester.pumpAndSettle();
  }

  void seed(AdaptiveProgramsState state) {
    SharedPreferences.setMockInitialValues(
        {AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(state)});
  }

  AdaptiveProgramsState balancedWithTwoDone({String? active = 'balanced_foundations'}) =>
      AdaptiveProgramsState(
        activeProgramId: active,
        progressByProgram: {
          'balanced_foundations': AdaptiveProgramProgress(
            programId: 'balanced_foundations',
            startedAt: t0,
            updatedAt: t0,
            completions: [
              AdaptiveProgramSessionCompletion(
                plannedSessionId: 'balanced_foundations_w1_s1',
                playerSessionId: 'p1',
                completedAt: t0,
              ),
              AdaptiveProgramSessionCompletion(
                plannedSessionId: 'balanced_foundations_w1_s3',
                playerSessionId: 'p3',
                completedAt: t0,
              ),
            ],
          ),
        },
      );

  group('Programs overview', () {
    testWidgets('shows header, copy and all five programs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programs);
      expect(find.text('Adaptive programs'), findsOneWidget);
      expect(
          find.text(
              'Structured multi-week plans whose workouts adapt to your current movement levels and setup.'),
          findsOneWidget);
      for (final def in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, find.text(def.name));
        expect(find.text(def.name), findsOneWidget);
        expect(find.text(def.focus), findsOneWidget);
      }
      await programScrollToTop(tester);
      // Structural facts (ListView is lazy, so check each while visible).
      const facts = {
        'Balanced Foundations': '4 weeks • 3 sessions/week • 12 workouts',
        'Strength Foundations': '6 weeks • 3 sessions/week • 18 workouts',
        'Endurance Builder': '4 weeks • 4 sessions/week • 16 workouts',
        'Mobility & Movement': '4 weeks • 3 sessions/week • 12 workouts',
        'Stay Active Starter': '4 weeks • 3 sessions/week • 12 workouts',
      };
      for (final entry in facts.entries) {
        await programScrollTo(tester, find.text(entry.key));
        final card = find.ancestor(
            of: find.text(entry.key), matching: find.byType(Card));
        expect(find.descendant(of: card, matching: find.text(entry.value)),
            findsOneWidget,
            reason: entry.key);
      }
    });

    testWidgets('marks the recommended program only', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programs,
          overrides: programOverrides(
              profile: programTestProfile(goal: FitnessGoal.buildMuscle)));
      expect(find.text('Matches your selected goal'), findsOneWidget);
      final tag = find.ancestor(
        of: find.text('Matches your selected goal'),
        matching: find.byType(Card),
      );
      expect(
          find.descendant(of: tag, matching: find.text('Strength Foundations')),
          findsOneWidget);
    });

    testWidgets('no recommendation tag without a profile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programs,
          overrides: programOverrides(includeProfile: false));
      expect(find.text('Matches your selected goal'), findsNothing);
      expect(find.text('Balanced Foundations'), findsOneWidget);
    });

    testWidgets('shows active and progress tags; tapping opens detail',
        (tester) async {
      seed(balancedWithTwoDone());
      await pumpAt(tester, AppRoutes.programs);
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('2 of 12 completed'), findsOneWidget);
      await tester.tap(find.text('Balanced Foundations'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
    });

    testWidgets('no medical/AI/success claims', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programs);
      for (final banned in ['Best', 'Optimal', 'Guaranteed', 'AI', 'medical', 'lose weight', 'burn']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });

    testWidgets('320px + text scale 1.5 and tablet render without overflow',
        (tester) async {
      seed(balancedWithTwoDone());
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await pumpAt(tester, AppRoutes.programs, textScale: 1.5);
      expect(find.text('Adaptive programs'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1024, 1366);
      await pumpAt(tester, AppRoutes.programs);
      expect(find.text('Adaptive programs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Program detail', () {
    testWidgets('fresh program shows structure, Start and all sessions',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programDetail('strength_foundations'));
      expect(find.text('Strength Foundations'), findsOneWidget);
      expect(find.textContaining('Six weeks of strength'), findsOneWidget);
      expect(find.text('6 weeks'), findsOneWidget);
      expect(find.text('3 sessions/week'), findsOneWidget);
      expect(find.text('18 workouts'), findsOneWidget);
      expect(find.text('Start program'), findsOneWidget);
      expect(find.text('Resume program'), findsNothing);
      expect(find.text('Restart program'), findsNothing);
      expect(find.text('Switch to this program'), findsNothing);
      expect(find.textContaining('workouts completed'), findsNothing);
      // Week groups and sessions. First session is Next even with no progress.
      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await programScrollTo(tester, find.text('Week 6'), step: 400);
      expect(find.text('Week 6'), findsOneWidget);
      // No locking or lateness claims anywhere.
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.textContaining('missed'), findsNothing);
      expect(find.textContaining('behind'), findsNothing);
    });

    testWidgets('session rows show focus, goal and View workout', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'));
      expect(find.text('Full-body basics • Goal: General fitness'), findsWidgets);
      await programScrollTo(
          tester, find.text('Strength • Goal: Build strength'));
      expect(find.text('Strength • Goal: Build strength'), findsWidgets);
      await programScrollTo(
          tester, find.text('Endurance • Goal: Improve endurance'));
      expect(find.text('Endurance • Goal: Improve endurance'), findsWidgets);
      await programScrollToTop(tester);
      expect(find.text('View workout'), findsWidgets);
      await tester.tap(find.text('View workout').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
      expect(find.text('Week 1 • Session 1'), findsOneWidget);
    });

    testWidgets('Start sets the program active and shows progress', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programDetail('mobility_movement'));
      await tester.tap(find.text('Start program'));
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('0 of 12 workouts completed'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Restart program'), findsOneWidget);
      expect(find.text('Start program'), findsNothing);
      final saved = await const AdaptiveProgramsStorage().load();
      expect(saved.activeProgramId, 'mobility_movement');
    });

    testWidgets('progress states: Completed / Next / Planned and bar',
        (tester) async {
      seed(balancedWithTwoDone());
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'));
      expect(find.text('2 of 12 workouts completed'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Week 1 • Next: Week 1 • Session 2'), findsOneWidget);
      // Sessions 1 and 3 of week 1 completed, session 2 is next.
      Finder rowOf(String sessionLabel) => find.ancestor(
            of: find.text(sessionLabel).first,
            matching: find.byType(ProgramSessionRow),
          );
      expect(find.descendant(of: rowOf('Session 1'), matching: find.text('Completed')),
          findsOneWidget);
      expect(find.descendant(of: rowOf('Session 2'), matching: find.text('Next')),
          findsOneWidget);
      await programScrollTo(tester, find.text('Session 3'));
      expect(find.descendant(of: rowOf('Session 3'), matching: find.text('Completed')),
          findsOneWidget);
      // Only one Next exists in the whole program.
      expect(find.text('Next').evaluate().length, lessThanOrEqualTo(1));
      await programScrollTo(tester, find.text('Week 2'));
      expect(find.text('Planned'), findsWidgets);
      expect(find.text('Next'), findsNothing);
      expect(find.textContaining('fitness progress'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('Trophy'), findsNothing);
    });

    testWidgets('non-active with progress shows Resume', (tester) async {
      seed(balancedWithTwoDone(active: null));
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'));
      expect(find.text('Resume program'), findsOneWidget);
      expect(find.text('Restart program'), findsOneWidget);
      await tester.tap(find.text('Resume program'));
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('2 of 12 workouts completed'), findsOneWidget);
    });

    testWidgets('Switch asks confirmation, keeps old progress', (tester) async {
      seed(balancedWithTwoDone());
      await pumpAt(tester, AppRoutes.programDetail('endurance_builder'));
      expect(find.text('Switch to this program'), findsOneWidget);
      await tester.tap(find.text('Switch to this program'));
      await tester.pumpAndSettle();
      expect(find.text('Switch active program?'), findsOneWidget);
      expect(find.text('Your progress in the current program will be kept.'),
          findsOneWidget);
      // Cancel first.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Switch to this program'), findsOneWidget);
      // Confirm.
      await tester.tap(find.text('Switch to this program'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('0 of 16 workouts completed'), findsOneWidget);

      final saved = await const AdaptiveProgramsStorage().load();
      expect(saved.activeProgramId, 'endurance_builder');
      expect(saved.progressFor('balanced_foundations')!.completions.length, 2);
    });

    testWidgets('Switch to a program with progress resumes it', (tester) async {
      seed(AdaptiveProgramsState(
        activeProgramId: 'stay_active_starter',
        progressByProgram: {
          'stay_active_starter': AdaptiveProgramProgress.fresh(
              programId: 'stay_active_starter', startedAt: t0),
          ...balancedWithTwoDone().progressByProgram,
        },
      ));
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'));
      expect(find.text('2 of 12 workouts completed'), findsOneWidget);
      await tester.tap(find.text('Switch to this program'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('2 of 12 workouts completed'), findsOneWidget);
    });

    testWidgets('Restart asks confirmation and clears only program progress',
        (tester) async {
      seed(balancedWithTwoDone());
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'));
      await tester.tap(find.text('Restart program'));
      await tester.pumpAndSettle();
      expect(find.text('Restart this program?'), findsOneWidget);
      expect(
          find.text(
              'Its saved program progress will be cleared. Completed workout history will stay unchanged.'),
          findsOneWidget);
      await tester.tap(find.text('Restart'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 12 workouts completed'), findsOneWidget);
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
    });

    testWidgets('complete program shows Program complete', (tester) async {
      final completions = <AdaptiveProgramSessionCompletion>[];
      var i = 0;
      for (final s in AdaptiveProgramCatalog.mobilityMovement.sessions) {
        completions.add(AdaptiveProgramSessionCompletion(
          plannedSessionId: s.id,
          playerSessionId: 'p${i++}',
          completedAt: t0,
        ));
      }
      seed(AdaptiveProgramsState(
        activeProgramId: 'mobility_movement',
        progressByProgram: {
          'mobility_movement': AdaptiveProgramProgress(
            programId: 'mobility_movement',
            startedAt: t0,
            updatedAt: t0,
            completions: completions,
          ),
        },
      ));
      await pumpAt(tester, AppRoutes.programDetail('mobility_movement'));
      expect(find.text('Program complete'), findsOneWidget);
      expect(find.text('12 of 12 workouts completed'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Restart program'), findsOneWidget);
    });

    testWidgets('unknown program ID is safe', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester, AppRoutes.programDetail('does_not_exist'));
      expect(find.text('Program not found'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px + 1.5 text scale renders without overflow', (tester) async {
      seed(balancedWithTwoDone());
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await pumpAt(tester, AppRoutes.programDetail('balanced_foundations'),
          textScale: 1.5);
      expect(find.text('Balanced Foundations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed persistence shows a snackbar and keeps state',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final failing = AdaptiveProgramsStorage(
        writeString: (prefs, key, value) async => false,
      );
      await pumpAt(
        tester,
        AppRoutes.programDetail('balanced_foundations'),
        overrides: [
          ...programOverrides(),
          adaptiveProgramsStorageProvider.overrideWithValue(failing),
        ],
      );
      await tester.tap(find.text('Start program'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't save program changes. Try again."),
          findsOneWidget);
      expect(find.text('Start program'), findsOneWidget);
      expect(find.text('Active program'), findsNothing);
    });
  });

  group('Program session preview', () {
    testWidgets('generates from current profile and shows all sections',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s3'));
      expect(find.text('Program workout'), findsOneWidget);
      expect(find.text('Balanced Foundations'), findsOneWidget);
      expect(find.text('Week 1 • Session 3'), findsOneWidget);
      expect(find.text('Focus: Endurance'), findsOneWidget);
      expect(find.text('Session goal: Improve endurance'), findsOneWidget);
      expect(find.text('15 min target'), findsOneWidget);
      expect(find.textContaining('planned'), findsWidgets);
      expect(find.textContaining('exercises'), findsWidgets);
      expect(find.textContaining(' sets'), findsWidgets);
      expect(
          find.text(
              'Generated from your current movement levels, equipment, environment, and preferences.'),
          findsOneWidget);
      expect(
          find.text(
              'Your saved profile goal is not changed by this program session.'),
          findsOneWidget);
      expect(find.text('Warm-up'), findsOneWidget);
      await programScrollTo(tester, find.text('Main workout'));
      expect(find.text('Main workout'), findsOneWidget);
      await programScrollTo(tester, find.text('Cooldown'));
      expect(find.text('Cooldown'), findsOneWidget);
      expect(find.byType(WorkoutPreviewExerciseRow), findsWidgets);
    });

    testWidgets('exercises match the resolver output (generator reuse)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final profile = programTestProfile();
      final cap = skillTreeCapabilityProfile();
      final session = AdaptiveProgramCatalog.balancedFoundations
          .sessionById('balanced_foundations_w1_s3')!;
      final expected = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
        userProfile: AdaptiveProgramGenerationProfile.forSession(
            current: profile, session: session),
        capabilityProfile: cap,
      ))!;
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s3'),
          overrides: programOverrides(profile: profile, capability: cap));
      final rows = tester
          .widgetList<WorkoutPreviewExerciseRow>(
              find.byType(WorkoutPreviewExerciseRow))
          .map((r) => r.prescription.exercise.id)
          .toList();
      // Only rows currently laid out are found; check prefix ordering.
      final expectedIds = expected.allExercises.map((e) => e.id).toList();
      expect(rows, isNotEmpty);
      expect(expectedIds.sublist(0, rows.length), rows);
    });

    testWidgets('Start is enabled and no transitional Part 1 copy remains',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'));
      await programScrollTo(tester, find.text('Start workout'), step: 300);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Start workout'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
      expect(
          find.text(
              'Workout start will be available after program setup finishes.'),
          findsNothing);
    });

    testWidgets('Home Low Energy / Comeback cannot change the program plan',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      List<String> idsFor(WorkoutSessionMode mode) => <String>[];
      final results = <WorkoutSessionMode, List<String>>{};
      for (final mode in WorkoutSessionMode.values) {
        final router = programTestRouter(
          initialLocation: AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(programTestApp(
          router: router,
          overrides: programOverrides(),
        ));
        await tester.pumpAndSettle();
        final element =
            tester.element(find.byType(ProgramSessionPreviewScreen));
        final container = ProviderScope.containerOf(element);
        container.read(workoutSessionModeProvider.notifier).selectMode(mode);
        await tester.pumpAndSettle();
        expect(container.read(workoutSessionModeProvider), mode);
        final ids = tester
            .widgetList<WorkoutPreviewExerciseRow>(
                find.byType(WorkoutPreviewExerciseRow))
            .map((r) => r.prescription.exercise.id)
            .toList();
        results[mode] = ids.isEmpty ? idsFor(mode) : ids;
        // Target duration stays the profile duration (no Low Energy cut).
        expect(find.text('15 min target'), findsOneWidget);
        expect(find.textContaining('Temporary for this workout'), findsNothing);
      }
      expect(results[WorkoutSessionMode.standard], isNotEmpty);
      expect(results[WorkoutSessionMode.lowEnergy],
          results[WorkoutSessionMode.standard]);
      expect(results[WorkoutSessionMode.comeback],
          results[WorkoutSessionMode.standard]);
    });

    testWidgets('generation failure is truthful; no fallback exercises',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
          overrides:
              programOverrides(profile: programUngenerableProfile()));
      expect(
          find.text(
              "This program workout can't be generated with your current setup."),
          findsOneWidget);
      expect(find.byType(WorkoutPreviewExerciseRow), findsNothing);
      expect(find.text('Start workout'), findsNothing);
      expect(find.text('Week 1 • Session 1'), findsOneWidget);
    });

    testWidgets('missing profile / capability show existing empty states',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
          overrides: programOverrides(includeProfile: false));
      expect(find.text('Complete profile'), findsOneWidget);

      // Dispose the previous ProviderScope so new overrides take effect.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
          overrides: programOverrides(includeCapability: false));
      expect(find.text('Start assessment'), findsOneWidget);
    });

    testWidgets('status chip reflects saved progress', (tester) async {
      seed(balancedWithTwoDone());
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'));
      expect(find.byType(ProgramSessionStatusChip), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('unknown program / session IDs are safe', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(tester,
          AppRoutes.programSessionPreview('nope', 'nope_w1_s1'));
      expect(find.text('Program not found'), findsWidgets);
      expect(tester.takeException(), isNull);

      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'strength_foundations_w1_s1'));
      expect(find.text('Session not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px + 1.5 text scale and tablet render without overflow',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'),
          textScale: 1.5);
      expect(find.text('Program workout'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1024, 1366);
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'balanced_foundations', 'balanced_foundations_w1_s1'));
      expect(find.text('Program workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no medical/AI/success claims', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpAt(
          tester,
          AppRoutes.programSessionPreview(
              'endurance_builder', 'endurance_builder_w1_s1'));
      for (final banned in ['Best', 'Optimal', 'Guaranteed', 'AI ', 'medical', 'lose weight', 'burn fat']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });
  });
}
