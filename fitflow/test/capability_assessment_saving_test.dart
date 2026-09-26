import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  const userProfileRegular = UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: {WorkoutEquipment.chair},
  );

  Future<void> pumpToAssessment(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await UserFitnessProfileStorage(prefs).save(userProfileRegular);
    await prefs.remove(CapabilityProfileStorage.profileKey);

    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> scrollToKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    try {
      await tester.scrollUntilVisible(
        finder,
        300,
        maxScrolls: 30,
      );
    } catch (_) {
      try {
        await tester.ensureVisible(finder);
      } catch (_) {}
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Saving - Mixed Assessment', () {
    testWidgets('complete/save mixed assessment preserves exact levels',
        (tester) async {
      await pumpToAssessment(tester);

      expect(find.text('Movement Check'), findsWidgets);

      // Change Push → Level 2
      await scrollToKey(tester, const ValueKey('assessment_card_push'));
      await tester.tap(find.byKey(const ValueKey('level_push_level2')));
      await tester.pump(const Duration(milliseconds: 300));

      // Squat → Level 4
      await scrollToKey(tester, const ValueKey('assessment_card_squat'));
      await tester.tap(find.byKey(const ValueKey('level_squat_level4')));
      await tester.pump(const Duration(milliseconds: 300));

      // Core → Level 1
      await scrollToKey(tester, const ValueKey('assessment_card_core'));
      await tester.tap(find.byKey(const ValueKey('level_core_level1')));
      await tester.pump(const Duration(milliseconds: 300));

      // Save & Continue
      await scrollToKey(
          tester, const Key('save_and_continue_button'));
      await tester.tap(find.byKey(const Key('save_and_continue_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 800));

      // Should navigate to Home
      expect(find.text('Your adaptive workout starts here'), findsOneWidget);

      // Verify persisted CapabilityProfile
      final prefs = await SharedPreferences.getInstance();
      final storage = CapabilityProfileStorage(prefs);
      final profile = storage.load();
      expect(profile, isNotNull);
      expect(profile!.isComplete, true);
      expect(profile.isValid, true);
      expect(profile.capabilities.length, 10);

      // Representative expected values
      expect(profile.capabilityFor(MovementPattern.push)!.level,
          CapabilityLevel.level2);
      expect(profile.capabilityFor(MovementPattern.squat)!.level,
          CapabilityLevel.level4);
      expect(profile.capabilityFor(MovementPattern.core)!.level,
          CapabilityLevel.level1);
      expect(profile.capabilityFor(MovementPattern.pull)!.level,
          CapabilityLevel.level3);

      // Verify source
      for (final cap in profile.all) {
        expect(cap.source, CapabilitySource.initialAssessment);
      }

      // Verify all 10 exist
      for (final pattern in [
        MovementPattern.push,
        MovementPattern.pull,
        MovementPattern.squat,
        MovementPattern.lunge,
        MovementPattern.hinge,
        MovementPattern.core,
        MovementPattern.glute,
        MovementPattern.cardio,
        MovementPattern.mobility,
        MovementPattern.balance,
      ]) {
        expect(profile.capabilityFor(pattern), isNotNull,
            reason: 'Missing $pattern');
      }
    });
  });

  group('Navigation - First Run Flow', () {
    testWidgets('onboarding → Get Started → Movement Check → Save → Home',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await waitUntilOnboarding(tester);

      expect(find.text('Welcome to FitFlow'), findsOneWidget);

      // Use completeOnboarding to reach assessment
      await completeOnboarding(tester);
      expect(find.text('Movement Check'), findsWidgets);

      // Save & Continue
      await scrollToKey(tester, const Key('save_and_continue_button'));
      await tester.tap(find.byKey(const Key('save_and_continue_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);
      expect(find.text('Movement Check'), findsNothing);
    });

    testWidgets('assessment cannot be skipped by normal flow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await waitUntilOnboarding(tester);

      // Complete onboarding
      await completeOnboarding(tester);
      expect(find.text('Movement Check'), findsWidgets);

      // Verify Home is not yet reachable without saving
      expect(find.text('Your adaptive workout starts here'), findsNothing);

      // Now save
      await scrollToKey(tester, const Key('save_and_continue_button'));
      await tester.tap(find.byKey(const Key('save_and_continue_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);
    });
  });
}
