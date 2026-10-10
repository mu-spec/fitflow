import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

/// Same eight engine buckets. True proportional bars with visible text
/// equivalents; no minimum-height fake values or animation of historical data.
class ProgressActivityChart extends StatefulWidget {
  const ProgressActivityChart({super.key, required this.analytics});
  final TrainingAnalytics analytics;
  @override
  State<ProgressActivityChart> createState() => _ProgressActivityChartState();
}

class _ProgressActivityChartState extends State<ProgressActivityChart> {
  bool _showSets = false;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final buckets = widget.analytics.trendBuckets;
    final maxValue = buckets
        .map((b) => _showSets ? b.mainSetCount : b.workoutCount)
        .fold(0, (a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TrainingHeading(l.trainingActivity),
      const SizedBox(height: 8),
      Text(l.trainingActivityHelp),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
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
      const SizedBox(height: 16),
      for (final bucket in buckets) ...[
        Text(
            '${bucket.isCurrent ? l.trainingCurrentPeriod : l.trainingWeeksAgo(buckets.length - 1 - bucket.index)} · ${_showSets ? l.trainingActivitySets(bucket.mainSetCount) : l.trainingActivityCount(bucket.workoutCount)}',
            style: Theme.of(context).textTheme.labelLarge),
        Text(
            '${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), bucket.start)} – ${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), bucket.end)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        ExcludeSemantics(
            child: LinearProgressIndicator(
                value: maxValue == 0
                    ? 0
                    : (_showSets ? bucket.mainSetCount : bucket.workoutCount) /
                        maxValue,
                minHeight: 6)),
        const SizedBox(height: 16),
      ],
      if (maxValue == 0) Text(l.trainingNoActivity),
    ]);
  }
}
