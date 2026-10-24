import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class ProgressConsistency extends StatelessWidget {
  const ProgressConsistency(
      {super.key, required this.analytics, this.showHeading = true});
  final TrainingAnalytics analytics;
  final bool showHeading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final recent = analytics.trendBuckets.skip(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showHeading)
        Text(l.progressConsistencyTitle, style: theme.textTheme.titleMedium),
      Text(l.progressActiveWeeks(analytics.activeWeeksCount),
          style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(l.progressConsistencyHelp, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      for (var i = 0; i < recent.length; i++)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExcludeSemantics(
                  child: Icon(
                      recent[i].workoutCount > 0
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      size: 18,
                      color: recent[i].workoutCount > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      recent[i].isCurrent
                          ? l.trainingCurrentPeriod
                          : l.trainingWeeksAgo(3 - i),
                      style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(l.trainingActivityCount(recent[i].workoutCount),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall)),
            ])),
    ]);
  }
}
