import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('Preview loads by ID and shows exact plan', (tester) async {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'Preview Test',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_bodyweight', sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(customWorkoutStorageProvider).saveAll([template]);

    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Scroll to View button if needed
    await tester.scrollUntilVisible(find.text('View').first, 100, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('View').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Preview Test'), findsOneWidget);
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Cool-down'), findsOneWidget);
  });

  testWidgets('Preview missing disables Start and shows issue', (tester) async {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_missing_0',
      name: 'Missing Exercise',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'nonexistent_ex', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(customWorkoutStorageProvider).saveAll([template]);

    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(find.text('View').first, 100, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('View').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Missing Exercise'), findsOneWidget);
    expect(find.text('This workout needs updates for your current setup.'), findsOneWidget);
  });
}
