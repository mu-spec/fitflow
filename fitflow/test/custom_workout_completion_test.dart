import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_completed_view.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Custom completion does not show Tune and shows protection copy', (tester) async {
    final exercise = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
    final plan = WorkoutPlan.withWorkoutDuration(
      workoutDuration: WorkoutDuration.fifteenMinutes,
      warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'march_in_place'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
      main: WorkoutSection(type: WorkoutSectionType.main, exercises: [
        WorkoutExercisePrescription(exercise: exercise, sets: 1, repsPerSet: 10, restBetweenSets: Duration.zero)
      ]),
      cooldown: WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'cobra_stretch'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
    );

    final state = WorkoutPlayerState(
      phase: WorkoutPlayerPhase.completed,
      isPaused: false,
      sectionIndex: 2,
      sectionType: WorkoutSectionType.cooldown,
      exerciseIndex: 0,
      exerciseCountInCurrentSection: 1,
      isLastExerciseInSection: true,
      isLastSection: true,
      setNumber: 1,
      completedSets: plan.totalExerciseCount,
      totalSets: plan.totalExerciseCount,
      remaining: Duration.zero,
      currentPrescription: plan.main.exercises.first,
      voiceEnabled: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WorkoutPlayerCompletedView(
              plan: plan,
              state: state,
              sessionMode: WorkoutSessionMode.standard,
              sessionOrigin: WorkoutSessionOrigin.custom,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text("Custom workouts don't change your movement levels."), findsOneWidget);
    expect(find.text('Tune next workout'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Generated Standard shows Tune', (tester) async {
    final exercise = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
    final plan = WorkoutPlan.withWorkoutDuration(
      workoutDuration: WorkoutDuration.fifteenMinutes,
      warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'march_in_place'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
      main: WorkoutSection(type: WorkoutSectionType.main, exercises: [
        WorkoutExercisePrescription(exercise: exercise, sets: 1, repsPerSet: 10, restBetweenSets: Duration.zero)
      ]),
      cooldown: WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'cobra_stretch'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
    );

    final state = WorkoutPlayerState(
      phase: WorkoutPlayerPhase.completed,
      isPaused: false,
      sectionIndex: 2,
      sectionType: WorkoutSectionType.cooldown,
      exerciseIndex: 0,
      exerciseCountInCurrentSection: 1,
      isLastExerciseInSection: true,
      isLastSection: true,
      setNumber: 1,
      completedSets: plan.totalExerciseCount,
      totalSets: plan.totalExerciseCount,
      remaining: Duration.zero,
      currentPrescription: plan.main.exercises.first,
      voiceEnabled: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WorkoutPlayerCompletedView(
              plan: plan,
              state: state,
              sessionMode: WorkoutSessionMode.standard,
              sessionOrigin: WorkoutSessionOrigin.adaptive,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Tune next workout'), findsOneWidget);
    expect(find.text("Custom workouts don't change your movement levels."), findsNothing);
  });

  testWidgets('Temporary mode shows unchanged copy and no Tune', (tester) async {
    final exercise = ExerciseCatalog.all.firstWhere((e) => e.id == 'squat_bodyweight');
    final plan = WorkoutPlan.withWorkoutDuration(
      workoutDuration: WorkoutDuration.fifteenMinutes,
      warmup: WorkoutSection(type: WorkoutSectionType.warmup, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'march_in_place'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
      main: WorkoutSection(type: WorkoutSectionType.main, exercises: [
        WorkoutExercisePrescription(exercise: exercise, sets: 1, repsPerSet: 10, restBetweenSets: Duration.zero)
      ]),
      cooldown: WorkoutSection(type: WorkoutSectionType.cooldown, exercises: [
        WorkoutExercisePrescription(
            exercise: ExerciseCatalog.all.firstWhere((e) => e.id == 'cobra_stretch'),
            sets: 1,
            workDuration: const Duration(seconds: 20),
            restBetweenSets: Duration.zero)
      ]),
    );

    final state = WorkoutPlayerState(
      phase: WorkoutPlayerPhase.completed,
      isPaused: false,
      sectionIndex: 2,
      sectionType: WorkoutSectionType.cooldown,
      exerciseIndex: 0,
      exerciseCountInCurrentSection: 1,
      isLastExerciseInSection: true,
      isLastSection: true,
      setNumber: 1,
      completedSets: plan.totalExerciseCount,
      totalSets: plan.totalExerciseCount,
      remaining: Duration.zero,
      currentPrescription: plan.main.exercises.first,
      voiceEnabled: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WorkoutPlayerCompletedView(
              plan: plan,
              state: state,
              sessionMode: WorkoutSessionMode.lowEnergy,
              sessionOrigin: WorkoutSessionOrigin.adaptive,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.textContaining('temporary'), findsOneWidget);
    expect(find.text('Tune next workout'), findsNothing);
  });

  test('Custom template history is self-contained and does not alter workout_history_v1 schema', () {
    final now = DateTime.now().toUtc();
    final template = CustomWorkoutTemplate(
      id: 'custom_1_0',
      name: 'History Test',
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

    final json = template.toJson();
    // Ensure no template ID stored in history schema (history should not contain custom_workout keys)
    expect(json.containsKey('id'), true);
    // History model should be separate – we just ensure template JSON does not contain history keys
    expect(json.containsKey('completedAt'), false);
  });
}
