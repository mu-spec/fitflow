import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'progress_presentation.dart';

class ProgressOverviewHeader extends StatelessWidget {
  const ProgressOverviewHeader({super.key, this.showDeviceNote = true});
  final bool showDeviceNote;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
            header: true,
            child: Text(context.l10n.yourProgress,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 22, fontWeight: FontWeight.w500))),
        if (showDeviceNote) ...[
          const SizedBox(height: 4),
          Text(context.l10n.progressDeviceNote,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ]);
}

/// Metrics share the current rolling seven-day window. Deltas compare with
/// the preceding window; none represents elapsed time or a workout goal.
class ProgressSummaryCards extends StatelessWidget {
  const ProgressSummaryCards({super.key, required this.analytics});
  final TrainingAnalytics analytics;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    String signed(int n) => n > 0 ? '+$n' : '$n';
    final timeDelta = analytics.plannedDurationDelta;
    final metrics = [
      _Metric(
          label: l.trainingWorkouts,
          value: '${analytics.currentPeriod.workoutCount}',
          delta: signed(analytics.workoutDelta)),
      _Metric(
          label: l.progressMainSets,
          value: '${analytics.currentPeriod.mainSets}',
          delta: signed(analytics.mainSetsDelta)),
      _Metric(
          label: l.progressPlannedTime,
          value: progressDuration(
              context, analytics.currentPeriod.plannedDuration),
          delta:
              '${timeDelta.isNegative ? '−' : timeDelta > Duration.zero ? '+' : ''}${progressDuration(context, timeDelta)}'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.trainingCurrentPeriod, style: text.bodyMedium),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 280 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        return columns
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: metrics[i]),
                ],
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final metric in metrics)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: metric),
              ]);
      }),
      const SizedBox(height: 4),
      Text(l.progressDeltaContext, style: text.bodySmall),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, required this.delta});
  final String label;
  final String value;
  final String delta;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
        label: '$label $value. ${context.l10n.progressDeltaContext}: $delta',
        excludeSemantics: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.w500)),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(delta,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]));
  }
}
