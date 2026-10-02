import 'dart:async';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A known-good profile used across M19 profile editing tests.
UserFitnessProfile profileEditorSeed() => UserFitnessProfile(
      goal: FitnessGoal.buildStrength,
      experience: ExperienceLevel.someExperience,
      workoutDuration: WorkoutDuration.twentyMinutes,
      environment: TrainingEnvironment.normalHome,
      equipment: const {WorkoutEquipment.chair},
      preferences: const {WorkoutPreference.noJumping},
    );

/// Mock SharedPreferences initial values containing only the persisted profile.
Map<String, Object> seedProfilePrefs(UserFitnessProfile profile) => {
      UserFitnessProfileStorage.profileKey:
          UserFitnessProfileStorage.encode(profile),
    };

/// Scriptable stand-in for [UserFitnessProfileController] used to simulate
/// save failures, count save calls, and gate saves behind a completer.
class ScriptedProfileController extends UserFitnessProfileController {
  ScriptedProfileController(UserFitnessProfile? initial) : profile = initial;

  UserFitnessProfile? profile;

  /// What `saveProfile` returns once the gate (if any) completes.
  bool saveResult = true;

  /// Number of `saveProfile` calls received.
  int saveCalls = 0;

  /// The last profile passed to `saveProfile`.
  UserFitnessProfile? lastSaveAttempt;

  /// When set, `saveProfile` waits on this before returning, so tests can
  /// observe the in-flight (busy) state.
  Completer<bool>? gate;

  /// When set, `build` waits on this future, keeping the provider loading.
  Completer<UserFitnessProfile?>? loadGate;

  /// When positive, `build` throws for this many invocations.
  int loadFailures = 0;

  int loadCalls = 0;

  @override
  Future<UserFitnessProfile?> build() async {
    loadCalls++;
    final gate = loadGate;
    if (gate != null) {
      return gate.future;
    }
    if (loadCalls <= loadFailures) {
      throw StateError('simulated profile load failure');
    }
    return profile;
  }

  @override
  Future<bool> saveProfile(UserFitnessProfile next) async {
    saveCalls++;
    lastSaveAttempt = next;
    final pending = gate;
    if (pending != null) {
      await pending.future;
    }
    if (saveResult) {
      profile = next;
      state = AsyncData(next);
    }
    return saveResult;
  }
}

/// Pumps the real app router positioned on [initialLocation] (a Profile-tab
/// location by default) with the given provider overrides.
Future<GoRouter> pumpProfileApp(
  WidgetTester tester, {
  String initialLocation = AppRoutes.profile,
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = AppRouter.create(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await settleProfileFrames(tester);
  return router;
}

/// Bounded pumps that settle async profile loads and route transitions
/// without risking a hang on the shell's persistent tickers.
Future<void> settleProfileFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Taps the onboarding-style option card with [label], scrolling it into
/// view first when the editor content is longer than the viewport.
Future<void> tapOption(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Whether the onboarding-style option card with [label] is selected.
bool optionCardSelected(WidgetTester tester, String label) {
  final card = find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
  final icon = find.descendant(of: card, matching: find.byType(Icon));
  final iconWidget = tester.widget<Icon>(icon);
  return iconWidget.icon == Icons.check_circle ||
      iconWidget.icon == Icons.check_box;
}

/// The Riverpod container behind the pumped app.
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
