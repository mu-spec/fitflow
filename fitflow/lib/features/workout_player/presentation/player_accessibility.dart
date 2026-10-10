import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';

/// Phase-level announcement. Intentionally omits the countdown so TalkBack
/// is not spammed every second. Timer values are exposed separately and are
/// not live regions.
String playerPhaseAnnouncement(WorkoutPlayerState state,
    [AppLocalizations? localization]) {
  final l = localization ?? AppLocalizationsEn();
  final name = state.currentPrescription.exercise.name;
  final section = sectionLabel(l, state.sectionType);
  final paused = state.isPaused ? l.flowPausedPrefix : '';
  switch (state.phase) {
    case WorkoutPlayerPhase.ready:
      return l.flowReadyAnnouncement(section, name);
    case WorkoutPlayerPhase.work:
      final target = state.isRepsExercise
          ? l.flowReps(state.currentPrescription.repsPerSet!)
          : l.flowTimedWork;
      return l.flowWorkAnnouncement(paused, section, name, state.setNumber,
          state.totalSetsForCurrentExercise, target);
    case WorkoutPlayerPhase.rest:
      return l.flowRestAnnouncement(paused, name);
    case WorkoutPlayerPhase.transition:
      return l.flowNextAnnouncement(
          paused, state.nextPrescription?.exercise.name ?? l.flowNextFallback);
    case WorkoutPlayerPhase.sectionBreak:
      return l.flowSectionComplete;
    case WorkoutPlayerPhase.completed:
      return l.flowCompleteAnnouncement;
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
