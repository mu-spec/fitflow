import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
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
    final fitFlowTheme = FitFlowTheme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TrainingHeading(l.trainingActivity),
      const SizedBox(height: FitFlowSpace.xs),
      Text(
        l.trainingActivityHelp,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fitFlowTheme.textSecondary),
      ),
      const SizedBox(height: FitFlowSpace.sm),
      Wrap(spacing: FitFlowSpace.xs, runSpacing: FitFlowSpace.xs, children: [
        ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            chipAnimationStyle: ChipAnimationStyle(
                selectAnimation: AnimationStyle(
                    duration: SystemMotion.micro(context),
                    reverseDuration: SystemMotion.micro(context))),
            label: Text(l.trainingWorkouts),
            selected: !_showSets,
            onSelected: (_) => setState(() => _showSets = false)),
        ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            chipAnimationStyle: ChipAnimationStyle(
                selectAnimation: AnimationStyle(
                    duration: SystemMotion.micro(context),
                    reverseDuration: SystemMotion.micro(context))),
            label: Text(l.trainingSets),
            selected: _showSets,
            onSelected: (_) => setState(() => _showSets = true)),
      ]),
      const SizedBox(height: FitFlowSpace.md),
      FitFlowV2InfoSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < buckets.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(FitFlowSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${buckets[i].isCurrent ? l.trainingCurrentPeriod : l.trainingWeeksAgo(buckets.length - 1 - buckets[i].index)} · ${_showSets ? l.trainingActivitySets(buckets[i].mainSetCount) : l.trainingActivityCount(buckets[i].workoutCount)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: FitFlowSpace.xxs),
                    Text(
                      '${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), buckets[i].start)} – ${FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), buckets[i].end)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: fitFlowTheme.textSecondary),
                    ),
                    const SizedBox(height: FitFlowSpace.xs),
                    ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: FitFlowRadius.pillBorder,
                        child: LinearProgressIndicator(
                          value: maxValue == 0
                              ? 0
                              : (_showSets
                                      ? buckets[i].mainSetCount
                                      : buckets[i].workoutCount) /
                                  maxValue,
                          minHeight: 8,
                          color: fitFlowTheme.brand,
                          backgroundColor: fitFlowTheme.subtleSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != buckets.length - 1)
                const Divider(
                    height: 1,
                    indent: FitFlowSpace.md,
                    endIndent: FitFlowSpace.md),
            ],
          ],
        ),
      ),
      if (maxValue == 0) ...[
        const SizedBox(height: FitFlowSpace.sm),
        Text(l.trainingNoActivity),
      ],
    ]);
  }
}
