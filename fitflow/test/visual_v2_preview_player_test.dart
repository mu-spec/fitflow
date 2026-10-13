import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_workout_media.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_rest_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_transition_view.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_replacement_picker.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_screen.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_section_header.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_summary_card.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/app_localizations_en.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'workout_preview_test.dart' as fixtures;

const _sizes = [
  Size(320, 700),
  Size(390, 844),
  Size(600, 900),
  Size(840, 1000),
  Size(900, 320),
];
const _captureKey = ValueKey('step5a_test_capture');
final _l = AppLocalizationsEn();

class _HistorySpy extends WorkoutHistoryController {
  final List<CompletedWorkout> saved = [];

  @override
  Future<List<CompletedWorkout>> build() async => [];

  @override
  Future<bool> addWorkout(CompletedWorkout workout) async {
    saved.add(workout);
    return true;
  }
}

class _Harness {
  _Harness(this.container, this.router, this.plan, this.coach, this.history);
  final ProviderContainer container;
  final GoRouter router;
  final WorkoutPlan plan;
  final FakeWorkoutCoach coach;
  final _HistorySpy history;
  int completions = 0;

  WorkoutPlayerController get controller =>
      container.read(workoutPlayerControllerProvider(plan).notifier);
}

WorkoutPlan _plan({bool timed = true}) {
  WorkoutExercisePrescription reps(String id, {int sets = 1}) =>
      WorkoutExercisePrescription(
        exercise: ExerciseCatalog.byId(id)!,
        sets: sets,
        repsPerSet: 10,
        restBetweenSets: const Duration(seconds: 10),
      );
  WorkoutExercisePrescription timer({int sets = 1}) =>
      WorkoutExercisePrescription(
        exercise: ExerciseCatalog.byId('plank_knee')!,
        sets: sets,
        workDuration: const Duration(seconds: 30),
        restBetweenSets: const Duration(seconds: 10),
      );
  return WorkoutPlan(
    warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
      timed ? timer(sets: 2) : reps('squat_bodyweight', sets: 2),
      reps('pushup_wall'),
    ]),
    main: WorkoutSection(
        type: WorkoutSectionType.main, exercises: [reps('squat_bodyweight')]),
    cooldown:
        WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [timer()]),
    timeBudget:
        WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

Widget _app(
  Widget child, {
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
  bool reduced = false,
  GoRouter? router,
}) {
  Widget builder(BuildContext context, Widget? body) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          padding: const EdgeInsets.only(top: 24, bottom: 18),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 18),
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: body!,
      );
  final theme = dark ? AppTheme.dark : AppTheme.light;
  return RepaintBoundary(
    key: _captureKey,
    child: router == null
        ? MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: builder,
            home: child,
          )
        : MaterialApp.router(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: builder,
            routerConfig: router,
          ),
  );
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool preview = false,
  bool timed = true,
  bool autoStartTimer = false,
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
  bool reduced = false,
  WorkoutSessionOrigin origin = WorkoutSessionOrigin.adaptive,
  WorkoutSessionMode mode = WorkoutSessionMode.standard,
  UserFitnessProfile? user,
}) async {
  _viewport(tester, size);
  user ??= fixtures.createUserProfile();
  final profile = user;
  final capability = fixtures.createFullProfile(CapabilityLevel.level5);
  final context = WorkoutGenerationContext(
      userProfile: profile, capabilityProfile: capability, sessionMode: mode);
  final plan = preview
      ? WorkoutGenerator.generateCatalog(context)!
      : _plan(timed: timed);
  final coach = FakeWorkoutCoach();
  final history = _HistorySpy();
  final container = ProviderContainer(overrides: [
    userFitnessProfileProvider.overrideWith(() =>
        fixtures.FakeUserProfileController(buildOverride: () async => profile)),
    capabilityProfileProvider.overrideWith(() =>
        fixtures.FakeCapabilityController(
            buildOverride: () async => capability)),
    workoutHistoryProvider.overrideWith(() => history),
    workoutPlayerControllerProvider
        .overrideWith((ref, plan) => WorkoutPlayerController(
              plan: plan,
              coach: coach,
              autoStartTimer: false,
              userProfile: profile,
              capabilityProfile: capability,
            )),
  ]);
  container.read(workoutSessionModeProvider.notifier).selectMode(mode);
  late final _Harness harness;
  final router = GoRouter(
    initialLocation: preview ? AppRoutes.workoutPreview : '/',
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (c, s) => const Scaffold(body: Text('Test home')),
        routes: [
          GoRoute(
            path: 'workout-preview',
            builder: (c, s) => const WorkoutPreviewScreen(),
            routes: [
              GoRoute(
                  path: 'player',
                  builder: (c, s) => const WorkoutPlayerScreen()),
            ],
          ),
        ],
      ),
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
              doneRoute: '/',
              onWorkoutCompleted: (completion) async {
                harness.completions++;
                return true;
              },
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/workouts/exercise-library/:exerciseId',
        builder: (c, s) => Scaffold(
            appBar: AppBar(title: const Text('Native detail route')),
            body: Text(s.pathParameters['exerciseId']!)),
      ),
    ],
  );
  harness = _Harness(container, router, plan, coach, history);
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: _app(const SizedBox.shrink(),
        router: router, size: size, dark: dark, scale: scale, reduced: reduced),
  ));
  await tester.pumpAndSettle();
  if (!preview) {
    // Match real launches: push a session on an existing navigation stack,
    // rather than synthesizing a declarative deep-link exit topology.
    router.push<void>('/session');
    await tester.pumpAndSettle();
  }
  return harness;
}

Finder _button(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

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

Future<void> _capture(WidgetTester tester, String name) async {
  // Optional local inspection only; never golden-baseline restoration.
  if (Platform.environment['FITFLOW_STEP5A_CAPTURE'] != '1') return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  final image = boundary.toImageSync();
  final bytes = await tester
      .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
  image.dispose();
  final file = File('/home/user/.cache/fitflow-step5a-validation/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  group('Step 5A truthful Preview and reachable Start', () {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          final name = '${size.width.toInt()}x${size.height.toInt()} '
              '${dark ? 'dark' : 'light'} ${scale}x';
          testWidgets(name, (tester) async {
            final h = await _pump(tester,
                preview: true, size: size, dark: dark, scale: scale);
            final summary = find.byType(WorkoutPreviewSummaryCard);
            Finder fact(String value) =>
                find.descendant(of: summary, matching: find.text(value));
            expect(fact(_l.homeSession), findsOneWidget);
            expect(fact(_l.flowTarget(20)), findsOneWidget);
            expect(
                fact('${_l.flowCount(h.plan.totalExerciseCount)} · '
                    '${_l.flowEstimate(plannedDuration(_l, h.plan.estimatedDuration))}'),
                findsOneWidget);
            expect(fact(_l.flowNoEquipment), findsOneWidget);
            expect(find.byKey(const ValueKey('v2_preview_summary')),
                findsOneWidget);
            expect(find.byType(FitFlowV2WorkoutMedia), findsOneWidget);
            expect(find.byType(Image), findsNothing);
            final rows = tester
                .widgetList<WorkoutPreviewExerciseRow>(
                    find.byType(WorkoutPreviewExerciseRow))
                .toList();
            expect(rows.map((r) => r.prescription), h.plan.allPrescriptions);
            expect(rows.map((r) => r.sequenceNumber),
                List.generate(h.plan.totalExerciseCount, (i) => i + 1));
            expect(rows.every((r) => r.visualV2), isTrue);
            final rowFinders = find.byType(WorkoutPreviewExerciseRow);
            for (var i = 0; i < rows.length; i++) {
              expect(
                  find.descendant(
                      of: rowFinders.at(i),
                      matching: find.text(rows[i].prescription.exercise.name)),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: rowFinders.at(i),
                      matching:
                          find.text(workloadLabel(_l, rows[i].prescription))),
                  findsOneWidget);
            }
            final sections = tester
                .widgetList<WorkoutPreviewSectionHeader>(
                    find.byType(WorkoutPreviewSectionHeader))
                .toList();
            expect(sections.map((s) => s.title),
                [_l.flowWarmup, _l.flowMain, _l.flowCooldown]);
            expect(sections.map((s) => s.exerciseCount), [
              h.plan.warmup.exerciseCount,
              h.plan.main.exerciseCount,
              h.plan.cooldown.exerciseCount
            ]);
            expect(MediaQuery.textScalerOf(tester.element(summary)).scale(16),
                16 * scale);
            final media = tester.widget<FitFlowV2WorkoutMedia>(
                find.byType(FitFlowV2WorkoutMedia));
            if (size.height < 400 || scale == 2) expect(media.height, 48);
            if (size == const Size(390, 844) && scale == 1) {
              await _capture(tester, 'preview_390_${dark ? 'dark' : 'light'}');
            }
            final start = find.byKey(const Key('preview_start'));
            expect(find.text(_l.startWorkout), findsOneWidget);
            await _reachable(tester, start, size);
            await tester.tap(start);
            await tester.pumpAndSettle();
            expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
            expect(
                GoRouterState.of(
                        tester.element(find.byType(WorkoutPlayerScreen)))
                    .uri
                    .path,
                AppRoutes.workoutPlayer);
            expect(h.history.saved, isEmpty);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('Step 5A active identity, timing/reps and controls', () {
    for (final timed in [true, false]) {
      for (final size in _sizes) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 2.0]) {
            final name = '${timed ? 'timed' : 'reps'} '
                '${size.width.toInt()}x${size.height.toInt()} '
                '${dark ? 'dark' : 'light'} ${scale}x';
            testWidgets(name, (tester) async {
              final h = await _pump(tester,
                  timed: timed, size: size, dark: dark, scale: scale);
              final c = h.controller;
              c.beginWorkout();
              await tester.pumpAndSettle();
              expect(find.byType(WorkoutPlayerExerciseCenter), findsOneWidget);
              expect(find.byKey(const ValueKey('v2_player_focus')),
                  findsOneWidget);
              expect(find.text(c.state.currentPrescription.exercise.name),
                  findsOneWidget);
              expect(find.text(_l.flowExercisePosition(1, 2)), findsOneWidget);
              expect(find.text(_l.flowSet(1, 2)), findsOneWidget);
              expect(
                  tester
                      .widget<LinearProgressIndicator>(
                          find.byType(LinearProgressIndicator))
                      .value,
                  c.state.progressFraction);
              expect(find.byType(FitFlowV2WorkoutMedia), findsOneWidget);
              expect(find.byType(Image), findsNothing);
              expect(find.text(_l.skipRest), findsNothing);
              expect(find.text(_l.skipTransition), findsNothing);
              expect(find.text(_l.flowDetails), findsNothing);
              expect(
                  MediaQuery.textScalerOf(tester
                          .element(find.byType(WorkoutPlayerExerciseCenter)))
                      .scale(16),
                  16 * scale);
              final media = tester.widget<FitFlowV2WorkoutMedia>(
                  find.byType(FitFlowV2WorkoutMedia));
              if (size.height < 400 || scale == 2) expect(media.height, 48);
              if (timed) {
                expect(find.byType(WorkoutCountdown), findsOneWidget);
                expect(find.text(countdown(const Duration(seconds: 30))),
                    findsOneWidget);
                c.tick();
                await tester.pump();
                expect(c.state.remaining, const Duration(seconds: 29));
                expect(find.text(countdown(const Duration(seconds: 29))),
                    findsOneWidget);
                expect(find.text(_l.setComplete), findsNothing);
              } else {
                expect(find.byType(WorkoutCountdown), findsNothing);
                expect(find.text(_l.flowReps(10)), findsOneWidget);
                // Reps do not own a timer. Never invoke the test-only timed
                // tick seam for reps: real elapsed UI time cannot count them.
                expect(c.hasActiveTimer, isFalse);
                await tester.pump(const Duration(minutes: 2));
                expect(c.state.completedSets, 0);
                expect(c.state.setNumber, 1);
                expect(c.state.remaining, Duration.zero);
                await _reachable(tester, _button(_l.setComplete), size);
              }
              if (size == const Size(390, 844) && scale == 1) {
                await _capture(tester,
                    'player_${timed ? 'timed' : 'reps'}_390_${dark ? 'dark' : 'light'}');
              }
              final remaining = c.state.remaining;
              final set = c.state.setNumber;
              final prescription = c.state.currentPrescription;
              await _tap(tester, timed ? _l.flowPause : _l.pause, size);
              expect(c.state.isPaused, isTrue);
              expect(find.text(_l.flowPaused), findsOneWidget);
              expect(find.byType(WorkoutPlayerExerciseCenter), findsOneWidget);
              c.tick();
              expect(c.state.remaining, remaining);
              expect(c.state.setNumber, set);
              expect(c.state.currentPrescription, prescription);
              expect(find.text(_l.setComplete), findsNothing);
              await _reachable(tester, _button(_l.flowDetails), size);
              await _tap(tester, _l.resume, size);
              expect(c.state.isPaused, isFalse);
              expect(c.state.remaining, remaining);
              if (!timed) {
                await _tap(tester, _l.setComplete, size);
                expect(c.state.completedSets, 1);
                expect(c.state.phase, WorkoutPlayerPhase.rest);
                expect(find.byType(WorkoutPlayerRestView), findsOneWidget);
                expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
              }
              expect(h.history.saved, isEmpty);
              expect(h.completions, 0);
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }
  });

  group('Step 5A native routes, conditional actions and unchanged engine', () {
    testWidgets(
        'rep work never auto-counts with production timer scheduling enabled',
        (tester) async {
      final h = await _pump(tester, timed: false, autoStartTimer: true);
      final c = h.controller;
      c.beginWorkout();
      await tester.pumpAndSettle();
      final prescription = c.state.currentPrescription;
      expect(c.hasActiveTimer, isFalse);
      await tester.pump(const Duration(minutes: 2));
      expect(c.hasActiveTimer, isFalse);
      expect(c.state.phase, WorkoutPlayerPhase.work);
      expect(c.state.completedSets, 0);
      expect(c.state.setNumber, 1);
      expect(c.state.currentPrescription, prescription);
      expect(find.text(_l.flowReps(10)), findsOneWidget);
      expect(find.byType(WorkoutCountdown), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'active Pause/Resume preserve native focus and keyboard activation',
        (tester) async {
      final h = await _pump(tester, timed: false);
      h.controller.beginWorkout();
      await tester.pumpAndSettle();
      Future<void> activate(String label) async {
        final button = _button(label);
        await _reachable(tester, button, const Size(390, 844));
        Focus.of(tester.element(
                find.descendant(of: button, matching: find.text(label))))
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }

      await activate(_l.pause);
      expect(h.controller.state.isPaused, isTrue);
      await activate(_l.resume);
      expect(h.controller.state.isPaused, isFalse);
      expect(h.controller.state.completedSets, 0);
      expect(h.controller.state.setNumber, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Preview row opens native exercise detail and returns to same sequence',
        (tester) async {
      final h = await _pump(tester, preview: true);
      final first = find.byType(WorkoutPreviewExerciseRow).first;
      final id = h.plan.allPrescriptions.first.exercise.id;
      await tester.ensureVisible(first);
      final tile = find.descendant(of: first, matching: find.byType(ListTile));
      await _reachable(tester, tile, const Size(390, 844));
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text('Native detail route'), findsOneWidget);
      expect(
          GoRouterState.of(tester.element(find.text('Native detail route')))
              .uri
              .path,
          AppRoutes.exerciseDetail(id));
      h.router.pop();
      await tester.pumpAndSettle();
      expect(
          tester
              .widgetList<WorkoutPreviewExerciseRow>(
                  find.byType(WorkoutPreviewExerciseRow))
              .map((r) => r.prescription),
          h.plan.allPrescriptions);
      expect(find.byKey(const Key('preview_start')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Start retains native keyboard activation', (tester) async {
      await _pump(tester, preview: true);
      final start = find.byKey(const Key('preview_start'));
      await _reachable(tester, start, const Size(390, 844));
      final label =
          find.descendant(of: start, matching: find.text(_l.startWorkout));
      Focus.of(tester.element(label)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final mode in WorkoutSessionMode.values) {
      testWidgets(
          'Preview displays existing factual ${mode.name} context and estimate',
          (tester) async {
        final h = await _pump(tester,
            preview: true,
            mode: mode,
            user: fixtures.createUserProfile(goal: FitnessGoal.buildStrength));
        final summary = find.byType(WorkoutPreviewSummaryCard);
        final context = WorkoutGenerationContext(
            userProfile:
                fixtures.createUserProfile(goal: FitnessGoal.buildStrength),
            capabilityProfile:
                fixtures.createFullProfile(CapabilityLevel.level5),
            sessionMode: mode);
        expect(
            find.descendant(
                of: summary,
                matching: find.text(
                    _l.flowTarget(context.effectiveWorkoutDuration.minutes))),
            findsOneWidget);
        expect(
            find.descendant(
                of: summary,
                matching: find.text(mode == WorkoutSessionMode.standard
                    ? sessionModeLabel(_l, mode)
                    : _l.flowModeTemporary(sessionModeLabel(_l, mode)))),
            findsOneWidget);
        expect(
            find.descendant(
                of: summary,
                matching:
                    find.text(fitnessGoalLabel(_l, FitnessGoal.buildStrength))),
            findsOneWidget);
        expect(tester.widget<WorkoutPreviewSummaryCard>(summary).plan, h.plan);
        expect(tester.takeException(), isNull);
      });
    }

    for (final origin in WorkoutSessionOrigin.values) {
      testWidgets(
          'active work uses the shared engine for ${origin.name} without origin mutation',
          (tester) async {
        final h = await _pump(tester, timed: false, origin: origin);
        final c = h.controller;
        final sessionId = c.sessionId;
        c.beginWorkout();
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<WorkoutPlayerSessionView>(
                    find.byType(WorkoutPlayerSessionView))
                .sessionOrigin,
            origin);
        await _tap(tester, _l.pause, const Size(390, 844));
        await _tap(tester, _l.resume, const Size(390, 844));
        expect(identical(c, h.controller), isTrue);
        expect(c.sessionId, sessionId);
        expect(
            tester
                .widget<WorkoutPlayerSessionView>(
                    find.byType(WorkoutPlayerSessionView))
                .plan,
            h.plan);
        expect(find.byType(FitFlowV2WorkoutMedia), findsOneWidget);
        expect(h.history.saved, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'existing rest/transition skips and within-section position are unchanged',
        (tester) async {
      final h = await _pump(tester, timed: false);
      final c = h.controller;
      c.beginWorkout();
      await tester.pumpAndSettle();
      await _tap(tester, _l.setComplete, const Size(390, 844));
      expect(c.state.phase, WorkoutPlayerPhase.rest);
      expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
      await _tap(tester, _l.skipRest, const Size(390, 844));
      expect(c.state.phase, WorkoutPlayerPhase.work);
      expect(find.text(_l.flowSet(2, 2)), findsOneWidget);
      expect(c.canReplaceCurrentExercise, isFalse);
      expect(find.text(_l.flowReplace), findsNothing);
      await _tap(tester, _l.setComplete, const Size(390, 844));
      expect(c.state.phase, WorkoutPlayerPhase.transition);
      expect(find.byType(WorkoutPlayerTransitionView), findsOneWidget);
      expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
      await _tap(tester, _l.skipTransition, const Size(390, 844));
      expect(c.state.phase, WorkoutPlayerPhase.work);
      expect(find.text(_l.flowExercisePosition(2, 2)), findsOneWidget);
      expect(
          find.text(c.state.currentPrescription.exercise.name), findsOneWidget);
      expect(h.history.saved, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'timed replacement keeps existing pause/picker/name/prescription behavior',
        (tester) async {
      final h = await _pump(tester);
      final c = h.controller;
      c.beginWorkout();
      await tester.pumpAndSettle();
      final original = c.state.currentPrescription;
      final remaining = c.state.remaining;
      final option = c.getReplacementOptions().first;
      await _tap(tester, _l.flowReplace, const Size(390, 844));
      expect(c.state.isPaused, isTrue);
      expect(find.byType(WorkoutReplacementPicker), findsOneWidget);
      expect(c.state.remaining, remaining);
      h.router.pop();
      await tester.pumpAndSettle();
      expect(c.replaceCurrentExercise(option), isTrue);
      await tester.pumpAndSettle();
      expect(find.text(option.exercise.name), findsOneWidget);
      expect(
          find.text(_l.flowReplaced(original.exercise.name)), findsOneWidget);
      expect(c.state.currentPrescription.sets, original.sets);
      expect(c.state.currentPrescription.workDuration, original.workDuration);
      expect(c.state.currentPrescription.restBetweenSets,
          original.restBetweenSets);
      expect(c.state.remaining, remaining);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paused active Details uses unchanged native route',
        (tester) async {
      final h = await _pump(tester, timed: false);
      h.controller.beginWorkout();
      await tester.pumpAndSettle();
      await _tap(tester, _l.pause, const Size(390, 844));
      final id = h.controller.state.currentPrescription.exercise.id;
      await _tap(tester, _l.flowDetails, const Size(390, 844));
      expect(find.text('Native detail route'), findsOneWidget);
      expect(
          GoRouterState.of(tester.element(find.text('Native detail route')))
              .uri
              .path,
          AppRoutes.exerciseDetail(id));
      h.router.pop();
      await tester.pumpAndSettle();
      expect(h.controller.state.isPaused, isTrue);
      expect(find.byType(WorkoutPlayerExerciseCenter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('active mute/enable remains the existing controller TTS toggle',
        (tester) async {
      final h = await _pump(tester);
      final c = h.controller;
      c.beginWorkout();
      await tester.pumpAndSettle();
      final position = c.state.exerciseIndex;
      final remaining = c.state.remaining;
      final spoken = List<String>.of(h.coach.spoken);
      final stops = h.coach.stopCalls;
      await _reachable(
          tester, find.byTooltip(_l.flowMute), const Size(390, 844));
      await tester.tap(find.byTooltip(_l.flowMute));
      await tester.pumpAndSettle();
      expect(c.state.voiceEnabled, isFalse);
      expect(h.coach.stopCalls, stops + 1);
      expect(h.coach.spoken, spoken);
      expect(c.state.remaining, remaining);
      expect(c.state.exerciseIndex, position);
      await tester.tap(find.byTooltip(_l.flowVoice));
      await tester.pumpAndSettle();
      expect(c.state.voiceEnabled, isTrue);
      expect(h.coach.spoken, spoken);
      expect(c.state.remaining, remaining);
      expect(tester.takeException(), isNull);
    });

    for (final paused in [false, true]) {
      testWidgets(
          'active ${paused ? 'paused' : 'running'} exit cancel/confirm uses original guard',
          (tester) async {
        final h = await _pump(tester, timed: false);
        final c = h.controller;
        c.beginWorkout();
        if (paused) c.pause();
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text(_l.flowExitTitle), findsOneWidget);
        await _tap(tester, _l.flowKeepGoing, const Size(390, 844));
        expect(c.state.isPaused, paused);
        expect(find.byType(WorkoutPlayerExerciseCenter), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await _tap(tester, _l.flowExit, const Size(390, 844));
        expect(find.byType(WorkoutPlayerSessionView), findsNothing);
        expect(find.text('Test root'), findsOneWidget);
        expect(h.history.saved, isEmpty);
        expect(h.completions, 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'width/text/theme changes keep one session, prescription, timer and voice state',
        (tester) async {
      final h = await _pump(tester);
      final c = h.controller;
      c.beginWorkout();
      c.tick();
      c.toggleVoice();
      c.pause();
      await tester.pumpAndSettle();
      final state = c.state;
      final sessionId = c.sessionId;
      for (final size in _sizes) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(UncontrolledProviderScope(
          container: h.container,
          child: _app(const SizedBox.shrink(),
              router: h.router,
              size: size,
              scale: 2,
              dark: true,
              reduced: true),
        ));
        await tester.pumpAndSettle();
        expect(identical(h.controller, c), isTrue);
        expect(c.sessionId, sessionId);
        expect(c.state, same(state));
        await _reachable(tester, _button(_l.resume), size);
        expect(tester.takeException(), isNull);
      }
      expect(h.history.saved, isEmpty);
      expect(h.completions, 0);
    });

    testWidgets(
        'Completion stays original, history/hook fire once, media is work-only',
        (tester) async {
      final h = await _pump(tester, timed: false);
      final c = h.controller;
      expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
      c.beginWorkout();
      await tester.pumpAndSettle();
      expect(find.byType(FitFlowV2WorkoutMedia), findsOneWidget);
      for (var i = 0;
          i < 200 && c.state.phase != WorkoutPlayerPhase.completed;
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
      expect(find.byType(WorkoutPlayerCompletedView), findsOneWidget);
      expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
      expect(h.history.saved, hasLength(1));
      expect(h.completions, 1);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(h.history.saved, hasLength(1));
      expect(h.completions, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('Step 5A semantics, contrast, media and scope', () {
    test('movement painter is static and repaints for palette inputs only', () {
      const style = FitFlowV2ArtStyle(
          panel: Colors.white,
          panelEdge: Colors.grey,
          ink: Colors.green,
          wash: Colors.teal,
          accent: Colors.orange);
      const painter = FitFlowV2WorkoutMovementPainter(style);
      expect(
          painter.shouldRepaint(const FitFlowV2WorkoutMovementPainter(style)),
          isFalse);
      for (var i = 0; i < 5; i++) {
        final changed = FitFlowV2ArtStyle(
          panel: i == 0 ? Colors.black : style.panel,
          panelEdge: i == 1 ? Colors.black : style.panelEdge,
          ink: i == 2 ? Colors.black : style.ink,
          wash: i == 3 ? Colors.black : style.wash,
          accent: i == 4 ? Colors.black : style.accent,
        );
        expect(painter.shouldRepaint(FitFlowV2WorkoutMovementPainter(changed)),
            isTrue);
      }
    });

    testWidgets('future media slot is excluded; real text remains semantic',
        (tester) async {
      _viewport(tester, const Size(390, 844));
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_app(Scaffold(
            body: Column(children: [
          Semantics(header: true, child: const Text('Real exercise name')),
          FitFlowV2WorkoutMedia(
              height: 48,
              artwork: Semantics(
                  label: 'Decorative artwork',
                  child: const Text('Decorative text'))),
        ]))));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Real exercise name'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Decorative')), findsNothing);
        expect(
            find.descendant(
                of: find.byType(FitFlowV2WorkoutMedia),
                matching: find.byType(ExcludeSemantics)),
            findsWidgets);
        expect(
            find.descendant(
                of: find.byType(FitFlowV2WorkoutMedia),
                matching: find.byType(RepaintBoundary)),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
        'real name/position/set stay semantic; timer is not a live announcement',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final h = await _pump(tester);
        final c = h.controller;
        c.beginWorkout();
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel(c.state.currentPrescription.exercise.name),
            findsOneWidget);
        expect(find.bySemanticsLabel(_l.flowExercisePosition(1, 2)),
            findsOneWidget);
        final nameSemantics = tester
            .widgetList<Semantics>(find.descendant(
                of: find.byType(WorkoutPlayerExerciseCenter),
                matching: find.byType(Semantics)))
            .where((s) => s.properties.header == true);
        expect(nameSemantics, hasLength(1));
        final timer = tester
            .widget<PlayerTimerSemantics>(find.byType(PlayerTimerSemantics));
        expect(timer.label, _l.flowRemaining(30));
        final message = tester
            .widget<PlayerPhaseAnnouncement>(
                find.byType(PlayerPhaseAnnouncement))
            .message;
        c.tick();
        await tester.pump();
        expect(
            tester
                .widget<PlayerTimerSemantics>(find.byType(PlayerTimerSemantics))
                .label,
            _l.flowRemaining(29));
        expect(
            tester
                .widget<PlayerPhaseAnnouncement>(
                    find.byType(PlayerPhaseAnnouncement))
                .message,
            message);
        final timerNode = tester.widget<Semantics>(find
            .descendant(
                of: find.byType(PlayerTimerSemantics),
                matching: find.byType(Semantics))
            .first);
        expect(timerNode.properties.liveRegion, isFalse);
        expect(find.bySemanticsLabel(RegExp('ground|movement paths|artwork')),
            findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    for (final dark in [false, true]) {
      testWidgets(
          '${dark ? 'dark' : 'light'} surfaces and text use intentional high-contrast roles',
          (tester) async {
        await _pump(tester, preview: true, dark: dark);
        final context = tester.element(find.byType(WorkoutPreviewSummaryCard));
        final t = FitFlowTheme.of(context);
        final v = FitFlowVisualV2.of(context);
        for (final background in [v.heroStart, v.heroEnd]) {
          expect(
              fitflowContrast(v.onHero, background), greaterThanOrEqualTo(4.5));
          expect(fitflowContrast(v.heroSecondary, background),
              greaterThanOrEqualTo(4.5));
        }
        expect(
            fitflowContrast(t.textPrimary, v.page), greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(t.textSecondary, v.page),
            greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(t.textPrimary, v.support),
            greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(t.textSecondary, v.support),
            greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(t.brand, v.tint), greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(t.onBrand, t.brand), greaterThanOrEqualTo(4.5));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'reduced motion retains static media and disables phase entry motion',
        (tester) async {
      final h = await _pump(tester,
          reduced: true, size: const Size(900, 320), scale: 2);
      h.controller.beginWorkout();
      await tester.pumpAndSettle();
      final entry = tester.widget<TweenAnimationBuilder<double>>(
          find.byWidgetPredicate((w) => w is TweenAnimationBuilder<double>));
      expect(entry.duration, Duration.zero);
      final chip = tester.widget<AnimatedContainer>(find.descendant(
          of: find.byType(WorkoutPhaseLabel),
          matching: find.byType(AnimatedContainer)));
      expect(chip.duration, Duration.zero);
      final media = find.byType(FitFlowV2WorkoutMedia);
      expect(tester.widget<FitFlowV2WorkoutMedia>(media).height, 48);
      expect(
          find.descendant(
              of: media, matching: find.byType(TweenAnimationBuilder<double>)),
          findsNothing);
      expect(
          find.descendant(of: media, matching: find.byType(AnimatedContainer)),
          findsNothing);
      await _tap(tester, _l.flowPause, const Size(900, 320));
      await _capture(tester, 'player_short_landscape_2x_reduced');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'shared Preview row/header remain legacy by default for Programs',
        (tester) async {
      _viewport(tester, const Size(390, 844));
      final plan = _plan(timed: false);
      await tester.pumpWidget(_app(Scaffold(
          body: Column(children: [
        WorkoutPreviewSectionHeader(
            title: _l.flowWarmup,
            exerciseCount: plan.warmup.exerciseCount,
            planned: plan.warmupEstimate,
            budget: plan.timeBudget.warmup),
        WorkoutPreviewExerciseRow(prescription: plan.warmup.exercises.first),
      ]))));
      await tester.pumpAndSettle();
      final row = tester.widget<WorkoutPreviewExerciseRow>(
          find.byType(WorkoutPreviewExerciseRow));
      expect(row.visualV2, isFalse);
      expect(row.sequenceNumber, isNull);
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.dense, isNull);
      expect(tile.leading, isNull);
      expect(find.byType(Divider), findsOneWidget);
      expect(
          tester
              .widget<WorkoutPreviewSectionHeader>(
                  find.byType(WorkoutPreviewSectionHeader))
              .visualV2,
          isFalse);
      final title = tester.widget<Text>(find.text(_l.flowWarmup));
      expect(
          title.style,
          Theme.of(tester.element(find.byType(WorkoutPreviewSectionHeader)))
              .textTheme
              .titleLarge);
      expect(find.byType(FitFlowV2WorkoutMedia), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
