import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';

/// Immutable state for Workout Player controller.
/// Keeps timer/state-machine logic out of widgets.
class WorkoutPlayerState {
  const WorkoutPlayerState({
    required this.phase,
    required this.isPaused,
    required this.sectionIndex,
    required this.sectionType,
    required this.exerciseIndex,
    required this.exerciseCountInCurrentSection,
    required this.isLastExerciseInSection,
    required this.isLastSection,
    required this.setNumber,
    required this.completedSets,
    required this.totalSets,
    required this.remaining,
    required this.currentPrescription,
    this.nextPrescription,
    this.previousPhaseBeforePause,
  });

  /// Current phase.
  final WorkoutPlayerPhase phase;

  /// Whether player is paused (timed work/rest/transition frozen).
  final bool isPaused;

  /// Section index 0=warmup,1=main,2=cooldown.
  final int sectionIndex;

  /// Section type for current section.
  final WorkoutSectionType sectionType;

  /// Exercise index inside current section (0-based).
  final int exerciseIndex;

  /// Exercise count in current section (for UI "Exercise X of Y").
  final int exerciseCountInCurrentSection;

  /// Whether current exercise is last in its section.
  final bool isLastExerciseInSection;

  /// Whether current section is last (cooldown).
  final bool isLastSection;

  /// Current set number (1-based) for current prescription.
  final int setNumber;

  /// Number of sets already completed in whole session.
  final int completedSets;

  /// Total session sets = sum of prescription.sets.
  final int totalSets;

  /// Remaining duration for timed work/rest/transition. Zero for reps work or ready/sectionBreak/completed.
  final Duration remaining;

  /// Current prescription being executed.
  final WorkoutExercisePrescription currentPrescription;

  /// Next prescription for transition UI, null otherwise.
  final WorkoutExercisePrescription? nextPrescription;

  /// When paused, remembers phase before pause to resume correctly.
  final WorkoutPlayerPhase? previousPhaseBeforePause;

  // --- Derived helpers ---

  int get totalSetsForCurrentExercise => currentPrescription.sets;

  bool get isLastSetOfExercise => setNumber >= currentPrescription.sets;

  bool get isFirstSetOfExercise => setNumber == 1;

  int get exercisePositionInSection => exerciseIndex + 1;

  bool get isRepsExercise => currentPrescription.repsPerSet != null;

  bool get isTimedExercise => currentPrescription.workDuration != null;

  double get progressFraction => totalSets == 0 ? 0 : completedSets / totalSets;

  String get progressLabel => '$completedSets / $totalSets sets';

  WorkoutPlayerState copyWith({
    WorkoutPlayerPhase? phase,
    bool? isPaused,
    int? sectionIndex,
    WorkoutSectionType? sectionType,
    int? exerciseIndex,
    int? exerciseCountInCurrentSection,
    bool? isLastExerciseInSection,
    bool? isLastSection,
    int? setNumber,
    int? completedSets,
    int? totalSets,
    Duration? remaining,
    WorkoutExercisePrescription? currentPrescription,
    WorkoutExercisePrescription? nextPrescription,
    bool clearNextPrescription = false,
    WorkoutPlayerPhase? previousPhaseBeforePause,
    bool clearPreviousPhaseBeforePause = false,
  }) {
    return WorkoutPlayerState(
      phase: phase ?? this.phase,
      isPaused: isPaused ?? this.isPaused,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      sectionType: sectionType ?? this.sectionType,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      exerciseCountInCurrentSection: exerciseCountInCurrentSection ?? this.exerciseCountInCurrentSection,
      isLastExerciseInSection: isLastExerciseInSection ?? this.isLastExerciseInSection,
      isLastSection: isLastSection ?? this.isLastSection,
      setNumber: setNumber ?? this.setNumber,
      completedSets: completedSets ?? this.completedSets,
      totalSets: totalSets ?? this.totalSets,
      remaining: remaining ?? this.remaining,
      currentPrescription: currentPrescription ?? this.currentPrescription,
      nextPrescription: clearNextPrescription ? null : (nextPrescription ?? this.nextPrescription),
      previousPhaseBeforePause: clearPreviousPhaseBeforePause
          ? null
          : (previousPhaseBeforePause ?? this.previousPhaseBeforePause),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPlayerState &&
        other.phase == phase &&
        other.isPaused == isPaused &&
        other.sectionIndex == sectionIndex &&
        other.sectionType == sectionType &&
        other.exerciseIndex == exerciseIndex &&
        other.exerciseCountInCurrentSection == exerciseCountInCurrentSection &&
        other.isLastExerciseInSection == isLastExerciseInSection &&
        other.isLastSection == isLastSection &&
        other.setNumber == setNumber &&
        other.completedSets == completedSets &&
        other.totalSets == totalSets &&
        other.remaining == remaining &&
        other.currentPrescription == currentPrescription &&
        other.nextPrescription == nextPrescription;
  }

  @override
  int get hashCode => Object.hash(
        phase,
        isPaused,
        sectionIndex,
        sectionType,
        exerciseIndex,
        exerciseCountInCurrentSection,
        isLastExerciseInSection,
        isLastSection,
        setNumber,
        completedSets,
        totalSets,
        remaining,
        currentPrescription,
        nextPrescription,
      );
}
