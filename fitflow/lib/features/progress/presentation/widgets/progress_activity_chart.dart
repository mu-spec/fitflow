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
        Semantics(
            header: true,
            child:
                Text(l.trainingActivity, style: theme.textTheme.titleMedium)),
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
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Large labels scroll horizontally instead of being compressed.
        final minSlot = scale > 1.3 ? 64.0 * scale : 34.0;
        final width = constraints.maxWidth < minSlot * buckets.length
            ? minSlot * buckets.length
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: width,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final bucket in buckets)
                  Expanded(
                      child: Semantics(
                    label:
                        '${period(bucket)} · ${count(bucket)} · ${dates(bucket)}',
                    excludeSemantics: true,
                    child: Column(children: [
                      Text(
                          '${_showSets ? bucket.mainSetCount : bucket.workoutCount}',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      SizedBox(
                          key: ValueKey('progress_bar_${bucket.index}'),
                          width: 22,
                          height: 88,
                          child: RotatedBox(
                              quarterTurns: 3,
                              child: LinearProgressIndicator(
                                value: maxValue == 0
                                    ? 0
                                    : (_showSets
                                            ? bucket.mainSetCount
                                            : bucket.workoutCount) /
                                        maxValue,
                                borderRadius: BorderRadius.circular(3),
                                color: theme.colorScheme.primary,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ))),
                      const SizedBox(height: 6),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                              MaterialLocalizations.of(context)
                                  .formatShortMonthDay(bucket.start.toLocal()),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall)),
                    ]),
                  )),
              ])),
        );
      }),
      if (maxValue == 0)
        Text(_showSets ? l.progressNoMainSets : l.trainingNoActivity,
            style: theme.textTheme.bodySmall),
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
