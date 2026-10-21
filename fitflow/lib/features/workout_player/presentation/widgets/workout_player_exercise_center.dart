import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Shared ready/work/rest/transition composition. No execution or timer ownership.
class WorkoutPlayerExerciseCenter extends StatelessWidget {
  const WorkoutPlayerExerciseCenter(
      {super.key, required this.state, this.mediaHeight = 240});
  final WorkoutPlayerState state;
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    final ready = state.phase == WorkoutPlayerPhase.ready;
    final rest = state.phase == WorkoutPlayerPhase.rest;
    final transition = state.phase == WorkoutPlayerPhase.transition;
    final prescription = transition
        ? state.nextPrescription ?? state.currentPrescription
        : state.currentPrescription;
    final remaining =
        ready ? prescription.workDuration ?? Duration.zero : state.remaining;
    final timed = rest || transition || prescription.workDuration != null;
    final phaseLabel = ready
        ? l.flowReady
        : rest
            ? l.flowRest
            : transition
                ? l.flowNext
                : l.flowWork;
    return Column(
      key: const ValueKey('v2_player_focus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true,
            child: Text(prescription.exercise.name,
                style: text.titleLarge
                    ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500))),
        const SizedBox(height: 2),
        Wrap(spacing: 8, runSpacing: 2, children: [
          if (!ready && !transition)
            Text(
                rest
                    ? l.flowNextSet(
                        state.setNumber + 1, state.totalSetsForCurrentExercise)
                    : l.flowSet(
                        state.setNumber, state.totalSetsForCurrentExercise),
                style: text.bodySmall),
          Text(workloadLabel(l, prescription), style: text.bodySmall),
        ]),
        if (!transition &&
            state.isCurrentReplaced &&
            state.originalExerciseName != null)
          Text(l.flowReplaced(state.originalExerciseName!),
              style: text.bodySmall),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, mediaHeight * 4 / 3);
          return Center(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FitFlowExerciseImage.hero(
              key: const ValueKey('v2_player_media'),
              exerciseId: prescription.exercise.id,
              width: width,
              height: width * 3 / 4,
            ),
          ));
        }),
        const SizedBox(height: 6),
        Text(equipmentSummary(l, prescription),
            style: text.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        // The same counter zone is retained on pause; only its state label changes.
        if (timed)
          WorkoutCountdown(
              remaining: remaining,
              semanticLabel: rest
                  ? l.flowRestRemaining(remaining.inSeconds)
                  : transition
                      ? l.flowTransitionRemaining(remaining.inSeconds)
                      : l.flowRemaining(remaining.inSeconds))
        else
          Text(l.flowReps(prescription.repsPerSet!),
              key: const ValueKey('player_rep_target'),
              style: text.displayMedium?.copyWith(fontSize: 40),
              textAlign: TextAlign.center),
        Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              if (timed)
                Text(rest ? l.flowRestSeconds : l.flowSeconds,
                    style: text.bodySmall),
              Text(state.isPaused ? l.flowPaused : phaseLabel,
                  style: text.labelMedium),
              if (state.isPaused) Text(phaseLabel, style: text.bodySmall),
            ]),
      ],
    );
  }
}
