import 'pushup_lottie_demonstration.dart';

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
    final target = prescription.repsPerSet != null
        ? l.flowReps(prescription.repsPerSet!)
        : '${prescription.workDuration!.inSeconds} ${l.flowSeconds}';
    final setLabel = rest
        ? l.flowNextSet(state.setNumber + 1, prescription.sets)
        : l.flowSet(transition ? 1 : state.setNumber, prescription.sets);
    return Column(
      key: const ValueKey('v2_player_focus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true,
            child: Text(prescription.exercise.name,
                style: text.titleLarge
                    ?.copyWith(fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(height: 2),
        Text(ready ? workloadLabel(l, prescription) : '$setLabel · $target',
            key: const ValueKey('player_prescription'), style: text.bodySmall),
        if (!transition &&
            state.isCurrentReplaced &&
            state.originalExerciseName != null)
          Text(l.flowReplaced(state.originalExerciseName!),
              style: text.bodySmall),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(0.0, mediaHeight * 4 / 3);
          return Center(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: prescription.exercise.id == 'pushup_standard' &&
                    !MediaQuery.disableAnimationsOf(context)
                ? PushupLottieDemonstration(
                    key: const ValueKey('v2_player_media'),
                    width: width,
                    height: width * 3 / 4,
                    animate:
                        (ready || state.phase == WorkoutPlayerPhase.work) &&
                            !state.isPaused)
                : FitFlowExerciseImage.hero(
                    // The former march pilot was still during Ready. Keep
                    // that behavior when using the shared athlete asset.
                    animate: ((ready &&
                                prescription.exercise.id != 'march_in_place') ||
                            state.phase == WorkoutPlayerPhase.work) &&
                        !state.isPaused,
                    key: const ValueKey('v2_player_media'),
                    exerciseId: prescription.exercise.id,
                    width: width,
                    height: width * 3 / 4,
                  ),
          ));
        }),
        const SizedBox(height: 16),
        // Purely reflects controller state; pause leaves remaining and progress frozen.
        if (ready)
          Text('Ready to begin?',
              key: const ValueKey('player_ready_title'),
              style: text.headlineSmall,
              textAlign: TextAlign.center)
        else if (timed)
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
        const SizedBox(height: 4),
        if (!ready)
          Text(state.isPaused ? l.flowPaused : phaseLabel,
              style: text.labelMedium, textAlign: TextAlign.center),
      ],
    );
  }
}
