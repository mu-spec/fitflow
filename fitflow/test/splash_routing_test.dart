import 'dart:convert';

import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const userProfile = UserFitnessProfile(
    goal: FitnessGoal.generalFitness,
    experience: ExperienceLevel.regularTraining,
    workoutDuration: WorkoutDuration.twentyMinutes,
    environment: TrainingEnvironment.normalHome,
    equipment: {WorkoutEquipment.chair},
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );
    // Wait for splash delay + routing
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Splash Routing Matrix', () {
    testWidgets('Case A: No UserFitnessProfile → Onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);

      expect(find.text('Welcome to FitFlow'), findsOneWidget);
      expect(find.text('Movement Check'), findsNothing);
      expect(find.text('Your adaptive workout starts here'), findsNothing);
    });

    testWidgets('Case B: UserFitnessProfile exists, Capability missing → Movement Check',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);
      await prefs.remove(CapabilityProfileStorage.profileKey);

      await pumpApp(tester);

      expect(find.text('Movement Check'), findsWidgets);
      expect(find.text('Welcome to FitFlow'), findsNothing);
      expect(find.text('Your adaptive workout starts here'), findsNothing);
    });

    testWidgets('Case C: Both valid profiles exist → Home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);
      final capabilityProfile =
          CapabilityProfile.initial(updatedAt: DateTime.utc(2026, 9, 26));
      await CapabilityProfileStorage(prefs).save(capabilityProfile);

      await pumpApp(tester);

      expect(find.text('Your adaptive workout starts here'), findsOneWidget);
      expect(find.text('Welcome to FitFlow'), findsNothing);
      expect(find.text('Movement Check'), findsNothing);
    });

    testWidgets('Corrupt capability JSON + valid user profile → Movement Check',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        UserFitnessProfileStorage.profileKey:
            '{"goal":"generalFitness","experience":"regularTraining","workoutDuration":"twentyMinutes","environment":"normalHome","equipment":["chair"],"preferences":[]}',
        CapabilityProfileStorage.profileKey: '{not valid json {{{',
      });

      await pumpApp(tester);

      expect(find.text('Movement Check'), findsWidgets);
      expect(find.text('Your adaptive workout starts here'), findsNothing);
    });

    testWidgets('Incomplete capability JSON (9 entries) → Movement Check',
        (tester) async {
      final now = DateTime.utc(2026, 1, 1);
      // Create incomplete profile with 9 entries
      final fullInitial = CapabilityProfile.initial(updatedAt: now);
      final nineMap = <dynamic, dynamic>{};
      for (final p in CapabilityProfile.trainablePatterns.take(9)) {
        nineMap[p] = fullInitial.capabilityFor(p)!;
      }
      final incompleteProfile = CapabilityProfile.fromMap(
        Map.fromEntries(
          nineMap.entries.map((e) => MapEntry(e.key as dynamic, e.value as dynamic)),
        ),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await UserFitnessProfileStorage(prefs).save(userProfile);
      // Directly store incomplete JSON bypassing save validation
      final jsonString = jsonEncode(incompleteProfile.toJson());
      await prefs.setString(CapabilityProfileStorage.profileKey, jsonString);

      await tester.pumpWidget(
        const ProviderScope(
          child: FitFlowApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Movement Check'), findsWidgets);
    });
  });
}
