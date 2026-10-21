import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPlayerProgressHeader extends StatelessWidget {
  const WorkoutPlayerProgressHeader({super.key, required this.state});
  final WorkoutPlayerState state;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
        spacing: FitFlowSpace.sm,
        runSpacing: FitFlowSpace.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(sectionLabel(l, state.sectionType),
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w500)),
          Text(
              l.flowExercisePosition(state.exercisePositionInSection,
                  state.exerciseCountInCurrentSection),
              style: text.bodySmall?.copyWith(color: t.textSecondary)),
        ],
      ),
      const SizedBox(height: FitFlowSpace.xs),
      Row(children: [
        Expanded(
            child: LinearProgressIndicator(
          value: state.progressFraction,
          minHeight: 4,
          color: t.progress,
          backgroundColor: v.tint,
          borderRadius: FitFlowRadius.pillBorder,
          semanticsLabel: l.flowOverall(state.completedSets, state.totalSets),
        )),
        const SizedBox(width: 12),
        Text(l.flowSetsProgress(state.completedSets, state.totalSets),
            style: text.bodySmall?.copyWith(color: t.textSecondary)),
      ]),
    ]);
  }
}
