import 'dart:async';

import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/flutter_tts_workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_execution.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for WorkoutCoach abstraction.
/// Production returns FlutterTtsWorkoutCoach, tests override with Fake/NoOp.
final workoutCoachProvider = Provider<WorkoutCoach>((ref) {
  return FlutterTtsWorkoutCoach();
});

/// Dedicated testable controller for Workout Player.
/// Owns single timer, prevents overlapping timers, duplicate advancement, negative time.
/// Voice coaching is side-effect only, never blocks progression.
class WorkoutPlayerController extends StateNotifier<WorkoutPlayerState> {
  WorkoutPlayerController({
    required WorkoutPlan plan,
    bool autoStartTimer = true,
    WorkoutCoach? coach,
    bool voiceEnabled = true,
  })  : _execution = WorkoutPlayerExecution(plan),
        _autoStartTimer = autoStartTimer,
        _coach = coach ?? NoOpWorkoutCoach(),
        super(_initialState(plan, voiceEnabled: voiceEnabled)) {
    // No timer in ready state.
  }

  final WorkoutPlayerExecution _execution;
  final bool _autoStartTimer;
  final WorkoutCoach _coach;
  Timer? _timer;
  bool _isDisposed = false;
  bool _isCompleting = false; // prevent duplicate zero advancement

  static WorkoutPlayerState _initialState(WorkoutPlan plan, {bool voiceEnabled = true}) {
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
      voiceEnabled: voiceEnabled,
    );
  }

  // --- Voice helpers ---

  void _speak(String message) {
    if (!state.voiceEnabled) return;
    if (message.trim().isEmpty) return;
    // Best-effort, never throw, never block progression
    try {
      final future = _coach.speak(message);
      // ignore: discarded_futures
      future.then((_) {}, onError: (_) {});
    } catch (_) {
      // Sync throw safety
    }
  }

  void _stopVoice() {
    try {
      final future = _coach.stop();
      // ignore: discarded_futures
      future.then((_) {}, onError: (_) {});
    } catch (_) {}
  }

  String _exerciseName() {
    try {
      final ex = state.currentPrescription;
      return ex.exercise.name;
    } catch (_) {
      return 'exercise';
    }
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
    // Voice cue: first exercise
    _speak('${_exerciseName()}. Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}.');
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
      return;
    }

    _cancelTimer();
    _stopVoice();
    state = state.copyWith(
      isPaused: true,
      previousPhaseBeforePause: state.phase,
    );
  }

  void pauseForLifecycle() {
    // Same as pause but called from AppLifecycleListener
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.work &&
        state.phase != WorkoutPlayerPhase.rest &&
        state.phase != WorkoutPlayerPhase.transition) {
      return;
    }
    _cancelTimer();
    _stopVoice();
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

    // Optional concise resume cue (no replay of half sentence)
    if (state.phase == WorkoutPlayerPhase.work) {
      _speak('Resuming.');
    }
  }

  void toggleVoice() {
    if (_isDisposed) return;
    final newEnabled = !state.voiceEnabled;
    state = state.copyWith(voiceEnabled: newEnabled);
    if (!newEnabled) {
      _stopVoice();
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
    _stopVoice();
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
        _speak('Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}.');
      } else {
        // Enter rest phase
        state = state.copyWith(
          completedSets: newCompleted,
          phase: WorkoutPlayerPhase.rest,
          remaining: restDuration,
        );
        _maybeStartTimerForCurrentPhase();
        _speak('Rest for ${restDuration.inSeconds} seconds.');
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
      final upcomingName = nextPrescription.exercise.name;
      _speak('Next, $upcomingName.');
      return;
    }

    // Last exercise of section completed
    if (!isLastSection) {
      // Section break manual
      final finishingSectionType = state.sectionType;
      state = state.copyWith(
        completedSets: newCompleted,
        phase: WorkoutPlayerPhase.sectionBreak,
        remaining: Duration.zero,
        clearNextPrescription: true,
      );
      // Voice cue for section completion
      if (finishingSectionType == WorkoutSectionType.warmup) {
        _speak('Warm-up complete. Main workout next.');
      } else if (finishingSectionType == WorkoutSectionType.main) {
        _speak('Main workout complete. Cooldown next.');
      }
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
    _speak('Workout complete.');
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
    _speak('Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}.');
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
    final name = nextPrescription.exercise.name;
    _speak('$name. Set 1 of ${nextPrescription.sets}.');
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
      _speak('Workout complete.');
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
    final name = nextPrescription.exercise.name;
    _speak('$name. Set 1 of ${nextPrescription.sets}.');
  }
}

/// Provider for controller, family with WorkoutPlan.
final workoutPlayerControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkoutPlayerController, WorkoutPlayerState, WorkoutPlan>((ref, plan) {
  final coach = ref.watch(workoutCoachProvider);
  return WorkoutPlayerController(plan: plan, coach: coach);
});

/// For tests that need to inject a fake coach and control voiceEnabled initial.
final workoutPlayerWithCoachProvider = StateNotifierProvider.autoDispose
    .family<WorkoutPlayerController, WorkoutPlayerState, ({WorkoutPlan plan, WorkoutCoach coach, bool autoStartTimer})>(
        (ref, args) {
  return WorkoutPlayerController(
    plan: args.plan,
    coach: args.coach,
    autoStartTimer: args.autoStartTimer,
  );
});
