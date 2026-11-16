import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_editorial_card.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recent_workouts.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/profile/presentation/fitness_profile_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/equipment_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/workout_preferences_editor_screen.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'helpers/profile_editor_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';
import 'workout_preview_test.dart' as fixtures;

void main() {
  setUpAll(() async {
    if (Platform.environment['FITFLOW_CAPTURE'] == '1') {
      final font = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(
            File('C:/Windows/Fonts/arial.ttf').readAsBytesSync())));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  final screens = <String, Widget>{
    'cards': WorkoutsTheme(child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      for (final program in AdaptiveProgramCatalog.all)
        Padding(padding: const EdgeInsets.only(bottom: 16), child: ProgramEditorialCard(program: program, onTap: () {})),
    ])))),
    'workouts': const WorkoutsScreen(),
    'builder': const CustomWorkoutBuilderScreen(),
    'profile': const ProfileScreen(),
    'fitness': const FitnessProfileEditorScreen(),
    'equipment': const EquipmentEditorScreen(),
    'preferences': const WorkoutPreferencesEditorScreen(),
    'settings': const SettingsScreen(),
    'report': const ProgressScreen(),
    'preview': const WorkoutPreviewScreen(),
  };
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} fits width $width scale $scale',
            (tester) async {
          ensureTimezones();
          SharedPreferences.setMockInitialValues(
              seedProfilePrefs(profileEditorSeed()));
          if (entry.key == 'report') {
            final prefs = await SharedPreferences.getInstance();
            await WorkoutHistoryStorage(prefs).saveAll([
              CompletedWorkout(
                  id: 'qa',
                  completedAt: DateTime.now(),
                  estimatedDuration: const Duration(minutes: 17),
                  totalExerciseCount: 2,
                  totalSetCount: 4,
                  warmup: const [],
                  main: const [],
                  cooldown: const [])
            ]);
          }
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              ...reminderOverrides(
                  service: FakeWorkoutReminderNotificationService()),
              userFitnessProfileProvider.overrideWith(
                  () => ScriptedProfileController(profileEditorSeed())),
              capabilityProfileProvider.overrideWith(() =>
                  fixtures.FakeCapabilityController(
                      buildOverride: () async =>
                          fixtures.createFullProfile(CapabilityLevel.level2))),
            ],
            child: MaterialApp(
                theme: AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                        disableAnimations: true),
                    child: child!),
                home: RepaintBoundary(
                    key: const ValueKey('capture'), child: entry.value)),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (entry.key == 'report') {
            for (final tab in [1, 2, 0]) {
              await tester.tap(find.byKey(ValueKey('report_tab_$tab')));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (tab == 1) {
                expect(find.byType(ProgressRecentWorkouts), findsOneWidget);
              }
            }
          }
          if (width == 390 &&
              scale == 1 &&
              Platform.environment['FITFLOW_CAPTURE'] == '1') {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('capture')));
            final image = boundary.toImageSync(pixelRatio: 1);
            final bytes = await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.png));
            await tester.runAsync(() async {
              final file = File('build/redesign-qa/${entry.key}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
            image.dispose();
          }
        });
      }
    }
  }
  testWidgets(
      'fitness dropdown saves only after explicit Save and retains draft on failure',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ScriptedProfileController(profileEditorSeed())
      ..saveResult = false;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (c, s) => const Scaffold(body: Text('Returned'))),
      GoRoute(
          path: '/edit', builder: (c, s) => const FitnessProfileEditorScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      userFitnessProfileProvider.overrideWith(() => controller)
    ], child: MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
    router.push('/edit');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<FitnessGoal>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General fitness').last);
    await tester.pumpAndSettle();
    expect(controller.saveCalls, 0);
    expect(controller.profile!.goal, FitnessGoal.buildStrength);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(controller.saveCalls, 1);
    expect(controller.profile!.goal, FitnessGoal.buildStrength);
    expect(find.text("Couldn't save your changes. Try again."), findsOneWidget);
    controller.saveResult = true;
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(controller.profile!.goal, FitnessGoal.generalFitness);
    expect(find.text('Returned'), findsOneWidget);
  });
}
