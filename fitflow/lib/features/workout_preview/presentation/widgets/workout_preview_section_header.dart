import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workout_player/presentation/workout_copy.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_estimate.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPreviewSectionHeader extends StatelessWidget {
  const WorkoutPreviewSectionHeader(
      {super.key,
      required this.title,
      required this.exerciseCount,
      required this.planned,
      required this.budget,
      this.visualV2 = false});
  final String title;
  final int exerciseCount;
  final WorkoutTimeEstimate? planned;
  final Duration budget;
  // V2 is opt-in so unchanged callers keep their existing presentation.
  final bool visualV2;
  @override
  Widget build(BuildContext context) {
    if (visualV2) {
      final text = Theme.of(context).textTheme;
      final t = FitFlowTheme.of(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              header: true,
              child: Text(title,
                  style:
                      text.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(
              '${context.l10n.flowCount(exerciseCount)} · ${context.l10n.flowEstimate(plannedDuration(context.l10n, planned?.total))}',
              style: text.bodySmall?.copyWith(color: t.textSecondary)),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      const SizedBox(height: FitFlowSpace.xxs),
      Text(
          '${context.l10n.flowCount(exerciseCount)} · ${context.l10n.flowEstimate(plannedDuration(context.l10n, planned?.total))}',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
