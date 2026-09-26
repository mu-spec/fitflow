import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Ensure no capability profile
    await prefs.remove(CapabilityProfileStorage.profileKey);

    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    // Wait for splash + routing to assessment
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> scrollToKey(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    // Try to scroll until visible - use all scrollables
    try {
      await tester.scrollUntilVisible(
        finder,
        300,
        maxScrolls: 30,
      );
    } catch (_) {
      // Fallback: ensure visible
      try {
        await tester.ensureVisible(finder);
      } catch (_) {}
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Assessment UI - Experience Prefill', () {
    testWidgets('regularTraining prefill shows Level 3 for representative movements',
        (tester) async {
      await pumpToAssessment(tester);

      expect(find.text('Movement Check'), findsWidgets);

      // Push is visible first
      expect(find.byKey(const ValueKey('assessment_card_push')), findsOneWidget);
      expect(find.byKey(const ValueKey('level_push_level3')), findsOneWidget);

      // Scroll to pull, squat, core
      await scrollToKey(tester, const ValueKey('assessment_card_pull'));
      expect(find.byKey(const ValueKey('level_pull_level3')), findsOneWidget);

      await scrollToKey(tester, const ValueKey('assessment_card_squat'));
      expect(find.byKey(const ValueKey('level_squat_level3')), findsOneWidget);

      await scrollToKey(tester, const ValueKey('assessment_card_core'));
      expect(find.byKey(const ValueKey('level_core_level3')), findsOneWidget);
    });
  });

  group('Assessment UI - Ten Movement Items', () {
    testWidgets('all 10 catalog items represented, no warmup/cooldown',
        (tester) async {
      await pumpToAssessment(tester);

      expect(find.text('Movement Check'), findsWidgets);

      for (final item in CapabilityAssessmentCatalog.all) {
        final cardKey = ValueKey('assessment_card_${item.movementPattern.name}');
        await scrollToKey(tester, cardKey);
        expect(
          find.byKey(cardKey),
          findsOneWidget,
          reason: 'Missing card for ${item.movementPattern.name}',
        );
      }

      // Ensure no warmup/cooldown cards
      expect(find.byKey(const ValueKey('assessment_card_warmup')), findsNothing);
      expect(find.byKey(const ValueKey('assessment_card_cooldown')), findsNothing);

      expect(CapabilityAssessmentCatalog.all.length, 10);
    });
  });

  group('Assessment UI - Independent Editing', () {
    testWidgets('change Push→2, Squat→4, Core→1 preserves Pull as 3',
        (tester) async {
      await pumpToAssessment(tester);

      // Change Push to Level 2
      await scrollToKey(tester, const ValueKey('assessment_card_push'));
      await tester.tap(find.byKey(const ValueKey('level_push_level2')));
      await tester.pump(const Duration(milliseconds: 300));

      // Change Squat to Level 4
      await scrollToKey(tester, const ValueKey('assessment_card_squat'));
      await tester.tap(find.byKey(const ValueKey('level_squat_level4')));
      await tester.pump(const Duration(milliseconds: 300));

      // Change Core to Level 1
      await scrollToKey(tester, const ValueKey('assessment_card_core'));
      await tester.tap(find.byKey(const ValueKey('level_core_level1')));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify via summary that changed movements show new levels
      await scrollToKey(tester, const Key('save_and_continue_button'));
      // Summary should contain Push L2, Squat L4, Core L1, Pull L3
      expect(find.textContaining('Push L2'), findsOneWidget);
      expect(find.textContaining('Squat L4'), findsOneWidget);
      expect(find.textContaining('Core L1'), findsOneWidget);
      expect(find.textContaining('Pull L3'), findsOneWidget);
      expect(find.textContaining('Lunge L3'), findsOneWidget);
      // Verify Level 3 still appears (for unchanged movements)
      expect(find.text('Level 3'), findsWidgets);
    });
  });

  group('Assessment UI - Level Description', () {
    testWidgets('select Level 4 shows Strong and description', (tester) async {
      await pumpToAssessment(tester);

      await scrollToKey(tester, const ValueKey('assessment_card_push'));
      // Tap Level 4 for push
      await tester.tap(find.byKey(const ValueKey('level_push_level4')));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Strong appears and Level 4 description
      expect(find.textContaining('Strong'), findsWidgets);
      expect(
        find.textContaining(
            'Comfortable with challenging variations and higher training demand'),
        findsWidgets,
      );
    });

    testWidgets('all level descriptions visible when selected', (tester) async {
      await pumpToAssessment(tester);

      await scrollToKey(tester, const ValueKey('assessment_card_push'));

      // Select each level for push and verify description
      final levelExpectations = {
        CapabilityLevel.level1: 'Just starting',
        CapabilityLevel.level2: 'Basic',
        CapabilityLevel.level3: 'Solid',
        CapabilityLevel.level4: 'Strong',
        CapabilityLevel.level5: 'Advanced',
      };

      for (final entry in levelExpectations.entries) {
        final level = entry.key;
        final title = entry.value;
        await tester.tap(
            find.byKey(ValueKey('level_push_${level.name}')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining(title), findsWidgets);
      }
    });
  });
}
