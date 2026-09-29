import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Small Riverpod controller for session-only mode, no persistence.
class WorkoutSessionModeController extends StateNotifier<WorkoutSessionMode> {
  WorkoutSessionModeController() : super(WorkoutSessionMode.standard);

  void selectMode(WorkoutSessionMode mode) {
    state = mode;
  }

  void reset() {
    state = WorkoutSessionMode.standard;
  }
}

final workoutSessionModeProvider = StateNotifierProvider<WorkoutSessionModeController, WorkoutSessionMode>(
  (ref) => WorkoutSessionModeController(),
);
