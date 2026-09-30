import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'exercise_skill_tree_fixtures.dart';

/// Fake profile controller that resolves to a fixed (possibly null) profile.
class FakeProgramUserProfileController extends UserFitnessProfileController {
  FakeProgramUserProfileController(this.profile);
  final UserFitnessProfile? profile;
  @override
  Future<UserFitnessProfile?> build() async => profile;
}

/// Fake capability controller that resolves to a fixed (possibly null) profile.
class FakeProgramCapabilityController extends CapabilityProfileController {
  FakeProgramCapabilityController(this.profile);
  final CapabilityProfile? profile;
  @override
  Future<CapabilityProfile?> build() async => profile;
}

UserFitnessProfile programTestProfile({
  FitnessGoal goal = FitnessGoal.generalFitness,
  WorkoutDuration duration = WorkoutDuration.fifteenMinutes,
  Set<WorkoutPreference> preferences = const {},
}) {
  return UserFitnessProfile(
    goal: goal,
    experience: ExperienceLevel.completelyNew,
    workoutDuration: duration,
    environment: TrainingEnvironment.normalHome,
    equipment: const {WorkoutEquipment.none},
    preferences: preferences,
  );
}

/// Restrictive profile for which the catalog cannot produce a valid plan.
UserFitnessProfile programUngenerableProfile() => UserFitnessProfile(
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.completelyNew,
      workoutDuration: WorkoutDuration.fifteenMinutes,
      environment: TrainingEnvironment.apartment,
      equipment: const {WorkoutEquipment.none},
      preferences: WorkoutPreference.values.toSet(),
    );

List<Override> programOverrides({
  UserFitnessProfile? profile,
  bool includeProfile = true,
  CapabilityProfile? capability,
  bool includeCapability = true,
  DateTime? now,
}) {
  return [
    userFitnessProfileProvider.overrideWith(() =>
        FakeProgramUserProfileController(
            includeProfile ? (profile ?? programTestProfile()) : null)),
    capabilityProfileProvider.overrideWith(() =>
        FakeProgramCapabilityController(includeCapability
            ? (capability ?? skillTreeCapabilityProfile())
            : null)),
    adaptiveProgramsClockProvider
        .overrideWithValue(() => now ?? DateTime.utc(2026, 9, 30, 12)),
  ];
}

/// Router covering the Workouts tab + all program routes.
GoRouter programTestRouter({String initialLocation = AppRoutes.workouts}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.workouts,
        builder: (context, state) =>
            const Scaffold(body: WorkoutsScreen()),
        routes: [
          GoRoute(
            path: 'programs',
            builder: (context, state) => const ProgramsOverviewScreen(),
            routes: [
              GoRoute(
                path: ':programId',
                builder: (context, state) => ProgramDetailScreen(
                  programId: state.pathParameters['programId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'session/:sessionId',
                    builder: (context, state) => ProgramSessionPreviewScreen(
                      programId: state.pathParameters['programId']!,
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget programTestApp({
  required GoRouter router,
  required List<Override> overrides,
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
}

/// Scrolls the single ListView on screen in small settled steps until
/// [finder] matches at least one widget, then ensures it is visible.
/// Positive [step] scrolls down (reveals items below), negative scrolls up.
Future<void> programScrollTo(
  WidgetTester tester,
  Finder finder, {
  double step = 150,
  int maxSteps = 60,
}) async {
  final list = find.byType(ListView).first;
  var remaining = maxSteps;
  while (finder.evaluate().isEmpty && remaining > 0) {
    await tester.drag(list, Offset(0, -step));
    await tester.pumpAndSettle();
    remaining--;
  }
  expect(finder, findsWidgets);
  await Scrollable.ensureVisible(tester.element(finder.first));
  await tester.pumpAndSettle();
}

/// Scrolls back to the very top of the single ListView.
Future<void> programScrollToTop(WidgetTester tester) async {
  final list = find.byType(ListView).first;
  for (var i = 0; i < 20; i++) {
    await tester.drag(list, const Offset(0, 800));
    await tester.pumpAndSettle();
  }
}
