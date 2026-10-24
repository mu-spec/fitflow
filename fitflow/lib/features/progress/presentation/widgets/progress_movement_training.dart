import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'progress_presentation.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

class ProgressMovementTraining extends StatelessWidget {
  const ProgressMovementTraining(
      {super.key,
      required this.analytics,
      this.showHeading = true,
      this.compact = false});

  final TrainingAnalytics analytics;
  final bool showHeading;
  final bool compact;

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

    final maxSets = withData.isEmpty
        ? 1
        : withData.map((m) => m.mainSets).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading)
          Semantics(
            header: true,
            child: Text(
              context.l10n.progressMovementTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          'Main-workout sets from your last 28 days.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        if (withData.isEmpty)
          ProgressRows(
            child: Text(
              'No Main movement training in last 28 days.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ProgressRows(
            padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
            child: Column(
              children: [
                for (var i = 0; i < withData.length; i++) ...[
                  _MovementRow(
                    data: withData[i],
                    compact: compact,
                    maxSets: maxSets,
                    now: analytics.now,
                    formatLast: _formatLastTrained,
                  ),
                  if (i != withData.length - 1)
                    const Divider(height: FitFlowSpace.md),
                ],
              ],
            ),
          ),
        if (withoutData.isNotEmpty) ...[
          const SizedBox(height: FitFlowSpace.md),
          Semantics(
            header: true,
            child: Text(
              context.l10n.progressNotTrained28,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(withoutData.map((m) => m.movementPattern.label).join(' · '),
              style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.data,
    required this.compact,
    required this.maxSets,
    required this.now,
    required this.formatLast,
  });

  final MovementTrainingAnalytics data;
  final bool compact;
  final int maxSets;
  final DateTime now;
  final String Function(DateTime?, DateTime) formatLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fitFlowTheme = FitFlowTheme.of(context);
    final barWidthFactor = maxSets == 0 ? 0.0 : data.mainSets / maxSets;

    return Semantics(
      label:
          '${data.movementPattern.label}: ${data.mainSets} Main sets, ${data.sessions} sessions, ${formatLast(data.lastTrained, now)}',
      excludeSemantics: true,
      child: compact
          ? LayoutBuilder(builder: (context, constraints) {
              final label = Text(data.movementPattern.label,
                  style: theme.textTheme.bodyMedium);
              final count =
                  Text('${data.mainSets}', style: theme.textTheme.bodyMedium);
              final bar = LinearProgressIndicator(
                  value: barWidthFactor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: fitFlowTheme.subtleSurface,
                  color: fitFlowTheme.brand);
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                  constraints.maxWidth < 280) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: label),
                        const SizedBox(width: 8),
                        count
                      ]),
                      const SizedBox(height: 6),
                      bar,
                    ]);
              }
              return Row(children: [
                SizedBox(width: 80, child: label),
                const SizedBox(width: 8),
                Expanded(child: bar),
                const SizedBox(width: 12),
                SizedBox(width: 32, child: count),
              ]);
            })
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.movementPattern.label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: FitFlowSpace.xs),
                    Text(
                      '${data.mainSets} sets',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: FitFlowSpace.xxs),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barWidthFactor,
                      minHeight: 8,
                      backgroundColor: fitFlowTheme.subtleSurface,
                      color: fitFlowTheme.brand,
                    ),
                  ),
                ),
                const SizedBox(height: FitFlowSpace.xs),
                Wrap(spacing: 12, runSpacing: 2, children: [
                  Text('${data.sessions} sessions',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text(formatLast(data.lastTrained, now),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ]),
              ],
            ),
    );
  }
}
