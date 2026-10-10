import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerExerciseCenter extends StatelessWidget {
  const WorkoutPlayerExerciseCenter({super.key, required this.state});
  final WorkoutPlayerState state;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = context.l10n;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WorkoutPhaseLabel(
              label: l.flowWork,
              icon: Icons.fitness_center_rounded,
              paused: state.isPaused),
          const SizedBox(height: FitFlowSpace.xl),
          Semantics(
              header: true,
              child: Text(state.currentPrescription.exercise.name,
                  style: text.headlineMedium, textAlign: TextAlign.center)),
          if (state.isCurrentReplaced &&
              state.originalExerciseName != null) ...[
            const SizedBox(height: FitFlowSpace.xs),
            Text(l.flowReplaced(state.originalExerciseName!),
                style: text.bodySmall, textAlign: TextAlign.center),
          ],
          const SizedBox(height: FitFlowSpace.md),
          Text(l.flowSet(state.setNumber, state.totalSetsForCurrentExercise),
              style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xl),
          if (state.isTimedExercise) ...[
            WorkoutCountdown(
                remaining: state.remaining,
                semanticLabel: l.flowRemaining(state.remaining.inSeconds)),
            const SizedBox(height: FitFlowSpace.xs),
            Text(l.flowSeconds,
                style: text.bodyMedium, textAlign: TextAlign.center),
          ] else
            Text(l.flowReps(state.currentPrescription.repsPerSet!),
                style: text.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.md),
          Text(equipmentSummary(l, state.currentPrescription),
              style: text.bodySmall, textAlign: TextAlign.center),
        ]));
  }
}
