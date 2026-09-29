import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutSessionModeController', () {
    test('default is standard', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final mode = container.read(workoutSessionModeProvider);
      expect(mode, WorkoutSessionMode.standard);
    });

    test('select low energy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.lowEnergy);
    });

    test('select comeback', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.comeback);
    });

    test('reset returns to standard', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.lowEnergy);
      container.read(workoutSessionModeProvider.notifier).reset();
      expect(container.read(workoutSessionModeProvider), WorkoutSessionMode.standard);
    });

    test('no persistence across container recreation (session-only)', () {
      final container1 = ProviderContainer();
      container1.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
      expect(container1.read(workoutSessionModeProvider), WorkoutSessionMode.comeback);
      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      expect(container2.read(workoutSessionModeProvider), WorkoutSessionMode.standard, reason: 'Should not persist');
    });

    test('labels correct', () {
      expect(WorkoutSessionMode.standard.label, 'Standard');
      expect(WorkoutSessionMode.lowEnergy.label, 'Low Energy');
      expect(WorkoutSessionMode.comeback.label, 'Comeback');
    });

    test('descriptions present', () {
      expect(WorkoutSessionMode.standard.description, isNotEmpty);
      expect(WorkoutSessionMode.lowEnergy.description, isNotEmpty);
      expect(WorkoutSessionMode.comeback.description, isNotEmpty);
    });

    test('supporting notes for temp modes', () {
      expect(WorkoutSessionMode.lowEnergy.supportingNote, isNotNull);
      expect(WorkoutSessionMode.comeback.supportingNote, isNotNull);
      expect(WorkoutSessionMode.standard.supportingNote, isNull);
    });
  });
}
