import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/material.dart';

/// Phase-level announcement. Intentionally omits the countdown so TalkBack
/// is not spammed every second. Timer values are exposed separately and are
/// not live regions.
String playerPhaseAnnouncement(WorkoutPlayerState state) {
  final name = state.currentPrescription.exercise.name;
  final section = switch (state.sectionType) {
    WorkoutSectionType.warmup => 'Warm-up',
    WorkoutSectionType.main => 'Main workout',
    WorkoutSectionType.cooldown => 'Cooldown',
  };
  final paused = state.isPaused ? 'Paused. ' : '';
  switch (state.phase) {
    case WorkoutPlayerPhase.ready:
      return 'Ready. $section. $name.';
    case WorkoutPlayerPhase.work:
      final target = state.isRepsExercise
          ? '${state.currentPrescription.repsPerSet} reps'
          : 'Timed work';
      return '$paused$section. $name. Set ${state.setNumber} of ${state.totalSetsForCurrentExercise}. $target.';
    case WorkoutPlayerPhase.rest:
      return '${paused}Rest. $name.';
    case WorkoutPlayerPhase.transition:
      final next = state.nextPrescription?.exercise.name ?? 'the next exercise';
      return '${paused}Next exercise. $next.';
    case WorkoutPlayerPhase.sectionBreak:
      return 'Section complete.';
    case WorkoutPlayerPhase.completed:
      return 'Workout complete.';
  }
}

/// Announces meaningful phase changes only. Rebuilds during a countdown do
/// not change [message], so they are not new live-region events.
class PlayerPhaseAnnouncement extends StatelessWidget {
  const PlayerPhaseAnnouncement({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: const SizedBox.shrink(),
    );
  }
}

/// Timer value available on focus. Not a live region.
class PlayerTimerSemantics extends StatelessWidget {
  const PlayerTimerSemantics({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: false,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}
