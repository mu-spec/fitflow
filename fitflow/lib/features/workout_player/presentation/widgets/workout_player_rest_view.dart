import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerRestView extends StatelessWidget {
  const WorkoutPlayerRestView({super.key, required this.state});
  final WorkoutPlayerState state;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WorkoutPhaseLabel(
              label: l.flowRest,
              icon: Icons.spa_outlined,
              rest: true,
              paused: state.isPaused),
          if (state.isPaused)
            Padding(
                padding: const EdgeInsets.only(top: FitFlowSpace.xs),
                child: Text(l.flowRest, textAlign: TextAlign.center)),
          const SizedBox(height: FitFlowSpace.xl),
          WorkoutCountdown(
              remaining: state.remaining,
              semanticLabel: l.flowRestRemaining(state.remaining.inSeconds)),
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowRestSeconds,
              style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xl),
          Text(
              l.flowNextSet(
                  state.setNumber + 1, state.totalSetsForCurrentExercise),
              style: text.labelLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xs),
          Text(state.currentPrescription.exercise.name,
              style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xs),
          Text(workloadLabel(l, state.currentPrescription),
              style: text.bodyMedium, textAlign: TextAlign.center),
        ]));
  }
}
