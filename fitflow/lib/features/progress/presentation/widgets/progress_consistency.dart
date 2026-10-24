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
      Row(children: [
        for (var i = 0; i < recent.length; i++)
          Expanded(
              child: Semantics(
            label:
                '${recent[i].isCurrent ? l.trainingCurrentPeriod : l.trainingWeeksAgo(3 - i)} · ${l.trainingActivityCount(recent[i].workoutCount)}',
            excludeSemantics: true,
            child: Padding(
                padding: EdgeInsetsDirectional.only(
                    end: i == recent.length - 1 ? 0 : 8),
                child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: recent[i].workoutCount > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest))),
          )),
      ]),
    ]);
  }
}
