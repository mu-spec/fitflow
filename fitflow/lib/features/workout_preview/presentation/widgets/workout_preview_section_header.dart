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
      required this.budget});
  final String title;
  final int exerciseCount;
  final WorkoutTimeEstimate? planned;
  final Duration budget;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
            '${context.l10n.flowCount(exerciseCount)} · ${context.l10n.flowEstimate(plannedDuration(context.l10n, planned?.total))}',
            style: Theme.of(context).textTheme.bodySmall),
      ]);
}
