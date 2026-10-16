import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class ProgressConsistency extends StatelessWidget {
  const ProgressConsistency({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fitFlowTheme = FitFlowTheme.of(context);
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Training consistency',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
          'Weeks with at least one completed workout.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        FitFlowV2InfoSurface(
          padding: const EdgeInsets.all(FitFlowSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${analytics.activeWeeksCount}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FitFlowSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${analytics.activeWeeksCount} of 4 recent weeks',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: FitFlowSpace.xxs),
                        Text(
                          'Based on last 28 days divided into four 7-day periods.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FitFlowSpace.md),
              const Divider(height: 1),
              const SizedBox(height: FitFlowSpace.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final compact = constraints.maxWidth < 520 || textScale > 1.3;
                  final recentBuckets = analytics.trendBuckets.skip(4).toList();

                  if (compact) {
                    return Column(
                      children: [
                        for (var i = 0; i < recentBuckets.length; i++) ...[
                          _CompactWeekStatus(
                            bucket: recentBuckets[i],
                            periodLabel: recentBuckets[i].isCurrent
                                ? l.trainingCurrentPeriod
                                : l.trainingWeeksAgo(3 - i),
                            activityLabel: l.trainingActivityCount(
                                recentBuckets[i].workoutCount),
                            activeColor: colorScheme.primary,
                            inactiveColor: colorScheme.surfaceContainerHighest,
                            textColor: fitFlowTheme.textSecondary,
                          ),
                          if (i != recentBuckets.length - 1)
                            const SizedBox(height: FitFlowSpace.xs),
                        ],
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < recentBuckets.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: i == 0 ? 0 : FitFlowSpace.xs / 2,
                              end: i == recentBuckets.length - 1
                                  ? 0
                                  : FitFlowSpace.xs / 2,
                            ),
                            child: _WideWeekStatus(
                              bucket: recentBuckets[i],
                              periodLabel: recentBuckets[i].isCurrent
                                  ? l.trainingCurrentPeriod
                                  : l.trainingWeeksAgo(3 - i),
                              activityLabel: l.trainingActivityCount(
                                  recentBuckets[i].workoutCount),
                              activeColor: colorScheme.primary,
                              inactiveColor:
                                  colorScheme.surfaceContainerHighest,
                              textColor: fitFlowTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactWeekStatus extends StatelessWidget {
  const _CompactWeekStatus({
    required this.bucket,
    required this.periodLabel,
    required this.activityLabel,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
  });

  final TrainingTrendBucket bucket;
  final String periodLabel;
  final String activityLabel;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final hasWorkout = bucket.workoutCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: FitFlowSpace.xs,
          runSpacing: FitFlowSpace.xxs,
          children: [
            Text(periodLabel, style: Theme.of(context).textTheme.labelLarge),
            Text(
              activityLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textColor),
            ),
          ],
        ),
        const SizedBox(height: FitFlowSpace.xxs),
        ExcludeSemantics(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: hasWorkout ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _WideWeekStatus extends StatelessWidget {
  const _WideWeekStatus({
    required this.bucket,
    required this.periodLabel,
    required this.activityLabel,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
  });

  final TrainingTrendBucket bucket;
  final String periodLabel;
  final String activityLabel;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final hasWorkout = bucket.workoutCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: hasWorkout ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(periodLabel, style: Theme.of(context).textTheme.labelMedium),
        Text(
          activityLabel,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
