import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
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
  });
  final WorkoutPlayerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final t = FitFlowTheme.of(context);
    final l = context.l10n;
    return Column(
      key: const ValueKey('v2_player_focus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkoutPhaseLabel(
            label: l.flowWork,
            icon: Icons.fitness_center_rounded,
            paused: state.isPaused),
        const SizedBox(height: FitFlowSpace.md),
        Semantics(
          header: true,
          child: Text(state.currentPrescription.exercise.name,
              style: text.titleLarge
                  ?.copyWith(color: t.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ),
        if (state.isCurrentReplaced && state.originalExerciseName != null) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Text(l.flowReplaced(state.originalExerciseName!),
              style: text.bodySmall?.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: FitFlowSpace.md),
        Text(l.flowSet(state.setNumber, state.totalSetsForCurrentExercise),
            style: text.titleMedium?.copyWith(color: t.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: FitFlowSpace.xs),
        if (state.isTimedExercise) ...[
          // Keep the existing formatter, type-role selection, focusable timer
          // semantics and non-live-region behavior. Only the text color changes.
          Theme(
            data: theme.copyWith(
                textTheme: text.apply(
                    bodyColor: t.textPrimary, displayColor: t.textPrimary)),
            child: WorkoutCountdown(
                remaining: state.remaining,
                semanticLabel: l.flowRemaining(state.remaining.inSeconds)),
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(l.flowSeconds,
              style: text.bodyMedium?.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center),
        ] else
          Text(l.flowReps(state.currentPrescription.repsPerSet!),
              style: text.displayMedium?.copyWith(color: t.textPrimary),
              textAlign: TextAlign.center),
        if (!state.isPaused) ...[
          const SizedBox(height: FitFlowSpace.sm),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0.0, 320.0);
            return Center(
                child: FitFlowExerciseImage.hero(
              key: const ValueKey('v2_player_media'),
              exerciseId: state.currentPrescription.exercise.id,
              width: width,
              height: width * 3 / 4,
            ));
          }),
        ],
        const SizedBox(height: FitFlowSpace.sm),
        Text(equipmentSummary(l, state.currentPrescription),
            style: text.bodySmall?.copyWith(color: t.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}
