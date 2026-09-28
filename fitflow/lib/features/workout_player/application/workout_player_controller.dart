import 'dart:async';

import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/flutter_tts_workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_execution.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_engine.dart';
import 'package:fitflow/features/workout_player/domain/workout_replacement_option.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for WorkoutCoach abstraction.
final workoutCoachProvider = Provider<WorkoutCoach>((ref) {
  return FlutterTtsWorkoutCoach();
});

/// Dedicated testable controller for Workout Player with smart replacement.
class WorkoutPlayerController extends StateNotifier<WorkoutPlayerState> {
  WorkoutPlayerController({
    required WorkoutPlan plan,
    bool autoStartTimer = true,
    WorkoutCoach? coach,
    bool voiceEnabled = true,
    UserFitnessProfile? userProfile,
    CapabilityProfile? capabilityProfile,
    List<Exercise>? catalog,
  })  : _execution = WorkoutPlayerExecution(plan),
        _autoStartTimer = autoStartTimer,
        _coach = coach ?? NoOpWorkoutCoach(),
        _userProfile = userProfile,
        _capabilityProfile = capabilityProfile,
        _catalog = catalog ?? ExerciseCatalog.all,
        _replacements = {},
        super(_initialState(plan, voiceEnabled: voiceEnabled));

  final WorkoutPlayerExecution _execution;
  final bool _autoStartTimer;
  final WorkoutCoach _coach;
  final UserFitnessProfile? _userProfile;
  final CapabilityProfile? _capabilityProfile;
  final List<Exercise> _catalog;
  Timer? _timer;
  bool _isDisposed = false;
  bool _isCompleting = false;

  final Map<String, WorkoutExercisePrescription> _replacements;

  String _keyFor(int sectionIndex, int exerciseIndex) => '$sectionIndex-$exerciseIndex';

  WorkoutExercisePrescription _originalPrescriptionAt(int sectionIndex, int exerciseIndex) {
    return _execution.prescriptionAt(sectionIndex, exerciseIndex);
  }

  WorkoutExercisePrescription _effectivePrescriptionAt(int sectionIndex, int exerciseIndex) {
    final key = _keyFor(sectionIndex, exerciseIndex);
    return _replacements[key] ?? _originalPrescriptionAt(sectionIndex, exerciseIndex);
  }

  Set<String> _effectiveIdsExcluding(int currentSection, int currentExercise) {
    final ids = <String>{};
    for (int s = 0; s < _execution.sectionCount; s++) {
      final count = _execution.exerciseCountInSection(s);
      for (int e = 0; e < count; e++) {
        if (s == currentSection && e == currentExercise) continue;
        final pres = _effectivePrescriptionAt(s, e);
        ids.add(pres.exercise.id);
      }
    }
    return ids;
  }

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

  void _speak(String message) {
    if (!state.voiceEnabled) return;
    if (message.trim().isEmpty) return;
    try {
      final future = _coach.speak(message);
      // ignore: discarded_futures
      future.then((_) {}, onError: (_) {});
    } catch (_) {}
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
      return state.currentPrescription.exercise.name;
    } catch (_) {
      return 'exercise';
    }
  }

  // --- Replacement API ---

  bool get canReplaceCurrentExercise {
    if (_isDisposed) return false;
    if (state.phase == WorkoutPlayerPhase.completed) return false;
    if (state.phase == WorkoutPlayerPhase.rest ||
        state.phase == WorkoutPlayerPhase.transition ||
        state.phase == WorkoutPlayerPhase.sectionBreak) {
      return false;
    }
    if (state.phase == WorkoutPlayerPhase.ready) return true;
    final effectivePhase = state.isPaused ? state.previousPhaseBeforePause : state.phase;
    if (effectivePhase == WorkoutPlayerPhase.work) {
      return state.setNumber == 1;
    }
    if (state.isPaused && state.previousPhaseBeforePause == WorkoutPlayerPhase.work) {
      return state.setNumber == 1;
    }
    return false;
  }

  List<WorkoutReplacementOption> getReplacementOptions() {
    if (_userProfile == null || _capabilityProfile == null) return const [];
    if (!canReplaceCurrentExercise) return const [];

    final eligibilityContext = ExerciseEligibilityContext.fromProfiles(
      userProfile: _userProfile!,
      capabilityProfile: _capabilityProfile!,
    );

    final effectiveElsewhere = _effectiveIdsExcluding(state.sectionIndex, state.exerciseIndex);

    return WorkoutReplacementEngine.getAlternatives(
      currentPrescription: state.currentPrescription,
      eligibilityContext: eligibilityContext,
      userProfile: _userProfile!,
      capabilityProfile: _capabilityProfile!,
      effectiveExerciseIdsElsewhere: effectiveElsewhere,
      catalog: _catalog,
      maxOptions: 3,
    );
  }

  bool replaceCurrentExercise(WorkoutReplacementOption option) {
    if (_isDisposed) return false;
    if (!canReplaceCurrentExercise) return false;

    final current = state.currentPrescription;
    if (option.exercise.id == current.exercise.id) return false;
    if (option.exercise.movementPattern != current.exercise.movementPattern) return false;
    if (option.exercise.exerciseType != current.exercise.exerciseType) return false;

    final elsewhere = _effectiveIdsExcluding(state.sectionIndex, state.exerciseIndex);
    if (elsewhere.contains(option.exercise.id)) return false;

    if (_userProfile != null && _capabilityProfile != null) {
      final ctx = ExerciseEligibilityContext.fromProfiles(
        userProfile: _userProfile!,
        capabilityProfile: _capabilityProfile!,
      );
      final result = ExerciseEligibilityEngine.evaluate(option.exercise, ctx);
      if (!result.eligible) return false;
    }

    if (!option.prescription.isValid) return false;
    if (option.prescription.sets != current.sets) return false;
    if (option.prescription.repsPerSet != current.repsPerSet) return false;
    if (option.prescription.workDuration != current.workDuration) return false;
    if (option.prescription.restBetweenSets != current.restBetweenSets) return false;
    if (option.prescription.exercise.id != option.exercise.id) return false;

    final existingOriginalId = state.originalExerciseId;
    final existingOriginalName = state.originalExerciseName;
    final originalId = existingOriginalId ?? current.exercise.id;
    final originalName = existingOriginalName ?? current.exercise.name;

    final key = _keyFor(state.sectionIndex, state.exerciseIndex);
    _replacements[key] = option.prescription;

    final newRemaining = option.prescription.workDuration ?? Duration.zero;

    state = state.copyWith(
      currentPrescription: option.prescription,
      remaining: newRemaining,
      setNumber: 1,
      originalExerciseId: originalId,
      originalExerciseName: originalName,
      clearNextPrescription: true,
    );

    _speak('Switched to ${option.exercise.name}.');
    return true;
  }

  // --- Public API ---

  void beginWorkout() {
    if (_isDisposed) return;
    if (state.phase != WorkoutPlayerPhase.ready) return;
    if (state.isPaused) return;

    final remaining = state.currentPrescription.workDuration ?? Duration.zero;
    state = state.copyWith(
      phase: WorkoutPlayerPhase.work,
      remaining: remaining,
    );
    _maybeStartTimerForCurrentPhase();
    _speak('${_exerciseName()}. Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}.');
  }

  void completeSet() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.work) return;
    if (state.isTimedExercise) return;

    _completeCurrentWorkSet();
  }

  void skipRest() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.rest) return;

    _cancelTimer();
    _advanceToNextSetAfterRest();
  }

  void skipTransition() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.transition) return;

    _cancelTimer();
    _advanceToNextExerciseAfterTransition();
  }

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

    if (previous == WorkoutPlayerPhase.work && state.isTimedExercise) {
      _maybeStartTimerForCurrentPhase();
    } else if (previous == WorkoutPlayerPhase.rest || previous == WorkoutPlayerPhase.transition) {
      _maybeStartTimerForCurrentPhase();
    } else if (state.phase == WorkoutPlayerPhase.work && state.isTimedExercise) {
      _maybeStartTimerForCurrentPhase();
    }

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

  @visibleForTesting
  void tick() {
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (state.phase != WorkoutPlayerPhase.work &&
        state.phase != WorkoutPlayerPhase.rest &&
        state.phase != WorkoutPlayerPhase.transition) {
      return;
    }

    if (_isCompleting) return;

    final newRemaining = state.remaining - const Duration(seconds: 1);
    if (newRemaining <= Duration.zero) {
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

  void _maybeStartTimerForCurrentPhase() {
    _cancelTimer();
    if (_isDisposed) return;
    if (state.isPaused) return;
    if (!_autoStartTimer) return;

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

  void _completeCurrentWorkSet() {
    _cancelTimer();
    if (_isDisposed) return;

    final newCompleted = state.completedSets + 1;

    final isLastSetOfCurrentExercise = state.isLastSetOfExercise;
    final isLastExerciseInSection = state.isLastExerciseInSection;
    final isLastSection = state.isLastSection;

    if (!isLastSetOfCurrentExercise) {
      final restDuration = state.currentPrescription.restBetweenSets;
      if (restDuration <= Duration.zero) {
        state = state.copyWith(
          completedSets: newCompleted,
          setNumber: state.setNumber + 1,
          phase: WorkoutPlayerPhase.work,
          remaining: state.currentPrescription.workDuration ?? Duration.zero,
        );
        _maybeStartTimerForCurrentPhase();
        _speak('Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}.');
      } else {
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

    if (!isLastExerciseInSection) {
      final nextExerciseIndex = state.exerciseIndex + 1;
      final nextPrescription = _effectivePrescriptionAt(state.sectionIndex, nextExerciseIndex);
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

    if (!isLastSection) {
      final finishingSectionType = state.sectionType;
      state = state.copyWith(
        completedSets: newCompleted,
        phase: WorkoutPlayerPhase.sectionBreak,
        remaining: Duration.zero,
        clearNextPrescription: true,
      );
      if (finishingSectionType == WorkoutSectionType.warmup) {
        _speak('Warm-up complete. Main workout next.');
      } else if (finishingSectionType == WorkoutSectionType.main) {
        _speak('Main workout complete. Cooldown next.');
      }
      return;
    }

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
    final nextPrescription = _effectivePrescriptionAt(state.sectionIndex, nextExerciseIndex);

    state = state.copyWith(
      exerciseIndex: nextExerciseIndex,
      exerciseCountInCurrentSection: section.exerciseCount,
      isLastExerciseInSection: nextExerciseIndex >= section.exerciseCount - 1,
      setNumber: 1,
      phase: WorkoutPlayerPhase.work,
      remaining: nextPrescription.workDuration ?? Duration.zero,
      currentPrescription: nextPrescription,
      clearNextPrescription: true,
      clearOriginalExercise: true,
    );
    _maybeStartTimerForCurrentPhase();
    final name = nextPrescription.exercise.name;
    _speak('$name. Set 1 of ${nextPrescription.sets}.');
  }

  void _advanceToNextSection() {
    if (_isDisposed) return;
    final nextSectionIndex = state.sectionIndex + 1;
    if (nextSectionIndex >= _execution.sectionCount) {
      state = state.copyWith(
        phase: WorkoutPlayerPhase.completed,
        remaining: Duration.zero,
      );
      _speak('Workout complete.');
      return;
    }

    final nextSection = _execution.sectionAt(nextSectionIndex);
    final nextPrescription = _effectivePrescriptionAt(nextSectionIndex, 0);
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
      clearOriginalExercise: true,
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
  final userProfile = ref.watch(userFitnessProfileProvider).value;
  final capProfile = ref.watch(capabilityProfileProvider).value;
  return WorkoutPlayerController(
    plan: plan,
    coach: coach,
    userProfile: userProfile,
    capabilityProfile: capProfile,
  );
});

/// For tests that need to inject a fake coach and control autoStart.
final workoutPlayerWithCoachProvider = StateNotifierProvider.autoDispose
    .family<WorkoutPlayerController, WorkoutPlayerState, ({WorkoutPlan plan, WorkoutCoach coach, bool autoStartTimer})>(
        (ref, args) {
  return WorkoutPlayerController(
    plan: args.plan,
    coach: args.coach,
    autoStartTimer: args.autoStartTimer,
  );
});

/// For tests with full profile injection.
final workoutPlayerWithProfilesProvider = StateNotifierProvider.autoDispose
    .family<WorkoutPlayerController, WorkoutPlayerState,
        ({WorkoutPlan plan, WorkoutCoach coach, bool autoStartTimer, UserFitnessProfile userProfile, CapabilityProfile capabilityProfile, List<Exercise> catalog})>(
        (ref, args) {
  return WorkoutPlayerController(
    plan: args.plan,
    coach: args.coach,
    autoStartTimer: args.autoStartTimer,
    userProfile: args.userProfile,
    capabilityProfile: args.capabilityProfile,
    catalog: args.catalog,
  );
});
