import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

class ProgressMovementTraining extends StatelessWidget {
  const ProgressMovementTraining({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  String _formatLastTrained(DateTime? last, DateTime now) {
    if (last == null) return 'Not trained in last 28 days';
    final diff = now.difference(last);
    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 1) return 'Last trained just now';
      return 'Last trained ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      if (diff.inHours == 1) return 'Last trained 1 hour ago';
      return 'Last trained ${diff.inHours} hours ago';
    }
    if (diff.inDays == 0) return 'Last trained today';
    if (diff.inDays == 1) return 'Last trained yesterday';
    if (diff.inDays < 7) return 'Last trained ${diff.inDays} days ago';
    return 'Last trained ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final movementData = analytics.movementAnalytics;
    final withData = movementData.where((m) => m.mainSets > 0).toList();
    final withoutData = movementData.where((m) => m.mainSets == 0).toList();

    final maxSets = withData.isEmpty ? 1 : withData.map((m) => m.mainSets).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Movement training',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Main-workout sets from your last 28 days.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (withData.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No Main movement training in last 28 days.',
                  style: theme.textTheme.bodyMedium),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < withData.length; i++) ...[
                    _MovementRow(
                      data: withData[i],
                      maxSets: maxSets,
                      now: analytics.now,
                      formatLast: _formatLastTrained,
                    ),
                    if (i != withData.length - 1) const Divider(height: 24),
                  ],
                ],
              ),
            ),
          ),
        if (withoutData.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Movements not trained yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('No Main sets for these movements in last 28 days.',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: withoutData.map((m) {
              return Chip(
                label: Text(m.movementPattern.label),
                backgroundColor: colorScheme.surfaceContainerHighest,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.data,
    required this.maxSets,
    required this.now,
    required this.formatLast,
  });

  final MovementTrainingAnalytics data;
  final int maxSets;
  final DateTime now;
  final String Function(DateTime?, DateTime) formatLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final barWidthFactor = maxSets == 0 ? 0.0 : data.mainSets / maxSets;

    return Semantics(
      label:
          '${data.movementPattern.label}: ${data.mainSets} Main sets, ${data.sessions} sessions, ${formatLast(data.lastTrained, now)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.movementPattern.label,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text('${data.mainSets} sets',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barWidthFactor,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('${data.sessions} sessions',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ),
              Expanded(
                child: Text(
                  formatLast(data.lastTrained, now),
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
