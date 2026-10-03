import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter/material.dart';

/// Bottom phase-specific controls.
class WorkoutPlayerControls extends StatelessWidget {
  const WorkoutPlayerControls({
    super.key,
    required this.state,
    required this.controller,
    this.plan,
  });

  final WorkoutPlayerState state;
  final WorkoutPlayerController controller;
  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case WorkoutPlayerPhase.ready:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.beginWorkout,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.l10n.beginWorkout),
          ),
        );

      case WorkoutPlayerPhase.work:
        if (state.isRepsExercise) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isPaused ? null : controller.completeSet,
              child: Text(context.l10n.setComplete),
            ),
          );
        } else {
          // Timed work shows pause/resume in AppBar, but also show remaining as control disabled?
          // For accessibility, show pause/resume here too.
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (state.isPaused) {
                      controller.resume();
                    } else {
                      controller.pause();
                    }
                  },
                  icon: Icon(state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(state.isPaused ? context.l10n.resume : context.l10n.pause),
                ),
              ),
            ],
          );
        }

      case WorkoutPlayerPhase.rest:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.isPaused ? null : controller.skipRest,
            child: Text(context.l10n.skipRest),
          ),
        );

      case WorkoutPlayerPhase.transition:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: state.isPaused ? null : controller.skipTransition,
            child: Text(context.l10n.skipTransition),
          ),
        );

      case WorkoutPlayerPhase.sectionBreak:
        final isWarmup = state.sectionType == WorkoutSectionType.warmup;
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: controller.continueSection,
            child: Text(isWarmup ? context.l10n.continueLabel : context.l10n.startCooldown),
          ),
        );

      case WorkoutPlayerPhase.completed:
        // Done is now handled inside WorkoutPlayerCompletedView alongside Tune next workout
        return const SizedBox.shrink();
    }
  }
}
