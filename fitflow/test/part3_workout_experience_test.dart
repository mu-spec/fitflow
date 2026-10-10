import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_reason.dart';
import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_replacement_picker.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/exercise_skill_tree_fixtures.dart';

WorkoutPlan flowPlan({bool replaceable = false}) {
  WorkoutExercisePrescription timed(String id, {int sets = 1}) =>
      WorkoutExercisePrescription(
          exercise: ExerciseCatalog.byId(id)!,
          sets: sets,
          workDuration: const Duration(seconds: 30),
          restBetweenSets: const Duration(seconds: 5));
  return WorkoutPlan(
    warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
      timed(replaceable ? 'plank_forearm' : 'march_in_place', sets: 2),
      timed('arm_circles'),
    ]),
    main: WorkoutSection(type: WorkoutSectionType.main, exercises: [
      WorkoutExercisePrescription(
          exercise: ExerciseCatalog.byId('squat_bodyweight')!,
          sets: 2,
          repsPerSet: 10,
          restBetweenSets: const Duration(seconds: 5)),
    ]),
    cooldown: WorkoutSection(
        type: WorkoutSectionType.cooldown,
        exercises: [timed('figure_four_stretch')]),
    timeBudget: const WorkoutTimeBudget(
        target: Duration(minutes: 15),
        warmup: Duration(minutes: 2),
        main: Duration(minutes: 11),
        cooldown: Duration(minutes: 2)),
  );
}

Future<void> surface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget flowApp(Widget child,
        {bool dark = false, bool reduced = true, double scale = 2}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: reduced),
          child: child!),
      home: child,
    );

Future<void> press(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void finishTimed(WorkoutPlayerController c) {
  for (var i = 0; i < 50 && c.state.phase == WorkoutPlayerPhase.work; i++) {
    c.tick();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final dark in [false, true]) {
    for (final size in [
      const Size(320, 700),
      const Size(390, 844),
      const Size(430, 900),
      const Size(600, 800),
      const Size(900, 800),
      const Size(900, 320)
    ]) {
      testWidgets(
          'Preview and every Player phase ${size.width}x${size.height} dark=$dark 2x',
          (tester) async {
        await surface(tester, size);
        await tester.pumpWidget(ProviderScope(
            overrides: programOverrides(),
            child: flowApp(const WorkoutPreviewScreen(), dark: dark)));
        await tester.pumpAndSettle();
        final generated = WorkoutGenerator.generateCatalog(
            WorkoutGenerationContext(
                userProfile: programTestProfile(),
                capabilityProfile: skillTreeCapabilityProfile()))!;
        expect(find.text('15 min target'), findsOneWidget);
        for (final p in generated.allPrescriptions) {
          expect(find.text(p.exercise.name), findsWidgets);
        }
        expect(find.text('Warm-up'), findsOneWidget);
        expect(find.text('Main workout'), findsOneWidget);
        expect(find.text('Cooldown'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('preview_start')));
        expect(tester.getSize(find.byKey(const Key('preview_start'))).height,
            greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());

        final plan = flowPlan();
        final coach = FakeWorkoutCoach();
        late WorkoutPlayerController c;
        await tester.pumpWidget(ProviderScope(
            overrides: [
              ...programOverrides(),
              workoutCoachProvider.overrideWithValue(coach),
              workoutPlayerControllerProvider(plan).overrideWith((ref) => c =
                  WorkoutPlayerController(
                      plan: plan, coach: coach, autoStartTimer: false)),
            ],
            child: flowApp(
                WorkoutPlayerSessionView(
                    plan: plan,
                    sessionMode: WorkoutSessionMode.lowEnergy,
                    sessionOrigin: WorkoutSessionOrigin.adaptive),
                dark: dark)));
        await tester.pumpAndSettle();
        expect(find.textContaining('Low Energy'), findsOneWidget);
        final session = c.sessionId;
        await press(tester, 'Begin workout');
        expect(find.text('Set 1 of 2'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(tester.takeException(), isNull);
        c.tick();
        await tester.pump();
        final beforePause = c.state.remaining;
        await press(tester, 'Pause workout');
        expect(find.text('Paused'), findsOneWidget);
        c.tick();
        await tester.pump();
        expect(c.state.remaining, beforePause);
        await press(tester, 'Resume');
        finishTimed(c);
        await tester.pumpAndSettle();
        expect(c.state.phase, WorkoutPlayerPhase.rest);
        expect(find.text('Rest'), findsOneWidget);
        expect(find.text('Next: Set 2 of 2'), findsOneWidget);
        await press(tester, 'Pause workout');
        expect(c.state.isPaused, isTrue);
        await press(tester, 'Resume');
        await press(tester, 'Skip rest');
        expect(c.state.setNumber, 2);
        finishTimed(c);
        await tester.pumpAndSettle();
        expect(c.state.phase, WorkoutPlayerPhase.transition);
        expect(find.text('Next exercise'), findsOneWidget);
        expect(find.text('Arm Circles'), findsOneWidget);
        await press(tester, 'Skip transition');
        expect(c.state.currentPrescription.exercise.id, 'arm_circles');
        finishTimed(c);
        await tester.pumpAndSettle();
        expect(find.text('Warm-up complete'), findsOneWidget);
        await press(tester, 'Continue');
        expect(find.text('10 reps'), findsOneWidget);
        expect(find.text('Set 1 of 2'), findsOneWidget);
        await press(tester, 'Set complete');
        await press(tester, 'Skip rest');
        await press(tester, 'Set complete');
        expect(find.text('Main workout complete'), findsOneWidget);
        await press(tester, 'Start cooldown');
        finishTimed(c);
        await tester.pumpAndSettle();
        expect(c.state.phase, WorkoutPlayerPhase.completed);
        expect(find.text('Workout complete'), findsOneWidget);
        expect(find.text('6 / 6'), findsOneWidget);
        expect(find.text('Tune next workout'), findsNothing);
        await tester.ensureVisible(find.text('Done'));
        expect(c.sessionId, session);
        expect(
            coach.spoken.where((s) => s == 'Workout complete.'), hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final reduced in [false, true]) {
    testWidgets(
        'Active replacement preserves workload, paused timer, ID and voice reduced=$reduced',
        (tester) async {
      await surface(tester, const Size(390, 844));
      final plan = flowPlan(replaceable: true);
      final coach = FakeWorkoutCoach();
      late WorkoutPlayerController c;
      await tester.pumpWidget(ProviderScope(
          overrides: [
            ...programOverrides(),
            workoutCoachProvider.overrideWithValue(coach),
            workoutPlayerControllerProvider(plan).overrideWith((ref) => c =
                WorkoutPlayerController(
                    plan: plan,
                    coach: coach,
                    autoStartTimer: false,
                    userProfile: programTestProfile(),
                    capabilityProfile: skillTreeCapabilityProfile())),
          ],
          child: flowApp(
              WorkoutPlayerSessionView(
                  plan: plan,
                  sessionMode: WorkoutSessionMode.standard,
                  sessionOrigin: WorkoutSessionOrigin.adaptive),
              reduced: reduced,
              scale: 1)));
      await tester.pumpAndSettle();
      final session = c.sessionId;
      await press(tester, 'Begin workout');
      c.tick();
      c.tick();
      c.tick();
      await tester.pump();
      final original = c.state.currentPrescription;
      final options = c.getReplacementOptions();
      expect(options, isNotEmpty,
          reason: 'This fixture must actually offer a replacement');
      final chosen = options.first;
      final beforeCancel = c.state.remaining;
      await press(tester, 'Replace exercise');
      expect(c.state.isPaused, isTrue);
      expect(c.state.remaining, beforeCancel);
      final picker = tester.widget<WorkoutReplacementPicker>(
          find.byType(WorkoutReplacementPicker));
      expect(picker.options.map((o) => o.exercise.id),
          options.map((o) => o.exercise.id));
      final l = englishAppLocalizations();
      for (final r in chosen.reasons.take(1)) {
        expect(replacementReasonLabel(l, r), r.label);
      }
      await press(tester, 'Cancel');
      expect(c.state.remaining, beforeCancel);
      expect(c.state.currentPrescription, original);
      await press(tester, 'Replace exercise');
      final use = find.byKey(ValueKey('replace_option_${chosen.exercise.id}'));
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(c.state.currentPrescription.exercise.id, chosen.exercise.id);
      expect(c.state.currentPrescription.sets, original.sets);
      expect(c.state.currentPrescription.workDuration, original.workDuration);
      expect(c.state.currentPrescription.repsPerSet, original.repsPerSet);
      expect(c.state.currentPrescription.restBetweenSets,
          original.restBetweenSets);
      expect(c.state.remaining,
          original.workDuration); // Existing reset-to-full-workload behavior.
      expect(c.state.isPaused, isTrue);
      expect(c.state.originalExerciseName, original.exercise.name);
      expect(find.text('Replaced ${original.exercise.name}'), findsOneWidget);
      final speech = List<String>.of(coach.spoken);
      final phaseAnimation = tester.widget<TweenAnimationBuilder<double>>(
          find.byType(TweenAnimationBuilder<double>));
      expect(phaseAnimation.duration,
          reduced ? Duration.zero : FitFlowMotion.standard);
      tester.view.physicalSize = const Size(900, 320);
      await tester.pumpAndSettle();
      expect(c.sessionId, session);
      expect(coach.spoken, speech,
          reason: 'Layout and animation must not speak or restart');
      await press(tester, 'Resume');
      c.tick();
      await tester.pump();
      expect(c.state.remaining,
          original.workDuration! - const Duration(seconds: 1));
      expect(c.state.completedSets, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('No alternatives is a calm scrollable state at 320 and 2x',
      (tester) async {
    await surface(tester, const Size(320, 320));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(flowApp(Scaffold(
        body: WorkoutReplacementPicker(
            currentPrescription: flowPlan().warmup.exercises.first,
            options: const [],
            scrollController: scroll,
            onSelect: (_) => fail('No selection should exist')))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('No suitable alternatives'), 120);
    expect(find.text('No suitable alternatives'), findsOneWidget);
    expect(find.text('Use this exercise'), findsNothing);
    await tester.ensureVisible(find.text('No suitable alternatives'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preview opens existing detail and starts existing Player route',
      (tester) async {
    final expected = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
        userProfile: programTestProfile(),
        capabilityProfile: skillTreeCapabilityProfile()))!;
    final first = expected.warmup.exercises.first;
    final router = GoRouter(initialLocation: AppRoutes.workoutPreview, routes: [
      GoRoute(
          path: AppRoutes.workoutPreview,
          builder: (context, state) => const WorkoutPreviewScreen()),
      GoRoute(
          path: AppRoutes.workoutPlayer,
          builder: (context, state) =>
              const Scaffold(body: Text('Existing player destination'))),
      GoRoute(
          path: AppRoutes.exerciseDetail(first.exercise.id),
          builder: (context, state) =>
              const Scaffold(body: Text('Existing exercise detail'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: programOverrides(),
        child:
            MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(first.exercise.name));
    await tester.tap(find.text(first.exercise.name));
    await tester.pumpAndSettle();
    expect(find.text('Existing exercise detail'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await press(tester, 'Start workout');
    expect(find.text('Existing player destination'), findsOneWidget);
  });

  testWidgets('Replaced row exposes original context only when supplied',
      (tester) async {
    final p = flowPlan().main.exercises.first;
    await tester.pumpWidget(flowApp(Scaffold(
        body: SingleChildScrollView(
            child: WorkoutPreviewExerciseRow(
                prescription: p, originalExerciseName: 'Original exercise')))));
    expect(find.text(p.exercise.name), findsOneWidget);
    expect(find.text('Replaced Original exercise'), findsOneWidget);
    await tester.pumpWidget(
        flowApp(Scaffold(body: WorkoutPreviewExerciseRow(prescription: p))));
    expect(find.textContaining('Replaced'), findsNothing);
  });

  testWidgets(
      'Native pause action, quiet timer semantics and completion are exactly once through resizing',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final plan = flowPlan();
      final coach = FakeWorkoutCoach();
      late WorkoutPlayerController c;
      var completed = 0;
      var done = 0;
      await surface(tester, const Size(390, 844));
      await tester.pumpWidget(ProviderScope(
          overrides: [
            ...programOverrides(),
            workoutCoachProvider.overrideWithValue(coach),
            workoutPlayerControllerProvider(plan).overrideWith((ref) => c =
                WorkoutPlayerController(
                    plan: plan, coach: coach, autoStartTimer: false)),
          ],
          child: flowApp(
              WorkoutPlayerSessionView(
                  plan: plan,
                  sessionMode: WorkoutSessionMode.standard,
                  sessionOrigin: WorkoutSessionOrigin.program,
                  onWorkoutCompleted: (_) async {
                    completed++;
                    return true;
                  },
                  onDone: () => done++),
              scale: 1)));
      await tester.pumpAndSettle();
      await press(tester, 'Begin workout');
      final pause = tester
          .getSemantics(find.widgetWithText(FilledButton, 'Pause workout'));
      expect(pause.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(pause.getSemanticsData().hasAction(SemanticsAction.focus), isTrue);
      final timer = tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Remaining \d+ seconds$')));
      expect(timer.flagsCollection.isLiveRegion, isFalse);
      final before = coach.spoken.length;
      c.tick();
      await tester.pumpAndSettle();
      expect(coach.spoken.length, before);
      await driveProgramPlayerToCompletion(tester, c);
      expect(completed, 1);
      expect(
          WorkoutHistoryStorage(await SharedPreferences.getInstance()).load(),
          hasLength(1));
      expect(find.text('Program workout completed.'), findsOneWidget);
      expect(find.text('Tune next workout'), findsOneWidget);
      await press(tester, 'Done');
      expect(done, 1);
      tester.view.physicalSize = const Size(900, 320);
      await tester.pumpAndSettle();
      await press(tester, 'Done');
      expect(done, 1);
      expect(completed, 1);
      expect(
          WorkoutHistoryStorage(await SharedPreferences.getInstance()).load(),
          hasLength(1));
      expect(find.textContaining('calories'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      handle.dispose();
    }
  });
  testWidgets(
      'Actual replacement reasons and chair equipment are truthful, workload stays compact',
      (tester) async {
    await surface(tester, const Size(390, 844));
    final base = flowPlan();
    final plan = WorkoutPlan(
        warmup: WorkoutSection(
            type: WorkoutSectionType.warmup, exercises: base.main.exercises),
        main: WorkoutSection(
            type: WorkoutSectionType.main, exercises: base.warmup.exercises),
        cooldown: base.cooldown,
        timeBudget: base.timeBudget);
    final c = WorkoutPlayerController(
        plan: plan,
        coach: FakeWorkoutCoach(),
        autoStartTimer: false,
        userProfile:
            programTestProfile().copyWith(equipment: {WorkoutEquipment.chair}),
        capabilityProfile: skillTreeCapabilityProfile(),
        catalog: [
          ExerciseCatalog.byId('squat_bodyweight')!,
          ExerciseCatalog.byId('squat_chair')!
        ]);
    addTearDown(c.dispose);
    final options = c.getReplacementOptions();
    expect(options, hasLength(1));
    expect(options.single.exercise.id, 'squat_chair');
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    WorkoutReplacementOption? selected;
    await tester.pumpWidget(flowApp(
        Scaffold(
            body: WorkoutReplacementPicker(
                currentPrescription: c.state.currentPrescription,
                options: options,
                scrollController: scroll,
                onSelect: (option) => selected = option)),
        scale: 1));
    await tester.pumpAndSettle();
    expect(find.text('Chair'), findsOneWidget);
    expect(find.text('No equipment'), findsNothing);
    expect(find.text('2 sets × 10 reps'), findsNWidgets(2));
    await press(tester, 'Why this fits');
    for (final reason in options.single.reasonLabels) {
      expect(find.text(reason), findsOneWidget);
    }
    await press(tester, 'Use this exercise');
    expect(identical(selected, options.single), isTrue);
    expect(selected!.prescription.repsPerSet, 10);
    expect(selected!.exercise.defaultReps, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Voice toggle is the existing action; animation and timer ticks do not repeat speech',
      (tester) async {
    final plan = flowPlan();
    final coach = FakeWorkoutCoach();
    late WorkoutPlayerController c;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          ...programOverrides(),
          workoutCoachProvider.overrideWithValue(coach),
          workoutPlayerControllerProvider(plan).overrideWith((ref) => c =
              WorkoutPlayerController(
                  plan: plan, coach: coach, autoStartTimer: false)),
        ],
        child: flowApp(
            WorkoutPlayerSessionView(
                plan: plan,
                sessionMode: WorkoutSessionMode.standard,
                sessionOrigin: WorkoutSessionOrigin.adaptive),
            reduced: false,
            scale: 1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mute voice'));
    await tester.pumpAndSettle();
    expect(c.state.voiceEnabled, isFalse);
    final spoken = coach.spoken.length;
    await press(tester, 'Begin workout');
    c.tick();
    await tester.pumpAndSettle();
    expect(coach.spoken.length, spoken);
    await tester.tap(find.byTooltip('Enable voice'));
    await tester.pumpAndSettle();
    expect(c.state.voiceEnabled, isTrue);
    final afterEnable = coach.spoken.length;
    await tester.pump(const Duration(milliseconds: 500));
    expect(coach.spoken.length, afterEnable);
    expect(c.state.phase, WorkoutPlayerPhase.work);
    await tester.pumpWidget(const SizedBox());
  });
}
