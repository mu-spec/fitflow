import 'dart:async';

import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_execution.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedicated testable controller for Workout Player.
/// Owns single timer, prevents overlapping timers, duplicate advancement, negative time.
class WorkoutPlayerController extends StateNotifier<WorkoutPlayerState> {
  WorkoutPlayerController({
    required WorkoutPlan plan,
    bool autoStartTimer = true,
  })  : _execution = WorkoutPlayerExecution(plan),
        _autoStartTimer = autoStartTimer,
        super(_initialState(plan)) {
    // No timer in ready state.
  }

  final WorkoutPlayerExecution _execution;
  final bool _autoStartTimer;
  Timer? _timer;
  bool _isDisposed = false;
  bool _isCompleting = false; // prevent duplicate zero advancement

  static WorkoutPlayerState _initialState(WorkoutPlan plan) {
    final execution = WorkoutPlayerExecution(plan);
    final firstSection = execution.sectionAt(0);
    final firstPrescription = firstSection.exercises.first;
    final totalSets = execution.totalSets;
    return WorkoutPlayerState(
      phase: WorkoutPlayerPhase.ready,
      isPaused: false,
      sectionIndex: 0,
      sectionType: WorkoutSectionType.warmup,
      exerciseIndex: 0,
      exerciseCountInCurrentSection: firstSection.exerciseCount,
      isLastExerciseInSection: firstSection.exerciseCount == 1,
      isLastSection: false,
      setNumber: 1,
      completedSets: 0,
      totalSets: totalSets,
      remaining: firstPrescription.workDuration ?? Duration.zero,
      currentPrescription: firstPrescription,
      nextPrescription: null,
    );
  }

  // --- Public API ---

  void beginWorkout() {
    if (_isDisposed) return;
    if (state.phase != WorkoutPlayerPhase.ready) return;
    if (state.isPaused) return;

    // Transition to work phase for first set
    final remaining = state.currentPrescription.workDuration ?? Duration.zero;
    state = state.copyWith(
      phase: WorkoutPlayerPhase.work,
      remaining: remaining,
    );
    _maybeStartTimerForCurrentPhase();
  }

  /// For reps exercises, user taps Set complete.
  void completeSet() {
    if (_isDisposed) return;
    if (state.isPaused) return; // prevent accidental advancement when paused
    if (state.phase != WorkoutPlayerPhase.work) return;
    if (state.isTimedExercise) return; // timed auto-completes, not manual

    _completeCurrentWorkSet();
  }

  /// Skip rest phase.
  void skipRest() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.rest) return;

    _cancelTimer();
    _advanceToNextSetAfterRest();
  }

  /// Skip transition phase.
  void skipTransition() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.transition) return;

    _cancelTimer();
    _advanceToNextExerciseAfterTransition();
  }

  /// Continue from section break (manual untimed).
  void continueSection() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.sectionBreak) return;

    _advanceToNextSection();
  }

  void pause() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase == WorkoutPlayerPhase.ready ||
        state.phase == WorkoutPlayerPhase.sectionBreak ||
        state.phase == WorkoutPlayerPhase.completed) {
      // No need to pause in these manual phases, but allow pausing to prevent accidental taps?
      // For simplicity, allow pause only in work/rest/transition.
      if (state.phase == WorkoutPlayerPhase.ready ||
          state.phase == WorkoutPlayerPhase.sectionBreak ||
          state.phase == WorkoutPlayerPhase.completed) {
        return;
      }
    }

    _cancelTimer();
    state = state.copyWith(
      isPaused: true,
      previousPhaseBeforePause: state.phase,
    );
  }

  void resume() {
    if (_isDisposed) return;
    if (!state.isPaused) return;

    final previous = state.previousPhaseBeforePause;
    state = state.copyWith(
      isPaused: false,
      clearPreviousPhaseBeforePause: true,
    );

    // Resume timer if previous phase was timed
    if (previous == WorkoutPlayerPhase.work && state.isTimedExercise) {
      _maybeStartTimerForCurrentPhase();
    } else if (previous == WorkoutPlayerPhase.rest || previous == WorkoutPlayerPhase.transition) {
      _maybeStartTimerForCurrentPhase();
    } else if (state.phase == WorkoutPlayerPhase.work && state.isTimedExercise) {
      // Fallback
      _maybeStartTimerForCurrentPhase();
    }
  }

  /// For tests: manually tick one second.
  @visibleForTesting
  void tick() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.work &&
        state.phase != WorkoutPlayerPhase.rest &&
        state.phase != WorkoutPlayerPhase.transition) {
      return;
    }

    if (_isCompleting) return; // prevent duplicate advancement

    final newRemaining = state.remaining - const Duration(seconds: 1);
    if (newRemaining <= Duration.zero) {
      // Clamp to zero, never negative
      state = state.copyWith(remaining: Duration.zero);
      _handleTimerZero();
    } else {
      state = state.copyWith(remaining: newRemaining);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelTimer();
    super.dispose();
  }

  // --- Internal timer handling ---

  void _maybeStartTimerForCurrentPhase() {
    _cancelTimer();
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (!_autoStartTimer) return; // for tests that want manual ticking

    Duration? durationToTrack;
    switch (state.phase) {
      case WorkoutPlayerPhase.work:
        if (state.isTimedExercise) {
          durationToTrack = state.remaining;
        }
        break;
      case WorkoutPlayerPhase.rest:
        durationToTrack = state.remaining;
        break;
      case WorkoutPlayerPhase.transition:
        durationToTrack = state.remaining;
        break;
      case WorkoutPlayerPhase.ready:
      case WorkoutPlayerPhase.sectionBreak:
      case WorkoutPlayerPhase.completed:
        durationToTrack = null;
        break;
    }

    if (durationToTrack == null) return;
    if (durationToTrack <= Duration.zero) {
      // Zero duration: advance immediately (e.g., zero rest)
      // Use microtask to avoid re-entrancy
      Future.microtask(() {
        if (_isDisposed) return;
        if (state.isPaused) return;
        _handleTimerZero();
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      tick();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTimerZero() {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      switch (state.phase) {
        case WorkoutPlayerPhase.work:
          // Timed work completed
          _completeCurrentWorkSet();
          break;
        case WorkoutPlayerPhase.rest:
          _advanceToNextSetAfterRest();
          break;
        case WorkoutPlayerPhase.transition:
          _advanceToNextExerciseAfterTransition();
          break;
        case WorkoutPlayerPhase.ready:
        case WorkoutPlayerPhase.sectionBreak:
        case WorkoutPlayerPhase.completed:
          break;
      }
    } finally {
      _isCompleting = false;
    }
  }

  // --- Core progression logic ---

  void _completeCurrentWorkSet() {
    _cancelTimer();
    if (_isDisposed) return;

    final newCompleted = state.completedSets + 1;

    // Check if this was final set of whole workout
    final isLastSetOfCurrentExercise = state.isLastSetOfExercise;
    final isLastExerciseInSection = state.isLastExerciseInSection;
    final isLastSection = state.isLastSection;

    // If there are more sets in same exercise
    if (!isLastSetOfCurrentExercise) {
      // Need rest between sets
      final restDuration = state.currentPrescription.restBetweenSets;
      if (restDuration <= Duration.zero) {
        // Zero rest advances immediately to next set
        state = state.copyWith(
          completedSets: newCompleted,
          setNumber: state.setNumber + 1,
          phase: WorkoutPlayerPhase.work,
          remaining: state.currentPrescription.workDuration ?? Duration.zero,
        );
        _maybeStartTimerForCurrentPhase();
      } else {
        // Enter rest phase
        state = state.copyWith(
          completedSets: newCompleted,
          phase: WorkoutPlayerPhase.rest,
          remaining: restDuration,
        );
        _maybeStartTimerForCurrentPhase();
      }
      return;
    }

    // Last set of this exercise completed
    // Check if there are more exercises in same section
    if (!isLastExerciseInSection) {
      // Transition to next exercise in same section (15 sec)
      final nextExerciseIndex = state.exerciseIndex + 1;
      final nextPrescription = _execution.prescriptionAt(state.sectionIndex, nextExerciseIndex);
      state = state.copyWith(
        completedSets: newCompleted,
        phase: WorkoutPlayerPhase.transition,
        remaining: WorkoutTimeEstimator.transitionBetweenExercises,
        nextPrescription: nextPrescription,
      );
      _maybeStartTimerForCurrentPhase();
      return;
    }

    // Last exercise of section completed
    if (!isLastSection) {
      // Section break manual
      state = state.copyWith(
        completedSets: newCompleted,
        phase: WorkoutPlayerPhase.sectionBreak,
        remaining: Duration.zero,
        clearNextPrescription: true,
      );
      // No timer for section break
      return;
    }

    // Last section (cooldown) last exercise last set → completed
    state = state.copyWith(
      completedSets: newCompleted,
      phase: WorkoutPlayerPhase.completed,
      remaining: Duration.zero,
      clearNextPrescription: true,
    );
  }

  void _advanceToNextSetAfterRest() {
    if (_isDisposed) return;
    // Move to next set of same exercise
    state = state.copyWith(
      setNumber: state.setNumber + 1,
      phase: WorkoutPlayerPhase.work,
      remaining: state.currentPrescription.workDuration ?? Duration.zero,
    );
    _maybeStartTimerForCurrentPhase();
  }

  void _advanceToNextExerciseAfterTransition() {
    if (_isDisposed) return;
    final nextExerciseIndex = state.exerciseIndex + 1;
    final section = _execution.sectionAt(state.sectionIndex);
    final nextPrescription = _execution.prescriptionAt(state.sectionIndex, nextExerciseIndex);

    state = state.copyWith(
      exerciseIndex: nextExerciseIndex,
      exerciseCountInCurrentSection: section.exerciseCount,
      isLastExerciseInSection: nextExerciseIndex >= section.exerciseCount - 1,
      setNumber: 1,
      phase: WorkoutPlayerPhase.work,
      remaining: nextPrescription.workDuration ?? Duration.zero,
      currentPrescription: nextPrescription,
      clearNextPrescription: true,
    );
    _maybeStartTimerForCurrentPhase();
  }

  void _advanceToNextSection() {
    if (_isDisposed) return;
    final nextSectionIndex = state.sectionIndex + 1;
    if (nextSectionIndex >= _execution.sectionCount) {
      // Should not happen, but complete
      state = state.copyWith(
        phase: WorkoutPlayerPhase.completed,
        remaining: Duration.zero,
      );
      return;
    }

    final nextSection = _execution.sectionAt(nextSectionIndex);
    final nextPrescription = nextSection.exercises.first;
    final sectionType = _execution.sectionTypeAt(nextSectionIndex);

    state = state.copyWith(
      sectionIndex: nextSectionIndex,
      sectionType: sectionType,
      exerciseIndex: 0,
      exerciseCountInCurrentSection: nextSection.exerciseCount,
      isLastExerciseInSection: nextSection.exerciseCount == 1,
      isLastSection: nextSectionIndex >= _execution.sectionCount - 1,
      setNumber: 1,
      phase: WorkoutPlayerPhase.work,
      remaining: nextPrescription.workDuration ?? Duration.zero,
      currentPrescription: nextPrescription,
      clearNextPrescription: true,
    );
    _maybeStartTimerForCurrentPhase();
  }
}

/// Provider for controller, family with WorkoutPlan.
final workoutPlayerControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkoutPlayerController, WorkoutPlayerState, WorkoutPlan>((ref, plan) {
  return WorkoutPlayerController(plan: plan);
});
