import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/profile/presentation/fitness_profile_editor_screen.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/profile_editor_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

WorkoutPlan _plan() {
  WorkoutExercisePrescription timed(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: 1,
      repsPerSet: null,
      workDuration: const Duration(seconds: 20),
      restBetweenSets: const Duration(seconds: 10),
    );
  }

  return WorkoutPlan(
    warmup: WorkoutSection(
      type: WorkoutSectionType.warmup,
      exercises: [timed('march_in_place')],
    ),
    main: WorkoutSection(
      type: WorkoutSectionType.main,
      exercises: [timed('squat_bodyweight')],
    ),
    cooldown: WorkoutSection(
      type: WorkoutSectionType.cooldown,
      exercises: [timed('figure_four_stretch')],
    ),
    timeBudget: const WorkoutTimeBudget(
      target: Duration(minutes: 16),
      warmup: Duration(minutes: 2),
      main: Duration(minutes: 12),
      cooldown: Duration(minutes: 2),
    ),
  );
}

Future<void> _pumpScaled(
  WidgetTester tester, {
  required Widget home,
  List<Override> overrides = const [],
  Size size = const Size(320, 700),
  double textScale = 2,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ensureTimezones();
  });

  testWidgets('Home stays usable at text scale 2 and 320px', (tester) async {
    await _pumpScaled(
      tester,
      overrides: programOverrides(),
      home: const HomeScreen(),
    );
    expect(find.text('View workout'), findsOneWidget);
  });

  testWidgets('Workout preview stays usable at text scale 2 and 320px',
      (tester) async {
    await _pumpScaled(
      tester,
      overrides: programOverrides(),
      home: const WorkoutPreviewScreen(),
    );
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('Player keeps pause reachable at text scale 2 and in landscape',
      (tester) async {
    Future<void> pump(Size size) async {
      await _pumpScaled(
        tester,
        size: size,
        overrides: programOverrides(),
        home: WorkoutPlayerSessionView(
          plan: _plan(),
          sessionMode: WorkoutSessionMode.standard,
          sessionOrigin: WorkoutSessionOrigin.adaptive,
        ),
      );
      expect(find.text('Begin workout'), findsOneWidget);
    }

    await pump(const Size(320, 700));
    await pump(const Size(700, 320));
  });

  testWidgets('Exercise library stays usable at text scale 2 and landscape',
      (tester) async {
    await _pumpScaled(tester, home: const ExerciseLibraryScreen());
    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);

    await _pumpScaled(
      tester,
      size: const Size(700, 320),
      textScale: 1.5,
      home: const ExerciseLibraryScreen(),
    );
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('Exercise detail stays usable at text scale 2', (tester) async {
    await _pumpScaled(
      tester,
      home: const ExerciseDetailScreen(exerciseId: 'squat_bodyweight'),
    );
    expect(find.text('Squat'), findsWidgets);
  });

  testWidgets('Program detail stays usable at text scale 2 and landscape',
      (tester) async {
    final screen = ProgramDetailScreen(
      programId: AdaptiveProgramCatalog.balancedFoundationsId,
    );
    await _pumpScaled(
      tester,
      overrides: programOverrides(),
      home: screen,
    );
    await tester.scrollUntilVisible(
      find.text('Start program'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Start program'), findsOneWidget);

    await _pumpScaled(
      tester,
      size: const Size(700, 320),
      textScale: 1.5,
      overrides: programOverrides(),
      home: screen,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile editor keeps Save reachable at text scale 2',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      seedProfilePrefs(profileEditorSeed()),
    );
    await pumpProfileApp(
      tester,
      initialLocation: AppRoutes.fitnessProfile,
      size: const Size(320, 700),
      textScale: 2,
    );
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.byType(FitnessProfileEditorScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings stays usable at text scale 2 and landscape',
      (tester) async {
    final reminders = FakeWorkoutReminderNotificationService();
    await _pumpScaled(
      tester,
      overrides: reminderOverrides(service: reminders),
      home: const SettingsScreen(),
    );
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Backup & restore'), findsWidgets);

    await _pumpScaled(
      tester,
      size: const Size(700, 320),
      textScale: 1.5,
      overrides: reminderOverrides(service: reminders),
      home: const SettingsScreen(),
    );
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Backup and restore actions stay reachable at text scale 2',
      (tester) async {
    await _pumpScaled(
      tester,
      home: const BackupRestoreScreen(),
    );
    expect(find.text('Create backup'), findsWidgets);
    expect(find.text('Choose backup file'), findsOneWidget);
    expect(find.byKey(BackupRestoreScreen.createButtonKey), findsOneWidget);
  });
}
