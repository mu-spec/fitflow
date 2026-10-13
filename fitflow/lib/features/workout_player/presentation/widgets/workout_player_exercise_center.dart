import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_workout_media.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_phase_focus.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Work-phase presentation only; timer, rep prescription, set, replacement
/// and paused state come directly from the unchanged execution engine.
class WorkoutPlayerExerciseCenter extends StatelessWidget {
  const WorkoutPlayerExerciseCenter({
    super.key,
    required this.state,
    this.artwork,
  });
  final WorkoutPlayerState state;

  /// Future Step 6 media can enter the same decoration-only slot.
  final Widget? artwork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final v = FitFlowVisualV2.of(context);
    final l = context.l10n;
    return FitFlowV2HeroSurface(
      key: const ValueKey('v2_player_focus'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        WorkoutPhaseLabel(
            label: l.flowWork,
            icon: Icons.fitness_center_rounded,
            paused: state.isPaused),
        const SizedBox(height: FitFlowSpace.md),
        Semantics(
          header: true,
          child: Text(state.currentPrescription.exercise.name,
              style: text.headlineMedium?.copyWith(color: v.onHero),
              textAlign: TextAlign.center),
        ),
        if (state.isCurrentReplaced && state.originalExerciseName != null) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowReplaced(state.originalExerciseName!),
              style: text.bodySmall?.copyWith(color: v.heroSecondary),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: FitFlowSpace.md),
        FitFlowV2WorkoutMedia(
          key: const ValueKey('v2_player_media'),
          height: WorkoutV2Layout.mediaHeight(context, player: true),
          onHero: true,
          artwork: artwork,
        ),
        const SizedBox(height: FitFlowSpace.md),
        Text(l.flowSet(state.setNumber, state.totalSetsForCurrentExercise),
            style: text.titleMedium?.copyWith(color: v.heroSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: FitFlowSpace.xs),
        if (state.isTimedExercise) ...[
          // Keep the existing formatter, type-role selection, focusable timer
          // semantics and non-live-region behavior. Only the text color changes.
          Theme(
            data: theme.copyWith(
                textTheme:
                    text.apply(bodyColor: v.onHero, displayColor: v.onHero)),
            child: WorkoutCountdown(
                remaining: state.remaining,
                semanticLabel: l.flowRemaining(state.remaining.inSeconds)),
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(l.flowSeconds,
              style: text.bodyMedium?.copyWith(color: v.heroSecondary),
              textAlign: TextAlign.center),
        ] else
          Text(l.flowReps(state.currentPrescription.repsPerSet!),
              style: text.displayMedium?.copyWith(color: v.onHero),
              textAlign: TextAlign.center),
        const SizedBox(height: FitFlowSpace.sm),
        Text(equipmentSummary(l, state.currentPrescription),
            style: text.bodySmall?.copyWith(color: v.heroSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
