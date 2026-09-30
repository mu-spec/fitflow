import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_workout_resolver.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_player_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/adaptive_progression_feedback_sheet.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

const _program = 'balanced_foundations';
const _s1 = 'balanced_foundations_w1_s1';
const _s2 = 'balanced_foundations_w1_s2';

/// M10 (Tune next workout) integration with program sessions.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<Override> overrides() => [
        ...programOverrides(),
        workoutCoachProvider.overrideWithValue(FakeWorkoutCoach()),
      ];

  ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(ProgramSessionPlayerScreen)));

  testWidgets('program completion: Tune opens the M10 sheet with effective Main prescriptions',
      (tester) async {
    final router = programTestRouter(
        initialLocation: AppRoutes.programSessionPlayer(_program, _s1));
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(router: router, overrides: overrides()));
    await tester.pumpAndSettle();

    final controller = programPlayerController(tester);
    await driveProgramPlayerToCompletion(tester, controller);
    expect(find.text('Tune next workout'), findsOneWidget);

    await tester.ensureVisible(find.text('Tune next workout'));
    await tester.tap(find.text('Tune next workout'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<AdaptiveProgressionFeedbackSheet>(
        find.byType(AdaptiveProgressionFeedbackSheet));
    final effective = controller.effectiveMainPrescriptions;
    expect(sheet.effectiveMainPrescriptions.map((p) => p.exercise.id).toList(),
        effective.map((p) => p.exercise.id).toList());
    expect(sheet.returnRoute, AppRoutes.programDetail(_program));
    expect(find.text('Too hard'), findsWidgets);
    expect(find.text('Just right'), findsWidgets);
    expect(find.text('Easy'), findsWidgets);
  });

  testWidgets('Too hard feedback applied after a program workout lowers capability; future preview reflects it; no stale plan stored',
      (tester) async {
    final router = programTestRouter(
        initialLocation: AppRoutes.programSessionPlayer(_program, _s1));
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(router: router, overrides: overrides()));
    await tester.pumpAndSettle();

    final controller = programPlayerController(tester);
    final container = containerOf(tester);
    final before = container.read(capabilityProfileProvider).value!;
    await driveProgramPlayerToCompletion(tester, controller);

    await tester.ensureVisible(find.text('Tune next workout'));
    await tester.tap(find.text('Tune next workout'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Too hard').first);
    await tester.tap(find.text('Too hard').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply & finish'));
    await tester.tap(find.text('Apply & finish'));
    await tester.pumpAndSettle();

    // Program flow: after applying, we land on the program detail.
    expect(find.byType(ProgramDetailScreen), findsOneWidget);
    expect(find.text('1 of 12 workouts completed'), findsOneWidget);

    final after = container.read(capabilityProfileProvider).value!;
    expect(after, isNot(equals(before)));
    final lowered = CapabilityProfile.trainablePatterns.where((p) {
      final a = after.capabilityFor(p)?.level.index ?? 0;
      final b = before.capabilityFor(p)?.level.index ?? 0;
      return a < b;
    });
    expect(lowered, isNotEmpty);

    // Future program session preview is generated from the CHANGED capability.
    router.go(AppRoutes.programSessionPreview(_program, _s2));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
    final def = AdaptiveProgramCatalog.byId(_program)!;
    final expected = AdaptiveProgramWorkoutResolver.resolve(
      definition: def,
      session: def.sessionById(_s2)!,
      userProfile: programTestProfile(),
      capabilityProfile: after,
    ).plan!;
    final rows = tester
        .widgetList<WorkoutPreviewExerciseRow>(find.byType(WorkoutPreviewExerciseRow))
        .map((r) => r.prescription.exercise.id)
        .toList();
    final expectedIds = expected.allExercises.map((e) => e.id).toList();
    expect(rows, isNotEmpty);
    expect(expectedIds.sublist(0, rows.length), rows);

    // No generated plan is persisted: program storage holds only IDs and
    // timestamps (history snapshots are the M11 record, not a plan cache).
    final prefs = await SharedPreferences.getInstance();
    final programsRaw = prefs.getString(AdaptiveProgramsStorage.key)!;
    expect(programsRaw.contains('warmup'), isFalse);
    expect(programsRaw.contains('exercise'), isFalse);
    expect(programsRaw.contains('sets'), isFalse);
    expect(programsRaw, contains(_s1));
  });

  testWidgets('temporary adaptive completion still hides Tune while program completion shows it',
      (tester) async {
    // Program completion (Standard) → Tune visible even if Home mode is Comeback.
    final router = programTestRouter(
        initialLocation: AppRoutes.programSessionPlayer(_program, _s1));
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(router: router, overrides: overrides()));
    await tester.pumpAndSettle();
    final container = containerOf(tester);
    container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
    await tester.pump();
    expect(programPlayerView(tester).sessionMode, WorkoutSessionMode.standard);
    await driveProgramPlayerToCompletion(tester, programPlayerController(tester));
    expect(find.text('Tune next workout'), findsOneWidget);
    expect(find.textContaining('temporary'), findsNothing);
    expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.comeback);
  });

  test('program complete via controller: exact total, no overflow, all sessions counted once',
      () async {
    final storageContainer = ProviderContainer(overrides: [
      adaptiveProgramsClockProvider.overrideWithValue(() => DateTime.utc(2026, 9, 30)),
    ]);
    addTearDown(storageContainer.dispose);
    final controller = storageContainer.read(adaptiveProgramsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(await controller.startOrResumeProgram(_program), isTrue);
    final def = AdaptiveProgramCatalog.byId(_program)!;
    final ids = def.sessions.map((s) => s.id).toList();
    expect(ids.length, def.totalSessionCount);
    var n = 0;
    for (final id in ids) {
      n++;
      expect(
          await controller.markSessionCompleted(
              programId: _program, plannedSessionId: id, playerSessionId: 'player_$n'),
          isTrue);
      // Duplicate planned session and duplicate player session are no-ops.
      expect(
          await controller.markSessionCompleted(
              programId: _program, plannedSessionId: id, playerSessionId: 'player_dup_$n'),
          isTrue);
      expect(
          await controller.markSessionCompleted(
              programId: _program, plannedSessionId: ids.first, playerSessionId: 'player_$n'),
          isTrue);
      expect(controller.completedCount(_program), n);
    }
    expect(controller.completedCount(_program), def.totalSessionCount);
    expect(controller.isProgramComplete(_program), isTrue);
    expect(controller.firstIncompleteSession(_program), isNull);
    // Extra completion attempts never overflow the total.
    await controller.markSessionCompleted(
        programId: _program, plannedSessionId: ids.last, playerSessionId: 'late');
    expect(controller.completedCount(_program), def.totalSessionCount);
    expect(controller.statusFor(_program)!.progress!.completions.length, def.totalSessionCount);
  });

  testWidgets('program complete detail: Program complete, X/X and Restart available',
      (tester) async {
    final def = AdaptiveProgramCatalog.byId(_program)!;
    final router = programTestRouter(initialLocation: AppRoutes.programDetail(_program));
    addTearDown(router.dispose);
    await tester.pumpWidget(programTestApp(router: router, overrides: overrides()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(ProgramDetailScreen)));
    final controller = container.read(adaptiveProgramsControllerProvider.notifier);
    await controller.startOrResumeProgram(_program);
    var n = 0;
    for (final s in def.sessions) {
      n++;
      await controller.markSessionCompleted(
          programId: _program, plannedSessionId: s.id, playerSessionId: 'p$n');
    }
    await tester.pumpAndSettle();
    expect(find.text('Program complete'), findsWidgets);
    expect(find.text('${def.totalSessionCount} of ${def.totalSessionCount} workouts completed'),
        findsOneWidget);
    expect(find.text('Restart program'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
