import 'dart:async';

import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M21 Part 2: a thrown startup read is not onboarding, assessment, or home.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final userProfile = UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: {WorkoutEquipment.chair},
  );

  Future<Map<String, String?>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys()) key: prefs.getString(key),
    };
  }

  Future<void> seedBoth() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await UserFitnessProfileStorage(prefs).save(userProfile);
    await CapabilityProfileStorage(prefs).save(
      CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 10, 2)),
    );
  }

  testWidgets('failed read shows retry and does not route', (tester) async {
    await seedBoth();
    final before = await snapshot();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFitnessProfileProvider
              .overrideWith(_ThrowingProfileController.new),
        ],
        child: const FitFlowApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(SplashScreen.recoveryTitle), findsOneWidget);
    expect(find.text(SplashScreen.recoveryBody), findsOneWidget);
    expect(find.text(SplashScreen.recoveryAction), findsOneWidget);
    expect(find.text('Welcome to FitFlow'), findsNothing);
    expect(find.text('Movement Check'), findsNothing);
    expect(find.text('Your adaptive workout'), findsNothing);
    expect(await snapshot(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry success routes home and does not rewrite keys',
      (tester) async {
    await seedBoth();
    final before = await snapshot();
    _FlakyProfileController.loads = 0;
    _ReadingCapabilityController.loads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFitnessProfileProvider.overrideWith(_FlakyProfileController.new),
          capabilityProfileProvider
              .overrideWith(_ReadingCapabilityController.new),
        ],
        child: const FitFlowApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(SplashScreen.recoveryTitle), findsOneWidget);
    expect(find.text('Your adaptive workout'), findsNothing);

    await tester.tap(find.text(SplashScreen.recoveryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Your adaptive workout'), findsOneWidget);
    expect(find.text(SplashScreen.recoveryTitle), findsNothing);
    expect(_FlakyProfileController.loads, greaterThanOrEqualTo(2));
    expect(_ReadingCapabilityController.loads, greaterThanOrEqualTo(2));
    expect(await snapshot(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated Retry is blocked while one attempt is in flight',
      (tester) async {
    await seedBoth();
    _GatedProfileController.loads = 0;
    _GatedProfileController.gate = Completer<UserFitnessProfile?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFitnessProfileProvider.overrideWith(_GatedProfileController.new),
          capabilityProfileProvider
              .overrideWith(_ReadingCapabilityController.new),
        ],
        child: const FitFlowApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(SplashScreen.recoveryTitle), findsOneWidget);

    final beforeTap = _GatedProfileController.loads;
    await tester.tap(find.text(SplashScreen.recoveryAction));
    await tester.pump();
    await tester.tap(
      find.text(SplashScreen.recoveryAction),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(_GatedProfileController.loads, beforeTap + 1);

    _GatedProfileController.gate.complete(userProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Your adaptive workout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed splash retry does not navigate or throw',
      (tester) async {
    await seedBoth();
    _GatedProfileController.loads = 0;
    _GatedProfileController.gate = Completer<UserFitnessProfile?>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFitnessProfileProvider.overrideWith(_GatedProfileController.new),
        ],
        child: const FitFlowApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text(SplashScreen.recoveryAction));
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('gone'))),
    );
    _GatedProfileController.gate.complete(userProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('gone'), findsOneWidget);
    expect(find.text('Your adaptive workout'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corrupt capability JSON is missing, not a failed read',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      UserFitnessProfileStorage.profileKey: UserFitnessProfileStorage.encode(
        userProfile,
      ),
      CapabilityProfileStorage.profileKey: '{not-json',
    });
    final before = await snapshot();

    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Movement Check'), findsWidgets);
    expect(find.text(SplashScreen.recoveryTitle), findsNothing);
    expect(find.text('Welcome to FitFlow'), findsNothing);
    expect(await snapshot(), before,
        reason: 'a safe null load must not overwrite corrupt bytes');
    expect(tester.takeException(), isNull);
  });
}

class _ThrowingProfileController extends UserFitnessProfileController {
  @override
  Future<UserFitnessProfile?> build() async {
    throw StateError('simulated profile read failure');
  }
}

class _FlakyProfileController extends UserFitnessProfileController {
  static int loads = 0;

  @override
  Future<UserFitnessProfile?> build() async {
    loads++;
    if (loads == 1) throw StateError('simulated profile read failure');
    final prefs = await SharedPreferences.getInstance();
    return UserFitnessProfileStorage(prefs).load();
  }
}

class _ReadingCapabilityController extends CapabilityProfileController {
  static int loads = 0;

  @override
  Future<CapabilityProfile?> build() async {
    loads++;
    final prefs = await SharedPreferences.getInstance();
    return CapabilityProfileStorage(prefs).load();
  }
}

class _GatedProfileController extends UserFitnessProfileController {
  static int loads = 0;
  static Completer<UserFitnessProfile?> gate = Completer<UserFitnessProfile?>();

  @override
  Future<UserFitnessProfile?> build() async {
    loads++;
    if (loads == 1) throw StateError('simulated profile read failure');
    return gate.future;
  }
}
