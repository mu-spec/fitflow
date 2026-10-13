import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_completion.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/adaptive_progression_feedback_sheet.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_rest_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_transition_view.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/app_localizations_en.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_preview_test.dart' as fixtures;

const _sizes = [
  Size(320, 700),
  Size(390, 844),
  Size(600, 900),
  Size(840, 1000),
  Size(900, 320),
];
final _l = AppLocalizationsEn();

/// Count calls while retaining real canonical history persistence.
class _HistorySpy extends WorkoutHistoryController {
  int attempts = 0;
  @override
  Future<bool> addWorkout(CompletedWorkout workout) {
    attempts++;
    return super.addWorkout(workout);
  }
}

/// Retains the real build/save implementation and storage transaction seam.
class _CapabilitySpy extends CapabilityProfileController {
  int saves = 0;
  @override
  Future<bool> saveProfile(CapabilityProfile profile) {
    saves++;
    return super.saveProfile(profile);
  }
}

class _Harness {
  _Harness(this.container, this.router, this.plan, this.coach, this.history,
      this.capability, this.prefs);
  final ProviderContainer container;
  final GoRouter router;
  final WorkoutPlan plan;
  final FakeWorkoutCoach coach;
  final _HistorySpy history;
  final _CapabilitySpy capability;
  final SharedPreferences prefs;
  final List<WorkoutPlayerCompletion> completions = [];
  WorkoutPlayerController get controller =>
      container.read(workoutPlayerControllerProvider(plan).notifier);
  List<CompletedWorkout> get saved => WorkoutHistoryStorage(prefs).load();
}

WorkoutPlan _plan({Duration rest = const Duration(seconds: 90)}) {
  WorkoutExercisePrescription reps(String id, int sets, Duration pause) =>
      WorkoutExercisePrescription(
          exercise: ExerciseCatalog.byId(id)!,
          sets: sets,
          repsPerSet: 10,
          restBetweenSets: pause);
  return WorkoutPlan(
    warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
      reps('squat_bodyweight', 2, rest),
      reps('pushup_wall', 1, Duration.zero),
    ]),
    main: WorkoutSection(type: WorkoutSectionType.main, exercises: [
      reps('squat_bodyweight', 2, const Duration(seconds: 8)),
    ]),
    cooldown: WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [
      WorkoutExercisePrescription(
          exercise: ExerciseCatalog.byId('plank_knee')!,
          sets: 1,
          workDuration: const Duration(seconds: 4),
          restBetweenSets: Duration.zero),
    ]),
    timeBudget:
        WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

Widget _app(_Harness h, Size size,
        {bool dark = false, double scale = 1, bool reduced = false}) =>
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark : AppTheme.light,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: h.router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            padding: const EdgeInsets.only(top: 24, bottom: 18),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 18),
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: SystemMotionTheme(child: child!),
        ),
      ),
    );

Future<_Harness> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
  bool reduced = false,
  bool autoStartTimer = false,
  WorkoutSessionOrigin origin = WorkoutSessionOrigin.adaptive,
  WorkoutSessionMode mode = WorkoutSessionMode.standard,
  String? doneRoute = '/',
  VoidCallback? onDone,
  String? completionNote,
  Duration rest = const Duration(seconds: 90),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final profile = fixtures.createUserProfile();
  final cap = fixtures.createFullProfile(CapabilityLevel.level3);
  SharedPreferences.setMockInitialValues({
    CapabilityProfileStorage.profileKey: CapabilityProfileStorage.encode(cap),
  });
  final prefs = await SharedPreferences.getInstance();
  final plan = _plan(rest: rest);
  final history = _HistorySpy();
  final capability = _CapabilitySpy();
  final coach = FakeWorkoutCoach();
  final container = ProviderContainer(overrides: [
    userFitnessProfileProvider.overrideWith(() =>
        fixtures.FakeUserProfileController(buildOverride: () async => profile)),
    capabilityProfileProvider.overrideWith(() => capability),
    workoutHistoryProvider.overrideWith(() => history),
    workoutPlayerControllerProvider.overrideWith((ref, p) =>
        WorkoutPlayerController(
            plan: p,
            autoStartTimer: autoStartTimer,
            coach: coach,
            userProfile: profile,
            capabilityProfile: cap)),
  ]);
  container.read(workoutSessionModeProvider.notifier).selectMode(mode);
  await container.read(capabilityProfileProvider.future);
  await container.read(workoutHistoryProvider.future);
  late final _Harness h;
  final router = GoRouter(initialLocation: '/', routes: [
    GoRoute(
        path: '/',
        builder: (c, s) => const Scaffold(body: Text('Test root')),
        routes: [
          GoRoute(
              path: 'session',
              builder: (c, s) => WorkoutPlayerSessionView(
                    plan: plan,
                    sessionMode: mode,
                    sessionOrigin: origin,
                    doneRoute: doneRoute,
                    onDone: onDone,
                    completionNote: completionNote,
                    onWorkoutCompleted: (completion) async {
                      h.completions.add(completion);
                      return true;
                    },
                  ))
        ]),
    GoRoute(
        path: AppRoutes.home,
        builder: (c, s) => const Scaffold(body: Text('Test Home'))),
    GoRoute(
        path: AppRoutes.workouts,
        builder: (c, s) => const Scaffold(body: Text('Test Workouts'))),
    GoRoute(
        path: '/program-detail',
        builder: (c, s) => const Scaffold(body: Text('Test Program'))),
    GoRoute(
        path: '/workouts/exercise-library/:id',
        builder: (c, s) =>
            Scaffold(body: Text('Detail ${s.pathParameters['id']}'))),
  ]);
  h = _Harness(container, router, plan, coach, history, capability, prefs);
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester
      .pumpWidget(_app(h, size, dark: dark, scale: scale, reduced: reduced));
  await tester.pumpAndSettle();
  router.push<void>('/session');
  await tester.pumpAndSettle();
  return h;
}

Future<void> _rest(WidgetTester tester, _Harness h) async {
  h.controller.beginWorkout();
  h.controller.completeSet();
  await tester.pumpAndSettle();
  expect(h.controller.state.phase, WorkoutPlayerPhase.rest);
}

Future<void> _complete(WidgetTester tester, _Harness h) async {
  final c = h.controller;
  for (var i = 0;
      i < 500 && c.state.phase != WorkoutPlayerPhase.completed;
      i++) {
    switch (c.state.phase) {
      case WorkoutPlayerPhase.ready:
        c.beginWorkout();
      case WorkoutPlayerPhase.work:
        if (c.state.isTimedExercise) {
          c.tick();
        } else {
          c.completeSet();
        }
      case WorkoutPlayerPhase.rest:
        c.skipRest();
      case WorkoutPlayerPhase.transition:
        c.skipTransition();
      case WorkoutPlayerPhase.sectionBreak:
        c.continueSection();
      case WorkoutPlayerPhase.completed:
        break;
    }
  }
  expect(c.state.phase, WorkoutPlayerPhase.completed);
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

Future<void> _reachable(WidgetTester tester, Finder finder, Size size) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThanOrEqualTo(48));
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(rect.center.dx, inInclusiveRange(0, size.width));
  expect(rect.center.dy, inInclusiveRange(24, size.height - 18));
  expect(finder.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, String label, Size size) async {
  final finder = _button(label);
  await _reachable(tester, finder, size);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Step 5B responsive truthful Rest', () {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              '${size.width.toInt()}x${size.height.toInt()} '
              '${dark ? 'dark' : 'light'} ${scale}x', (tester) async {
            final h = await _pump(tester, size: size, dark: dark, scale: scale);
            await _rest(tester, h);
            final c = h.controller;
            expect(find.text(_l.flowRest), findsOneWidget);
            expect(find.text(countdown(const Duration(seconds: 90))),
                findsOneWidget);
            expect(find.text(_l.flowNextSet(2, 2)), findsOneWidget);
            expect(find.text(c.state.currentPrescription.exercise.name),
                findsOneWidget);
            expect(find.text(workloadLabel(_l, c.state.currentPrescription)),
                findsOneWidget);
            expect(find.text(_l.skipTransition), findsNothing);
            expect(find.text(_l.flowReplace), findsNothing);
            expect(
                MediaQuery.textScalerOf(
                        tester.element(find.byType(WorkoutPlayerRestView)))
                    .scale(16),
                16 * scale);
            final prescription = c.state.currentPrescription;
            final remaining = c.state.remaining;
            await _reachable(tester, _button(_l.skipRest), size);
            await _tap(tester, _l.flowPause, size);
            expect(c.state.isPaused, isTrue);
            c.tick();
            expect(c.state.remaining, remaining);
            expect(c.state.currentPrescription, prescription);
            expect(find.text(_l.flowRest), findsOneWidget);
            expect(find.text(_l.flowPaused), findsOneWidget);
            expect(find.text(_l.skipRest), findsNothing);
            await _reachable(tester, _button(_l.flowDetails), size);
            await _tap(tester, _l.resume, size);
            await _tap(tester, _l.skipRest, size);
            expect(c.state.phase, WorkoutPlayerPhase.work);
            expect(c.state.setNumber, 2);
            expect(c.state.currentPrescription, prescription);
            expect(c.state.completedSets, 1);
            expect(find.byType(WorkoutPlayerExerciseCenter), findsOneWidget);
            expect(h.history.attempts, 0);
            expect(h.completions, isEmpty);
            expect(h.capability.saves, 0);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('Step 5B responsive truthful Completion', () {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              '${size.width.toInt()}x${size.height.toInt()} '
              '${dark ? 'dark' : 'light'} ${scale}x', (tester) async {
            final h = await _pump(tester, size: size, dark: dark, scale: scale);
            expect(h.history.attempts, 0);
            expect(h.completions, isEmpty);
            await _complete(tester, h);
            final c = h.controller;
            expect(find.byType(WorkoutPlayerCompletedView), findsOneWidget);
            expect(find.text(_l.flowComplete), findsOneWidget);
            expect(find.text(_l.flowFinished), findsOneWidget);
            expect(
                find.descendant(
                    of: find.byKey(const ValueKey('v2_completed_exercises')),
                    matching: find.text('${h.plan.totalExerciseCount}')),
                findsOneWidget);
            expect(
                find.descendant(
                    of: find.byKey(const ValueKey('v2_completed_sets')),
                    matching: find.text(
                        '${c.state.completedSets} / ${c.state.totalSets}')),
                findsOneWidget);
            expect(find.text(plannedDuration(_l, h.plan.targetDuration)),
                findsOneWidget);
            expect(find.text(plannedDuration(_l, h.plan.estimatedDuration)),
                findsOneWidget);
            expect(find.text(_l.flowHistory), findsOneWidget);
            expect(
                find.textContaining(RegExp(
                    'calories|\\bXP\\b|streak|score|rank|fat burned|heart rate',
                    caseSensitive: false)),
                findsNothing);
            expect(find.byType(Image), findsNothing);
            expect(
                MediaQuery.textScalerOf(
                        tester.element(find.byType(WorkoutPlayerCompletedView)))
                    .scale(16),
                16 * scale);
            if (scale == 2 || size.height < 400) {
              expect(
                  tester
                      .getSize(find.byKey(const ValueKey('v2_completed_mark'))),
                  const Size(40, 40));
            }
            await _reachable(tester, _button(_l.flowTune), size);
            await _reachable(tester, _button(_l.done), size);
            expect(h.history.attempts, 1);
            expect(h.saved, hasLength(1));
            expect(h.completions, hasLength(1));
            expect(h.capability.saves, 0);
            await _tap(tester, _l.done, size);
            expect(find.text('Test root'), findsOneWidget);
            expect(h.history.attempts, 1);
            expect(h.saved, hasLength(1));
            expect(h.completions, hasLength(1));
            expect(h.capability.saves, 0);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('Step 5B existing timing and one-shot actions', () {
    testWidgets(
        'bounded standalone Completion scrolls without changing existing tests or actions',
        (tester) async {
      var done = 0;
      final h = await _pump(tester);
      await _complete(tester, h);
      final state = h.controller.state;
      for (final size in _sizes) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(UncontrolledProviderScope(
            container: h.container,
            child: MaterialApp(
              theme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      size: size,
                      padding: const EdgeInsets.only(top: 24, bottom: 18),
                      viewPadding: const EdgeInsets.only(top: 24, bottom: 18),
                      textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: Scaffold(
                  body: SafeArea(
                      child: WorkoutPlayerCompletedView(
                          plan: h.plan, state: state, onDone: () => done++))),
            ),
          ));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('v2_completed_scroll')),
              findsOneWidget);
          await _reachable(tester, _button(_l.done), size);
          await _reachable(tester, _button(_l.flowTune), size);
          expect(h.history.attempts, 1);
          expect(h.completions, hasLength(1));
          expect(h.capability.saves, 0);
          expect(tester.takeException(), isNull);
        }
      }
      expect(done, 0);
    });

    testWidgets(
        'production rest timer owns one timer, freezes on pause, reaches the next set',
        (tester) async {
      final h = await _pump(tester,
          autoStartTimer: true, rest: const Duration(seconds: 3));
      await _rest(tester, h);
      final c = h.controller;
      expect(c.hasActiveTimer, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(c.state.remaining, const Duration(seconds: 2));
      await _tap(tester, _l.flowPause, const Size(390, 844));
      expect(c.hasActiveTimer, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(c.state.remaining, const Duration(seconds: 2));
      await _tap(tester, _l.resume, const Size(390, 844));
      expect(c.hasActiveTimer, isTrue);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(c.state.phase, WorkoutPlayerPhase.work);
      expect(c.state.setNumber, 2);
      expect(c.hasActiveTimer, isFalse);
      expect(h.history.attempts, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'rest ticks finish the next set, then use the existing transition',
        (tester) async {
      final h = await _pump(tester, rest: const Duration(seconds: 3));
      await _rest(tester, h);
      final c = h.controller;
      final prescription = c.state.currentPrescription;
      c.tick();
      await tester.pump();
      expect(c.state.remaining, const Duration(seconds: 2));
      expect(find.text('2'), findsOneWidget);
      c.tick();
      c.tick();
      await tester.pumpAndSettle();
      expect(c.state.phase, WorkoutPlayerPhase.work);
      expect(c.state.setNumber, 2);
      expect(c.state.currentPrescription, prescription);
      expect(c.state.exerciseIndex, 0);
      c.completeSet();
      await tester.pumpAndSettle();
      expect(c.state.phase, WorkoutPlayerPhase.transition);
      expect(find.byType(WorkoutPlayerTransitionView), findsOneWidget);
      expect(c.state.nextPrescription, h.plan.warmup.exercises[1]);
      await _tap(tester, _l.skipTransition, const Size(390, 844));
      expect(c.state.currentPrescription, h.plan.warmup.exercises[1]);
      expect(h.history.attempts, 0);
      expect(h.capability.saves, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rest lifecycle pause freezes time without auto-resuming',
        (tester) async {
      final h = await _pump(tester);
      await _rest(tester, h);
      final remaining = h.controller.state.remaining;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(h.controller.state.isPaused, isTrue);
      h.controller.tick();
      expect(h.controller.state.remaining, remaining);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(h.controller.state.isPaused, isTrue);
      await _tap(tester, _l.resume, const Size(390, 844));
      expect(h.controller.state.remaining, remaining);
      expect(h.history.attempts, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'rest voice/exit controls remain existing controller and guard actions',
        (tester) async {
      final h = await _pump(tester);
      await _rest(tester, h);
      final remaining = h.controller.state.remaining;
      final stops = h.coach.stopCalls;
      await _reachable(
          tester, find.byTooltip(_l.flowMute), const Size(390, 844));
      await tester.tap(find.byTooltip(_l.flowMute));
      await tester.pumpAndSettle();
      expect(h.controller.state.voiceEnabled, isFalse);
      expect(h.coach.stopCalls, stops + 1);
      expect(h.controller.state.remaining, remaining);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(_l.flowExitTitle), findsOneWidget);
      await _tap(tester, _l.flowKeepGoing, const Size(390, 844));
      expect(h.controller.state.phase, WorkoutPlayerPhase.rest);
      expect(h.controller.state.remaining, remaining);
      expect(h.saved, isEmpty);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _tap(tester, _l.flowExit, const Size(390, 844));
      expect(find.text('Test root'), findsOneWidget);
      expect(h.history.attempts, 0);
      expect(h.completions, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Rest width/theme/text rebuilds never mutate state or restart TTS',
        (tester) async {
      final h = await _pump(tester);
      await _rest(tester, h);
      h.controller.tick();
      h.controller.pause();
      await tester.pumpAndSettle();
      final state = h.controller.state;
      final speech = List<String>.of(h.coach.spoken);
      final session = h.controller.sessionId;
      for (final size in _sizes) {
        tester.view.physicalSize = size;
        await tester
            .pumpWidget(_app(h, size, scale: 2, dark: true, reduced: true));
        await tester.pumpAndSettle();
        expect(h.controller.state, same(state));
        expect(h.controller.sessionId, session);
        expect(h.coach.spoken, speech);
        await _reachable(tester, _button(_l.resume), size);
        expect(h.history.attempts, 0);
        expect(h.completions, isEmpty);
        expect(h.capability.saves, 0);
        expect(tester.takeException(), isNull);
      }
    });

    for (final origin in WorkoutSessionOrigin.values) {
      testWidgets(
          '${origin.name} completion rebuilds preserve one-shot history/hook and origin',
          (tester) async {
        final h = await _pump(tester, origin: origin);
        await _complete(tester, h);
        final snapshot = h.saved.single;
        final c = h.controller;
        final session = c.sessionId;
        for (final size in _sizes) {
          tester.view.physicalSize = size;
          await tester
              .pumpWidget(_app(h, size, scale: 2, dark: true, reduced: true));
          await tester.pumpAndSettle();
          expect(identical(h.controller, c), isTrue);
          expect(c.sessionId, session);
          expect(h.history.attempts, 1);
          expect(h.saved, hasLength(1));
          expect(h.saved.single.id, snapshot.id);
          expect(h.completions, hasLength(1));
          expect(h.completions.single.origin, origin);
          expect(h.completions.single.plan, h.plan);
          expect(h.capability.saves, 0);
          await _reachable(tester, _button(_l.done), size);
          expect(tester.takeException(), isNull);
        }
      });
    }

    for (final mode in WorkoutSessionMode.values) {
      testWidgets(
          'adaptive ${mode.name}: same Tune eligibility and Done mode/navigation behavior',
          (tester) async {
        final h = await _pump(tester, mode: mode, doneRoute: null);
        await _complete(tester, h);
        expect(
            find.text(_l.flowTune),
            mode == WorkoutSessionMode.standard
                ? findsOneWidget
                : findsNothing);
        if (mode != WorkoutSessionMode.standard) {
          expect(find.text(_l.flowTemporaryNote(sessionModeLabel(_l, mode))),
              findsOneWidget);
        }
        await _tap(tester, _l.done, const Size(390, 844));
        expect(find.text('Test Home'), findsOneWidget);
        expect(h.container.read(workoutSessionModeProvider),
            WorkoutSessionMode.standard);
        expect(h.capability.saves, 0);
        expect(h.saved, hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'custom completion retains protection copy, no Tune, Workouts fallback',
        (tester) async {
      final h = await _pump(tester,
          origin: WorkoutSessionOrigin.custom, doneRoute: null);
      await _complete(tester, h);
      expect(find.text(_l.flowCustomNote), findsOneWidget);
      expect(find.text(_l.flowTune), findsNothing);
      await _tap(tester, _l.done, const Size(390, 844));
      expect(find.text('Test Workouts'), findsOneWidget);
      expect(h.capability.saves, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'program completion retains real note, Tune, return destination and Home mode',
        (tester) async {
      final h = await _pump(tester,
          origin: WorkoutSessionOrigin.program,
          doneRoute: '/program-detail',
          completionNote: WorkoutPlayerCompletedView.programCompletedCopy);
      h.container
          .read(workoutSessionModeProvider.notifier)
          .selectMode(WorkoutSessionMode.lowEnergy);
      await _complete(tester, h);
      expect(find.text(_l.flowProgramComplete), findsOneWidget);
      expect(find.text(_l.flowTune), findsOneWidget);
      await _tap(tester, _l.done, const Size(390, 844));
      expect(find.text('Test Program'), findsOneWidget);
      expect(h.container.read(workoutSessionModeProvider),
          WorkoutSessionMode.lowEnergy);
      expect(h.completions.single.origin, WorkoutSessionOrigin.program);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Done callback is still guarded against double tap and later rebuild',
        (tester) async {
      var done = 0;
      final h = await _pump(tester, onDone: () => done++);
      await _complete(tester, h);
      final button = _button(_l.done);
      await _reachable(tester, button, const Size(390, 844));
      await tester.tap(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(done, 1);
      h.controller.toggleVoice();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(h.history.attempts, 1);
      expect(h.completions, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Rest Pause/Resume and Completion Done retain native keyboard activation',
        (tester) async {
      var done = 0;
      final h = await _pump(tester, onDone: () => done++);
      await _rest(tester, h);
      Future<void> enter(String label) async {
        final button = _button(label);
        await _reachable(tester, button, const Size(390, 844));
        Focus.of(tester.element(
                find.descendant(of: button, matching: find.text(label))))
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }

      await enter(_l.flowPause);
      expect(h.controller.state.isPaused, isTrue);
      await enter(_l.resume);
      expect(h.controller.state.isPaused, isFalse);
      await _complete(tester, h);
      await enter(_l.done);
      expect(done, 1);
      expect(h.history.attempts, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Tune opens exactly the existing feedback options; opening and Skip do not save tuning',
        (tester) async {
      final h = await _pump(tester);
      await _complete(tester, h);
      final cap = h.prefs.getString(CapabilityProfileStorage.profileKey);
      await _tap(tester, _l.flowTune, const Size(390, 844));
      expect(find.byType(AdaptiveProgressionFeedbackSheet), findsOneWidget);
      for (final option in MovementWorkoutFeedback.values) {
        expect(find.text(feedbackLabel(_l, option)), findsOneWidget);
      }
      expect(
          tester.widget<FilledButton>(_button(_l.flowApply)).onPressed, isNull);
      expect(h.capability.saves, 0);
      expect(h.history.attempts, 1);
      await _tap(tester, _l.flowSkip, const Size(390, 844));
      expect(find.text('Test root'), findsOneWidget);
      expect(h.prefs.getString(CapabilityProfileStorage.profileKey), cap);
      expect(h.capability.saves, 0);
      expect(h.saved, hasLength(1));
      expect(h.completions, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'existing feedback Apply writes canonical tuning once, not while rendering completion',
        (tester) async {
      final h = await _pump(tester);
      await _complete(tester, h);
      expect(h.capability.saves, 0);
      await _tap(tester, _l.flowTune, const Size(390, 844));
      await _tap(tester, feedbackLabel(_l, MovementWorkoutFeedback.tooHard),
          const Size(390, 844));
      expect(h.capability.saves, 0);
      final apply = _button(_l.flowApply);
      await _reachable(tester, apply, const Size(390, 844));
      await tester.tap(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(h.capability.saves, 1);
      expect(
          CapabilityProfileStorage(h.prefs)
              .load()!
              .capabilityFor(MovementPattern.squat)!
              .level,
          CapabilityLevel.level2);
      expect(find.text('Test root'), findsOneWidget);
      expect(h.history.attempts, 1);
      expect(h.saved, hasLength(1));
      expect(h.completions, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('Step 5B semantics, contrast and reduced motion', () {
    testWidgets(
        'Rest timer semantics stay non-live and decoration never hides the value',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final h = await _pump(tester);
        await _rest(tester, h);
        expect(find.bySemanticsLabel(_l.flowRestRemaining(90)), findsOneWidget);
        expect(find.bySemanticsLabel(_l.flowNextSet(2, 2)), findsOneWidget);
        final timer = tester
            .getSemantics(find.bySemanticsLabel(_l.flowRestRemaining(90)));
        expect(timer.flagsCollection.isLiveRegion, isFalse);
        final announcement = tester
            .widget<PlayerPhaseAnnouncement>(
                find.byType(PlayerPhaseAnnouncement))
            .message;
        h.controller.tick();
        await tester.pump();
        expect(find.bySemanticsLabel(_l.flowRestRemaining(89)), findsOneWidget);
        expect(
            tester
                .widget<PlayerPhaseAnnouncement>(
                    find.byType(PlayerPhaseAnnouncement))
                .message,
            announcement);
        expect(
            tester
                .widget<ExcludeSemantics>(
                    find.byKey(const ValueKey('v2_rest_ring_decoration')))
                .excluding,
            isTrue);
        expect(
            find.bySemanticsLabel(
                RegExp('recovery score|ring decoration', caseSensitive: false)),
            findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
        'Completion retains heading and existing live announcement; mark is decorative',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final h = await _pump(tester);
        await _complete(tester, h);
        final node =
            tester.getSemantics(find.bySemanticsLabel(_l.flowComplete));
        expect(node.flagsCollection.isHeader, isTrue);
        final announcement = tester
            .getSemantics(find.bySemanticsLabel(_l.flowCompleteAnnouncement));
        expect(announcement.flagsCollection.isLiveRegion, isTrue);
        expect(
            find.ancestor(
                of: find.byKey(const ValueKey('v2_completed_mark')),
                matching: find.byType(ExcludeSemantics)),
            findsWidgets);
        expect(
            find.bySemanticsLabel(
                RegExp('trophy|confetti|achievement', caseSensitive: false)),
            findsNothing);
        expect(tester.getSemantics(_button(_l.done)).flagsCollection.isButton,
            isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    for (final dark in [false, true]) {
      testWidgets(
          '${dark ? 'Dark' : 'Light'} Rest/Completion text has sufficient contrast',
          (tester) async {
        final h = await _pump(tester, dark: dark);
        await _rest(tester, h);
        final context = tester.element(find.byType(WorkoutPlayerRestView));
        final t = FitFlowTheme.of(context);
        final v = FitFlowVisualV2.of(context);
        for (final bg in [v.support, v.tint]) {
          expect(fitflowContrast(t.textPrimary, bg), greaterThanOrEqualTo(4.5));
          expect(
              fitflowContrast(t.textSecondary, bg), greaterThanOrEqualTo(4.5));
        }
        expect(fitflowContrast(t.brand, v.support), greaterThanOrEqualTo(4.5));
        await _complete(tester, h);
        for (final bg in [v.heroStart, v.heroEnd]) {
          expect(fitflowContrast(v.onHero, bg), greaterThanOrEqualTo(4.5));
          expect(
              fitflowContrast(v.heroSecondary, bg), greaterThanOrEqualTo(4.5));
        }
        expect(fitflowContrast(t.onBrand, t.brand), greaterThanOrEqualTo(4.5));
        expect(tester.takeException(), isNull);
      });
    }

    for (final completed in [false, true]) {
      testWidgets(
          '${completed ? 'Completion' : 'Rest'} reduced-motion short landscape at 2x stays static/reachable',
          (tester) async {
        const size = Size(900, 320);
        final h = await _pump(tester, size: size, scale: 2, reduced: true);
        if (completed) {
          await _complete(tester, h);
        } else {
          await _rest(tester, h);
        }
        final entry = tester.widget<TweenAnimationBuilder<double>>(
            find.byWidgetPredicate((w) => w is TweenAnimationBuilder<double>));
        expect(entry.duration, Duration.zero);
        if (completed) {
          expect(
              tester.getSize(find.byKey(const ValueKey('v2_completed_mark'))),
              const Size(40, 40));
          await _reachable(tester, _button(_l.done), size);
        } else {
          final chip = tester.widget<AnimatedContainer>(find.descendant(
              of: find.byType(WorkoutPhaseLabel),
              matching: find.byType(AnimatedContainer)));
          expect(chip.duration, Duration.zero);
          expect(
              tester
                  .getSize(find.byKey(const ValueKey('v2_rest_timer_frame')))
                  .height,
              lessThan(216));
          await _reachable(tester, _button(_l.skipRest), size);
        }
        await tester.pump(const Duration(seconds: 1));
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
