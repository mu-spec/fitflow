import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'progress_presentation.dart';
import 'package:flutter/material.dart';

/// Compact identity header shared by the populated and empty Progress states.
class ProgressOverviewHeader extends StatelessWidget {
  const ProgressOverviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
            header: true,
            child: Text(l.yourProgress,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 22, fontWeight: FontWeight.w500))),
        const SizedBox(height: FitFlowSpace.xs),
        Text(l.progressDeviceNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}

/// The three canonical, history-derived facts shown at the top of Progress.
/// Values and calculation sources intentionally remain owned by analytics.
class ProgressSummaryCards extends StatelessWidget {
  const ProgressSummaryCards({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final stats = [
      _ProgressSummaryStat(
        label: l.trainingSavedWorkouts,
        value: '${analytics.savedWorkoutsCount}',
      ),
      _ProgressSummaryStat(
        label: l.trainingLast7,
        value: '${analytics.currentPeriod.workoutCount}',
      ),
      _ProgressSummaryStat(
        label: l.trainingPlanned7,
        value: progressDuration(
          context,
          analytics.currentPeriod.plannedDuration,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useColumns = constraints.maxWidth >= 280 && textScale <= 1.3;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (useColumns)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _ProgressMetric(
                                  stat: stats[0], stacked: true)),
                          const SizedBox(width: FitFlowSpace.md),
                          Expanded(
                              child: _ProgressMetric(
                                  stat: stats[1], stacked: true)),
                        ])
                  else ...[
                    _ProgressMetric(stat: stats[0]),
                    _ProgressMetric(stat: stats[1]),
                  ],
                  const SizedBox(height: FitFlowSpace.sm),
                  const Divider(height: 1),
                  const SizedBox(height: FitFlowSpace.xs),
                  _ProgressMetric(stat: stats[2]),
                ]);
          },
        ),
        const SizedBox(height: FitFlowSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: FitFlowSpace.xs),
            Expanded(
              child: Text(
                l.trainingPlannedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressSummaryStat {
  const _ProgressSummaryStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.stat, this.stacked = false});

  final _ProgressSummaryStat stat;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${stat.label} ${stat.value}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xs),
        child: stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stat.value,
                    style:
                        text.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: FitFlowSpace.xxs),
                Text(stat.label,
                    style: text.bodyMedium?.copyWith(
                        color: FitFlowTheme.of(context).textSecondary)),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(stat.label,
                        style: text.bodyMedium?.copyWith(
                            color: FitFlowTheme.of(context).textSecondary))),
                const SizedBox(width: FitFlowSpace.sm),
                Flexible(
                    child: Text(stat.value,
                        textAlign: TextAlign.end,
                        style: text.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w500))),
              ]),
      ),
    );
  }
}
