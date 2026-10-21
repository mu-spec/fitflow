import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerControls extends StatelessWidget {
  const WorkoutPlayerControls(
      {super.key,
      required this.state,
      required this.controller,
      this.plan,
      this.secondaryActions = const []});
  final WorkoutPlayerState state;
  final WorkoutPlayerController controller;
  final WorkoutPlan? plan;
  final List<Widget> secondaryActions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (state.phase == WorkoutPlayerPhase.completed) {
      return const SizedBox.shrink();
    }
    late final String label;
    late final VoidCallback action;
    late final IconData icon;
    final secondary = <Widget>[];
    if (state.isPaused) {
      label = l.resume;
      action = controller.resume;
      icon = Icons.play_arrow_rounded;
    } else {
      switch (state.phase) {
        case WorkoutPlayerPhase.ready:
          label = l.beginWorkout;
          action = controller.beginWorkout;
          icon = Icons.play_arrow_rounded;
        case WorkoutPlayerPhase.work:
          if (state.isTimedExercise) {
            label = l.flowPause;
            action = controller.pause;
            icon = Icons.pause_rounded;
          } else {
            label = l.setComplete;
            action = controller.completeSet;
            icon = Icons.check_rounded;
            secondary.add(TextButton.icon(
                onPressed: controller.pause,
                icon: const Icon(Icons.pause_rounded, size: 18),
                label: Text(l.pause)));
          }
        case WorkoutPlayerPhase.rest:
        case WorkoutPlayerPhase.transition:
          label = l.flowPause;
          action = controller.pause;
          icon = Icons.pause_rounded;
          secondary.add(TextButton(
              onPressed: state.phase == WorkoutPlayerPhase.rest
                  ? controller.skipRest
                  : controller.skipTransition,
              child: Text(state.phase == WorkoutPlayerPhase.rest
                  ? l.skipRest
                  : l.skipTransition)));
        case WorkoutPlayerPhase.sectionBreak:
          label = state.sectionType == WorkoutSectionType.warmup
              ? l.continueLabel
              : l.startCooldown;
          action = controller.continueSection;
          icon = Icons.arrow_forward_rounded;
        case WorkoutPlayerPhase.completed:
          return const SizedBox.shrink();
      }
    }
    secondary.addAll(secondaryActions);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
          key: const ValueKey('player_primary_action'),
          onPressed: action,
          icon: Icon(icon),
          label: Text(label)),
      const SizedBox(height: 4),
      // Reserve the same secondary zone even when no secondary action applies.
      if (secondary.isEmpty)
        const SizedBox(height: 64)
      else if (MediaQuery.textScalerOf(context).scale(14) > 21)
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: secondary)
      else
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(children: [
            for (final child in secondary) Expanded(child: child)
          ]),
        ),
    ]);
  }
}
