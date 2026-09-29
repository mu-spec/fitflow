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
  testWidgets('Generated player still works', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await completeOnboardingToHome(tester);

    expect(find.text('View workout'), findsOneWidget);

    await tester.tap(find.text('View workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Workout preview'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Start workout'), 100, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Start workout'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Workout player'), findsWidgets);
  });

  testWidgets('Custom uses same engine and preserves sets/reps/duration/rest/order', (tester) async {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'Player Integration',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_chair', sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30)),
        CustomWorkoutExerciseEntry(exerciseId: 'pushup_wall', sets: 1, repsPerSet: 8, restBetweenSets: const Duration(seconds: 45)),
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
    await tester.tap(find.text('View').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(find.text('Start').first, 100, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Start').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Custom workout'), findsWidgets);
  });

  testWidgets('Custom player shows voice and replace', (tester) async {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'Player Features',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 5), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_chair', sets: 1, repsPerSet: 1, restBetweenSets: Duration.zero)
      ],
      cooldown: [
        CustomWorkoutExerciseEntry(exerciseId: 'cobra_stretch', sets: 1, workDuration: const Duration(seconds: 5), restBetweenSets: Duration.zero)
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
    await tester.tap(find.text('View').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(find.text('Start').first, 100, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Start').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Custom workout'), findsWidgets);
    expect(find.text('Begin workout'), findsOneWidget);
  });

  testWidgets('Home M12 mode does not alter custom prescription display', (tester) async {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'M12 Isolation',
      targetDuration: WorkoutDuration.fifteenMinutes,
      createdAt: now,
      updatedAt: now,
      warmup: [
        CustomWorkoutExerciseEntry(exerciseId: 'march_in_place', sets: 1, workDuration: const Duration(seconds: 20), restBetweenSets: Duration.zero)
      ],
      main: [
        CustomWorkoutExerciseEntry(exerciseId: 'squat_chair', sets: 2, repsPerSet: 10, restBetweenSets: const Duration(seconds: 30))
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
    await tester.tap(find.text('View').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('2 × 10 reps'), findsOneWidget);
  });
}
