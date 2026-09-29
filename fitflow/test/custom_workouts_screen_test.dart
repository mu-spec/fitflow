import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_controller.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('Workouts screen Exercise Library visible and Create visible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Exercise Library'), findsOneWidget);
    expect(find.text('Create custom workout'), findsOneWidget);
    expect(find.text('Custom workouts'), findsOneWidget);
  });

  testWidgets('Workouts screen empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No custom workouts yet'), findsOneWidget);
    expect(find.text('Build your own workout with exercises from your library.'), findsWidgets);
    expect(find.text('Create workout'), findsOneWidget);
  });

  testWidgets('Workouts screen saved visible and newest ordering', (tester) async {
    final now = DateTime.now().toUtc();
    final t1 = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'Old Workout',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
    );
    final t2 = CustomWorkoutTemplate(
      id: 'custom_2_0',
      name: 'New Workout',
      targetDuration: WorkoutDuration.thirtyMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final storage = container.read(customWorkoutStorageProvider);
    await storage.saveAll([t1, t2]);

    await tester.pumpWidget(const ProviderScope(overrides: [], child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Should show both, newest first
    expect(find.text('New Workout'), findsOneWidget);
    expect(find.text('Old Workout'), findsOneWidget);
    // Check ordering: New Workout appears before Old Workout in widget tree
    final newOffset = tester.getTopLeft(find.text('New Workout')).dy;
    final oldOffset = tester.getTopLeft(find.text('Old Workout')).dy;
    expect(newOffset < oldOffset, true);
  });

  testWidgets('Workouts screen target duration visible', (tester) async {
    final now = DateTime.now().toUtc();
    final t = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'Duration Test',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_bodyweight', sets: 1, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
    );

    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(customWorkoutStorageProvider).saveAll([t]);

    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('15 minutes'), findsWidgets);
  });

  testWidgets('Workouts screen placeholders for Recommended and Programs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
  });

  testWidgets('Workouts screen 320px width no overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your workouts'), findsOneWidget);
    // No overflow exception means pass
  });

  testWidgets('Workouts screen text scale 1.5 no overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const FitFlowApp(),
        ),
      ),
    );
    await completeOnboardingToHome(tester);

    await tester.tap(find.text('Workouts'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your workouts'), findsOneWidget);
  });
}
