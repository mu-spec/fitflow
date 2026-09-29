import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buckets = widget.analytics.trendBuckets;

    final maxWorkouts = buckets.map((b) => b.workoutCount).fold(0, (a, b) => a > b ? a : b);
    final maxSets = buckets.map((b) => b.mainSetCount).fold(0, (a, b) => a > b ? a : b);
    final maxValue = _showSets ? maxSets : maxWorkouts;
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNarrow) ...[
              Text('8-week activity',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Completed workouts over eight rolling 7-day periods. Oldest left, current right.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Workouts')),
                    ButtonSegment(value: true, label: Text('Sets')),
                  ],
                  selected: {_showSets},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _showSets = newSelection.first;
                    });
                  },
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('8-week activity',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            'Completed workouts over eight rolling 7-day periods. Oldest left, current right.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Workouts')),
                      ButtonSegment(value: true, label: Text('Sets')),
                    ],
                    selected: {_showSets},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showSets = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(8, (i) {
                          final bucket = buckets[i];
                          final value = _showSets ? bucket.mainSetCount : bucket.workoutCount;
                          final heightFactor = value / safeMax;
                          final barHeight = value == 0 ? 4.0 : (20 + heightFactor * 90);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$value',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: value == 0
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.primary,
                                    ),
                                    semanticsLabel: _showSets
                                        ? '$value Main sets in period ${i + 1}'
                                        : '$value workouts in period ${i + 1}',
                                  ),
                                  const SizedBox(height: 4),
                                  Semantics(
                                    label: _showSets
                                        ? 'Period ${i + 1}: $value Main sets'
                                        : 'Period ${i + 1}: $value workouts',
                                    child: Container(
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: bucket.isCurrent
                                            ? colorScheme.primary
                                            : colorScheme.primary.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(8, (i) {
                        final label = _getBucketLabel(i, isNarrow);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Current week',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Previous weeks',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (maxValue == 0) ...[
              const SizedBox(height: 8),
              Text('No workouts in last 8 weeks.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ],
        );
      },
    );
  }

  String _getBucketLabel(int index, bool isNarrow) {
    if (isNarrow) {
      // Very short labels for 320px
      switch (index) {
        case 0:
          return '7w';
        case 1:
          return '6w';
        case 2:
          return '5w';
        case 3:
          return '4w';
        case 4:
          return '3w';
        case 5:
          return '2w';
        case 6:
          return '1w';
        case 7:
          return 'Now';
        default:
          return 'W${index + 1}';
      }
    }
    switch (index) {
      case 0:
        return '7w ago';
      case 1:
        return '6w ago';
      case 2:
        return '5w ago';
      case 3:
        return '4w ago';
      case 4:
        return '3w ago';
      case 5:
        return '2w ago';
      case 6:
        return 'Last week';
      case 7:
        return 'This week';
      default:
        return 'W${index + 1}';
    }
  }
}
