import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'progress_presentation.dart';

/// Same eight rolling buckets and proportional values; dates remain accessible.
class ProgressActivityChart extends StatefulWidget {
  const ProgressActivityChart(
      {super.key, required this.analytics, this.showHeading = true});
  final TrainingAnalytics analytics;
  final bool showHeading;
  @override
  State<ProgressActivityChart> createState() => _ProgressActivityChartState();
}

class _ProgressActivityChartState extends State<ProgressActivityChart> {
  bool _showSets = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final buckets = widget.analytics.trendBuckets;
    final maxValue = buckets
        .map((b) => _showSets ? b.mainSetCount : b.workoutCount)
        .fold(0, (a, b) => a > b ? a : b);
    String period(TrainingTrendBucket b) => b.isCurrent
        ? l.trainingCurrentPeriod
        : l.trainingWeeksAgo(buckets.length - 1 - b.index);
    String count(TrainingTrendBucket b) => _showSets
        ? l.trainingActivitySets(b.mainSetCount)
        : l.trainingActivityCount(b.workoutCount);
    String dates(TrainingTrendBucket b) =>
        '${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), b.start)} – ${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), b.end)}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.showHeading)
        Text(l.trainingActivity, style: theme.textTheme.titleMedium),
      Text(l.progressPeriodOrder, style: theme.textTheme.bodySmall),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 4, children: [
        ChoiceChip(
            chipAnimationStyle: ChipAnimationStyle(
                selectAnimation: AnimationStyle(
                    duration: SystemMotion.micro(context),
                    reverseDuration: SystemMotion.micro(context))),
            label: Text(l.trainingWorkouts),
            selected: !_showSets,
            onSelected: (_) => setState(() => _showSets = false)),
        ChoiceChip(
            chipAnimationStyle: ChipAnimationStyle(
                selectAnimation: AnimationStyle(
                    duration: SystemMotion.micro(context),
                    reverseDuration: SystemMotion.micro(context))),
            label: Text(l.trainingSets),
            selected: _showSets,
            onSelected: (_) => setState(() => _showSets = true)),
      ]),
      const SizedBox(height: 8),
      for (final bucket in buckets)
        Semantics(
          label: '${period(bucket)} · ${count(bucket)} · ${dates(bucket)}',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: LayoutBuilder(builder: (context, constraints) {
              final label =
                  Text(period(bucket), style: theme.textTheme.bodySmall);
              final value = Text(
                  '${_showSets ? bucket.mainSetCount : bucket.workoutCount}',
                  style: theme.textTheme.bodyMedium);
              final bar = LinearProgressIndicator(
                value: maxValue == 0
                    ? 0
                    : (_showSets ? bucket.mainSetCount : bucket.workoutCount) /
                        maxValue,
                minHeight: 6,
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: label),
                        const SizedBox(width: 8),
                        value
                      ]),
                      const SizedBox(height: 4),
                      bar,
                    ]);
              }
              return Row(children: [
                SizedBox(width: constraints.maxWidth * .4, child: label),
                const SizedBox(width: 8),
                Expanded(child: bar),
                const SizedBox(width: 12),
                SizedBox(width: 32, child: value),
              ]);
            }),
          ),
        ),
      if (maxValue == 0)
        Text(l.trainingNoActivity, style: theme.textTheme.bodySmall),
      ProgressDisclosure(
          key: const Key('progress_period_dates'),
          title: l.progressPeriodDates,
          children: [
            for (final bucket in buckets)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                      '${period(bucket)} · ${count(bucket)}\n${dates(bucket)}',
                      style: theme.textTheme.bodySmall)),
          ]),
    ]);
  }
}
