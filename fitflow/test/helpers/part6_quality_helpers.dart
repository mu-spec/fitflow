import 'dart:convert';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/widgets/fitflow_navigation.dart';
import 'package:fitflow/features/backup/application/backup_restore_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workout_player/presentation/player_accessibility.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_program_test_helpers.dart';
import 'backup_test_helpers.dart';
import 'profile_editor_test_helpers.dart';
import 'workout_reminder_test_helpers.dart';
import '../part3_workout_experience_test.dart'
    show flowPlan, finishTimed, press;

// TEST fixtures only: not a shipped sample-data route or production asset.
const part6Sizes = [
  Size(320, 700),
  Size(360, 800),
  Size(390, 844),
  Size(430, 900),
  Size(600, 900),
  Size(840, 1000),
  Size(1024, 768),
  Size(900, 320)
];

class TestHistory extends WorkoutHistoryController {
  @override
  Future<List<CompletedWorkout>> build() async => backupHistory();
}

Future<void> seedPart6() async {
  ensureTimezones();
  SharedPreferences.setMockInitialValues({
    ...seedProfilePrefs(backupProfile()),
    CapabilityProfileStorage.profileKey:
        jsonEncode(backupCapabilityProfile().toJson()),
  });
  await const CustomWorkoutStorage().saveAll([
    backupTemplate('TEST-custom', DateTime.utc(2026, 10, 10)),
  ]);
}

Widget part6Host(
    {Widget? child,
    GoRouter? router,
    bool dark = false,
    double scale = 1,
    bool reduced = true,
    double keyboard = 0,
    List<Override> extra = const []}) {
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
          viewInsets: EdgeInsets.only(bottom: keyboard)),
      child: SystemMotionTheme(child: child!));
  return ProviderScope(
      overrides: [
        ...reminderOverrides(service: FakeWorkoutReminderNotificationService()),
        backupFileServiceProvider.overrideWithValue(FakeBackupFileService()),
        workoutHistoryProvider.overrideWith(TestHistory.new),
        ...extra,
      ],
      child: router == null
          ? MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: builder,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: child)
          : MaterialApp.router(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: builder,
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales));
}

Future<GoRouter> part6Route(WidgetTester tester, String route,
    {bool dark = false,
    double scale = 1,
    bool reduced = true,
    double keyboard = 0}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final router = AppRouter.create(initialLocation: route);
  await tester.pumpWidget(part6Host(
      router: router,
      dark: dark,
      scale: scale,
      reduced: reduced,
      keyboard: keyboard));
  await tester.pumpAndSettle();
  return router;
}

void assertClean(WidgetTester tester, String context) {
  expect(tester.takeException(), isNull, reason: context);
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? '')
      .join('\n');
  expect(
      text,
      isNot(matches(RegExp(
          r'\blevel[1-5]\b|TEST_INTERNAL_ERROR|\bAI[- ]powered\b|\bcalories burned\b|\bXP\b'))),
      reason: context);
}

// Separate width entry points bound test-process memory; every case remains.
void registerPart6Matrix(List<Size> sizes) {
  for (final size in sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Part6 production routes $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await seedPart6();
          final program = AdaptiveProgramCatalog.all.first;
          final routes = [
            AppRoutes.onboarding,
            AppRoutes.capabilityAssessment,
            AppRoutes.home,
            AppRoutes.workouts,
            AppRoutes.programs,
            AppRoutes.programDetail(program.id),
            AppRoutes.programSessionPreview(
                program.id, program.sessions.first.id),
            AppRoutes.customWorkoutDetail('TEST-custom'),
            AppRoutes.customWorkoutEdit('TEST-custom'),
            AppRoutes.exerciseLibrary,
            AppRoutes.exerciseDetail('pushup_standard'),
            AppRoutes.skillTrees,
            AppRoutes.skillTreeFamily('pushup'),
            AppRoutes.progress,
            AppRoutes.workoutPreview,
            AppRoutes.profile,
            AppRoutes.fitnessProfile,
            AppRoutes.equipment,
            AppRoutes.workoutPreferences,
            AppRoutes.settings,
            AppRoutes.backupRestore,
            AppRoutes.privacyPolicy
          ];
          for (final route in routes) {
            final router =
                await part6Route(tester, route, dark: dark, scale: scale);
            assertClean(tester, '$route $size scale=$scale');
            if (route == AppRoutes.home) {
              expect(
                  find.byType(
                      size.width >= 840 ? NavigationRail : NavigationBar),
                  findsOneWidget);
              await tester.ensureVisible(find.text('View workout'));
              expect(
                  tester
                      .getSize(
                          find.widgetWithText(FilledButton, 'View workout'))
                      .height,
                  greaterThanOrEqualTo(48));
            }
            if (route == AppRoutes.workoutPreview) {
              await tester
                  .ensureVisible(find.byKey(const Key('preview_start')));
              expect(
                  tester.getSize(find.byKey(const Key('preview_start'))).height,
                  greaterThanOrEqualTo(48));
            }
            assertClean(tester, '$route actions');
            await tester.pumpWidget(const SizedBox.shrink());
            router.dispose();
          }
        });
        testWidgets('Part6 Player phases $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await seedPart6();
          final plan = flowPlan();
          late WorkoutPlayerController c;
          await tester.pumpWidget(part6Host(
              dark: dark,
              scale: scale,
              extra: [
                ...programOverrides(),
                workoutPlayerControllerProvider(plan).overrideWith((ref) => c =
                    WorkoutPlayerController(
                        plan: plan,
                        coach: FakeWorkoutCoach(),
                        autoStartTimer: false)),
              ],
              child: FitFlowNavigationShell(
                  selectedIndex: 0,
                  onSelected: (_) {},
                  destinations: const [
                    FitFlowNavDestination(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Home'),
                    FitFlowNavDestination(
                        icon: Icons.fitness_center,
                        selectedIcon: Icons.fitness_center,
                        label: 'Workouts'),
                    FitFlowNavDestination(
                        icon: Icons.insights_outlined,
                        selectedIcon: Icons.insights,
                        label: 'Progress'),
                    FitFlowNavDestination(
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person,
                        label: 'Profile'),
                  ],
                  body: WorkoutPlayerSessionView(
                      plan: plan,
                      sessionMode: WorkoutSessionMode.standard,
                      sessionOrigin: WorkoutSessionOrigin.adaptive))));
          await tester.pumpAndSettle();
          await press(tester, 'Begin workout');
          assertClean(tester, 'work');
          final semantics = tester.ensureSemantics();
          final timer = find.descendant(
              of: find.byType(PlayerTimerSemantics),
              matching: find.byType(Semantics));
          expect(timer, findsOneWidget);
          expect(
              tester
                  .getSemantics(timer)
                  .getSemanticsData()
                  .flagsCollection
                  .isLiveRegion,
              isFalse);
          semantics.dispose();
          finishTimed(c);
          await tester.pumpAndSettle();
          expect(c.state.phase, WorkoutPlayerPhase.rest);
          assertClean(tester, 'rest');
          for (var i = 0;
              i < 300 && c.state.phase != WorkoutPlayerPhase.completed;
              i++) {
            switch (c.state.phase) {
              case WorkoutPlayerPhase.work:
                c.state.currentPrescription.workDuration != null
                    ? c.tick()
                    : c.completeSet();
              case WorkoutPlayerPhase.rest:
                c.skipRest();
              case WorkoutPlayerPhase.transition:
                c.skipTransition();
              case WorkoutPlayerPhase.sectionBreak:
                c.continueSection();
              default:
                break;
            }
          }
          await tester.pumpAndSettle();
          expect(c.state.phase, WorkoutPlayerPhase.completed);
          await tester.ensureVisible(find.text('Done'));
          assertClean(tester, 'completion');
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
