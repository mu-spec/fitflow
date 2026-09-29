import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

class ProgressConsistency extends StatelessWidget {
  const ProgressConsistency({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Training consistency',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Weeks with at least one completed workout.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${analytics.activeWeeksCount} of 4 recent weeks',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Based on last 28 days divided into four 7-day periods.',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Visual indicator of 4 weeks
        Row(
          children: List.generate(4, (i) {
            // buckets 4,5,6,7 are last 4 weeks
            final bucketIndex = 4 + i;
            final bucket = analytics.trendBuckets[bucketIndex];
            final hasWorkout = bucket.workoutCount > 0;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                height: 8,
                decoration: BoxDecoration(
                  color: hasWorkout ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
