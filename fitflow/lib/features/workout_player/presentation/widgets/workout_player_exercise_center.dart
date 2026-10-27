import 'dart:math' as math;
import 'pilot_exercise_demonstration.dart';
import 'pushup_lottie_demonstration.dart';

import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimator.dart';
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
    final phaseDuration = rest
        ? state.currentPrescription.restBetweenSets
        : transition
            ? WorkoutTimeEstimator.transitionBetweenExercises
            : prescription.workDuration ?? Duration.zero;
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
        Text(ready ? workloadLabel(l, prescription) : '$setLabel · $target',
            key: const ValueKey('player_prescription'), style: text.bodySmall),
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
            child: prescription.exercise.id == 'pushup_standard' &&
                    !MediaQuery.disableAnimationsOf(context)
                ? PushupLottieDemonstration(
                    key: const ValueKey('v2_player_media'),
                    width: width,
                    height: width * 3 / 4,
                    animate:
                        (ready || state.phase == WorkoutPlayerPhase.work) &&
                            !state.isPaused)
                : PilotExerciseDemonstration.supports(
                            prescription.exercise.id) &&
                        !MediaQuery.disableAnimationsOf(context)
                    ? PilotExerciseDemonstration(
                        key: const ValueKey('v2_player_media'),
                        exerciseId: prescription.exercise.id,
                        running: state.phase == WorkoutPlayerPhase.work &&
                            !state.isPaused,
                        width: width,
                        height: width * 3 / 4)
                    : FitFlowExerciseImage.hero(
                        animate:
                            (ready || state.phase == WorkoutPlayerPhase.work) &&
                                !state.isPaused,
                        key: const ValueKey('v2_player_media'),
                        exerciseId: prescription.exercise.id,
                        width: width,
                        height: width * 3 / 4,
                      ),
          ));
        }),
        const SizedBox(height: 8),
        // Purely reflects controller state; pause leaves remaining and progress frozen.
        if (timed)
          _CountdownRing(
              remaining: remaining,
              duration: phaseDuration,
              sizeSample: countdown(Duration(
                      seconds: [
                prescription.workDuration?.inSeconds ?? 0,
                prescription.restBetweenSets.inSeconds,
                WorkoutTimeEstimator.transitionBetweenExercises.inSeconds,
              ].reduce(math.max)))
                  .replaceAll(RegExp(r'\d'), '8'),
              ready: ready,
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
        Text(state.isPaused ? l.flowPaused : phaseLabel,
            style: text.labelMedium, textAlign: TextAlign.center),
      ],
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing(
      {required this.remaining,
      required this.duration,
      required this.ready,
      required this.semanticLabel,
      required this.sizeSample});
  final Duration remaining;
  final Duration duration;
  final bool ready;
  final String semanticLabel;
  final String sizeSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final valueSize = TextPainter(
        text: TextSpan(text: sizeSample, style: theme.textTheme.displayMedium),
        textDirection: Directionality.of(context),
        textScaler: scaler)
      ..layout();
    final unitSize = TextPainter(
        text: TextSpan(
            text: context.l10n.flowSeconds, style: theme.textTheme.bodySmall),
        textDirection: Directionality.of(context),
        textScaler: scaler)
      ..layout();
    // Equal sides always: text scaling enlarges the circle, never flattens it.
    final diameter = math.max(
        100.0,
        math.max(math.max(valueSize.width, unitSize.width) + 32,
            valueSize.height + unitSize.height + 28));
    valueSize.dispose();
    unitSize.dispose();
    final progress = ready || duration.inMicroseconds <= 0
        ? 0.0
        : (1 - remaining.inMicroseconds / duration.inMicroseconds)
            .clamp(0.0, 1.0);
    return Center(
        child: SizedBox.square(
      key: const ValueKey('player_countdown_ring'),
      dimension: diameter,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
            child: ExcludeSemantics(
                child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 4,
          strokeCap: StrokeCap.round,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surfaceContainer,
        ))),
        Column(mainAxisSize: MainAxisSize.min, children: [
          WorkoutCountdown(remaining: remaining, semanticLabel: semanticLabel),
          Text(context.l10n.flowSeconds, style: theme.textTheme.bodySmall),
        ]),
      ]),
    ));
  }
}
