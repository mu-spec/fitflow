import 'dart:async';

import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/splash/startup_destination.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M21 Part 1: startup latency and routing efficiency.
///
/// The fixed 1.5s splash delay is gone; routing waits only for the two
/// required persisted states, resolved concurrently, and navigates once.
void main() {
  final userProfile = UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: {WorkoutEquipment.chair},
  );

  group('decideStartupDestination (pure decision)', () {
    test('profile missing -> onboarding', () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.missing,
          capabilityProfile: StartupLoadState.missing,
        ),
        StartupDestination.onboarding,
      );
    });

    test('profile present, capability missing -> assessment', () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.present,
          capabilityProfile: StartupLoadState.missing,
        ),
        StartupDestination.capabilityAssessment,
      );
    });

    test('both present -> home', () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.present,
          capabilityProfile: StartupLoadState.present,
        ),
        StartupDestination.home,
      );
    });

    test('capability load failure behaves like missing (re-assessable)',
        () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.present,
          capabilityProfile: StartupLoadState.failed,
        ),
        StartupDestination.capabilityAssessment,
      );
    });

    test('profile load failure with present capability routes home, '
        'never onboarding', () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.failed,
          capabilityProfile: StartupLoadState.present,
        ),
        StartupDestination.home,
      );
    });

    test('profile load failure without capability falls back to the '
        'non-destructive assessment, never onboarding', () {
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.failed,
          capabilityProfile: StartupLoadState.missing,
        ),
        StartupDestination.capabilityAssessment,
      );
      expect(
        decideStartupDestination(
          userProfile: StartupLoadState.failed,
          capabilityProfile: StartupLoadState.failed,
        ),
        StartupDestination.capabilityAssessment,
      );
    });
  });

  group('splash startup behavior', () {
    Future<void> seedBothProfiles() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);
      await CapabilityProfileStorage(prefs).save(
        CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 10, 2)),
      );
    }

    /// Pumps until [finder] appears or [maxCumulative] of fake time has
    /// passed. Returns cumulative milliseconds pumped.
    Future<int> pumpUntil(
      WidgetTester tester,
      Finder finder, {
      int maxCumulative = 1500,
      int step = 100,
    }) async {
      var pumped = 0;
      while (pumped < maxCumulative) {
        await tester.pump(const Duration(milliseconds: 100));
        pumped += step;
        if (finder.evaluate().isNotEmpty) return pumped;
      }
      return pumped;
    }

    testWidgets('no artificial 1500ms delay: configured user reaches Home '
        'well under the old delay', (tester) async {
      await seedBothProfiles();
      await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));

      final ms = await pumpUntil(
        tester,
        find.text('Your adaptive workout'),
        maxCumulative: 600,
      );

      expect(find.text('Your adaptive workout'), findsOneWidget,
          reason: 'startup must reach Home within ${ms}ms — the fixed '
              '1500ms delay must be gone');
      expect(ms, lessThan(1500));
    });

    testWidgets('first launch routes to Onboarding without the old delay',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));

      final ms = await pumpUntil(
        tester,
        find.text('Welcome to FitFlow'),
        maxCumulative: 600,
      );

      expect(find.text('Welcome to FitFlow'), findsOneWidget);
      expect(ms, lessThan(1500));
    });

    testWidgets('profile without capability routes to assessment quickly',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);
      await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));

      final ms = await pumpUntil(
        tester,
        find.text('Movement Check'),
        maxCumulative: 600,
      );

      expect(find.text('Movement Check'), findsWidgets);
      expect(ms, lessThan(1500));
    });

    testWidgets('navigation happens only once and stays settled',
        (tester) async {
      await seedBothProfiles();
      await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
      await pumpUntil(tester, find.text('Your adaptive workout'));
      expect(find.text('Your adaptive workout'), findsOneWidget);

      // Extra settling time must not re-route or throw.
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Your adaptive workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('startup load semantics', () {
    testWidgets('splash waits for BOTH states concurrently before routing',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);

      final capabilityGate = Completer<CapabilityProfile?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capabilityProfileProvider
                .overrideWith(() => _GatedCapabilityController(capabilityGate)),
          ],
          child: const FitFlowApp(),
        ),
      );

      // Profile already resolved; capability still pending -> still splash.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('FitFlow'), findsWidgets);
      expect(find.text('Movement Check'), findsNothing);
      expect(find.text('Your adaptive workout'), findsNothing);

      // Capability resolves (missing) -> assessment, proving both loads were
      // awaited concurrently and routing happened as soon as both completed.
      capabilityGate.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Movement Check'), findsWidgets);
    });

    testWidgets('disposed splash never navigates', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);

      final profileGate = Completer<UserFitnessProfile?>();
      final capabilityGate = Completer<CapabilityProfile?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userFitnessProfileProvider
                .overrideWith(() => _GatedProfileController(profileGate)),
            capabilityProfileProvider
                .overrideWith(() => _GatedCapabilityController(capabilityGate)),
          ],
          child: const FitFlowApp(),
        ),
      );
      await tester.pump();

      // Replace the tree (disposing the splash) BEFORE either load resolves.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('gone'))));
      expect(find.text('gone'), findsOneWidget);

      // Now let the pending loads finish; the disposed splash must not
      // navigate or throw.
      profileGate.complete(userProfile);
      capabilityGate.complete(
        CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 10, 2)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('gone'), findsOneWidget,
          reason: 'no destination may be forced after splash disposal');
      expect(tester.takeException(), isNull);
    });
  });
}

/// Capability controller whose build is gated by a test completer.
class _GatedCapabilityController extends CapabilityProfileController {
  _GatedCapabilityController(this._gate);

  final Completer<CapabilityProfile?> _gate;

  @override
  Future<CapabilityProfile?> build() => _gate.future;
}

/// Profile controller whose build is gated by a test completer.
class _GatedProfileController extends UserFitnessProfileController {
  _GatedProfileController(this._gate);

  final Completer<UserFitnessProfile?> _gate;

  @override
  Future<UserFitnessProfile?> build() => _gate.future;
}
