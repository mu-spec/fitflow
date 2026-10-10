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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(sectionLabel(l, state.sectionType), style: text.labelLarge),
      const SizedBox(height: FitFlowSpace.xxs),
      Text(
          l.flowExercisePosition(state.exercisePositionInSection,
              state.exerciseCountInCurrentSection),
          style: text.bodySmall),
      const SizedBox(height: FitFlowSpace.sm),
      LinearProgressIndicator(
          value: state.progressFraction,
          minHeight: 4,
          color: FitFlowTheme.of(context).progress,
          borderRadius: FitFlowRadius.pillBorder,
          semanticsLabel: l.flowOverall(state.completedSets, state.totalSets)),
      const SizedBox(height: FitFlowSpace.xxs),
      Text(l.flowSetsProgress(state.completedSets, state.totalSets),
          style: text.bodySmall, textAlign: TextAlign.end),
    ]);
  }
}
