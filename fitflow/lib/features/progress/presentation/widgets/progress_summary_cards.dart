import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

/// Compact identity header shared by the populated and empty Progress states.
class ProgressOverviewHeader extends StatelessWidget {
  const ProgressOverviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);
    final colors = FitFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: visual.tint,
              borderRadius: FitFlowRadius.mediumBorder,
            ),
            child: Icon(
              Icons.insights_outlined,
              color: colors.brand,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: FitFlowSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrainingHeading(l.yourProgress),
              const SizedBox(height: FitFlowSpace.xxs),
              Text(
                l.progressDeviceNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
        value: FitFlowLocaleFormat.formatDuration(
          l,
          analytics.currentPeriod.plannedDuration,
        ),
      ),
    ];

    return FitFlowV2InfoSurface(
      padding: const EdgeInsets.all(FitFlowSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final useColumns =
                  constraints.maxWidth >= 560 && textScale <= 1.25;

              if (useColumns) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: FitFlowSpace.md),
                      Expanded(child: _ProgressMetric(stat: stats[i])),
                    ],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: FitFlowSpace.md),
                        child: Divider(height: 1),
                      ),
                    _ProgressMetric(stat: stats[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: FitFlowSpace.md),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: FitFlowSpace.md),
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
      ),
    );
  }
}

class _ProgressSummaryStat {
  const _ProgressSummaryStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.stat});

  final _ProgressSummaryStat stat;

  @override
  Widget build(BuildContext context) => FitFlowStat(
        label: stat.label,
        value: stat.value,
      );
}
