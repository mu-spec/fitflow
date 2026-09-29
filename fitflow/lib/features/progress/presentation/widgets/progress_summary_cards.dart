import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

class ProgressSummaryCards extends StatelessWidget {
  const ProgressSummaryCards({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0 min';
    final totalMinutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) return '$hours' 'h';
      return '$hours' 'h $mins' 'm';
    }
    if (totalMinutes > 0 && seconds == 0) return '$totalMinutes min';
    if (totalMinutes > 0) return '$totalMinutes' 'm $seconds' 's';
    return '$seconds' 's';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your progress', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Based on workout history stored on this device.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Analytics use your recent saved FitFlow history.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isNarrow = maxWidth < 360;
            final cards = [
              _SummaryCard(
                title: 'Saved workouts',
                value: '${analytics.savedWorkoutsCount}',
                subtitle: 'Workouts stored on this device',
              ),
              _SummaryCard(
                title: 'Last 7 days',
                value: '${analytics.currentPeriod.workoutCount}',
                subtitle: 'Completed workouts',
              ),
              _SummaryCard(
                title: 'Main sets — last 7 days',
                value: '${analytics.currentPeriod.mainSets}',
                subtitle: 'Main sets completed',
              ),
              _SummaryCard(
                title: 'Planned time — last 7 days',
                value: _formatDuration(analytics.currentPeriod.plannedDuration),
                subtitle: 'Planned training time',
              ),
            ];

            if (isNarrow) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 12),
                  ]
                ],
              );
            }

            // 2 columns
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards.map((c) => SizedBox(width: (maxWidth - 12) / 2, child: c)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, this.subtitle});
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
