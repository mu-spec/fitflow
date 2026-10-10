import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerControls extends StatelessWidget {
  const WorkoutPlayerControls(
      {super.key, required this.state, required this.controller, this.plan});
  final WorkoutPlayerState state;
  final WorkoutPlayerController controller;
  final WorkoutPlan? plan;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget primary(String label, VoidCallback? action, IconData icon) =>
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
              onPressed: action, icon: Icon(icon), label: Text(label)),
        );
    if (state.isPaused) {
      return primary(l.resume, controller.resume, Icons.play_arrow_rounded);
    }
    switch (state.phase) {
      case WorkoutPlayerPhase.ready:
        return primary(
            l.beginWorkout, controller.beginWorkout, Icons.play_arrow_rounded);
      case WorkoutPlayerPhase.work:
        if (state.isTimedExercise) {
          return primary(l.flowPause, controller.pause, Icons.pause_rounded);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary(
                  l.setComplete, controller.completeSet, Icons.check_rounded),
              const SizedBox(height: FitFlowSpace.xs),
              OutlinedButton.icon(
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause_rounded),
                  label: Text(l.pause)),
            ]);
      case WorkoutPlayerPhase.rest:
      case WorkoutPlayerPhase.transition:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary(l.flowPause, controller.pause, Icons.pause_rounded),
              const SizedBox(height: FitFlowSpace.xs),
              OutlinedButton(
                  onPressed: state.phase == WorkoutPlayerPhase.rest
                      ? controller.skipRest
                      : controller.skipTransition,
                  child: Text(state.phase == WorkoutPlayerPhase.rest
                      ? l.skipRest
                      : l.skipTransition)),
            ]);
      case WorkoutPlayerPhase.sectionBreak:
        return primary(
            state.sectionType == WorkoutSectionType.warmup
                ? l.continueLabel
                : l.startCooldown,
            controller.continueSection,
            Icons.arrow_forward_rounded);
      case WorkoutPlayerPhase.completed:
        return const SizedBox.shrink();
    }
  }
}
