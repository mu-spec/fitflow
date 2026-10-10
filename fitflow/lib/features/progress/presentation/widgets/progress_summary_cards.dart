import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

class ProgressSummaryCards extends StatelessWidget {
  const ProgressSummaryCards({super.key, required this.analytics});
  final TrainingAnalytics analytics;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TrainingHeading(l.yourProgress, large: true),
      const SizedBox(height: 8),
      Text(l.progressDeviceNote, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24
            ? 3
            : 1;
        return Wrap(spacing: 16, runSpacing: 20, children: [
          for (final stat in [
            FitFlowStat(
                label: l.trainingSavedWorkouts,
                value: '${analytics.savedWorkoutsCount}'),
            FitFlowStat(
                label: l.trainingLast7,
                value: '${analytics.currentPeriod.workoutCount}'),
            FitFlowStat(
                label: l.trainingPlanned7,
                value: FitFlowLocaleFormat.formatDuration(
                    l, analytics.currentPeriod.plannedDuration)),
          ])
            SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 16) / columns,
                child: stat),
        ]);
      }),
      const SizedBox(height: 12),
      Text(l.trainingPlannedNote, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
