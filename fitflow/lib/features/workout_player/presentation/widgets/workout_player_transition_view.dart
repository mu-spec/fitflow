import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerTransitionView extends StatelessWidget {
  const WorkoutPlayerTransitionView({super.key, required this.state});
  final WorkoutPlayerState state;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final next = state.nextPrescription;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          WorkoutPhaseLabel(
              label: l.flowNext,
              icon: Icons.arrow_forward_rounded,
              rest: true,
              paused: state.isPaused),
          if (state.isPaused)
            Padding(
                padding: const EdgeInsets.only(top: FitFlowSpace.xs),
                child: Text(l.flowNext, textAlign: TextAlign.center)),
          const SizedBox(height: FitFlowSpace.xl),
          if (next != null) ...[
            Semantics(
                header: true,
                child: Text(next.exercise.name,
                    style: text.headlineMedium, textAlign: TextAlign.center)),
            const SizedBox(height: FitFlowSpace.sm),
            Text(workloadLabel(l, next),
                style: text.bodyLarge, textAlign: TextAlign.center),
          ],
          const SizedBox(height: FitFlowSpace.xl),
          WorkoutCountdown(
              remaining: state.remaining,
              semanticLabel:
                  l.flowTransitionRemaining(state.remaining.inSeconds)),
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowSeconds, textAlign: TextAlign.center),
        ]));
  }
}
